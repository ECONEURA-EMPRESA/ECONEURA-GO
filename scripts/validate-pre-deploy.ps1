# ECONEURA-FULL - Validación Pre-Deploy Exhaustiva
# Valida TODOS los requisitos antes de deployar a Azure
# NO EJECUTAR DEPLOY SIN QUE ESTE SCRIPT PASE AL 100%

param(
    [string]$Environment = "staging"
)

$ErrorActionPreference = "Stop"
$global:Errors = @()
$global:Warnings = @()

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "❌ ERROR: $Message" -ForegroundColor Red
    $global:Errors += $Message
}

function Write-Warning-Custom {
    param([string]$Message)
    Write-Host "⚠️  WARNING: $Message" -ForegroundColor Yellow
    $global:Warnings += $Message
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

Write-Host "`n🔍 VALIDACIÓN PRE-DEPLOY EXHAUSTIVA - ECONEURA-FULL`n" -ForegroundColor Cyan
Write-Host "Environment: $Environment`n" -ForegroundColor Cyan

# ============================================================================
# 1. VALIDACIÓN DE ESTRUCTURA DE ARCHIVOS
# ============================================================================
Write-Host "📁 1. Validando estructura de archivos..." -ForegroundColor Yellow

$requiredFiles = @(
    "package.json",
    "tsconfig.base.json",
    "packages/backend/package.json",
    "packages/backend/tsconfig.json",
    "packages/backend/src/index.ts",
    "packages/backend/src/api/http/server.ts",
    "packages/frontend/package.json",
    "packages/frontend/index.html",
    "packages/frontend/src/main.tsx",
    "infrastructure/azure/main.bicep",
    ".github/workflows/app-deploy.yml",
    ".github/workflows/infra-deploy.yml"
)

foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Success "Archivo existe: $file"
    } else {
        Write-Error-Custom "Archivo faltante: $file"
    }
}

# ============================================================================
# 2. VALIDACIÓN DE DEPENDENCIAS
# ============================================================================
Write-Host "`n📦 2. Validando dependencias..." -ForegroundColor Yellow

if (Test-Path "package-lock.json") {
    Write-Success "package-lock.json existe"
} else {
    Write-Error-Custom "package-lock.json NO existe - ejecutar 'npm install'"
}

if (Test-Path "node_modules") {
    Write-Success "node_modules existe"
} else {
    Write-Error-Custom "node_modules NO existe - ejecutar 'npm install'"
}

# Verificar dependencias críticas
$criticalDeps = @(
    "express",
    "typescript",
    "zod",
    "winston",
    "applicationinsights",
    "ioredis",
    "cookie-parser"
)

foreach ($dep in $criticalDeps) {
    $depPath = "node_modules/$dep"
    if (Test-Path $depPath) {
        Write-Success "Dependencia instalada: $dep"
    } else {
        Write-Error-Custom "Dependencia faltante: $dep"
    }
}

# ============================================================================
# 3. VALIDACIÓN DE TYPESCRIPT
# ============================================================================
Write-Host "`n🔷 3. Validando TypeScript..." -ForegroundColor Yellow

Push-Location "packages/backend"
try {
    $tscOutput = npm run type-check 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "TypeScript backend: 0 errores"
    } else {
        $tsErrors = ($tscOutput | Select-String "error TS").Count
        Write-Error-Custom "TypeScript backend: $tsErrors errores encontrados"
        Write-Host "Ejecutar: npm run type-check:backend" -ForegroundColor Red
    }
} catch {
    Write-Error-Custom "No se pudo ejecutar type-check: $_"
}
Pop-Location

Push-Location "packages/frontend"
try {
    $tscOutput = npm run type-check 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "TypeScript frontend: 0 errores"
    } else {
        $tsErrors = ($tscOutput | Select-String "error TS").Count
        Write-Error-Custom "TypeScript frontend: $tsErrors errores encontrados"
        Write-Host "Ejecutar: npm run type-check:frontend" -ForegroundColor Red
    }
} catch {
    Write-Error-Custom "No se pudo ejecutar type-check frontend: $_"
}
Pop-Location

