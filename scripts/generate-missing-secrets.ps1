# generate-missing-secrets.ps1
# Automates the retrieval of the 3 MISSING secrets for ECONEURA
# PREREQUISITE: Run 'az login' first!

Write-Host "Fetching Missing Secrets..." -ForegroundColor Cyan

# Check Azure Login
$account = az account show --output json | ConvertFrom-Json
if (!$account) {
    Write-Error "Not logged in to Azure. Please run 'az login' first."
    exit 1
}
Write-Host "Logged in as: $($account.user.name)" -ForegroundColor Green

# 1. AZURE_CREDENTIALS
Write-Host ""
Write-Host "1. Generating AZURE_CREDENTIALS..." -ForegroundColor Yellow
$subId = $account.id
$spName = "econeura-gh-actions"
# Using --sdk-auth is deprecated but still often used for GitHub Actions. 
# If it fails, we might need to use a different approach, but sticking to the request.
$creds = az ad sp create-for-rbac --name $spName --role contributor --scopes /subscriptions/$subId --sdk-auth --output json
if ($creds) {
    Write-Host "AZURE_CREDENTIALS generated!" -ForegroundColor Green
    $creds | Set-Content "secret_AZURE_CREDENTIALS.json"
    Write-Host "Saved to: secret_AZURE_CREDENTIALS.json" -ForegroundColor Cyan
}
else {
    Write-Error "Failed to generate AZURE_CREDENTIALS"
}

# 2. AZURE_WEBAPP_PUBLISH_PROFILE_BACKEND
Write-Host ""
Write-Host "2. Fetching AZURE_WEBAPP_PUBLISH_PROFILE_BACKEND..." -ForegroundColor Yellow
$rgName = "econeura-rg" 
$appName = "econeura-backend-production" 
$profile = az webapp deployment list-publishing-profiles --name $appName --resource-group $rgName --xml --output tsv
if ($profile) {
    Write-Host "Publish Profile fetched!" -ForegroundColor Green
    $profile | Set-Content "secret_PUBLISH_PROFILE.xml"
    Write-Host "Saved to: secret_PUBLISH_PROFILE.xml" -ForegroundColor Cyan
}
else {
    Write-Error "Failed to fetch Publish Profile (Check Resource Group / App Name)"
}

# 3. AZURE_STATIC_WEB_APPS_API_TOKEN
Write-Host ""
Write-Host "3. Fetching AZURE_STATIC_WEB_APPS_API_TOKEN..." -ForegroundColor Yellow
$staticAppName = "econeura-frontend" 
$token = az staticwebapp secrets list --name $staticAppName --resource-group $rgName --query "properties.apiKey" --output tsv
if ($token) {
    Write-Host "Static Web App Token fetched!" -ForegroundColor Green
    $token | Set-Content "secret_SWA_TOKEN.txt"
    Write-Host "Saved to: secret_SWA_TOKEN.txt" -ForegroundColor Cyan
}
else {
    Write-Error "Failed to fetch SWA Token (Check Resource Group / App Name)"
}

Write-Host ""
Write-Host "DONE! Open the generated files to copy your secrets." -ForegroundColor Green
