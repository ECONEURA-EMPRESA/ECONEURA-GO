@description('Nombre del entorno (dev, staging, prod)')
param environment string

@description('Ubicación para recursos de monitorización')
param location string

@description('Nombre base del sistema ECONEURA-FULL')
param baseName string

var workspaceName = 'logs-${baseName}-${environment}'
var appInsightsName = 'ai-${baseName}-${environment}'

@description('Tags comunes para recursos de monitorización')
var monitoringTags = {
  environment: environment
  system: baseName
  component: 'monitoring'
}

// Log Analytics Workspace
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: workspaceName
  location: location
  properties: {
    retentionInDays: 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
  tags: monitoringTags
}

// Application Insights vinculado al workspace
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Bluefield'
    Request_Source: 'rest'
    WorkspaceResourceId: logAnalytics.id
  }
  tags: monitoringTags
}

@description('Connection string de Application Insights para usar en el backend')
output appInsightsConnectionString string = appInsights.properties.ConnectionString