# ============================================================================
# 4. VALIDACIÓN DE BUILD
# ============================================================================
Write-Host "`n🏗️  4. Validando builds..." -ForegroundColor Yellow

# Backend build
Push-Location "packages/backend"
try {
    npm run build 2>&1 | Out-Null
    if (Test-Path "dist/index.js") {
        Write-Success "Backend build: dist/index.js existe"
    } else {
        Write-Error-Custom "Backend build falló: dist/index.js no existe"
    }
} catch {
    Write-Error-Custom "Backend build falló: $_"
}
Pop-Location

# Frontend build
Push-Location "packages/frontend"
try {
    npm run build 2>&1 | Out-Null
    if (Test-Path "dist/index.html") {
        Write-Success "Frontend build: dist/index.html existe"
    } else {
        Write-Error-Custom "Frontend build falló: dist/index.html no existe"
    }
} catch {
    Write-Error-Custom "Frontend build falló: $_"
}
Pop-Location

# ============================================================================
# 5. VALIDACIÓN DE GITHUB SECRETS (Documentación)
# ============================================================================
Write-Host "`n🔐 5. Validando GitHub Secrets (documentación)..." -ForegroundColor Yellow

$requiredSecrets = @(
    "AZURE_CREDENTIALS",
    "AZURE_WEBAPP_NAME_BACKEND",
    "AZURE_WEBAPP_PUBLISH_PROFILE_BACKEND",
    "AZURE_STATIC_WEB_APPS_API_TOKEN",
    "POSTGRES_ADMIN_PASSWORD",
    "OPENAI_API_KEY"
)

Write-Host "`nSecrets requeridos en GitHub (Settings → Secrets and variables → Actions):" -ForegroundColor Cyan
foreach ($secret in $requiredSecrets) {
    Write-Host "  - $secret" -ForegroundColor White
}

Write-Host "`n⚠️  IMPORTANTE: Verificar manualmente que todos los secrets están configurados" -ForegroundColor Yellow

# ============================================================================
# 6. VALIDACIÓN DE BICEP
# ============================================================================
Write-Host "`n☁️  6. Validando Bicep..." -ForegroundColor Yellow

if (Get-Command az -ErrorAction SilentlyContinue) {
    try {
        $bicepOutput = az bicep build --file infrastructure/azure/main.bicep 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Bicep: Validación exitosa"
        } else {
            Write-Error-Custom "Bicep: Errores de validación"
            Write-Host $bicepOutput -ForegroundColor Red
        }
    } catch {
        Write-Warning-Custom "No se pudo validar Bicep (Azure CLI no configurado o no hay conexión)"
    }
} else {
    Write-Warning-Custom "Azure CLI no instalado - no se puede validar Bicep"
}

# ============================================================================
# 7. VALIDACIÓN DE CONFIGURACIÓN DE ENTORNO
# ============================================================================
Write-Host "`n⚙️  7. Validando configuración de entorno..." -ForegroundColor Yellow

# Verificar envSchema.ts tiene todas las variables necesarias
$envSchemaPath = "packages/backend/src/config/envSchema.ts"
if (Test-Path $envSchemaPath) {
    $envSchemaContent = Get-Content $envSchemaPath -Raw
    
    $requiredEnvVars = @(
        "NODE_ENV",
        "PORT",
        "OPENAI_API_KEY",
        "DATABASE_URL",
        "REDIS_URL",
        "APPLICATIONINSIGHTS_CONNECTION_STRING",
        "KEY_VAULT_URL",
        "AZURE_STORAGE_CONNECTION_STRING"
    )
    
    foreach ($var in $requiredEnvVars) {
        if ($envSchemaContent -match $var) {
            Write-Success "Variable en schema: $var"
        } else {
            Write-Warning-Custom "Variable no encontrada en schema: $var"
        }
    }
}

