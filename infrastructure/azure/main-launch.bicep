targetScope = 'resourceGroup'

// ============================================
// PLAN DE DESPEGUE: $190 USD BUDGET
// Optimizado para funcionalidad máxima con presupuesto limitado
// Mes 1: Validación y crecimiento
// Mes 2+: Upgrade a SKUs production-grade
// ============================================

@description('Environment - usa "launch" para el plan de despegue')
@allowed(['launch', 'prod'])
param env string = 'launch'

@description('Location for all resources')
param location string = resourceGroup().location

@description('Base name for ECONEURA-OK')
param baseName string = 'econeura-ok'

@secure()
@description('PostgreSQL admin password (minimum 8 characters)')
param postgresAdminPassword string

@secure()
@description('Gemini API Key for NEURAs')
param geminiApiKey string

// ============================================
// SKUS OPTIMIZADOS PARA $190 BUDGET
// ============================================
var launchSkus = {
  // App Service B3: $55/mes - 4 cores, 7GB RAM
  // EXCELENTE para 11 NEURAs + usuarios concurrentes
  appService: 'B3'
  appServiceTier: 'Basic'
  
  // PostgreSQL B2s: $55/mes - 2 vCores, 4GB RAM
  // Suficiente para empezar, upgrade fácil después
  postgres: 'Standard_B2s'
  postgresStorageGB: 64
  postgresBackupRetention: 7
  
  // Redis Basic C1: $35/mes - 1GB
  // Bien para rate limiting + cache básico
  redis: 'C1'
  redisTier: 'Basic'
  
  // Storage: $10/mes
  storageRedundancy: 'LRS'
  storageTier: 'Hot'
}

var prodSkus = {
  // Para cuando tengas más presupuesto (mes 2+)
  appService: 'S2'
  appServiceTier: 'Standard'
  postgres: 'Standard_D2s_v3'
  postgresStorageGB: 128
  postgresBackupRetention: 14
  redis: 'C2'
  redisTier: 'Standard'
  storageRedundancy: 'GRS'
  storageTier: 'Hot'
}

var currentSkus = env == 'launch' ? launchSkus : prodSkus

// ============================================
// MODULE 1: MONITORING (Application Insights)
// $20/mes para 5GB/día
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
// MODULE 2: POSTGRESQL
// $55/mes - Standard_B2s (2 vCores, 4GB RAM)
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
// MODULE 3: REDIS CACHE
// $35/mes - Basic C1 (1GB)
// ============================================
module redis 'modules/redis.bicep' = {
  name: 'redisDeploy'
  params: {
    environment: env
    location: location
    baseName: baseName
    redisSku: currentSkus.redis
    enableAutoPause: false  // Always on
  }
}

// ============================================
// MODULE 4: BLOB STORAGE
// $10/mes - Standard LRS Hot
// ============================================
module storage 'storage.bicep' = {
  name: 'storageDeploy'
  params: {
    environment: env
    location: location
    baseName: baseName
    accessTier: currentSkus.storageTier
    redundancy: currentSkus.storageRedundancy
  }
}

// ============================================
// MODULE 5: KEY VAULT (Incluido en B3 pricing)
// ============================================
module keyvault 'keyvault.bicep' = {
  name: 'keyvaultDeploy'
  params: {
    environment: env
    location: location
    baseName: baseName
    databaseUrlPlaceholder: 'will-be-set-by-outputs'
    openAiApiKey: geminiApiKey
  }
}

// ============================================
// MODULE 6: APP SERVICE PLAN
// $55/mes - B3 (4 cores, 7GB RAM)
// CRÍTICO: Este es el mejor bang-for-buck
// ============================================
resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: 'asp-${baseName}-${env}'
  location: location
  sku: {
    name: currentSkus.appService
    tier: currentSkus.appServiceTier
    capacity: 1  // 1 instancia para empezar
  }
  properties: {
    reserved: true  // Linux (más barato que Windows)
  }
  tags: {
    environment: env
    project: 'ECONEURA-OK'
    budget: 'launch-190usd'
  }
}

// ============================================
// MODULE 7: BACKEND APP SERVICE
// ============================================
resource appService 'Microsoft.Web/sites@2022-03-01' = {
  name: 'app-${baseName}-${env}'
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'NODE|20-lts'
      alwaysOn: currentSkus.appServiceTier != 'Basic'
      http20Enabled: true
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
      appSettings: [
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~20'
        }
        {
          name: 'NODE_ENV'
          value: 'production'
        }
        {
          name: 'PORT'
          value: '8080'
        }
        {
          name: 'DATABASE_URL'
          value: 'postgresql://econeuraadmin:${postgresAdminPassword}@${postgres.outputs.databaseHost}/econeura_app?sslmode=require'
        }
        {
          name: 'REDIS_URL'
          value: 'redis://${redis.outputs.redisHost}:6379'
        }
        {
          name: 'GEMINI_API_KEY'
          value: geminiApiKey
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: monitoring.outputs.appInsightsInstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: monitoring.outputs.appInsightsConnectionString
        }
        {
          name: 'AZURE_STORAGE_CONNECTION_STRING'
          value: storage.outputs.storageConnectionString
        }
        {
          name: 'USE_MEMORY_STORE'
          value: 'false'
        }
      ]
    }
  }
  tags: {
    environment: env
    project: 'ECONEURA-OK'
    budget: 'launch-190usd'
  }
  dependsOn: [
    appServicePlan
  ]
}

// ============================================
// MODULE 8: STATIC WEB APP (FREE)
// $0/mes - Frontend con CDN global
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
    branch: 'main'
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
output appServiceUrl string = appService.properties.defaultHostName
output staticWebAppUrl string = staticWebApp.properties.defaultHostname
output databaseHost string = postgres.outputs.databaseHost
output databaseName string = postgres.outputs.databaseName
output redisHost string = redis.outputs.redisHost
output storageAccountName string = storage.outputs.storageAccountNameOutput
output appInsightsConnectionString string = monitoring.outputs.appInsightsConnectionString
output keyVaultUri string = keyvault.outputs.keyVaultUri

// Connection strings completas
output databaseUrl string = 'postgresql://econeuraadmin:${postgresAdminPassword}@${postgres.outputs.databaseHost}/econeura_app?sslmode=require'
output redisUrl string = 'redis://${redis.outputs.redisHost}:6379'

// Budget tracking
output estimatedMonthlyCost string = env == 'launch' ? '$175 USD (~€165)' : '$295 USD (~€280)'
output nextMonthUpgradePath string = 'Change env parameter from "launch" to "prod" and redeploy'
