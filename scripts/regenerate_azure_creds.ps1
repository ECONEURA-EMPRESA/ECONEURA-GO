# Script to regenerate Azure Credentials for GitHub Actions
$subscriptionId = "a0991f95-16e0-4f03-85df-db3d69004d94"
$resourceGroup = "rg-econeura-ok-prod"
$appName = "econeura-backend-sp"

Write-Host "Logging into Azure..."
az login

Write-Host "Setting subscription..."
az account set --subscription $subscriptionId

Write-Host "Creating Service Principal for RBAC..."
$json = az ad sp create-for-rbac --name $appName --role contributor --scopes /subscriptions/$subscriptionId/resourceGroups/$resourceGroup --sdk-auth

Write-Host "`n✅ NEW AZURE_CREDENTIALS JSON (COPY THIS):" -ForegroundColor Green
Write-Host $json -ForegroundColor Yellow

Write-Host "`n👉 ACTION REQUIRED: Update the 'AZURE_CREDENTIALS' secret in GitHub with this JSON." -ForegroundColor Cyan
