# FASE 17: Actualizar GitHub Workflows
$ErrorActionPreference = "Stop"

Write-Host "🔧 Actualizando GitHub Workflows..." -ForegroundColor Cyan

# Crear workflow de deployment
$deployWorkflow = @"
name: Deploy to Azure

on:
  push:
    branches: [main]
  workflow_dispatch:

env:
  NODE_VERSION: '20.x'

jobs:
  validate:
    name: Validate Code
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: `${{ env.NODE_VERSION }}
          cache: 'npm'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Type check
        run: npm run type-check
      
      - name: Lint
        run: npm run lint
      
      - name: Build
        run: npm run build
      
      - name: Security audit
        run: npm audit --audit-level=high

  deploy-infrastructure:
    name: Deploy Infrastructure
    needs: validate
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: `${{ secrets.AZURE_CREDENTIALS }}
      
      - name: Deploy Bicep
        run: |
          az deployment group create \
            --resource-group econeura-rg \
            --template-file infrastructure/azure/main.bicep \
            --parameters environment=production \
            --verbose

  deploy-frontend:
    name: Deploy Frontend
    needs: deploy-infrastructure
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - uses: actions/setup-node@v4
        with:
          node-version: `${{ env.NODE_VERSION }}
      
      - name: Build Frontend
        run: |
          cd packages/frontend
          npm install
          npm run build
      
      - name: Deploy to Static Web App
        uses: Azure/static-web-apps-deploy@v1
        with:
          azure_static_web_apps_api_token: `${{ secrets.AZURE_STATIC_WEB_APPS_API_TOKEN }}
          repo_token: `${{ secrets.GITHUB_TOKEN }}
          app_location: 'packages/frontend'
          output_location: 'dist'

  deploy-backend:
    name: Deploy Backend
    needs: deploy-infrastructure
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - uses: actions/setup-node@v4
        with:
          node-version: `${{ env.NODE_VERSION }}
      
      - name: Build Backend
        run: |
          cd packages/backend
          npm install
          npm run build
      
      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: `${{ secrets.AZURE_CREDENTIALS }}
      
      - name: Deploy to App Service
        uses: azure/webapps-deploy@v2
        with:
          app-name: econeura-backend-production
          package: packages/backend
"@

Set-Content ".github/workflows/deploy.yml" $deployWorkflow
Write-Host "  ✅ deploy.yml actualizado" -ForegroundColor Green

# Crear workflow de validación
$validateWorklflow = @"
name: Validate

on:
  pull_request:
  push:
    branches: [main, develop]

jobs:
  lint-and-type-check:
    name: Lint & Type Check
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - uses: actions/setup-node@v4
        with:
          node-version: '20.x'
          cache: 'npm'
      
      - run: npm ci
      - run: npm run type-check
      - run: npm run lint

  tests:
    name: Run Tests
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - uses: actions/setup-node@v4
        with:
          node-version: '20.x'
          cache: 'npm'
      
      - run: npm ci
      - run: npm test

  security:
    name: Security Audit
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - uses: actions/setup-node@v4
        with:
          node-version: '20.x'
          cache: 'npm'
      
      - run: npm ci
      - run: npm audit
"@

Set-Content ".github/workflows/validate.yml" $validateWorklflow
Write-Host "  ✅ validate.yml actualizado" -ForegroundColor Green

Write-Host "`n✅ FASE 17 COMPLETADA: Workflows actualizados" -ForegroundColor Green
