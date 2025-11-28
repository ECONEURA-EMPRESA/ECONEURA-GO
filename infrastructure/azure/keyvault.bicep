@description('Nombre del entorno (dev, staging, prod)')
param environment string

@description('Ubicación para Key Vault')
param location string

@description('Nombre base del sistema ECONEURA-FULL')
param baseName string

@description('Nombre del Key Vault (opcional)')
@allowed([
  ''
])
param keyVaultName string = ''

@secure()
@description('Valor para OPENAI_API_KEY (no usar en producción sin rotarlo)')
param openAiApiKey string

@secure()
@description('Valor para DATABASE_URL placeholder (no usar en producción sin rotarlo)')
param databaseUrlPlaceholder string

var resolvedVaultName = empty(keyVaultName) ? 'kv-${baseName}-${environment}' : keyVaultName

@description('Tags comunes para Key Vault')
var keyVaultTags = {
  environment: environment
  system: baseName
  component: 'keyvault'
}

resource vault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: resolvedVaultName
  location: location
  properties: {
    enableSoftDelete: true
    enablePurgeProtection: true
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    accessPolicies: [] // Se gestionan fuera de la plantilla (RBAC recomendado)
  }
  tags: keyVaultTags
}

// Secrets para documentar el modelo. En entornos reales estos valores
// deben gestionarse y rotarse desde pipelines/portal.
// OJO: los nombres de secretos de Key Vault sólo permiten [a-zA-Z0-9-]
resource openAiSecret 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  name: 'openai-api-key'
  parent: vault
  properties: {
    value: openAiApiKey
  }
}

resource databaseUrlSecret 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  name: 'database-url'
  parent: vault
  properties: {
    value: databaseUrlPlaceholder
  }
}

@description('Nombre del Key Vault creado')
output keyVaultNameOutput string = vault.name

