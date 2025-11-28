@description('Nombre del entorno (dev, staging, prod)')
param environment string

@description('Ubicación para App Service')
param location string

@description('Nombre base del sistema ECONEURA-FULL')
param baseName string

@description('Connection string de Application Insights para el backend')
param appInsightsConnectionString string

@description('Host de la base de datos PostgreSQL (sin usuario ni password)')
param databaseHost string

@description('Nombre lógico de la base de datos PostgreSQL')
param databaseName string

@description('Host de Redis Cache (opcional)')
param redisHost string = ''

@description('Nombre del Storage Account (opcional)')
param storageAccountName string = ''

@description('Nombre del plan de App Service (opcional)')
@allowed([
  ''
])
param appServicePlanName string = ''

@description('Nombre de la app backend (opcional)')
@allowed([
  ''
])
param appServiceName string = ''

var resolvedPlanName = empty(appServicePlanName) ? 'plan-${baseName}-${environment}' : appServicePlanName
var resolvedAppName = empty(appServiceName) ? '${baseName}-backend-${environment}' : appServiceName

@description('Tags comunes para el backend')
var backendTags = {
  environment: environment
  system: baseName
  component: 'backend'
}

resource plan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: resolvedPlanName
  location: location
  kind: 'linux'
  sku: {
    name: 'B2'
    tier: 'Basic'
  }
  properties: {
    reserved: true
  }
  tags: backendTags
}

resource app 'Microsoft.Web/sites@2023-01-01' = {
  name: resolvedAppName
  location: location
  kind: 'app,linux'
  properties: {
    serverFarmId: plan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'NODE|20-lts'
      appSettings: [
        {
          name: 'NODE_ENV'
          value: 'production'
        }
        {
          name: 'PORT'
          value: '8080'
        }
        // La connection string real se inyectará vía secret/Key Vault.
        // Aquí solo dejamos un placeholder para recordar el formato.
        {
          name: 'DATABASE_URL'
          value: 'postgresql://<user>:<password>@${databaseHost}:5432/${databaseName}?sslmode=require'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
        // Redis Cache para rate limiting distribuido
        {
          name: 'REDIS_URL'
          value: !empty(redisHost) ? 'rediss://${redisHost}' : ''
        }
        // Azure Blob Storage para documentos RAG
        {
          name: 'AZURE_STORAGE_CONNECTION_STRING'
          #disable-next-line no-hardcoded-env-urls
          value: !empty(storageAccountName) ? 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=<key>;EndpointSuffix=core.windows.net' : ''
        }
        {
          name: 'AZURE_BLOB_CONTAINER'
          value: 'documents'
        }
      ]
    }
  }
  tags: backendTags
}

@description('URL base pública del backend')
output backendUrl string = 'https://${app.name}.azurewebsites.net'

