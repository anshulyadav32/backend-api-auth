# Quick-Start Deployment Guide

This guide provides the essential steps to deploy your enterprise authentication system to production quickly.

## 1. Set up Azure Resources

### Create Resource Group
```bash
az group create --name auth-system-rg --location eastus
```

### Create PostgreSQL Database
```bash
az postgres server create \
  --name auth-system-db \
  --resource-group auth-system-rg \
  --location eastus \
  --admin-user dbadmin \
  --admin-password <strong-password> \
  --sku-name GP_Gen5_2 \
  --version 12

# Create a database
az postgres db create \
  --server-name auth-system-db \
  --resource-group auth-system-rg \
  --name authdb
```

### Create App Service
```bash
# Create App Service Plan
az appservice plan create \
  --name auth-system-plan \
  --resource-group auth-system-rg \
  --sku P1V2 \
  --is-linux

# Create Web App
az webapp create \
  --name auth-system-api \
  --resource-group auth-system-rg \
  --plan auth-system-plan \
  --runtime "NODE|18-lts"
```

## 2. Configure Environment

### Create .env File Locally
```bash
# Create a local .env file with all required variables
cat > .env.production <<EOL
# Database Configuration
POSTGRES_HOST=auth-system-db.postgres.database.azure.com
POSTGRES_PORT=5432
POSTGRES_USER=dbadmin
POSTGRES_PASSWORD=<strong-password>
POSTGRES_DATABASE=authdb
POSTGRES_SSL=true

# JWT Configuration
JWT_SECRET=$(openssl rand -hex 32)
JWT_REFRESH_SECRET=$(openssl rand -hex 32)
JWT_ACCESS_EXPIRY=900
JWT_REFRESH_EXPIRY=604800

# OAuth Configuration
GOOGLE_CLIENT_ID=<from-google-console>
GOOGLE_CLIENT_SECRET=<from-google-console>
GITHUB_CLIENT_ID=<from-github>
GITHUB_CLIENT_SECRET=<from-github>

# Security Settings
NODE_ENV=production
PORT=8080
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=20
CORS_ORIGINS=https://your-frontend-domain.com
EOL
```

### Upload Configuration to Azure
```bash
# Convert .env file to JSON format
node -e "require('dotenv').config({path: '.env.production'}); const settings = Object.entries(process.env).map(([k,v]) => ({name: k, value: v})); require('fs').writeFileSync('app-settings.json', JSON.stringify(settings));"

# Apply settings to App Service
az webapp config appsettings set \
  --name auth-system-api \
  --resource-group auth-system-rg \
  --settings @app-settings.json
```

## 3. Package and Deploy

### Install Production Dependencies
```bash
npm ci --production
```

### Create Deployment Package
```bash
zip -r deploy.zip . -x "*.git*" "node_modules/*/test/*" "test/*" "*.md" ".env*"
```

### Deploy to Azure
```bash
az webapp deployment source config-zip \
  --name auth-system-api \
  --resource-group auth-system-rg \
  --src deploy.zip
```

## 4. Verify Deployment

### Check Health Endpoint
```bash
curl https://auth-system-api.azurewebsites.net/health
```

### Create Initial Admin User
```bash
# Using the CLI admin tool (via Kudu Console in Azure Portal)
cd D:\home\site\wwwroot
node auth-admin.js list-users
node auth-admin.js promote --email admin@example.com
```

## 5. Set Up Monitoring

### Enable Application Insights
```bash
# Create Application Insights resource
az monitor app-insights component create \
  --app auth-system-insights \
  --resource-group auth-system-rg \
  --location eastus

# Get the instrumentation key
APPINSIGHTS_KEY=$(az monitor app-insights component show \
  --app auth-system-insights \
  --resource-group auth-system-rg \
  --query instrumentationKey \
  --output tsv)

# Add instrumentation key to web app settings
az webapp config appsettings set \
  --name auth-system-api \
  --resource-group auth-system-rg \
  --settings APPLICATIONINSIGHTS_CONNECTION_STRING="InstrumentationKey=$APPINSIGHTS_KEY"
```

### Set Up Alerts
```bash
# Create alert for server errors
az monitor metrics alert create \
  --name "High-Error-Rate" \
  --resource-group auth-system-rg \
  --scopes $(az monitor app-insights component show --app auth-system-insights --resource-group auth-system-rg --query id --output tsv) \
  --condition "count requests/failed gt 10" \
  --window-size 5m \
  --evaluation-frequency 1m
```

## 6. Set Up SSL and Custom Domain

```bash
# Add custom domain
az webapp config hostname add \
  --webapp-name auth-system-api \
  --resource-group auth-system-rg \
  --hostname auth.yourdomain.com

# Add managed certificate
az webapp config ssl create \
  --resource-group auth-system-rg \
  --name auth-system-api \
  --hostname auth.yourdomain.com
```

## 7. Set Up Continuous Deployment from GitHub

```bash
# Get publishing credentials
PUBLISH_PROFILE=$(az webapp deployment list-publishing-profiles \
  --name auth-system-api \
  --resource-group auth-system-rg \
  --xml)

# Add as GitHub secret: AZURE_WEBAPP_PUBLISH_PROFILE
# Then create GitHub workflow as described in the full deployment guide
```

## Additional Commands

### Scale Up if Needed
```bash
# Scale up to more powerful instance
az appservice plan update \
  --name auth-system-plan \
  --resource-group auth-system-rg \
  --sku P2V2
```

### Enable Auto-scaling
```bash
# Set up auto-scaling rules
az monitor autoscale create \
  --resource-group auth-system-rg \
  --name autoscale-auth-system \
  --resource auth-system-plan \
  --resource-type Microsoft.Web/serverFarms \
  --min-count 1 \
  --max-count 3 \
  --count 1

# Add scale out rule
az monitor autoscale rule create \
  --resource-group auth-system-rg \
  --autoscale-name autoscale-auth-system \
  --condition "CpuPercentage > 75 avg 5m" \
  --scale out 1
```

### Database Backup
```bash
# Backup database (Azure PostgreSQL has automatic backups)
# Adjust retention period
az postgres server update \
  --name auth-system-db \
  --resource-group auth-system-rg \
  --backup-retention 14
```

This quick-start guide covers the essential steps to deploy your authentication system to Azure. For more details and alternative deployment options, refer to the comprehensive deployment guide.
