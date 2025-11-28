# set-github-secrets.ps1
# Script para configurar los 3 secretos faltantes en GitHub

Write-Host "Configurando secretos en GitHub..." -ForegroundColor Cyan

# PASO 1: Obtener el Client Secret de Azure AD
Write-Host "`n1. Necesito el Client Secret REAL de Azure AD" -ForegroundColor Yellow
Write-Host "   Ve a: Azure Portal > Azure AD > App registrations > Econeura-Deploy-Agent > Certificates & secrets" -ForegroundColor Gray
$clientSecret = Read-Host "Pega aqui el valor del Client Secret"

# PASO 2: Configurar AZURE_CREDENTIALS
Write-Host "`n2. Configurando AZURE_CREDENTIALS..." -ForegroundColor Yellow
$azureCredentials = @"
{
  "clientId": "9551aadf-6690-4a4b-8635-9e4f15643db3",
  "clientSecret": "$clientSecret",
  "subscriptionId": "a0991f95-16e0-4f03-85df-db3d69004d94",
  "tenantId": "d35f8c15-6e8e-4d56-b7e9-2d64fdfc213e",
  "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
  "resourceManagerEndpointUrl": "https://management.azure.com/",
  "activeDirectoryGraphResourceId": "https://graph.windows.net/",
  "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
  "galleryEndpointUrl": "https://gallery.azure.com/",
  "managementEndpointUrl": "https://management.core.windows.net/"
}
"@

$azureCredentials | gh secret set AZURE_CREDENTIALS --repo ECONEURA-EMPRESA/ECONEURA-GO
if ($LASTEXITCODE -eq 0) {
    Write-Host "   AZURE_CREDENTIALS configurado correctamente" -ForegroundColor Green
}
else {
    Write-Error "   Falló la configuración de AZURE_CREDENTIALS"
    exit 1
}

# PASO 3: Configurar AZURE_WEBAPP_PUBLISH_PROFILE_BACKEND
Write-Host "`n3. Configurando AZURE_WEBAPP_PUBLISH_PROFILE_BACKEND..." -ForegroundColor Yellow
Write-Host "   Localiza el archivo XML del publish profile que descargaste" -ForegroundColor Gray
$publishProfilePath = Read-Host "Pega aqui la ruta completa al archivo XML"

if (Test-Path $publishProfilePath) {
    Get-Content $publishProfilePath | gh secret set AZURE_WEBAPP_PUBLISH_PROFILE_BACKEND --repo ECONEURA-EMPRESA/ECONEURA-GO
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   AZURE_WEBAPP_PUBLISH_PROFILE_BACKEND configurado correctamente" -ForegroundColor Green
    }
    else {
        Write-Error "   Falló la configuración de AZURE_WEBAPP_PUBLISH_PROFILE_BACKEND"
        exit 1
    }
}
else {
    Write-Error "   No se encontró el archivo XML en la ruta especificada"
    exit 1
}

# PASO 4: Configurar AZURE_STATIC_WEB_APPS_API_TOKEN
Write-Host "`n4. Configurando AZURE_STATIC_WEB_APPS_API_TOKEN..." -ForegroundColor Yellow
Write-Host "   Pega el token completo del Static Web App (empieza con 6577944f...)" -ForegroundColor Gray
$swaToken = Read-Host "Token"

$swaToken | gh secret set AZURE_STATIC_WEB_APPS_API_TOKEN --repo ECONEURA-EMPRESA/ECONEURA-GO
if ($LASTEXITCODE -eq 0) {
    Write-Host "   AZURE_STATIC_WEB_APPS_API_TOKEN configurado correctamente" -ForegroundColor Green
}
else {
    Write-Error "   Falló la configuración de AZURE_STATIC_WEB_APPS_API_TOKEN"
    exit 1
}

# PASO 5: Verificar todos los secretos
Write-Host "`n5. Verificando todos los secretos..." -ForegroundColor Yellow
gh secret list --repo ECONEURA-EMPRESA/ECONEURA-GO

Write-Host "`nTODOS LOS SECRETOS CONFIGURADOS CORRECTAMENTE" -ForegroundColor Green
Write-Host "El próximo push a 'develop' o 'main' desplegará automáticamente a Azure" -ForegroundColor Cyan
