# Script para preparar y subir a GitHub
# Uso: .\scripts\prepare-github.ps1

Write-Host "`n=== 📤 PREPARACIÓN PARA GITHUB ===" -ForegroundColor Cyan

# Verificar que estamos en el directorio correcto
if (-not (Test-Path ".git")) {
    Write-Host "❌ Error: No es un repositorio Git. Inicializando..." -ForegroundColor Yellow
    git init
    Write-Host "✅ Repositorio Git inicializado" -ForegroundColor Green
}

# Verificar estado de Git
Write-Host "`n📋 Estado actual de Git:" -ForegroundColor Yellow
git status --short

# Verificar que no hay archivos sensibles
Write-Host "`n🔍 Verificando archivos sensibles..." -ForegroundColor Yellow
$sensitiveFiles = @(".env", "packages\backend\.env", "packages\frontend\.env", "*.log", "node_modules")
$found = $false

foreach ($pattern in $sensitiveFiles) {
    $files = Get-ChildItem -Path . -Filter $pattern -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notmatch "node_modules" }
    if ($files) {
        Write-Host "⚠️  Archivos sensibles encontrados: $pattern" -ForegroundColor Yellow
        $found = $true
    }
}

if (-not $found) {
    Write-Host "✅ No se encontraron archivos sensibles" -ForegroundColor Green
}

# Verificar .gitignore
Write-Host "`n🔍 Verificando .gitignore..." -ForegroundColor Yellow
if (Test-Path ".gitignore") {
    $gitignore = Get-Content ".gitignore" -Raw
    $required = @("node_modules", ".env", "*.log", "dist", "build", "logs")
    $missing = @()
    
    foreach ($item in $required) {
        if ($gitignore -notmatch [regex]::Escape($item)) {
            $missing += $item
        }
    }
    
    if ($missing.Count -eq 0) {
        Write-Host "✅ .gitignore está completo" -ForegroundColor Green
    } else {
        Write-Host "⚠️  .gitignore falta: $($missing -join ', ')" -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠️  .gitignore no existe" -ForegroundColor Yellow
}

Write-Host "`n📋 COMANDOS PARA SUBIR A GITHUB:" -ForegroundColor Cyan
Write-Host "`n1. Verificar cambios:" -ForegroundColor White
Write-Host "   git status" -ForegroundColor Gray
Write-Host "`n2. Agregar todos los archivos:" -ForegroundColor White
Write-Host "   git add ." -ForegroundColor Gray
Write-Host "`n3. Commit:" -ForegroundColor White
Write-Host "   git commit -m 'feat: ECONEURA 10/10 - Todos los críticos resueltos'" -ForegroundColor Gray
Write-Host "`n4. Si es la primera vez, agregar remote:" -ForegroundColor White
Write-Host "   git remote add origin https://github.com/TU-USUARIO/ECONEURA-FULL.git" -ForegroundColor Gray
Write-Host "`n5. Push:" -ForegroundColor White
Write-Host "   git push -u origin main" -ForegroundColor Gray
Write-Host "`n✅ Listo para subir!" -ForegroundColor Green


