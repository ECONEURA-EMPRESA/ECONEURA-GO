targetScope = 'resourceGroup'

@description('Environment (dev, staging, prod)')
@allowed(['dev', 'staging', 'prod'])
param env string = 'dev'

@description('Location for all resources')
param location string = resourceGroup().location

@description('Base name for ECONEURA-OK')
param baseName string = 'econeura-ok'

@secure()
@description('PostgreSQL admin password')
param postgresAdminPassword string

@secure()
@description('Gemini API Key for NEURAs')
param geminiApiKey string

// ============================================
// SKUS CONDICIONALES POR ENVIRONMENT
// ============================================
var skus = {
  dev: {
    appService: 'B1'                    // €10/mes
    postgres: 'Standard_B1ms'           // €10/mes
    redis: 'C0'                         // €15/mes (Basic)
    redisTier: 'Basic'
    postgresHighAvailability: 'Disabled'
    postgresStorageGB: 32
  }
  staging: {
    appService: 'B2'                    // €30/mes
    postgres: 'Standard_B2s'            // €30/mes
    redis: 'C0'                         // €15/mes (Basic)
    redisTier: 'Basic'
    postgresHighAvailability: 'Disabled'
    postgresStorageGB: 32
  }
  prod: {
    appService: 'S1'                    // €60/mes (Always On, Slots)
    postgres: 'Standard_D2s_v3'         // €150/mes (2 vCores, 8GB RAM)
    redis: 'C1'                         // €70/mes (1GB, Standard)
    redisTier: 'Standard'
    postgresHighAvailability: 'ZoneRedundant'  // Alta disponibilidad
    postgresStorageGB: 128
  }
}

var currentSku = skus[env]

// ============================================
// MODULE 1: MONITORING (CRÍTICO)
// ============================================
module monitoring 'monitoring.bicep' = {
  name: 'monitoringDeploy'
  params: {
    environment: env
    location: location
    baseName: baseName
  }
}

// ============================================
// MODULE 2: POSTGRESQL (11 NEURAS + USUARIOS)
// ============================================
module postgres 'modules/postgres.bicep' = {
  name: 'postgresDeploy'
  params: {
    environment: env
    location: location
    baseName: baseName
    postgresAdminPassword: postgresAdminPassword
  }
}

// ============================================
// MODULE 3: REDIS (RATE LIMITING + CACHE)
// ============================================
module redis 'modules/redis.bicep' = {
  name: 'redisDeploy'
  params: {
    environment: env
    location: location
    baseName: baseName
    redisSku: currentSku.redis
    enableAutoPause: env == 'dev'
  }
}

// ============================================
// MODULE 4: BLOB STORAGE (DOCUMENTOS RAG)
// ============================================
module storage 'storage.bicep' = {
  name: 'storageDeploy'
  params: {
    environment: env
    location: location
    baseName: baseName
    accessTier: 'Hot'
    redundancy: env == 'prod' ? 'GRS' : 'LRS'  // GRS para prod
  }
}

// ============================================
// MODULE 5: KEY VAULT (SECRETOS)
// ============================================
module keyvault 'keyvault.bicep' = {
  name: 'keyvaultDeploy'
  params: {
    environment: env
    location: location
    baseName: baseName
    databaseUrlPlaceholder: 'postgresql://placeholder'
    openAiApiKey: geminiApiKey
  }
}

// ============================================
// MODULE 6: APP SERVICE PLAN
// ============================================
resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: 'asp-${baseName}-${env}'
  location: location
  sku: {
    name: currentSku.appService
    tier: env == 'prod' ? 'Standard' : 'Basic'
  }
  properties: {
    reserved: true  // Linux
  }
  tags: {
    environment: env
    project: 'ECONEURA-OK'
  }
}

// ============================================
// MODULE 7: BACKEND APP SERVICE
// ============================================
module appBackend 'modules/app-backend.bicep' = {
  name: 'appBackendDeploy'
  params: {
    environment: env
    location: location
    baseName: baseName
    appInsightsConnectionString: monitoring.outputs.appInsightsConnectionString
    databaseHost: postgres.outputs.databaseHost
    databaseName: postgres.outputs.databaseName
    redisHost: redis.outputs.redisHost
    storageAccountName: storage.outputs.storageAccountNameOutput
  }
  dependsOn: [
    appServicePlan
  ]
}

// ============================================
// MODULE 8: FRONTEND (STATIC WEB APP)
// ============================================
resource staticWebApp 'Microsoft.Web/staticSites@2022-03-01' = {
  name: 'swa-${baseName}-${env}'
  location: location
  sku: {
    name: 'Free'
    tier: 'Free'
  }
  properties: {
    repositoryUrl: 'https://github.com/ECONEURA-EMPRESA/ECONEURA-OK'
    branch: env == 'prod' ? 'main' : 'develop'
    buildProperties: {
      appLocation: 'packages/frontend'
      apiLocation: ''
      outputLocation: 'dist'
    }
  }
  tags: {
    environment: env
    project: 'ECONEURA-OK'
  }
}

// ============================================
// OUTPUTS PARA GITHUB SECRETS
// ============================================
output appServiceUrl string = appBackend.outputs.defaultHostName
output staticWebAppUrl string = staticWebApp.properties.defaultHostname
output databaseHost string = postgres.outputs.databaseHost
output databaseName string = postgres.outputs.databaseName
output redisHost string = redis.outputs.redisHost
output storageAccountName string = storage.outputs.storageAccountNameOutput
output appInsightsConnectionString string = monitoring.outputs.appInsightsConnectionString
output keyVaultUri string = keyvault.outputs.keyVaultUri

// Full connection strings (para configurar en GitHub Secrets)
output databaseUrl string = 'postgresql://econeuraadmin:${postgresAdminPassword}@${postgres.outputs.databaseHost}/econeura_app'
output redisUrl string = 'redis://${redis.outputs.redisHost}:6379'
