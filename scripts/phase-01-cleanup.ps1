# FASE 1: Limpieza exhaustiva
$ErrorActionPreference = "Stop"

Write-Host "🧹 Limpiando archivos temporales y logs..." -ForegroundColor Cyan

# Eliminar archivos .txt de logs
$txtFiles = Get-ChildItem -Path "." -Filter "*.txt" -File | Where-Object {
    $_.Name -match "_(log|failure|report|debug)" -or
    $_.Name -match "^(backend|frontend|deployment|validation|test|lint)_"
}

foreach ($file in $txtFiles) {
    Remove-Item $file.FullName -Force
    Write-Host "  ✅ Eliminado: $($file.Name)" -ForegroundColor Green
}

# Eliminar carpetas temporales
$tempDirs = @("out", "temp_repo", ".turbo")
foreach ($dir in $tempDirs) {
    if (Test-Path $dir) {
        Remove-Item $dir -Recurse -Force
        Write-Host "  ✅ Eliminado directorio: $dir" -ForegroundColor Green
    }
}

# Eliminar archivos temporales
$tempFiles = @("backend-deploy.zip", "deployment-outputs.json")
foreach ($file in $tempFiles) {
    if (Test-Path $file) {
        Remove-Item $file -Force
        Write-Host "  ✅ Eliminado: $file" -ForegroundColor Green
    }
}

# Limpiar dist en packages
Get-ChildItem -Path "packages" -Recurse -Directory -Filter "dist" -ErrorAction SilentlyContinue | ForEach-Object {
    Remove-Item $_.FullName -Recurse -Force
    Write-Host "  ✅ Eliminado: $($_.FullName)" -ForegroundColor Green
}

Write-Host "`n✅ FASE 1 COMPLETADA: Limpieza exhaustiva" -ForegroundColor Green
