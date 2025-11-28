@description('Nombre del entorno (dev, staging, prod)')
param environment string

@description('Ubicación para Storage Account')
param location string

@description('Nombre base del sistema ECONEURA-FULL')
param baseName string

@description('Nombre del Storage Account (opcional, debe ser único globalmente)')
@allowed([
  ''
])
param storageAccountName string = ''

@description('Tier de almacenamiento (Hot, Cool, Archive)')
@allowed([
  'Hot'
  'Cool'
])
param accessTier string = 'Hot'

@description('Redundancia (LRS, GRS, ZRS)')
@allowed([
  'LRS'
  'GRS'
  'ZRS'
])
param redundancy string = 'LRS'

// Generar nombre único si no se proporciona
var uniqueSuffix = uniqueString(resourceGroup().id, baseName, environment)
var resolvedStorageName = empty(storageAccountName) 
  ? 'st${baseName}${environment}${uniqueSuffix}' 
  : storageAccountName

@description('Tags comunes para Storage Account')
var storageTags = {
  environment: environment
  system: baseName
  component: 'storage'
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: resolvedStorageName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_${redundancy}'
  }
  properties: {
    accessTier: accessTier
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false // Seguridad: no permitir acceso público
    allowSharedKeyAccess: true
  }
  tags: storageTags
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  name: 'default'
  parent: storageAccount
}

// Container para documentos RAG
resource documentsContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  name: 'documents'
  parent: blobService
  properties: {
    publicAccess: 'None' // Privado, solo acceso vía connection string
    metadata: {
      purpose: 'RAG documents storage'
      environment: environment
    }
  }
}

// Container para otros archivos (si es necesario)
resource filesContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  name: 'files'
  parent: blobService
  properties: {
    publicAccess: 'None'
    metadata: {
      purpose: 'General file storage'
      environment: environment
    }
  }
}

@description('Nombre del Storage Account creado')
output storageAccountNameOutput string = storageAccount.name

@description('Connection string del Storage Account (se obtiene desde Key Vault o portal)')
#disable-next-line no-hardcoded-env-urls
output storageConnectionStringPlaceholder string = 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=<key>;EndpointSuffix=core.windows.net'

@description('URL base del Blob Storage')
#disable-next-line no-hardcoded-env-urls
output blobStorageUrl string = 'https://${storageAccount.name}.blob.core.windows.net'

