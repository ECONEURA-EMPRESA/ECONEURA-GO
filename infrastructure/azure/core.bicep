@description('Nombre del entorno (dev, staging, prod)')
param environment string

@description('Ubicación por defecto para los recursos')
param location string

@description('Nombre base del sistema ECONEURA-FULL')
param baseName string

@description('Tags comunes para todos los recursos')
var commonTags = {
  environment: environment
  system: baseName
}

// Este módulo define solo parámetros/tags comunes.
// La creación del Resource Group se realiza desde fuera del Bicep
// (GitHub Actions / CLI) para mantener responsabilidades separadas.


