@description('Nombre del entorno (dev, staging, prod)')
param environment string

@description('Ubicación para frontend')
param location string

@description('Nombre base del sistema ECONEURA-FULL')
param baseName string

@description('Nombre de la Static Web App (opcional)')
@allowed([
  ''
])
param staticWebAppName string = ''

var resolvedStaticWebAppName = empty(staticWebAppName) ? '${baseName}-frontend-${environment}' : staticWebAppName

@description('Tags comunes para el frontend')
var frontendTags = {
  environment: environment
  system: baseName
  component: 'frontend'
}

// Static Web App que servirá el frontend construido con Vite
resource staticWeb 'Microsoft.Web/staticSites@2022-03-01' = {
  name: resolvedStaticWebAppName
  location: location
  sku: {
    name: 'Free'
    tier: 'Free'
  }
  properties: {
    repositoryUrl: ''
    branch: ''
    buildProperties: {
      appLocation: 'packages/frontend'
      outputLocation: 'dist'
    }
  }
  tags: frontendTags
}

@description('URL pública del frontend')
output frontendHostname string = staticWeb.properties.defaultHostname

