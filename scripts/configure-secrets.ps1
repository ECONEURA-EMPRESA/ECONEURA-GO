# PowerShell Script - Windows Version
# Usage: .\configure-secrets.ps1

$ErrorActionPreference = "Stop"
$REPO = "ECONEURA-EMPRESA/ECONEURA-OK"

Write-Host "`n🔐 GitHub Secrets Automation - ECONEURA-OK`n" -ForegroundColor Cyan

# Check prerequisites
if (!(Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Host "❌ GitHub CLI (gh) not installed" -ForegroundColor Red
    Write-Host "Install: https://cli.github.com/"
    exit 1
}

if (!(Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Azure CLI (az) not installed" -ForegroundColor Red
    Write-Host "Install: https://docs.microsoft.com/cli/azure/install-azure-cli"
    exit 1
}

# Check GitHub CLI auth
try {
    gh auth status 2>&1 | Out-Null
}
catch {
    Write-Host "⚠️  Not logged in to GitHub CLI" -ForegroundColor Yellow
    gh auth login
}

# Check Azure CLI auth
try {
    az account show 2>&1 | Out-Null
}
catch {
    Write-Host "⚠️  Not logged in to Azure CLI" -ForegroundColor Yellow
    az login
}

Write-Host "✅ Prerequisites OK`n" -ForegroundColor Green

# Get Azure subscription
$SUBSCRIPTION_ID = az account show --query id -o tsv
Write-Host "📋 Subscription ID: $SUBSCRIPTION_ID"

# 1. AZURE_CREDENTIALS
Write-Host "`n[1/4] Creating Service Principal..." -ForegroundColor Cyan
$SP_NAME = "econeura-github-actions-$(Get-Date -Format 'yyyyMMddHHmmss')"

$SP_JSON = az ad sp create-for-rbac `
    --name $SP_NAME `
    --role Contributor `
    --scopes "/subscriptions/$SUBSCRIPTION_ID" `
    --sdk-auth 2>$null

if ($LASTEXITCODE -eq 0) {
    $SP_JSON | gh secret set AZURE_CREDENTIALS -R $REPO
    Write-Host "✅ AZURE_CREDENTIALS configured" -ForegroundColor Green
}
else {
    Write-Host "❌ Failed to create Service Principal" -ForegroundColor Red
    exit 1
}

# 2. AZURE_WEBAPP_NAME_BACKEND
Write-Host "`n[2/4] Searching for Backend App Service..." -ForegroundColor Cyan

$BACKEND_NAMES = az webapp list --query "[?contains(name, 'econeura') || contains(name, 'backend')].name" -o tsv

if ([string]::IsNullOrEmpty($BACKEND_NAMES)) {
    $BACKEND_NAME = Read-Host "Enter Backend App Service name"
}
else {
    Write-Host "Found App Services:"
    $BACKEND_NAMES_ARRAY = $BACKEND_NAMES -split "`n"
    for ($i = 0; $i -lt $BACKEND_NAMES_ARRAY.Length; $i++) {
        Write-Host "[$($i+1)] $($BACKEND_NAMES_ARRAY[$i])"
    }
    $selection = Read-Host "Select number"
    $BACKEND_NAME = $BACKEND_NAMES_ARRAY[[int]$selection - 1]
}

$BACKEND_NAME | gh secret set AZURE_WEBAPP_NAME_BACKEND -R $REPO
Write-Host "✅ AZURE_WEBAPP_NAME_BACKEND = $BACKEND_NAME" -ForegroundColor Green

# 3. AZURE_WEBAPP_PUBLISH_PROFILE_BACKEND
Write-Host "`n[3/4] Getting Backend Publish Profile..." -ForegroundColor Cyan

$RG = az webapp show --name $BACKEND_NAME --query resourceGroup -o tsv
$PUBLISH_PROFILE = az webapp deployment list-publishing-profiles `
    --name $BACKEND_NAME `
    --resource-group $RG `
    --xml 2>$null

if ($PUBLISH_PROFILE) {
    $PUBLISH_PROFILE | gh secret set AZURE_WEBAPP_PUBLISH_PROFILE_BACKEND -R $REPO
    Write-Host "✅ AZURE_WEBAPP_PUBLISH_PROFILE_BACKEND configured" -ForegroundColor Green
}

# 4. AZURE_STATIC_WEB_APPS_API_TOKEN
Write-Host "`n[4/4] Searching for Static Web App..." -ForegroundColor Cyan

$SWA_NAMES = az staticwebapp list --query "[?contains(name, 'econeura') || contains(name, 'frontend')].name" -o tsv

if ([string]::IsNullOrEmpty($SWA_NAMES)) {
    $SWA_NAME = Read-Host "Enter Static Web App name (or 'skip')"
}
else {
    Write-Host "Found:"
    $SWA_NAMES_ARRAY = $SWA_NAMES -split "`n"
    for ($i = 0; $i -lt $SWA_NAMES_ARRAY.Length; $i++) {
        Write-Host "[$($i+1)] $($SWA_NAMES_ARRAY[$i])"
    }
    Write-Host "[0] Skip"
    $selection = Read-Host "Select"
    if ($selection -eq "0") {
        $SWA_NAME = "skip"
    }
    else {
        $SWA_NAME = $SWA_NAMES_ARRAY[[int]$selection - 1]
    }
}

if ($SWA_NAME -ne "skip") {
    $SWA_TOKEN = az staticwebapp secrets list --name $SWA_NAME --query "properties.apiKey" -o tsv 2>$null
    if ($SWA_TOKEN) {
        $SWA_TOKEN | gh secret set AZURE_STATIC_WEB_APPS_API_TOKEN -R $REPO
        Write-Host "✅ AZURE_STATIC_WEB_APPS_API_TOKEN configured" -ForegroundColor Green
    }
}

Write-Host "`n🎉 Secrets Configuration Complete!`n" -ForegroundColor Green
Write-Host "View: https://github.com/$REPO/settings/secrets/actions"
Write-Host "`nNext: Run 'App Deploy' workflow on GitHub Actions"
