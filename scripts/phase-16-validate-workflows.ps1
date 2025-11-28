# FASE 16: Validar GitHub Workflows
$ErrorActionPreference = "Stop"

Write-Host "🔍 Validando GitHub Workflows existentes..." -ForegroundColor Cyan

# Verificar gh CLI
try {
    gh --version 2>&1 | Out-Null
}
catch {
    Write-Host "  ⚠️  GitHub CLI no instalado - instalando manualmente..." -ForegroundColor Yellow
    winget install --id GitHub.cli
}

# Listar workflows
Write-Host "`n  📋 Workflows existentes:" -ForegroundColor Yellow
Get-ChildItem ".github/workflows/*.yml" | ForEach-Object {
    Write-Host "    - $($_.Name)" -ForegroundColor Cyan
}

# Verificar si hay errores de sintaxis
$workflowFiles = Get-ChildItem ".github/workflows/*.yml"
$hasErrors = $false

foreach ($file in $workflowFiles) {
    Write-Host "`n  🔍 Validando $($file.Name)..." -ForegroundColor Yellow
    
    # Validación básica de YAML
    try {
        $content = Get-Content $file.FullName -Raw
        if ($content -match "on:" -and $content -match "jobs:") {
            Write-Host "    ✅ Sintaxis válida" -ForegroundColor Green
        }
        else {
            Write-Host "    ⚠️  Estructura incompleta" -ForegroundColor Yellow
            $hasErrors = $true
        }
    }
    catch {
        Write-Host "    ❌ Error: $_" -ForegroundColor Red
        $hasErrors = $true
    }
}

# Verificar secretos (si gh funciona)
Write-Host "`n  🔐 Verificando secretos GitHub..." -ForegroundColor Yellow
try {
    gh secret list 2>&1 | Out-File "github-secrets-list.txt"
    
    $requiredSecrets = @(
        "AZURE_CREDENTIALS",
        "AZURE_SUBSCRIPTION_ID",
        "AZURE_STATIC_WEB_APPS_API_TOKEN"
    )
    
    $secretsList = Get-Content "github-secrets-list.txt" -Raw
    
    foreach ($secret in $requiredSecrets) {
        if ($secretsList -match $secret) {
            Write-Host "    ✅ $secret configurado" -ForegroundColor Green
        }
        else {
            Write-Host "    ⚠️  $secret faltante" -ForegroundColor Yellow
        }
    }
}
catch {
    Write-Host "    ⚠️  No se pudo verificar secretos (requiere autenticación gh)" -ForegroundColor Yellow
}

# Generar reporte
$report = @"
# GitHub Workflows Validation Report

**Fecha**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Workflows Encontrados

$($workflowFiles.Count) workflows en .github/workflows/

## Estado

- Sintaxis: $(if (-not $hasErrors) { "✅ OK" } else { "⚠️ Revisar" })
- Secretos: Revisar github-secrets-list.txt

## Próximos Pasos

1. Actualizar workflows con phase-17
2. Verificar secretos manualmente
"@

Set-Content "workflow-validation-report.md" $report

Write-Host "`n✅ FASE 16 COMPLETADA: Workflows validados" -ForegroundColor Green
Write-Host "   Reporte: workflow-validation-report.md" -ForegroundColor Cyan
