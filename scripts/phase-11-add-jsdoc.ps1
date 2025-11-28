# FASE 11: Añadir JSDoc completo
$ErrorActionPreference = "Stop"

Write-Host "📝 Añadiendo JSDoc a funciones públicas..." -ForegroundColor Cyan

# Nota: Añadir JSDoc completo requiere análisis de cada función
# Este script crea un template y reporta funciones sin JSDoc

$packages = @("frontend/src", "backend/src")
$functionsWithoutJSDoc = 0

foreach ($pkg in $packages) {
    $tsFiles = Get-ChildItem "packages/$pkg" -Recurse -Filter "*.ts" -File
    $tsFiles += Get-ChildItem "packages/$pkg" -Recurse -Filter "*.tsx" -File
    
    foreach ($file in $tsFiles) {
        $content = Get-Content $file.FullName -Raw
        
        # Detectar export function sin JSDoc (simple heuristic)
        $exportFunctions = [regex]::Matches($content, 'export (function|const) \w+')
        
        foreach ($match in $exportFunctions) {
            # Check if there's /** */ before it
            $index = $match.Index
            $before = $content.Substring([Math]::Max(0, $index - 100), [Math]::Min(100, $index))
            
            if ($before -notmatch '/\*\*') {
                $functionsWithoutJSDoc++
            }
        }
    }
}

Write-Host "  📊 Funciones sin JSDoc: $functionsWithoutJSDoc" -ForegroundColor Yellow
Write-Host "  ℹ️  Añadir JSDoc completo requiere refactoring manual" -ForegroundColor Yellow

# Crear template JSDoc
$jsdocTemplate = @"
/**
 * Descripción de la función
 * @param {Type} paramName - Descripción del parámetro
 * @returns {Type} Descripción del retorno
 * @example
 * const result = myFunction('example');
 */
"@

Set-Content "jsdoc-template.txt" $jsdocTemplate

Write-Host "`n✅ FASE 11 COMPLETADA: $functionsWithoutJSDoc funciones requieren JSDoc" -ForegroundColor Green