# ============================================================================
# 8. VALIDACIÓN DE RUTAS Y ENDPOINTS
# ============================================================================
Write-Host "`n🛣️  8. Validando rutas y endpoints..." -ForegroundColor Yellow

$serverPath = "packages/backend/src/api/http/server.ts"
if (Test-Path $serverPath) {
    $serverContent = Get-Content $serverPath -Raw
    
    $requiredRoutes = @(
        "/health",
        "/api/neuras",
        "/api/conversations",
        "/api/library",
        "/api/agents"
    )
    
    foreach ($route in $requiredRoutes) {
        if ($serverContent -match [regex]::Escape($route)) {
            Write-Success "Ruta encontrada: $route"
        } else {
            Write-Warning-Custom "Ruta no encontrada: $route"
        }
    }
}

# ============================================================================
# 9. VALIDACIÓN DE MIDDLEWARE DE SEGURIDAD
# ============================================================================
Write-Host "`n🛡️  9. Validando middleware de seguridad..." -ForegroundColor Yellow

$middlewarePath = "packages/backend/src/api/http/middleware"
if (Test-Path $middlewarePath) {
    $securityMiddleware = @(
        "authMiddleware.ts",
        "rateLimiter.ts",
        "sanitizeInput.ts",
        "csrf.ts",
        "security.ts"
    )
    
    foreach ($mw in $securityMiddleware) {
        $mwPath = "$middlewarePath/$mw"
        if (Test-Path $mwPath) {
            Write-Success "Middleware existe: $mw"
        } else {
            Write-Warning-Custom "Middleware faltante: $mw"
        }
    }
}

# ============================================================================
# 10. VALIDACIÓN DE SERVICIOS DE INFRAESTRUCTURA
# ============================================================================
Write-Host "`n🔧 10. Validando servicios de infraestructura..." -ForegroundColor Yellow

$infraServices = @(
    "packages/backend/src/infra/secrets/SecretsManager.ts",
    "packages/backend/src/infra/cache/redisClient.ts",
    "packages/backend/src/infra/observability/applicationInsights.ts",
    "packages/backend/src/infra/di/container.ts"
)

foreach ($service in $infraServices) {
    if (Test-Path $service) {
        Write-Success "Servicio existe: $(Split-Path $service -Leaf)"
    } else {
        Write-Error-Custom "Servicio faltante: $service"
    }
}

# ============================================================================
# RESUMEN FINAL
# ============================================================================
Write-Host "`n" -NoNewline
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "📊 RESUMEN DE VALIDACIÓN" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan

$errorCount = $global:Errors.Count
$warningCount = $global:Warnings.Count

if ($errorCount -eq 0 -and $warningCount -eq 0) {
    Write-Host "`n✅ VALIDACIÓN EXITOSA - Listo para deploy`n" -ForegroundColor Green
    exit 0
} elseif ($errorCount -eq 0) {
    Write-Host "`n⚠️  VALIDACIÓN CON ADVERTENCIAS" -ForegroundColor Yellow
    Write-Host "Errores: 0" -ForegroundColor Green
    Write-Host "Advertencias: $warningCount`n" -ForegroundColor Yellow
    Write-Host "Puedes proceder con deploy, pero revisa las advertencias.`n" -ForegroundColor Yellow
    exit 0
} else {
    Write-Host "`n❌ VALIDACIÓN FALLIDA" -ForegroundColor Red
    Write-Host "Errores: $errorCount" -ForegroundColor Red
    Write-Host "Advertencias: $warningCount`n" -ForegroundColor Yellow
    
    Write-Host "ERRORES ENCONTRADOS:" -ForegroundColor Red
    foreach ($error in $global:Errors) {
        Write-Host "  ❌ $error" -ForegroundColor Red
    }
    
    Write-Host "`n⚠️  NO PUEDES HACER DEPLOY HASTA CORREGIR TODOS LOS ERRORES`n" -ForegroundColor Red
    exit 1
}

