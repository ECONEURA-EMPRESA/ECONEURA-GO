# FASE 3: Clean install de dependencias
$ErrorActionPreference = "Stop"

Write-Host "📦 Reinstalando dependencias limpias..." -ForegroundColor Cyan

# Eliminar node_modules existente si hay
if (Test-Path "node_modules") {
    Write-Host "  🗑️ Eliminando node_modules anterior..." -ForegroundColor Yellow
    Remove-Item "node_modules" -Recurse -Force
}

# Eliminar package-lock.json
if (Test-Path "package-lock.json") {
    Remove-Item "package-lock.json" -Force
}

# Install limpio
Write-Host "  📥 Ejecutando npm install --legacy-peer-deps..." -ForegroundColor Cyan
npm install --legacy-peer-deps 2>&1 | Out-Null

if ($LASTEXITCODE -ne 0) {
    throw "❌ npm install falló"
}

# Verificar instalación
$packagesCount = (Get-ChildItem "node_modules" -Directory | Measure-Object).Count
Write-Host "  ✅ $packagesCount packages instalados" -ForegroundColor Green

# Verificar vulnerabilidades
Write-Host "  🔒 Verificando seguridad..." -ForegroundColor Cyan
$auditResult = npm audit --json | ConvertFrom-Json
$critical = $auditResult.metadata.vulnerabilities.critical
$high = $auditResult.metadata.vulnerabilities.high

Write-Host "    - Vulnerabilidades críticas: $critical" -ForegroundColor $(if ($critical -eq 0) { "Green" } else { "Red" })
Write-Host "    - Vulnerabilidades altas: $high" -ForegroundColor $(if ($high -eq 0) { "Green" } else { "Yellow" })

Write-Host "`n✅ FASE 3 COMPLETADA: Dependencias instaladas" -ForegroundColor Green
