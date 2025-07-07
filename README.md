# Grim Hallow Data

A Flask web application for managing D&D monster data with MongoDB backend.

## Docker Compose Setup

This project includes three Docker Compose configurations for different environments:

### Quick Start (Development)

```bash
# Uses docker-compose.yml (development mode)
docker-compose up -d
```

### Development with Debug

```bash
# Uses docker-compose.dev.yml (debug mode, hot reload)
docker-compose -f docker-compose.dev.yml up -d
```

### Production Deployment

```bash
# Uses docker-compose.prod.yml (secure, optimized)
docker-compose -f docker-compose.prod.yml up -d
```

## Environment Files

Create a `.env` file in the project root:

```bash
MONGO_INITDB_ROOT_USERNAME=admin
MONGO_INITDB_ROOT_PASSWORD=your_secure_password_here
MONGO_DB_NAME=dnd_data
SECRET_KEY=your_secret_key_here
```

## Configuration Differences

| Feature           | Default     | Development | Production     |
| ----------------- | ----------- | ----------- | -------------- |
| Flask Environment | development | development | production     |
| Debug Mode        | No          | Yes         | No             |
| MongoDB Security  | Basic       | Basic       | Enhanced       |
| Network Isolation | No          | No          | Yes            |
| Resource Limits   | No          | No          | Yes            |
| Restart Policy    | always      | always      | unless-stopped |

## Production Deployment

For production deployments, always use `docker-compose.prod.yml` as it includes:

- **Security**: MongoDB bound to localhost, isolated networks
- **Performance**: Optimized ulimits and resource settings
- **Reliability**: Better restart policies and error handling
- **Monitoring**: Enhanced logging and process management

## Automated Deployment

The GitHub Actions workflow automatically uses `docker-compose.prod.yml` for deployments.

## Troubleshooting

See `scripts/deployment_troubleshooting.md` for common issues and solutions.

## Access

- **Local**: http://localhost:5000
- **Production**: Configure your domain/port forwarding as needed
