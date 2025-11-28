targetScope = 'resourceGroup'

@description('Environment name')
param environment string

@description('Azure region')
param location string

// User-Assigned Managed Identity
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'econeura-identity-${environment}'
  location: location
  tags: {
    environment: environment
    project: 'econeura'
  }
}

output id string = managedIdentity.id
output principalId string = managedIdentity.properties.principalId
output clientId string = managedIdentity.properties.clientId
