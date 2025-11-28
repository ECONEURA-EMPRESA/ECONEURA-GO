@description('Nombre del entorno (dev, staging, prod)')
param environment string

@description('Ubicación para la base de datos')
param location string

@description('Nombre base del sistema ECONEURA-FULL')
param baseName string

@description('Nombre del servidor PostgreSQL (opcional). Si no se especifica se deriva de baseName+environment.')
@allowed([
  ''
])
param postgresServerName string = ''

@description('Usuario administrador de PostgreSQL')
param postgresAdminUser string = 'econeuraadmin'

@description('Nombre de la base de datos lógica')
param postgresDatabaseName string = 'econeura_app'

// Nota importante:
// La contraseña del admin NUNCA debe estar hardcodeada en la plantilla.
// Se pasa desde parámetros seguros (GitHub/Azure DevOps) o se gestiona vía Key Vault.
@secure()
@description('Password del usuario administrador de PostgreSQL (NO guardar en el repo)')
param postgresAdminPassword string

var serverName = empty(postgresServerName) ? 'pg-${baseName}-${environment}' : postgresServerName

@description('Tags comunes para recursos de base de datos')
var databaseTags = {
  environment: environment
  system: baseName
  component: 'database'
}

resource postgres 'Microsoft.DBforPostgreSQL/flexibleServers@2022-12-01' = {
  name: serverName
  location: location
  sku: {
    name: 'Standard_B2s'
    tier: 'Burstable'
  }
  properties: {
    administratorLogin: postgresAdminUser
    administratorLoginPassword: postgresAdminPassword
    version: '16'
    storage: {
      storageSizeGB: 32
    }
    highAvailability: {
      mode: 'Disabled'
    }
    backup: {
      backupRetentionDays: 7
    }
  }
  tags: databaseTags
}

resource postgresDb 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2022-12-01' = {
  name: postgresDatabaseName
  parent: postgres
  properties: {}
}

// No devolvemos la connection string completa (con password) para evitar exponer credenciales.
// En su lugar exponemos las partes necesarias para construir DATABASE_URL en el runtime/CI.
@description('Host del servidor PostgreSQL (sin usuario ni password)')
output databaseHost string = '${postgres.name}.postgres.database.azure.com'

@description('Nombre lógico de la base de datos')
output databaseName string = postgresDb.name

