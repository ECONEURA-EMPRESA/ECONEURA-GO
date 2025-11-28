# FASE 9: TypeScript Strict Mode
$ErrorActionPreference = "Stop"

Write-Host "📘 Activando TypeScript Strict Mode en todos los packages..." -ForegroundColor Cyan

$packages = @("frontend", "backend", "shared", "config")

foreach ($pkg in $packages) {
    $tsconfigPath = "packages/$pkg/tsconfig.json"
    
    if (-not (Test-Path $tsconfigPath)) {
        Write-Host "  ⚠️  $pkg: No tiene tsconfig.json" -ForegroundColor Yellow
        continue
    }

    Write-Host "  🔧 Actualizando $pkg..." -ForegroundColor Cyan
    
    $tsconfig = Get-Content $tsconfigPath | ConvertFrom-Json
    
    # Activar TODAS las opciones strict
    if (-not $tsconfig.compilerOptions) {
        $tsconfig | Add-Member -NotePropertyName "compilerOptions" -NotePropertyValue @{} -Force
    }
    
    $tsconfig.compilerOptions.strict = $true
    $tsconfig.compilerOptions.noImplicitAny = $true
    $tsconfig.compilerOptions.strictNullChecks = $true
    $tsconfig.compilerOptions.strictFunctionTypes = $true
    $tsconfig.compilerOptions.strictBindCallApply = $true
    $tsconfig.compilerOptions.strictPropertyInitialization = $true
    $tsconfig.compilerOptions.noImplicitThis = $true
    $tsconfig.compilerOptions.alwaysStrict = $true
    $tsconfig.compilerOptions.noUnusedLocals = $true
    $tsconfig.compilerOptions.noUnusedParameters = $true
    $tsconfig.compilerOptions.noImplicitReturns = $true
    $tsconfig.compilerOptions.noFallthroughCasesInSwitch = $true
    $tsconfig.compilerOptions.noUncheckedIndexedAccess = $true
    $tsconfig.compilerOptions.noPropertyAccessFromIndexSignature = $true
    
    # Guardar
    $tsconfig | ConvertTo-Json -Depth 100 | Set-Content $tsconfigPath
    
    Write-Host "  ✅ $pkg: Strict mode activado" -ForegroundColor Green
}

# Validar que compila
Write-Host "`n  🔍 Validando compilación..."  -ForegroundColor Cyan
cd packages/frontend
npm run type-check 2>&1 | Out-File "../../typescript-errors-strict.log"
cd ../..

$errors = (Get-Content "typescript-errors-strict.log" | Select-String "error TS" | Measure-Object).Count
Write-Host "  📊 Errores TypeScript detectados: $errors" -ForegroundColor $(if ($errors -eq 0) { "Green" } else { "Yellow" })

Write-Host "`n✅ FASE 9 COMPLETADA: Strict mode activado ($errors errors a resolver)" -ForegroundColor Green
