# FASE 2: Validación de estructura
$ErrorActionPreference = "Stop"

Write-Host "🔍 Validando estructura del monorepo..." -ForegroundColor Cyan

$requiredPaths = @(
    "packages/frontend",
    "packages/backend",
    "packages/shared",
    "packages/config",
    "infrastructure/azure",
    ".github/workflows",
    "package.json",
    "turbo.json",
    "eslint.config.mjs"
)

$allOk = $true

foreach ($path in $requiredPaths) {
    if (Test-Path $path) {
        Write-Host "  ✅ $path" -ForegroundColor Green
    }
    else {
        Write-Host "  ❌ FALTA: $path" -ForegroundColor Red
        $allOk = $false
    }
}

if (-not $allOk) {
    throw "❌ Estructura incompleta - faltan archivos críticos"
}

# Validar package.json workspaces
$packageJson = Get-Content "package.json" | ConvertFrom-Json
if (-not $packageJson.workspaces) {
    throw "❌ package.json no tiene workspaces definidos"
}

Write-Host "`n✅ FASE 2 COMPLETADA: Estructura validada" -ForegroundColor Green
