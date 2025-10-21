# NDP-EP Stack Demo 🚀

A complete Docker-in-Docker containerized stack for National Data Platform demonstrations, featuring PRE-CKAN, MongoDB, and web interfaces.

## 🌟 What's Included

This single Docker container provides a complete data platform stack:

- **PRE-CKAN 2.11.3** - Open data platform with PostgreSQL, Solr, Redis, Datapusher, and NGINX
- **MongoDB** - NoSQL document database with authentication
- **Mongo Express** - Web-based MongoDB administration interface
- **MinIO** - S3-compatible object storage with web console
- **Unified Authentication** - Single admin credentials for all services

## 🚀 Quick Start

### Prerequisites
- Docker and Docker Compose installed
- Available ports: 5001, 81, 27017, 8081, 9000, 9001

### Basic Usage

```bash
# Clone the repository
git clone git@github.com:rbardaji/ndp-ep-stack-demo.git
cd ndp-ep-stack-demo

# Start the complete stack
docker compose up --build -d

# View logs
docker compose logs -f

# Stop the stack
docker compose down
```

**That's it!** All services will be automatically configured and ready to use.

## 🌐 Access Points

After starting, the following services will be available:

| Service | URL | Credentials |
|---------|-----|-------------|
| **PRE-CKAN** | http://localhost:5001 | admin / admin123 |
| **NGINX** | http://localhost:81 | - |
| **MongoDB** | mongodb://localhost:27017 | admin / admin123 |
| **Mongo Express** | http://localhost:8081 | admin / admin123 |
| **MinIO API** | http://localhost:9000 | admin / admin123 |
| **MinIO Console** | http://localhost:9001 | admin / admin123 |

## 🔑 Authentication

All services use unified credentials:
- **Username**: `admin`
- **Password**: `admin123`
- **Email**: `admin@example.com`

### API Access
PRE-CKAN automatically generates an API token for the admin user:
```bash
# Get the API token
API_TOKEN=$(docker exec ndp-ep-stack-demo-pre-ckan-demo-1 cat /app/tokens/api_token.txt)

# Use the API
curl -H "Authorization: $API_TOKEN" "http://localhost:5001/api/3/action/package_list"
```

## ⚙️ Configuration

### Custom Credentials
Override default credentials using environment variables:

```bash
ADMIN_USERNAME=myuser \
ADMIN_PASSWORD=mypassword \
ADMIN_EMAIL=my@email.com \
docker compose up --build -d
```

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `ADMIN_USERNAME` | Admin username for all services | `admin` |
| `ADMIN_PASSWORD` | Admin password for all services | `admin123` |
| `ADMIN_EMAIL` | Admin email for PRE-CKAN | `admin@example.com` |
| `CKAN_SITE_URL` | PRE-CKAN site URL | `http://localhost:5001` |

### Using .env File
Create a `.env` file in the project root:

```bash
ADMIN_USERNAME=demo
ADMIN_PASSWORD=demo123
ADMIN_EMAIL=demo@example.com
CKAN_SITE_URL=http://localhost:5001
```

## 📋 Service Details

### PRE-CKAN Stack
- **PostgreSQL** - Primary database with datastore support
- **Solr** - Search engine and indexing
- **Redis** - Caching and session storage
- **Datapusher** - Data processing service
- **NGINX** - Reverse proxy and web server

### MongoDB
- **Authentication** enabled with admin user
- **Persistent storage** using Docker volumes
- **Network access** on standard port 27017

### Mongo Express
- **Web interface** for MongoDB management
- **Basic authentication** using unified credentials
- **Full database administration** capabilities

### MinIO
- **S3-compatible API** for object storage
- **Web console** for bucket and object management
- **Persistent storage** using Docker volumes
- **Access keys** configured with unified credentials

## 🛠️ Common Operations

### View Running Services
```bash
# Check all containers
docker compose ps

# Check internal services
docker exec ndp-ep-stack-demo-pre-ckan-demo-1 docker ps
```

### Access Logs
```bash
# View all logs
docker compose logs -f

# View specific service logs
docker compose logs ckan-demo
```

### Backup Data
```bash
# Export PRE-CKAN data
API_TOKEN=$(docker exec ndp-ep-stack-demo-pre-ckan-demo-1 cat /app/tokens/api_token.txt)
curl -H "Authorization: $API_TOKEN" "http://localhost:5001/api/3/action/package_search" > backup.json

# Export MongoDB data
docker exec ndp-ep-stack-demo-pre-ckan-demo-1 docker exec mongodb-internal mongodump --authenticationDatabase admin -u admin -p admin123

# Access MinIO with mc client
docker exec ndp-ep-stack-demo-pre-ckan-demo-1 docker run --rm --network host minio/mc alias set local http://localhost:9000 admin admin123
docker exec ndp-ep-stack-demo-pre-ckan-demo-1 docker run --rm --network host minio/mc ls local
```

### Reset Everything
```bash
# Stop and remove all containers and volumes
docker compose down -v

# Rebuild from scratch
docker compose up --build -d
```

## 🔧 Troubleshooting

### Services Not Starting
```bash
# Check container status
docker compose ps

# View detailed logs
docker compose logs -f

# Restart specific service
docker compose restart
```

### Port Conflicts
If ports are already in use, modify `docker-compose.yml`:
```yaml
ports:
  - "5002:5000"  # Change PRE-CKAN port
  - "82:81"      # Change NGINX port
  - "27018:27017" # Change MongoDB port
  - "8082:8081"   # Change Mongo Express port
```

### Memory Issues
The stack requires adequate memory. Ensure Docker has at least 4GB RAM allocated.

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────┐
│                Main Container                    │
│  ┌─────────────┐    ┌──────────────────────────┐│
│  │   MongoDB   │    │        PRE-CKAN         ││
│  │             │    │  ┌─────────┬──────────┐  ││
│  │   ┌─────────┤    │  │ PostgreSQL│   Solr   │  ││
│  │   │ Express │    │  ├─────────┼──────────┤  ││
│  │   │   Web   │    │  │  Redis    │Datapusher│  ││
│  │   │   UI    │    │  ├─────────┴──────────┤  ││
│  │   └─────────┤    │  │       NGINX        │  ││
│  │             │    │  └────────────────────┘  ││
│  └─────────────┘    └──────────────────────────┘│
│      :8081                    :5001, :81         │
└─────────────────────────────────────────────────┘
              Docker-in-Docker (DinD)
```

## 📦 What's Next

This stack is designed to be extensible. Future additions may include:
- Additional data processing services
- Message queues and streaming platforms
- Analytics and visualization tools
- Additional databases and storage systems

## 🤝 Contributing

This is a demonstration stack. To modify or extend:

1. Fork the repository
2. Make your changes
3. Test thoroughly
4. Submit a pull request

## 📄 License

This project is provided as-is for demonstration purposes.

## 🆘 Support

For issues or questions:
- Check the troubleshooting section above
- Review container logs for error messages
- Ensure all required ports are available
- Verify adequate system resources

---

**Built with Docker-in-Docker for easy deployment and demonstration of National Data Platform capabilities.**