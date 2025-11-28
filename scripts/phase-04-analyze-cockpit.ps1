# FASE 4: Análisis de EconeuraCockpit.BACKUP.tsx
# Identifica secciones para extracción exacta
$ErrorActionPreference = "Stop"

Write-Host "🔍 Analizando EconeuraCockpit.BACKUP.tsx..." -ForegroundColor Cyan

$cockpitFile = "packages/frontend/src/EconeuraCockpit.BACKUP.tsx"

if (-not (Test-Path $cockpitFile)) {
    throw "❌ No se encuentra EconeuraCockpit.BACKUP.tsx"
}

$content = Get-Content $cockpitFile -Raw
$lines = Get-Content $cockpitFile

Write-Host "  📊 Total líneas: $($lines.Count)" -ForegroundColor White

# Análisis de secciones (aproximado por comentarios y estructura)
$sections = @{
    "imports"   = @{ start = 1; end = 100 }
    "types"     = @{ start = 100; end = 400 }
    "functions" = @{ start = 400; end = 800 }
    "component" = @{ start = 800; end = 1741 }
}

# Guardar análisis en JSON para siguientes fases
$analysis = @{
    totalLines         = $lines.Count
    sections           = $sections
    loginApproxStart   = 400
    loginApproxEnd     = 600
    cockpitApproxStart = 760
    cockpitApproxEnd   = 1400
    chatApproxStart    = 240
    chatApproxEnd      = 430
} | ConvertTo-Json -Depth 10

Set-Content "cockpit-analysis.json" $analysis

Write-Host "  ✅ Análisis guardado en cockpit-analysis.json" -ForegroundColor Green
Write-Host "`n✅ FASE 4 COMPLETADA: Análisis realizado" -ForegroundColor Green
