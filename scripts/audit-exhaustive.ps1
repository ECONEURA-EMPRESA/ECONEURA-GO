# Script de Auditoría Exhaustiva - ECONEURA-FULL
# Ejecuta todas las fases de auditoría automáticamente

param(
    [switch]$Phase1,
    [switch]$Phase2,
    [switch]$Phase3,
    [switch]$Phase4,
    [switch]$Phase5,
    [switch]$Phase6,
    [switch]$Phase7,
    [switch]$Phase8,
    [switch]$Phase9,
    [switch]$Phase10,
    [switch]$All
)

$ErrorActionPreference = "Continue"
$errors = @()
$warnings = @()

function Write-PhaseHeader($phase, $title) {
    Write-Host "`n" + ("=" * 70) -ForegroundColor Cyan
    Write-Host "FASE $phase : $title" -ForegroundColor Cyan
    Write-Host ("=" * 70) -ForegroundColor Cyan
}

function Add-Error($message) {
    $script:errors += $message
    Write-Host "  ❌ $message" -ForegroundColor Red
}

function Add-Warning($message) {
    $script:warnings += $message
    Write-Host "  ⚠️  $message" -ForegroundColor Yellow
}

function Add-Success($message) {
    Write-Host "  ✅ $message" -ForegroundColor Green
}

# FASE 1: Análisis de Estructura y Configuración
if ($All -or $Phase1) {
    Write-PhaseHeader "1" "ANÁLISIS DE ESTRUCTURA Y CONFIGURACIÓN"
    
    # Verificar package.json raíz
    if (Test-Path "package.json") {
        Add-Success "package.json existe"
        $rootPkg = Get-Content "package.json" | ConvertFrom-Json
        if ($rootPkg.workspaces) {
            Add-Success "Workspaces configurados: $($rootPkg.workspaces -join ', ')"
        } else {
            Add-Error "Workspaces no configurados en package.json raíz"
        }
    } else {
        Add-Error "package.json raíz no encontrado"
    }
    
    # Verificar tsconfig.base.json
    if (Test-Path "tsconfig.base.json") {
        Add-Success "tsconfig.base.json existe"
    } else {
        Add-Error "tsconfig.base.json no encontrado"
    }
    
    # Verificar .gitignore
    if (Test-Path ".gitignore") {
        Add-Success ".gitignore existe"
    } else {
        Add-Warning ".gitignore no encontrado"
    }
    
    # Verificar .env.example
    if (Test-Path ".env.example") {
        Add-Success ".env.example existe"
    } else {
        Add-Warning ".env.example no encontrado (recomendado para documentar variables)"
    }
    
    # Verificar packages/backend/package.json
    if (Test-Path "packages/backend/package.json") {
        Add-Success "packages/backend/package.json existe"
        $backendPkg = Get-Content "packages/backend/package.json" | ConvertFrom-Json
        if ($backendPkg.scripts.build) {
            Add-Success "Script build configurado en backend"
        } else {
            Add-Error "Script build no encontrado en backend"
        }
    } else {
        Add-Error "packages/backend/package.json no encontrado"
    }
    
    # Verificar packages/frontend/package.json
    if (Test-Path "packages/frontend/package.json") {
        Add-Success "packages/frontend/package.json existe"
        $frontendPkg = Get-Content "packages/frontend/package.json" | ConvertFrom-Json
        if ($frontendPkg.scripts.build) {
            Add-Success "Script build configurado en frontend"
        } else {
            Add-Error "Script build no encontrado en frontend"
        }
    } else {
        Add-Error "packages/frontend/package.json no encontrado"
    }
    
    # Verificar tsconfig en backend y frontend
    if (Test-Path "packages/backend/tsconfig.json") {
        Add-Success "packages/backend/tsconfig.json existe"
    } else {
        Add-Error "packages/backend/tsconfig.json no encontrado"
    }
    
    if (Test-Path "packages/frontend/tsconfig.json") {
        Add-Success "packages/frontend/tsconfig.json existe"
    } else {
        Add-Error "packages/frontend/tsconfig.json no encontrado"
    }
    
    # Verificar scripts/
    if (Test-Path "scripts") {
        $scriptCount = (Get-ChildItem "scripts" -Filter "*.ps1" -ErrorAction SilentlyContinue).Count
        Add-Success "Carpeta scripts/ existe ($scriptCount scripts)"
    } else {
        Add-Warning "Carpeta scripts/ no encontrada"
    }
    
    # Verificar docs/
    if (Test-Path "docs") {
        $docCount = (Get-ChildItem "docs" -Filter "*.md" -ErrorAction SilentlyContinue).Count
        Add-Success "Carpeta docs/ existe ($docCount documentos)"
    } else {
        Add-Warning "Carpeta docs/ no encontrada"
    }
}

