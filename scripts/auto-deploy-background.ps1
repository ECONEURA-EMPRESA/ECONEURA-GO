# ============================================
# SCRIPT DEPLOYMENT AUTOMÁTICO (PowerShell)
# Ejecuta deployment y configuración de secrets en background
# ============================================

$logFile = "deployment-automation.log"
$outputsFile = "deployment-outputs.json"

Start-Transcript -Path $logFile -Append

Write-Output "🚀 Iniciando deployment automático en background (PowerShell)..."
Get-Date

# 1. Ejecutar Deployment
Write-Output "📦 Desplegando infraestructura Azure..."
# Nota: Usamos un placeholder para la API Key si no está definida, para no bloquear.
$geminiKey = $env:GEMINI_API_KEY
if ([string]::IsNullOrEmpty($geminiKey)) {
    $geminiKey = "PLACEHOLDER_KEY_UPDATE_LATER"
    Write-Output "⚠️ Usando placeholder para Gemini API Key. Actualizar manualmente en App Service."
}

az deployment group create `
  --resource-group rg-econeura-ok-prod `
  --template-file infrastructure/azure/main.bicep `
  --parameters `
    postgresAdminPassword='Q5elkWEcQKm5iK+LGO5OaxxUpqaG52y9' `
    geminiApiKey=$geminiKey `
  --query properties.outputs -o json > $outputsFile

if ($LASTEXITCODE -ne 0) {
    Write-Output "❌ Error en deployment. Reintentando en 30s..."
    Start-Sleep -Seconds 30
    az deployment group create `
      --resource-group rg-econeura-ok-prod `
      --template-file infrastructure/azure/main.bicep `
      --parameters `
        postgresAdminPassword='Q5elkWEcQKm5iK+LGO5OaxxUpqaG52y9' `
        geminiApiKey=$geminiKey `
      --query properties.outputs -o json > $outputsFile
}

if (-not (Test-Path $outputsFile)) {
    Write-Output "❌ Error fatal: No se generó archivo de outputs"
    Stop-Transcript
    exit 1
}

Write-Output "✅ Infraestructura desplegada. Configurando secrets..."

# 2. Leer Outputs
$json = Get-Content $outputsFile | ConvertFrom-Json
$appUrl = $json.appServiceUrl.value
$dbUrl = $json.databaseUrl.value
$redisHost = $json.redisHost.value
$redisPort = $json.redisPort.value
$redisKey = $json.redisPrimaryKey.value
$insights = $json.appInsightsConnectionString.value
$storage = $json.storageConnectionString.value
$staticUrl = $json.staticWebAppUrl.value

# 3. Configurar Secrets
Write-Output "🔑 Configurando GitHub Secrets..."

gh secret set AZURE_APP_SERVICE_URL -b "https://$appUrl"
gh secret set DATABASE_URL -b "$dbUrl"
gh secret set REDIS_HOST -b "$redisHost"
gh secret set REDIS_PORT -b "$redisPort"
gh secret set REDIS_PASSWORD -b "$redisKey"
gh secret set APPLICATIONINSIGHTS_CONNECTION_STRING -b "$insights"
gh secret set AZURE_STORAGE_CONNECTION_STRING -b "$storage"
gh secret set AZURE_STATIC_WEB_APP_URL -b "https://$staticUrl"
gh secret set NODE_ENV -b "production"
gh secret set USE_MEMORY_STORE -b "false"
# Configurar la key real si la tenemos, o el placeholder
gh secret set GEMINI_API_KEY -b "$geminiKey"

Write-Output "✅ Secrets configurados."

# 4. Trigger CI/CD
Write-Output "🚀 Disparando CI/CD..."
gh workflow run ci.yml --ref feat/omega-protocol-10-10

Write-Output "🎉 PROCESO COMPLETADO EXITOSAMENTE"
Get-Date
Stop-Transcript
