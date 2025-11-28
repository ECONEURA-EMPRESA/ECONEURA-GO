# SCRIPT AUTOMATIZADO - OBTENER TODOS LOS SECRETOS
Write-Host "=== SECRETOS GITHUB DESDE AZURE ===" -ForegroundColor Cyan

# 1. DATABASE_URL
Write-Host "`n1. DATABASE_URL:" -ForegroundColor Yellow
$dbHost = az postgres flexible-server show --resource-group econeura-rg --name econeura-psql-production --query "fullyQualifiedDomainName" -o tsv
$dbUrl = "postgresql://econadmin:EcoNeura2025!Secure@$dbHost:5432/econeura_db?sslmode=require"
Write-Host $dbUrl -ForegroundColor Green

# 2. REDIS_HOST
Write-Host "`n2. REDIS_HOST:" -ForegroundColor Yellow
$redisHost = az redis show --name econeura-redis-production --resource-group econeura-rg --query "hostName" -o tsv
Write-Host $redisHost -ForegroundColor Green

# 3. REDIS_PASSWORD
Write-Host "`n3. REDIS_PASSWORD:" -ForegroundColor Yellow
$redisPass = az redis list-keys --name econeura-redis-production --resource-group econeura-rg --query "primaryKey" -o tsv
Write-Host $redisPass -ForegroundColor Green

# 4. AZURE_STORAGE_CONNECTION_STRING
Write-Host "`n4. AZURE_STORAGE_CONNECTION_STRING:" -ForegroundColor Yellow
$storageConn = az storage account show-connection-string --name econeurastorageprod --resource-group econeura-rg -o tsv
Write-Host $storageConn -ForegroundColor Green

# 5. APPLICATIONINSIGHTS_CONNECTION_STRING
Write-Host "`n5. APPLICATIONINSIGHTS_CONNECTION_STRING:" -ForegroundColor Yellow
$aiConn = az monitor app-insights component show --app econeura-insights-production --resource-group econeura-rg --query "connectionString" -o tsv
Write-Host $aiConn -ForegroundColor Green

# 6. AZURE_APP_SERVICE_URL
Write-Host "`n6. AZURE_APP_SERVICE_URL:" -ForegroundColor Yellow
$backendHost = az webapp show --name econeura-backend-production --resource-group econeura-rg --query "defaultHostName" -o tsv
Write-Host "https://$backendHost" -ForegroundColor Green

# 7. AZURE_STATIC_WEB_APP_URL
Write-Host "`n7. AZURE_STATIC_WEB_APP_URL:" -ForegroundColor Yellow
$frontendHost = az staticwebapp show --name econeura-frontend-production --resource-group econeura-rg --query "defaultHostname" -o tsv
Write-Host "https://$frontendHost" -ForegroundColor Green

# 8. AZURE_STATIC_WEB_APPS_API_TOKEN
Write-Host "`n8. AZURE_STATIC_WEB_APPS_API_TOKEN:" -ForegroundColor Yellow
$swaToken = az staticwebapp secrets list --name econeura-frontend-production --resource-group econeura-rg --query "properties.apiKey" -o tsv
Write-Host $swaToken -ForegroundColor Green

Write-Host "`n=== RESUMEN ===" -ForegroundColor Cyan
$allSecrets = @"
DATABASE_URL=$dbUrl
REDIS_HOST=$redisHost
REDIS_PASSWORD=$redisPass
AZURE_STORAGE_CONNECTION_STRING=$storageConn
APPLICATIONINSIGHTS_CONNECTION_STRING=$aiConn
AZURE_APP_SERVICE_URL=https://$backendHost
AZURE_STATIC_WEB_APP_URL=https://$frontendHost
AZURE_STATIC_WEB_APPS_API_TOKEN=$swaToken
"@

Write-Host $allSecrets -ForegroundColor White

Write-Host "`n=== COPIANDO AL PORTAPAPELES ===" -ForegroundColor Cyan
Set-Clipboard $allSecrets
Write-Host "Todos los secretos copiados al portapapeles!" -ForegroundColor Green
Write-Host "`nGuardalo en un archivo de texto para referenciar" -ForegroundColor Yellow
Write-Host "`nFalta obtener separadamente:" -ForegroundColor Yellow
Write-Host "  - AZURE_WEBAPP_PUBLISH_PROFILE_BACKEND (ejecutar comando en la guia)" -ForegroundColor White
