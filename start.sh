#!/bin/bash

# Limpiar cualquier pid file previo y iniciar el daemon de Docker
rm -f /var/run/docker.pid
dockerd &

# Esperar a que Docker esté listo
echo "Esperando a que Docker esté disponible..."
while ! docker info > /dev/null 2>&1; do
    sleep 1
done

echo "Docker está listo. Iniciando PRE-CKAN..."

# Cambiar al directorio ckan-docker
cd /app/ckan-docker

# Verificar que estamos en el directorio correcto
ls -la

# Crear archivo .env si no existe
if [ ! -f .env ]; then
    cp .env.example .env
fi

# Modificar el archivo .env con las variables de entorno personalizadas
if [ ! -z "$ADMIN_USERNAME" ]; then
    sed -i "s/CKAN_SYSADMIN_NAME=.*/CKAN_SYSADMIN_NAME=$ADMIN_USERNAME/" .env
fi

if [ ! -z "$ADMIN_PASSWORD" ]; then
    sed -i "s/CKAN_SYSADMIN_PASSWORD=.*/CKAN_SYSADMIN_PASSWORD=$ADMIN_PASSWORD/" .env
fi

if [ ! -z "$ADMIN_EMAIL" ]; then
    sed -i "s/CKAN_SYSADMIN_EMAIL=.*/CKAN_SYSADMIN_EMAIL=$ADMIN_EMAIL/" .env
fi

if [ ! -z "$CKAN_SITE_URL" ]; then
    sed -i "s|CKAN_SITE_URL=.*|CKAN_SITE_URL=$CKAN_SITE_URL|" .env
fi

# Arreglar configuración del datapusher
if ! grep -q "CKAN__DATAPUSHER__API_TOKEN" .env; then
    echo "CKAN__DATAPUSHER__API_TOKEN=your-secret-token" >> .env
fi

echo "Configuración actualizada:"
grep -E "(CKAN_SYSADMIN_NAME|CKAN_SYSADMIN_PASSWORD|CKAN_SYSADMIN_EMAIL|CKAN_SITE_URL)" .env

# Iniciar MongoDB en segundo plano
echo "Iniciando MongoDB..."
docker run -d \
    --name mongodb-internal \
    --network host \
    -e MONGO_INITDB_ROOT_USERNAME=${ADMIN_USERNAME:-admin} \
    -e MONGO_INITDB_ROOT_PASSWORD=${ADMIN_PASSWORD:-admin123} \
    -v mongodb_data:/data/db \
    -p 27017:27017 \
    mongo:latest

echo "MongoDB iniciado en puerto 27017"

# Esperar a que MongoDB esté listo
echo "Esperando a que MongoDB esté listo..."
until docker exec mongodb-internal mongosh --eval "db.runCommand({ping: 1})" > /dev/null 2>&1; do
    echo "MongoDB no está listo aún, esperando..."
    sleep 5
done

# Iniciar Mongo Express para interfaz web de MongoDB
echo "Iniciando Mongo Express..."
docker run -d \
    --name mongo-express-internal \
    --network host \
    -e ME_CONFIG_MONGODB_ADMINUSERNAME=${ADMIN_USERNAME:-admin} \
    -e ME_CONFIG_MONGODB_ADMINPASSWORD=${ADMIN_PASSWORD:-admin123} \
    -e ME_CONFIG_MONGODB_URL=mongodb://${ADMIN_USERNAME:-admin}:${ADMIN_PASSWORD:-admin123}@127.0.0.1:27017/ \
    -e ME_CONFIG_BASICAUTH_USERNAME=${ADMIN_USERNAME:-admin} \
    -e ME_CONFIG_BASICAUTH_PASSWORD=${ADMIN_PASSWORD:-admin123} \
    -p 8081:8081 \
    mongo-express:latest

echo "Mongo Express iniciado en puerto 8081"

# Construir e iniciar los servicios de PRE-CKAN
echo "Iniciando PRE-CKAN..."
docker compose up --build -d

# Esperar a que PRE-CKAN esté completamente listo
echo "Esperando a que PRE-CKAN esté listo..."
until curl -s http://localhost:5000/api/3/action/status_show > /dev/null 2>&1; do
    echo "PRE-CKAN no está listo aún, esperando..."
    sleep 10
done

echo "PRE-CKAN está listo. Creando token de API..."

# Crear token de API para el usuario administrador
ADMIN_USER=${ADMIN_USERNAME:-admin}
TOKEN_NAME="api-token-$(date +%s)"

# Ejecutar comando dentro del contenedor CKAN para crear token
API_TOKEN_OUTPUT=$(docker compose exec -T ckan ckan user token add $ADMIN_USER $TOKEN_NAME 2>/dev/null)
API_TOKEN=$(echo "$API_TOKEN_OUTPUT" | grep "API Token created:" -A 1 | tail -1 | sed 's/^[[:space:]]*//')

if [ ! -z "$API_TOKEN" ]; then
    echo "===========================================" 
    echo "🔑 TOKEN DE API CREADO EXITOSAMENTE:"
    echo "👤 Usuario: $ADMIN_USER"
    echo "🎫 Token: $API_TOKEN"
    echo "📝 Nombre: $TOKEN_NAME"
    echo "🌐 Usar con: http://localhost:5000/api/3/action/"
    echo "==========================================="
    
    # Guardar token en archivos para acceso posterior
    mkdir -p /app/tokens
    echo "CKAN_API_TOKEN=$API_TOKEN" > /app/tokens/ckan_token.env
    echo "$API_TOKEN" > /app/tokens/api_token.txt
    echo "Token guardado en: /app/tokens/ckan_token.env y /app/tokens/api_token.txt"
else
    echo "❌ Error: No se pudo crear el token de API"
fi

# Mostrar resumen de URLs de acceso
echo "==========================================="
echo "🌐 SERVICIOS DISPONIBLES:"
echo "🔗 PRE-CKAN: http://localhost:5001"
echo "🔗 NGINX: http://localhost:81"
echo "🔗 MongoDB: mongodb://localhost:27017"
echo "🖥️  Mongo Express: http://localhost:8081"
echo "📊 Credenciales: ${ADMIN_USERNAME:-admin}/${ADMIN_PASSWORD:-admin123}"
echo "🔑 API Token: $API_TOKEN"
echo "==========================================="

# Mantener logs visibles
docker compose logs -f

# Mantener el contenedor activo
tail -f /dev/null