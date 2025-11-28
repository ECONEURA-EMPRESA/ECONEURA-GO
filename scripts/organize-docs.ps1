# Script para reorganizar documentación en carpetas categorizadas
# Ejecutar: .\scripts\organize-docs.ps1

Write-Host "`n📁 Reorganizando documentación..." -ForegroundColor Cyan

$docsPath = "docs"
$archivePath = "$docsPath\archive"

# Crear carpetas si no existen
@("architecture", "deployment", "development", "operations") | ForEach-Object {
    $folder = "$docsPath\$_"
    if (-not (Test-Path $folder)) {
        New-Item -ItemType Directory -Path $folder -Force | Out-Null
        Write-Host "✅ Creada carpeta: $_" -ForegroundColor Green
    }
}

# Mover archivos de arquitectura
$architectureFiles = @(
    "ARCHITECTURE.md",
    "DOMAIN-NEURAS.md",
    "RBAC-MODEL.md",
    "AZURE-INFRA.md"
)

foreach ($file in $architectureFiles) {
    $source = "$docsPath\$file"
    if (Test-Path $source) {
        Move-Item -Path $source -Destination "$docsPath\architecture\" -Force -ErrorAction SilentlyContinue
        Write-Host "✅ Movido: $file -> architecture/" -ForegroundColor Green
    }
}

# Mover archivos de deployment
$deploymentFiles = @(
    "*DEPLOY*",
    "*DESPLEGUE*",
    "*CHECKLIST*",
    "*TROUBLESHOOTING*",
    "*COMANDOS*",
    "*SOLUCION*",
    "*CORRECCION*"
)

Get-ChildItem -Path $docsPath -Filter "*.md" | Where-Object {
    $name = $_.Name
    $deploymentFiles | ForEach-Object { if ($name -like $_) { return $true } }
    return $false
} | ForEach-Object {
    if ($_.DirectoryName -ne "$docsPath\deployment") {
        Move-Item -Path $_.FullName -Destination "$docsPath\deployment\" -Force -ErrorAction SilentlyContinue
        Write-Host "✅ Movido: $($_.Name) -> deployment/" -ForegroundColor Green
    }
}

# Mover archivos de desarrollo
$developmentFiles = @(
    "*COMANDO*",
    "*GUIA*",
    "*INICIO*"
)

Get-ChildItem -Path $docsPath -Filter "*.md" | Where-Object {
    $name = $_.Name
    $developmentFiles | ForEach-Object { if ($name -like $_) { return $true } }
    return $false
} | ForEach-Object {
    if ($_.DirectoryName -ne "$docsPath\development") {
        Move-Item -Path $_.FullName -Destination "$docsPath\development\" -Force -ErrorAction SilentlyContinue
        Write-Host "✅ Movido: $($_.Name) -> development/" -ForegroundColor Green
    }
}

# Mover archivos de operaciones
$operationsFiles = @(
    "OPERATIONS.md",
    "PERFORMANCE-MONITORING.md",
    "KUSTO-QUERIES.md"
)

foreach ($file in $operationsFiles) {
    $source = "$docsPath\$file"
    if (Test-Path $source) {
        Move-Item -Path $source -Destination "$docsPath\operations\" -Force -ErrorAction SilentlyContinue
        Write-Host "✅ Movido: $file -> operations/" -ForegroundColor Green
    }
}

Write-Host "`n✅ Documentación reorganizada" -ForegroundColor Green
Write-Host "`n📋 Archivos restantes en docs/ (análisis, planes, etc.):" -ForegroundColor Yellow
Get-ChildItem -Path $docsPath -Filter "*.md" -File | Where-Object {
    $_.DirectoryName -eq (Resolve-Path $docsPath)
} | Select-Object -First 10 Name

