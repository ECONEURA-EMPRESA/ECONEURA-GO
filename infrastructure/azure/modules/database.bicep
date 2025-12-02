targetScope = 'resourceGroup'

@description('Environment name')
param environment string

@description('Azure region')
param location string

@description('PostgreSQL admin username')
param adminUsername string

@description('PostgreSQL admin password')
@secure()
param adminPassword string

@description('VNet ID for private endpoint')
param vnetId string

@description('Subnet ID for database')
param dbSubnetId string

// PostgreSQL Flexible Server - SECURED WITH PRIVATE NETWORKING
resource postgresServer 'Microsoft.DBforPostgreSQL/flexibleServers@2023-03-01-preview' = {
  name: 'econeura-psql-${environment}'
  location: location
  sku: {
    name: 'Standard_D2s_v3'
    tier: 'GeneralPurpose'
  }
  properties: {
    administratorLogin: adminUsername
    administratorLoginPassword: adminPassword
    version: '16'
    storage: {
      storageSizeGB: 128
      autoGrow: 'Enabled'
    }
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Enabled'
    }
    highAvailability: {
      mode: 'Disabled'
    }
    // CRITICAL SECURITY FIX: Disable public access and use VNet
    publicNetworkAccess: 'Disabled'
    network: {
      delegatedSubnetResourceId: dbSubnetId
      privateDnsZoneArmResourceId: ''  // Private DNS will be configured separately
    }
  }
  tags: {
    environment: environment
    project: 'econeura'
  }
}

// Database
resource database 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2023-03-01-preview' = {
  name: 'econeura_db'
  parent: postgresServer
  properties: {
    charset: 'UTF8'
    collation: 'en_US.utf8'
  }
}

// REMOVED: Firewall rule exposing 0.0.0.0
// Public network access is now disabled - database only accessible via VNet

output id string = postgresServer.id
output name string = postgresServer.name
output fqdn string = postgresServer.properties.fullyQualifiedDomainName
