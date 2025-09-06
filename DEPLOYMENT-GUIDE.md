# Enterprise Authentication System - Production Deployment Guide

## Deployment Architecture Overview

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│                 │     │                 │     │                 │
│    Frontend     │────▶│   Auth API      │────▶│   Database      │
│    (Optional)   │     │   Service       │     │   (PostgreSQL)  │
│                 │     │                 │     │                 │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                              │
                              │
                              ▼
                        ┌─────────────────┐
                        │   Email         │
                        │   Service       │
                        │   (SMTP)        │
                        └─────────────────┘
```

## Step 1: Infrastructure Setup

### 1.1 Database Setup (PostgreSQL)
- Create a managed PostgreSQL database (Azure Database for PostgreSQL or AWS RDS)
- Set up appropriate security groups/firewall rules
- Create database user with limited permissions
- Configure connection pooling
- Set up automated backups

**Sample Azure PostgreSQL setup:**
```bash
# Using Azure CLI
az postgres server create \
  --name myauthdb \
  --resource-group myResourceGroup \
  --location eastus \
  --admin-user dbadmin \
  --admin-password <secure-password> \
  --sku-name GP_Gen5_2 \
  --version 12

# Create firewall rule for API service
az postgres server firewall-rule create \
  --resource-group myResourceGroup \
  --server-name myauthdb \
  --name allow-api-service \
  --start-ip-address <API-SERVER-IP> \
  --end-ip-address <API-SERVER-IP>
```

### 1.2 Setup API Service Environment
- Use a Platform-as-a-Service (Azure App Service, AWS Elastic Beanstalk)
- Or set up containerized deployment (Docker + Kubernetes)
- Configure auto-scaling based on traffic
- Set up CI/CD pipeline

**Sample Azure App Service setup:**
```bash
# Create App Service Plan
az appservice plan create \
  --name myauthplan \
  --resource-group myResourceGroup \
  --sku P1V2 \
  --is-linux

# Create Web App
az webapp create \
  --name myauthservice \
  --resource-group myResourceGroup \
  --plan myauthplan \
  --runtime "NODE|18-lts"
```

## Step 2: Environment Configuration

### 2.1 Environment Variables
Create a secure configuration for production with these required variables:

```
# Database Configuration
POSTGRES_HOST=myauthdb.postgres.database.azure.com
POSTGRES_PORT=5432
POSTGRES_USER=dbadmin
POSTGRES_PASSWORD=<secure-password>
POSTGRES_DATABASE=authdb
POSTGRES_SSL=true

# JWT Configuration
JWT_SECRET=<generate-strong-random-string>
JWT_REFRESH_SECRET=<generate-different-strong-random-string>
JWT_ACCESS_EXPIRY=900  # 15 minutes in seconds
JWT_REFRESH_EXPIRY=604800  # 7 days in seconds

# OAuth Configuration
GOOGLE_CLIENT_ID=<from-google-developer-console>
GOOGLE_CLIENT_SECRET=<from-google-developer-console>
GITHUB_CLIENT_ID=<from-github-developer-settings>
GITHUB_CLIENT_SECRET=<from-github-developer-settings>

# Email Service (For Phase 6 features)
SMTP_HOST=smtp.sendgrid.net
SMTP_PORT=587
SMTP_USER=apikey
SMTP_PASSWORD=<sendgrid-api-key>
EMAIL_FROM=noreply@yourdomain.com

# Security Settings
NODE_ENV=production
PORT=8080
RATE_LIMIT_WINDOW_MS=900000  # 15 minutes
RATE_LIMIT_MAX_REQUESTS=20
CORS_ORIGINS=https://your-frontend-domain.com
```

### 2.2 Set Environment Variables in App Service
```bash
# Azure example
az webapp config appsettings set \
  --name myauthservice \
  --resource-group myResourceGroup \
  --settings @env-settings.json
