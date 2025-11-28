# Script para eliminar ECONEURA-REMOTE de forma segura
# Si está bloqueada, intenta varias veces

$folderPath = "ECONEURA-REMOTE"

if (-not (Test-Path $folderPath)) {
    Write-Host "✅ La carpeta $folderPath no existe" -ForegroundColor Green
    exit 0
}

Write-Host "🗑️  Intentando eliminar $folderPath..." -ForegroundColor Yellow

$maxAttempts = 5
$attempt = 1

while ($attempt -le $maxAttempts) {
    try {
        Remove-Item -Recurse -Force $folderPath -ErrorAction Stop
        Write-Host "✅ Carpeta $folderPath eliminada exitosamente" -ForegroundColor Green
        exit 0
    } catch {
        if ($attempt -lt $maxAttempts) {
            Write-Host "⚠️  Intento $attempt/$maxAttempts falló. Esperando 2 segundos..." -ForegroundColor Yellow
            Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Gray
            Start-Sleep -Seconds 2
            $attempt++
        } else {
            Write-Host "❌ No se pudo eliminar después de $maxAttempts intentos" -ForegroundColor Red
            Write-Host ""
            Write-Host "🔧 SOLUCIONES:" -ForegroundColor Cyan
            Write-Host "   1. Cierra el explorador de archivos si está abierto" -ForegroundColor White
            Write-Host "   2. Cierra VS Code/Cursor si tiene archivos abiertos de esa carpeta" -ForegroundColor White
            Write-Host "   3. Cierra cualquier proceso que pueda estar usando la carpeta" -ForegroundColor White
            Write-Host "   4. Reinicia el terminal y vuelve a intentar" -ForegroundColor White
            Write-Host "   5. O elimínala manualmente desde el explorador de archivos" -ForegroundColor White
            exit 1
        }
    }
}

