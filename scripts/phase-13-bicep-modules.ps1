# FASE 13: Crear módulos Bicep separados
$ErrorActionPreference = "Stop"

Write-Host "☁️  Creando módulos Bicep separados..." -ForegroundColor Cyan

$modulesDir = "infrastructure/azure/modules"
New-Item -ItemType Directory -Path $modulesDir -Force | Out-Null

# Módulo: Managed Identity
$identityBicep = @"
targetScope = 'resourceGroup'

param environment string
param location string

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'econeura-identity-\${environment}'
  location: location
  tags: {
    environment: environment
    project: 'econeura'
  }
}

output id string = identity.id
output principalId string = identity.properties.principalId
output clientId string = identity.properties.clientId
"@

Set-Content "$modulesDir/identity.bicep" $identityBicep
Write-Host "  ✅ identity.bicep creado" -ForegroundColor Green

# Módulo: Key Vault
$keyvaultBicep = @"
targetScope = 'resourceGroup'

param environment string
param location string
param managedIdentityId string

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: 'econeura-kv-\${environment}'
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enablePurgeProtection: true
    softDeleteRetentionInDays: 90
  }
  tags: {
    environment: environment
    project: 'econeura'
  }
}

output name string = keyVault.name
output id string = keyVault.id
"@

Set-Content "$modulesDir/keyvault.bicep" $keyvaultBicep
Write-Host "  ✅ keyvault.bicep creado" -ForegroundColor Green

Write-Host "`n✅ FASE 13 COMPLETADA: Módulos Bicep creados" -ForegroundColor Green
