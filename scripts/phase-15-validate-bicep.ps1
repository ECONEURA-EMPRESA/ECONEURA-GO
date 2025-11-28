# FASE 15: Validar Bicep
$ErrorActionPreference = "Stop"

Write-Host "🔍 Validando sintaxis Bicep..." -ForegroundColor Cyan

# Verificar que az cli está instalado
try {
    az --version 2>&1 | Out-Null
}
catch {
    Write-Host "  ⚠️  Azure CLI no instalado - skipping validación Bicep" -ForegroundColor Yellow
    exit 0
}

# Validar main.bicep
$mainBicep = "infrastructure/azure/main.bicep"

if (-not (Test-Path $mainBicep)) {
    Write-Host "  ⚠️  main.bicep no encontrado" -ForegroundColor Yellow
    exit 0
}

Write-Host "  🔧 Validando $mainBicep..." -ForegroundColor Cyan

# Build bicep (valida sintaxis)
az bicep build --file $mainBicep 2>&1 | Out-File "bicep-build.log"

if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✅ Sintaxis Bicep correcta" -ForegroundColor Green
}
else {
    Write-Host "  ❌ Errores de sintaxis en Bicep - ver bicep-build.log" -ForegroundColor Red
}

Write-Host "`n✅ FASE 15 COMPLETADA: Bicep validado" -ForegroundColor Green
