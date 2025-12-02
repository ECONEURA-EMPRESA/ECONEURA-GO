targetScope = 'resourceGroup'

@description('Environment name (production, staging, development)')
param environment string = 'production'

@description('Azure region for resources')
param location string = resourceGroup().location

@description('PostgreSQL admin username')
@secure()
param dbAdminUsername string

@description('PostgreSQL admin password')
@secure()
param dbAdminPassword string

@description('Custom domain for frontend (e.g. econeura.com)')
param frontendCustomDomain string = ''

// ============================================
// 1. MANAGED IDENTITY (First - everything depends on this)
// ============================================
module identity 'modules/identity.bicep' = {
  name: 'identity-deployment'
  params: {
    environment: environment
    location: location
  }
}

// ============================================
// 2. NETWORKING (Second - before private endpoints)
// ============================================
module networking 'modules/networking.bicep' = {
  name: 'networking-deployment'
  params: {
    environment: environment
    location: location
  }
}

// ============================================
// 3. KEY VAULT (Third - stores secrets)
// ============================================
module keyvault 'modules/keyvault.bicep' = {
  name: 'keyvault-deployment'
  params: {
    environment: environment
    location: location
    managedIdentityId: identity.outputs.principalId
  }
  dependsOn: [
    identity
  ]
}

// ============================================
// 4. DATABASE (PostgreSQL with Private Endpoint)
// ============================================
module database 'modules/database.bicep' = {
  name: 'database-deployment'
  params: {
    environment: environment
    location: location
    adminUsername: dbAdminUsername
    adminPassword: dbAdminPassword
    vnetId: networking.outputs.vnetId
    dbSubnetId: networking.outputs.dbSubnetId
  }
  dependsOn: [
    networking
    keyvault
  ]
}

// ============================================
// 5. REDIS (Cache with Private Endpoint)
// ============================================
module redis 'modules/redis.bicep' = {
  name: 'redis-deployment'
  params: {
    environment: environment
    location: location
    vnetId: networking.outputs.vnetId
    redisSubnetId: networking.outputs.redisSubnetId
  }
  dependsOn: [
    networking
  ]
}

// ============================================
// 6. STORAGE (Blob storage with Managed Identity)
// ============================================
module storage 'modules/storage.bicep' = {
  name: 'storage-deployment'
  params: {
    environment: environment
    location: location
    managedIdentityId: identity.outputs.principalId
  }
  dependsOn: [
    identity
  ]
}

// ============================================
// 7. MONITORING (Application Insights + Log Analytics)
// ============================================
module monitoring 'modules/monitoring.bicep' = {
  name: 'monitoring-deployment'
  params: {
    environment: environment
    location: location
  }
}

// ============================================
// 8. WEB APP (Static Web App + App Service)
// ============================================
module webapp 'modules/webapp.bicep' = {
  name: 'webapp-deployment'
  params: {
    environment: environment
    location: location
    managedIdentityId: identity.outputs.id
    appInsightsKey: monitoring.outputs.instrumentationKey
    customDomain: frontendCustomDomain
  }
  dependsOn: [
    identity
    keyvault
    database
    redis
    monitoring
  ]
}

// ============================================
// OUTPUTS
// ============================================
output identityId string = identity.outputs.id
output identityPrincipalId string = identity.outputs.principalId
output keyVaultName string = keyvault.outputs.name
output webAppUrl string = webapp.outputs.webAppUrl
output backendUrl string = webapp.outputs.backendUrl
output storageAccountName string = storage.outputs.name
output appInsightsName string = monitoring.outputs.name
