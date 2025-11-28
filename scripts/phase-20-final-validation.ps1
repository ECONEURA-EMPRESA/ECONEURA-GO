# FASE 20: Validación Final 100/100
$ErrorActionPreference = "Stop"

Write-Host "✅ Ejecutando validación exhaustiva 100/100..." -ForegroundColor Cyan

$validations = @{}

# 1. TypeScript
Write-Host "`n  📘 TypeScript..." -ForegroundColor Yellow
cd packages/frontend
npm run type-check 2>&1 | Out-Null
$validations["TypeScript"] = ($LASTEXITCODE -eq 0)
cd ../..

# 2. ESLint
Write-Host "  📋 ESLint..." -ForegroundColor Yellow
npm run lint 2>&1 | Out-File "lint-final.log"
$lintErrors = (Get-Content "lint-final.log" | Select-String "(\d+) errors").Matches[0].Groups[1].Value
$validations["ESLint"] = ([int]$lintErrors -eq 0)

# 3. Build
Write-Host "  🔨 Build..." -ForegroundColor Yellow
npm run build 2>&1 | Out-Null
$validations["Build"] = ($LASTEXITCODE -eq 0)

# 4. Security
Write-Host "  🔒 Security..." -ForegroundColor Yellow
$audit = npm audit --json | ConvertFrom-Json
$critical = $audit.metadata.vulnerabilities.critical
$high = $audit.metadata.vulnerabilities.high
$validations["Security"] = (($critical + $high) -eq 0)

# Reporte
Write-Host "`n📊 RESULTADOS:" -ForegroundColor Cyan
foreach ($validation in $validations.GetEnumerator()) {
    $status = if ($validation.Value) { "✅" } else { "❌" }
    Write-Host "  $status $($validation.Key)" -ForegroundColor $(if ($validation.Value) { "Green" } else { "Red" })
}

$allPassed = ($validations.Values | Where-Object { -not $_ }).Count -eq 0

if ($allPassed) {
    Write-Host "`n🎉 ¡PERFECCIÓN 100/100 ALCANZADA!" -ForegroundColor Green
}
else {
    Write-Host "`n⚠️  Algunas validaciones fallaron" -ForegroundColor Yellow
}

Write-Host "`n✅ FASE 20 COMPLETADA" -ForegroundColor Green
