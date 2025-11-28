# ECONEURA-FULL - Validación Completa Pre-Deploy
# Script maestro que ejecuta TODAS las validaciones

param(
    [string]$Environment = "staging",
    [string]$ResourceGroup = "rg-econeura-full-staging",
    [switch]$SkipAzureValidation
)

$ErrorActionPreference = "Stop"

Write-Host "`n" -NoNewline
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "🔍 VALIDACIÓN COMPLETA PRE-DEPLOY - ECONEURA-FULL" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host ""

$global:TotalErrors = 0
$global:TotalWarnings = 0

# ============================================================================
# 1. VALIDACIÓN LOCAL
# ============================================================================
Write-Host "📁 FASE 1: Validación Local" -ForegroundColor Yellow
Write-Host "-" * 80 -ForegroundColor Gray

& "$PSScriptRoot\validate-pre-deploy.ps1" -Environment $Environment
$localExitCode = $LASTEXITCODE

if ($localExitCode -ne 0) {
    $global:TotalErrors++
    Write-Host "`n❌ Validación local falló" -ForegroundColor Red
} else {
    Write-Host "`n✅ Validación local exitosa" -ForegroundColor Green
}

Write-Host "`n"

# ============================================================================
# 2. VALIDACIÓN AZURE (si Azure CLI está disponible)
# ============================================================================
if (-not $SkipAzureValidation) {
    if (Get-Command az -ErrorAction SilentlyContinue) {
        Write-Host "☁️  FASE 2: Validación Azure Resources" -ForegroundColor Yellow
        Write-Host "-" * 80 -ForegroundColor Gray
        
        & "$PSScriptRoot\validate-azure-resources.ps1" -ResourceGroup $ResourceGroup -Environment $Environment
        $azureExitCode = $LASTEXITCODE
        
        if ($azureExitCode -ne 0) {
            $global:TotalErrors++
            Write-Host "`n❌ Validación Azure falló" -ForegroundColor Red
        } else {
            Write-Host "`n✅ Validación Azure exitosa" -ForegroundColor Green
        }
        
        Write-Host "`n"
    } else {
        Write-Host "⚠️  FASE 2: Azure CLI no disponible - saltando validación Azure" -ForegroundColor Yellow
        Write-Host "Instalar: https://aka.ms/InstallAzureCLIWindows`n" -ForegroundColor Gray
    }
} else {
    Write-Host "⏭️  FASE 2: Validación Azure omitida (--SkipAzureValidation)" -ForegroundColor Yellow
    Write-Host "`n"
}

# ============================================================================
# 3. RESUMEN FINAL
# ============================================================================
Write-Host "`n" -NoNewline
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "📊 RESUMEN FINAL" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan

if ($global:TotalErrors -eq 0) {
    Write-Host "`n✅ VALIDACIÓN COMPLETA EXITOSA" -ForegroundColor Green
    Write-Host "Puedes proceder con el deployment.`n" -ForegroundColor Green
    
    Write-Host "Próximos pasos:" -ForegroundColor Cyan
    Write-Host "  1. Verificar GitHub Secrets están configurados" -ForegroundColor White
    Write-Host "  2. Ejecutar workflow: infra-deploy.yml (si es primera vez)" -ForegroundColor White
    Write-Host "  3. Ejecutar workflow: app-deploy.yml" -ForegroundColor White
    Write-Host "  4. Ejecutar health check: .\scripts\health-check-complete.ps1`n" -ForegroundColor White
    
    exit 0
} else {
    Write-Host "`n❌ VALIDACIÓN FALLIDA" -ForegroundColor Red
    Write-Host "Errores encontrados: $global:TotalErrors" -ForegroundColor Red
    Write-Host "`n⚠️  NO PUEDES HACER DEPLOY HASTA CORREGIR TODOS LOS ERRORES`n" -ForegroundColor Red
    
    Write-Host "Acciones recomendadas:" -ForegroundColor Yellow
    Write-Host "  1. Revisar errores arriba" -ForegroundColor White
    Write-Host "  2. Consultar: docs/TROUBLESHOOTING-GUIA-COMPLETA.md" -ForegroundColor White
    Write-Host "  3. Ejecutar correcciones: .\scripts\fix-common-issues.ps1`n" -ForegroundColor White
    
    exit 1
}