```

## Step 3: Prepare Application for Deployment

### 3.1 Update Database Configuration
Ensure the application is properly configured to use PostgreSQL:

```javascript
// Verify database config is production-ready
const sequelize = new Sequelize(process.env.POSTGRES_DATABASE, process.env.POSTGRES_USER, process.env.POSTGRES_PASSWORD, {
  host: process.env.POSTGRES_HOST,
  port: process.env.POSTGRES_PORT,
  dialect: 'postgres',
  dialectOptions: {
    ssl: process.env.POSTGRES_SSL === 'true' ? {
      require: true,
      rejectUnauthorized: false
    } : false
  },
  logging: false,
  pool: {
    max: 10,
    min: 0,
    acquire: 30000,
    idle: 10000
  }
});
```

### 3.2 Set up Production Optimizations
Add production-specific middleware and optimizations:

```javascript
// Add these optimizations to server.js
if (process.env.NODE_ENV === 'production') {
  // Compression for faster response
  const compression = require('compression');
  app.use(compression());
  
  // Force HTTPS
  app.use((req, res, next) => {
    if (req.headers['x-forwarded-proto'] !== 'https') {
      return res.redirect(['https://', req.get('Host'), req.url].join(''));
    }
    return next();
  });
  
  // Stricter CSP for production
  app.use(helmet({
    contentSecurityPolicy: {
      directives: {
        defaultSrc: ["'self'"],
        scriptSrc: ["'self'"],
        styleSrc: ["'self'", "'unsafe-inline'"],
        imgSrc: ["'self'", "data:"],
        connectSrc: ["'self'"],
        fontSrc: ["'self'"],
        objectSrc: ["'none'"],
        mediaSrc: ["'self'"],
        frameSrc: ["'self'", "accounts.google.com"]
      }
    }
  }));
}
```

## Step 4: Deployment Process

### 4.1 Build and Package Application
```bash
# Install production dependencies only
npm ci --only=production

# Create deployment package
zip -r deploy.zip . -x "*.git*" "node_modules/*/test/*" "*.md" "test/*"
```

### 4.2 Database Migrations
Create and run proper database migrations:

```bash
# Create database tables
node scripts/migrate.js
```

Or use Sequelize CLI migrations:
```bash
npx sequelize-cli db:migrate --env production
```

### 4.3 Deploy Application
Deploy the packaged application to your chosen platform:

**Azure App Service:**
```bash
az webapp deployment source config-zip \
  --resource-group myResourceGroup \
  --name myauthservice \
  --src deploy.zip
```

**AWS Elastic Beanstalk:**
```bash
eb deploy
```

**Docker:**
```bash
docker build -t auth-api:1.0.0 .
docker tag auth-api:1.0.0 your-registry/auth-api:1.0.0
docker push your-registry/auth-api:1.0.0
```

## Step 5: Post-Deployment Verification

### 5.1 Health Check Endpoint
Verify the server is running properly:
```bash
curl https://myauthservice.azurewebsites.net/health
```

### 5.2 Run Basic Authentication Tests
```bash
# Test user registration
curl -X POST https://myauthservice.azurewebsites.net/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com", "password":"SecurePass123!", "name":"Admin User"}'

# Test login
curl -X POST https://myauthservice.azurewebsites.net/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com", "password":"SecurePass123!"}'
```

### 5.3 Create Initial Admin User
After deployment, create an admin user:

```bash
# Using the CLI admin tool (must configure env vars for this as well)
NODE_ENV=production \
POSTGRES_HOST=myauthdb.postgres.database.azure.com \
POSTGRES_USER=dbadmin \
POSTGRES_PASSWORD=<secure-password> \
POSTGRES_DATABASE=authdb \
node auth-admin.js promote --email admin@example.com
```

## Step 6: Monitoring and Maintenance

### 6.1 Set up Application Monitoring
Integrate with an APM (Application Performance Monitoring) tool:

- Azure Monitor + Application Insights
- AWS CloudWatch
- New Relic
- Datadog

For Azure App Service:
```bash
# Add Application Insights
az webapp config appsettings set \
  --name myauthservice \
  --resource-group myResourceGroup \
  --settings APPINSIGHTS_INSTRUMENTATIONKEY=<instrumentation-key>
