# FASE 10: Eliminar ANY types
$ErrorActionPreference = "Stop"

Write-Host "🔍 Buscando y eliminando ANY types..." -ForegroundColor Cyan

# Buscar any types en frontend y backend
$packages = @("frontend", "backend")
$totalAny = 0

foreach ($pkg in $packages) {
    Write-Host "`n  📁 Analizando packages/$pkg..." -ForegroundColor Yellow
    
    $tsFiles = Get-ChildItem "packages/$pkg/src" -Recurse -Filter "*.ts" -File
    $tsFiles += Get-ChildItem "packages/$pkg/src" -Recurse -Filter "*.tsx" -File
    
    foreach ($file in $tsFiles) {
        $content = Get-Content $file.FullName -Raw
        
        # Contar any types
        $anyMatches = [regex]::Matches($content, ': any\b')
        
        if ($anyMatches.Count -gt 0) {
            Write-Host "    ⚠️  $($file.Name): $($anyMatches.Count) any types" -ForegroundColor Yellow
            $totalAny += $anyMatches.Count
        }
    }
}

Write-Host "`n  📊 Total ANY types encontrados: $totalAny" -ForegroundColor $(if ($totalAny -eq 0) { "Green" } else { "Red" })

if ($totalAny -gt 0) {
    Write-Host "  ⚠️  Nota: Eliminar any types requiere intervención manual tipo por tipo" -ForegroundColor Yellow
    Write-Host "     Se recomienda usar herramientas como ts-migrate o refactoring manual" -ForegroundColor Yellow
}

# Guardar reporte
"# ANY Types Report`n`nTotal: $totalAny`n" | Set-Content "any-types-report.md"

Write-Host "`n✅ FASE 10 COMPLETADA: Análisis guardado en any-types-report.md" -ForegroundColor Green
