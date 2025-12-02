targetScope = 'resourceGroup'

@description('Environment name')
param environment string

@description('Azure region')
param location string

@description('Managed Identity ID')
param managedIdentityId string

@description('App Insights instrumentation key')
param appInsightsKey string

@description('Custom domain for frontend (optional)')
param customDomain string = ''

// App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: 'econeura-plan-${environment}'
  location: location
  sku: {
    name: 'P1v3'
    tier: 'PremiumV3'
    capacity: 1
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
  tags: {
    environment: environment
    project: 'econeura'
  }
}

// Backend App Service
resource backendApp 'Microsoft.Web/sites@2023-01-01' = {
  name: 'econeura-backend-${environment}'
  location: location
  kind: 'app,linux'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'NODE|20-lts'
      alwaysOn: true
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      http20Enabled: true
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsightsKey
        }
        {
          name: 'NODE_ENV'
          value: environment
        }
      ]
    }
  }
  tags: {
    environment: environment
    project: 'econeura'
  }
}

// Static Web App (Frontend)
resource staticWebApp 'Microsoft.Web/staticSites@2023-01-01' = {
  name: 'econeura-frontend-${environment}'
  location: location
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
  properties: {
    repositoryUrl: 'https://github.com/ECONEURA-EMPRESA/ECONEURA'
    branch: 'main'
    buildProperties: {
      appLocation: 'packages/frontend'
      outputLocation: 'dist'
      appBuildCommand: 'npm run build'
    }
  }
  tags: {
    environment: environment
    project: 'econeura'
  }
}

resource customDomainResource 'Microsoft.Web/staticSites/customDomains@2022-03-01' = if (!empty(customDomain)) {
  parent: staticWebApp
  name: customDomain
  properties: {}
}

output webAppUrl string = 'https://${staticWebApp.properties.defaultHostname}'
output backendUrl string = 'https://${backendApp.properties.defaultHostName}'
output backendName string = backendApp.name
output frontendName string = staticWebApp.name