# FASE 9: Type-check (se puede ejecutar independientemente)
if ($All -or $Phase9) {
    Write-PhaseHeader "9" "AUDITORÍA DE TIPOS Y TYPE-SAFETY"
    
    # Type-check backend
    Write-Host "`nVerificando TypeScript en backend..." -ForegroundColor Yellow
    Push-Location "packages/backend"
    try {
        $result = & npm run type-check 2>&1
        if ($LASTEXITCODE -eq 0) {
            Add-Success "Backend type-check: SIN ERRORES"
        } else {
            Add-Error "Backend type-check: ERRORES ENCONTRADOS"
            Write-Host $result -ForegroundColor Red
        }
    } catch {
        Add-Warning "No se pudo ejecutar type-check en backend (npm no disponible?)"
    } finally {
        Pop-Location
    }
    
    # Type-check frontend
    Write-Host "`nVerificando TypeScript en frontend..." -ForegroundColor Yellow
    Push-Location "packages/frontend"
    try {
        $result = & npm run typecheck 2>&1
        if ($LASTEXITCODE -eq 0) {
            Add-Success "Frontend type-check: SIN ERRORES"
        } else {
            Add-Error "Frontend type-check: ERRORES ENCONTRADOS"
            Write-Host $result -ForegroundColor Red
        }
    } catch {
        Add-Warning "No se pudo ejecutar type-check en frontend (npm no disponible?)"
    } finally {
        Pop-Location
    }
}

# FASE 10: Build y verificación final
if ($All -or $Phase10) {
    Write-PhaseHeader "10" "VERIFICACIÓN FINAL Y BUILD"
    
    # Build backend
    Write-Host "`nCompilando backend..." -ForegroundColor Yellow
    Push-Location "packages/backend"
    try {
        $result = & npm run build 2>&1
        if ($LASTEXITCODE -eq 0) {
            Add-Success "Backend build: EXITOSO"
        } else {
            Add-Error "Backend build: FALLÓ"
            Write-Host $result -ForegroundColor Red
        }
    } catch {
        Add-Warning "No se pudo compilar backend (npm no disponible?)"
    } finally {
        Pop-Location
    }
    
    # Build frontend
    Write-Host "`nCompilando frontend..." -ForegroundColor Yellow
    Push-Location "packages/frontend"
    try {
        $result = & npm run build 2>&1
        if ($LASTEXITCODE -eq 0) {
            Add-Success "Frontend build: EXITOSO"
        } else {
            Add-Error "Frontend build: FALLÓ"
            Write-Host $result -ForegroundColor Red
        }
    } catch {
        Add-Warning "No se pudo compilar frontend (npm no disponible?)"
    } finally {
        Pop-Location
    }
}

# Resumen
Write-Host "`n" + ("=" * 70) -ForegroundColor Cyan
Write-Host "📊 RESUMEN DE AUDITORÍA" -ForegroundColor Cyan
Write-Host ("=" * 70) -ForegroundColor Cyan

if ($errors.Count -eq 0) {
    Write-Host "`n✅ NO SE ENCONTRARON ERRORES CRÍTICOS" -ForegroundColor Green
} else {
    Write-Host "`n❌ ERRORES ENCONTRADOS: $($errors.Count)" -ForegroundColor Red
    foreach ($error in $errors) {
        Write-Host "   - $error" -ForegroundColor Red
    }
}

if ($warnings.Count -gt 0) {
    Write-Host "`n⚠️  ADVERTENCIAS: $($warnings.Count)" -ForegroundColor Yellow
    foreach ($warning in $warnings) {
        Write-Host "   - $warning" -ForegroundColor Yellow
    }
}

Write-Host "`n"

