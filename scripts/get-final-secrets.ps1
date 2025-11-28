# Script to retrieve final secrets for GitHub

$rg = "econeura-rg"
$backendName = "econeura-backend-production"
$frontendName = "econeura-frontend-prod"
$dbName = "econeura-psql-prod"
$dbUser = "econadmin"
$dbPass = "EcoNeura2025!Secure"

Write-Host "=== RETRIEVING FINAL SECRETS ===" -ForegroundColor Cyan

# 1. DATABASE_URL
Write-Host "`n1. DATABASE_URL:" -ForegroundColor Yellow
try {
    $dbHost = az postgres flexible-server show --resource-group $rg --name $dbName --query fullyQualifiedDomainName -o tsv
    if ($dbHost) {
        $dbUrl = "postgres://$($dbUser):$($dbPass)@$($dbHost):5432/postgres?sslmode=require"
        Write-Host $dbUrl -ForegroundColor Green
    }
    else {
        Write-Host "Error: Could not retrieve DB host" -ForegroundColor Red
    }
}
catch {
    Write-Host "Error retrieving DB info: $_" -ForegroundColor Red
}

# 2. AZURE_APP_SERVICE_URL
Write-Host "`n2. AZURE_APP_SERVICE_URL:" -ForegroundColor Yellow
try {
    $backendUrl = az webapp show --resource-group $rg --name $backendName --query defaultHostName -o tsv
    if ($backendUrl) {
        Write-Host "https://$backendUrl" -ForegroundColor Green
    }
    else {
        Write-Host "Error: Could not retrieve Backend URL (App Service might not be ready)" -ForegroundColor Red
    }
}
catch {
    Write-Host "Error retrieving Backend URL: $_" -ForegroundColor Red
}

# 3. AZURE_STATIC_WEB_APPS_API_TOKEN
Write-Host "`n3. AZURE_STATIC_WEB_APPS_API_TOKEN:" -ForegroundColor Yellow
try {
    $token = az staticwebapp secrets list --name $frontendName --resource-group $rg --query "properties.apiKey" -o tsv
    if ($token) {
        Write-Host $token -ForegroundColor Green
    }
    else {
        Write-Host "Error: Could not retrieve Static Web App Token" -ForegroundColor Red
    }
}
catch {
    Write-Host "Error retrieving SWA Token: $_" -ForegroundColor Red
}

# 4. AZURE_WEBAPP_PUBLISH_PROFILE_BACKEND
Write-Host "`n4. AZURE_WEBAPP_PUBLISH_PROFILE_BACKEND:" -ForegroundColor Yellow
try {
    $profile = az webapp deployment list-publishing-profiles --name $backendName --resource-group $rg --xml
    if ($profile) {
        Write-Host "Profile retrieved (XML content hidden for brevity, save to file to view)" -ForegroundColor Green
        $profile | Out-File "publish-profile.xml" -Encoding UTF8
        Write-Host "Saved to publish-profile.xml" -ForegroundColor Gray
    }
    else {
        Write-Host "Error: Could not retrieve Publish Profile" -ForegroundColor Red
    }
}
catch {
    Write-Host "Error retrieving Publish Profile: $_" -ForegroundColor Red
}