```

### 6.2 Configure Logging
Set up proper logging for production:

```javascript
// Add to your server.js
const winston = require('winston');
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.json(),
  defaultMeta: { service: 'auth-service' },
  transports: [
    new winston.transports.File({ filename: 'error.log', level: 'error' }),
    new winston.transports.File({ filename: 'combined.log' })
  ]
});

// In production, also log to the console with timestamps
if (process.env.NODE_ENV === 'production') {
  logger.add(new winston.transports.Console({
    format: winston.format.combine(
      winston.format.timestamp(),
      winston.format.json()
    )
  }));
}

// Export for use in other modules
module.exports = logger;
```

### 6.3 Setup Database Backup Strategy
Configure automated backups:

```bash
# Azure PostgreSQL automated backup (enabled by default)
# Adjust retention days
az postgres server update \
  --name myauthdb \
  --resource-group myResourceGroup \
  --backup-retention 14
```

## Step 7: SSL and Domain Configuration

### 7.1 Configure Custom Domain
```bash
# Add custom domain to Azure App Service
az webapp config hostname add \
  --webapp-name myauthservice \
  --resource-group myResourceGroup \
  --hostname auth-api.yourdomain.com
```

### 7.2 Set up SSL Certificate
```bash
# Add managed certificate in Azure
az webapp config ssl create \
  --resource-group myResourceGroup \
  --name myauthservice \
  --hostname auth-api.yourdomain.com
```

## Step 8: Security Hardening

### 8.1 Azure Security Recommendations
- Enable Azure Security Center for your resources
- Configure Azure Defender for SQL
- Set up Azure Private Link for database access
- Configure WAF (Web Application Firewall) via Azure Front Door

### 8.2 Network Security
- Configure IP restrictions for admin endpoints
- Set up VNet integration for App Service
- Use Private Endpoints for database access

### 8.3 Rate Limiting and Security Headers
Verify these are properly configured for production.

## Step 9: CI/CD Pipeline Integration

### 9.1 Set up GitHub Actions
Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy Authentication API

on:
  push:
    branches: [ main ]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '18'
        cache: 'npm'
    
    - name: Install dependencies
      run: npm ci
    
    - name: Run tests
      run: npm test
      
    - name: Create deployment package
      run: zip -r deploy.zip . -x "*.git*" "node_modules/*/test/*" "*.md" "test/*"
    
    - name: Deploy to Azure App Service
      uses: azure/webapps-deploy@v2
      with:
        app-name: 'myauthservice'
        publish-profile: ${{ secrets.AZURE_WEBAPP_PUBLISH_PROFILE }}
        package: ./deploy.zip
        
    - name: Post-deployment checks
      run: |
        sleep 30  # Allow deployment to complete
        curl https://myauthservice.azurewebsites.net/health
```

## Step 10: Documentation

### 10.1 Create API Documentation
Document all authentication endpoints using Swagger/OpenAPI:

```javascript
// Add to server.js
const swaggerUi = require('swagger-ui-express');
const swaggerDocument = require('./swagger.json');

if (process.env.NODE_ENV === 'development') {
  app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerDocument));
}
```

### 10.2 Create Runbook for Operations
Document common operational tasks:
- How to restart services
- How to check logs
- How to perform database backups/restores
- How to rotate secrets/keys
- How to scale resources

## Conclusion

This deployment plan provides a comprehensive guide to deploying your enterprise authentication system to a production environment. By following these steps, you'll ensure a secure, scalable, and maintainable authentication service for your applications.

Remember to:
- Regularly update dependencies for security patches
- Rotate secrets periodically
- Monitor for unusual activity
- Set up alerts for system health
- Perform regular security audits
- Test disaster recovery procedures

With proper deployment and maintenance, your authentication system will provide robust identity management for all connected applications.
