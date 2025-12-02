targetScope = 'resourceGroup'

@description('Environment name')
param environment string

@description('Azure region')
param location string

@description('Managed Identity Principal ID')
param managedIdentityId string

// Key Vault - SECURED WITH PRIVATE NETWORKING
resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: 'econeurakv${take(environment, 8)}'
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: false
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    // CRITICAL SECURITY FIX: Disable public access
    publicNetworkAccess: 'Disabled'
    // Network ACLs: Deny by default, allow only Azure services
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
      ipRules: []
      virtualNetworkRules: []
    }
    accessPolicies: []
  }
  tags: {
    environment: environment
    project: 'econeura'
  }
}

// Role assignment: Key Vault Secrets User
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, managedIdentityId, 'KeyVaultSecretsUser')
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')
    principalId: managedIdentityId
    principalType: 'ServicePrincipal'
  }
}

output id string = keyVault.id
output name string = keyVault.name
output uri string = keyVault.properties.vaultUri
