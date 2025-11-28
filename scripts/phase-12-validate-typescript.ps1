# FASE 12: Validación TypeScript
$ErrorActionPreference = "Stop"

Write-Host "🔍 Validando TypeScript en todos los packages..." -ForegroundColor Cyan

# Ejecutar type-check en cada package
$packages = @("frontend", "backend", "shared", "config")
$allPassed = $true

foreach ($pkg in $packages) {
    if (-not (Test-Path "packages/$pkg/package.json")) {
        continue
    }
    
    Write-Host "`n  📦 $pkg..." -ForegroundColor Cyan
    
    cd "packages/$pkg"
    
    # Ejecutar type-check
    npm run type-check 2>&1 | Out-File "../../typescript-check-$pkg.log"
    $exitCode = $LASTEXITCODE
    
    cd ../..
    
    if ($exitCode -eq 0) {
        Write-Host "    ✅ Sin errores TypeScript" -ForegroundColor Green
    }
    else {
        $errors = (Get-Content "typescript-check-$pkg.log" | Select-String "error TS" | Measure-Object).Count
        Write-Host "    ❌ $errors errores TypeScript" -ForegroundColor Red
        $allPassed = $false
    }
}

if ($allPassed) {
    Write-Host "`n✅ FASE 12 COMPLETADA: TypeScript perfecto (0 errores)" -ForegroundColor Green
}
else {
    Write-Host "`n⚠️  FASE 12 COMPLETADA: TypeScript con errores - revisar logs" -ForegroundColor Yellow
}
