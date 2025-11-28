targetScope = 'resourceGroup'

@description('Environment name')
param environment string

@description('Azure region')
param location string

@description('VNet ID for private endpoint')
param vnetId string

@description('Subnet ID for Redis')
param redisSubnetId string

// Azure Cache for Redis (Premium tier)
resource redis 'Microsoft.Cache/redis@2023-08-01' = {
  name: 'econeuraredis${environment}'
  location: location
  properties: {
    sku: {
      name: 'Premium'
      family: 'P'
      capacity: 1
    }
    enableNonSslPort: false
    minimumTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
    redisConfiguration: {
      'maxmemory-policy': 'allkeys-lru'
    }
    redisVersion: '6'
  }
  tags: {
    environment: environment
    project: 'econeura'
  }
}

output id string = redis.id
output name string = redis.name
output hostName string = redis.properties.hostName
output sslPort int = redis.properties.sslPort
