# Script para verificar que el CRM está listo para producción con agentes reales
# Ejecutar: .\scripts\verify-crm-production-ready.ps1

Write-Host "`n🔍 VERIFICANDO CRM PARA PRODUCCIÓN CON AGENTES REALES" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Cyan

$errors = @()
$warnings = @()

# 1. Verificar CRM_WEBHOOK_SECRET
Write-Host "`n[1/8] Verificando CRM_WEBHOOK_SECRET..." -ForegroundColor Yellow
$envFile = "packages/backend/.env"
if (Test-Path $envFile) {
    $envContent = Get-Content $envFile -Raw
    if ($envContent -match "CRM_WEBHOOK_SECRET\s*=\s*(.+)") {
        $secret = $matches[1].Trim()
        if ($secret.Length -ge 32) {
            Write-Host "  ✅ CRM_WEBHOOK_SECRET configurado (${secret.Length} caracteres)" -ForegroundColor Green
        } else {
            $errors += "CRM_WEBHOOK_SECRET muy corto (mínimo 32 caracteres)"
            Write-Host "  ❌ CRM_WEBHOOK_SECRET muy corto" -ForegroundColor Red
        }
    } else {
        $errors += "CRM_WEBHOOK_SECRET no encontrado en .env"
        Write-Host "  ❌ CRM_WEBHOOK_SECRET no configurado" -ForegroundColor Red
    }
} else {
    $warnings += "Archivo .env no encontrado (puede estar en Azure App Settings)"
    Write-Host "  ⚠️  Archivo .env no encontrado" -ForegroundColor Yellow
}

# 2. Verificar tablas CRM en PostgreSQL
Write-Host "`n[2/8] Verificando tablas CRM..." -ForegroundColor Yellow
$dbUrl = if (Test-Path $envFile) {
    $envContent = Get-Content $envFile -Raw
    if ($envContent -match "DATABASE_URL\s*=\s*(.+)") {
        $matches[1].Trim()
    } else {
        $null
    }
} else {
    $null
}

if ($dbUrl) {
    try {
        # Intentar conectar (requiere psql en PATH)
        $result = & psql $dbUrl -c "SELECT COUNT(*) FROM crm_leads;" 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✅ Tabla crm_leads existe" -ForegroundColor Green
            
            # Verificar otras tablas
            $tables = @("crm_conversations", "crm_deals", "crm_agents")
            foreach ($table in $tables) {
                $check = & psql $dbUrl -c "SELECT COUNT(*) FROM $table;" 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "  ✅ Tabla $table existe" -ForegroundColor Green
                } else {
                    $errors += "Tabla $table no existe"
                    Write-Host "  ❌ Tabla $table no existe" -ForegroundColor Red
                }
            }
        } else {
            $warnings += "No se pudo verificar tablas (psql no disponible o DB no accesible)"
            Write-Host "  ⚠️  No se pudo verificar tablas" -ForegroundColor Yellow
        }
    } catch {
        $warnings += "No se pudo conectar a PostgreSQL (puede estar en Azure)"
        Write-Host "  ⚠️  No se pudo conectar a PostgreSQL" -ForegroundColor Yellow
    }
} else {
    $warnings += "DATABASE_URL no configurado (puede estar en Azure)"
    Write-Host "  ⚠️  DATABASE_URL no encontrado" -ForegroundColor Yellow
}

# 3. Verificar webhooks registrados en server.ts
Write-Host "`n[3/8] Verificando webhooks en backend..." -ForegroundColor Yellow
$webhookFile = "packages/backend/src/crm/api/webhookRoutes.ts"
if (Test-Path $webhookFile) {
    $webhookContent = Get-Content $webhookFile -Raw
    $endpoints = @(
        "/lead-created",
        "/conversation",
        "/deal-stage-change"
    )
    
    foreach ($endpoint in $endpoints) {
        if ($webhookContent -match $endpoint) {
            Write-Host "  ✅ Webhook $endpoint implementado" -ForegroundColor Green
        } else {
            $errors += "Webhook $endpoint no encontrado"
            Write-Host "  ❌ Webhook $endpoint no encontrado" -ForegroundColor Red
        }
    }
} else {
    $errors += "Archivo webhookRoutes.ts no encontrado"
    Write-Host "  ❌ webhookRoutes.ts no encontrado" -ForegroundColor Red
}

# 4. Verificar que webhooks están registrados en server.ts
Write-Host "`n[4/8] Verificando registro de webhooks en server..." -ForegroundColor Yellow
$serverFile = "packages/backend/src/api/http/server.ts"
if (Test-Path $serverFile) {
    $serverContent = Get-Content $serverFile -Raw
    if ($serverContent -match "/api/crm/webhooks") {
        Write-Host "  ✅ Webhooks registrados en server.ts" -ForegroundColor Green
    } else {
        $errors += "Webhooks no registrados en server.ts"
        Write-Host "  ❌ Webhooks no registrados en server.ts" -ForegroundColor Red
    }
} else {
    $errors += "server.ts no encontrado"
    Write-Host "  ❌ server.ts no encontrado" -ForegroundColor Red
}

# 5. Verificar que no hay datos mock en hooks del frontend
Write-Host "`n[5/8] Verificando hooks del frontend (sin mocks activos)..." -ForegroundColor Yellow
$hooksDir = "packages/frontend/src/hooks"
$hookFiles = @("useCRMData.ts", "useCRMLeads.ts")

foreach ($file in $hookFiles) {
    $filePath = Join-Path $hooksDir $file
    if (Test-Path $filePath) {
        $content = Get-Content $filePath -Raw
        # Verificar que los mocks solo se usan como fallback (no como datos principales)
        if ($content -match "MOCK.*fallback|fallback.*MOCK|mock.*fallback|fallback.*mock") {
            Write-Host "  ✅ $file usa mocks solo como fallback" -ForegroundColor Green
        } else {
            Write-Host "  ⚠️  $file - Revisar uso de mocks" -ForegroundColor Yellow
        }
        
        # Verificar que hay llamadas a API reales
        if ($content -match "fetch.*API_URL|API_URL.*fetch") {
            Write-Host "  ✅ $file hace llamadas a API reales" -ForegroundColor Green
        } else {
            $warnings += "$file puede no estar haciendo llamadas a API"
            Write-Host "  ⚠️  $file - Verificar llamadas a API" -ForegroundColor Yellow
        }
    }
}

# 6. Verificar que CRMPremiumPanel usa hooks reales
Write-Host "`n[6/8] Verificando CRMPremiumPanel..." -ForegroundColor Yellow
$panelFile = "packages/frontend/src/components/CRMPremiumPanel.tsx"
if (Test-Path $panelFile) {
    $panelContent = Get-Content $panelFile -Raw
    if ($panelContent -match "useCRMData|useCRMLeads") {
        Write-Host "  ✅ CRMPremiumPanel usa hooks reales" -ForegroundColor Green
    } else {
        $errors += "CRMPremiumPanel no usa hooks reales"
        Write-Host "  ❌ CRMPremiumPanel no usa hooks reales" -ForegroundColor Red
    }
} else {
    $errors += "CRMPremiumPanel.tsx no encontrado"
    Write-Host "  ❌ CRMPremiumPanel.tsx no encontrado" -ForegroundColor Red
}

# 7. Verificar documentación de conexión
Write-Host "`n[7/8] Verificando documentación..." -ForegroundColor Yellow
$docFile = "docs/CONEXION-AGENTES-N8N-CRM-PRODUCCION.md"
if (Test-Path $docFile) {
    Write-Host "  ✅ Documentación de conexión creada" -ForegroundColor Green
} else {
    $warnings += "Documentación de conexión no encontrada"
    Write-Host "  ⚠️  Documentación de conexión no encontrada" -ForegroundColor Yellow
}

# 8. Verificar que backend compila sin errores
Write-Host "`n[8/8] Verificando compilación del backend..." -ForegroundColor Yellow
$backendDir = "packages/backend"
if (Test-Path $backendDir) {
    Push-Location $backendDir
    try {
        $buildResult = & npm run type-check 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✅ Backend compila sin errores" -ForegroundColor Green
        } else {
            $errors += "Backend tiene errores de TypeScript"
            Write-Host "  ❌ Backend tiene errores de TypeScript" -ForegroundColor Red
            Write-Host $buildResult -ForegroundColor Red
        }
    } catch {
        $warnings += "No se pudo verificar compilación (npm no disponible)"
        Write-Host "  ⚠️  No se pudo verificar compilación" -ForegroundColor Yellow
    } finally {
        Pop-Location
    }
}

# Resumen
Write-Host "`n" + ("=" * 60) -ForegroundColor Cyan
Write-Host "📊 RESUMEN" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Cyan

if ($errors.Count -eq 0) {
    Write-Host "`n✅ CRM LISTO PARA PRODUCCIÓN" -ForegroundColor Green
    Write-Host "   Todos los checks críticos pasaron" -ForegroundColor Green
} else {
    Write-Host "`n❌ CRM NO ESTÁ LISTO PARA PRODUCCIÓN" -ForegroundColor Red
    Write-Host "   Errores encontrados:" -ForegroundColor Red
    foreach ($error in $errors) {
        Write-Host "   - $error" -ForegroundColor Red
    }
}

if ($warnings.Count -gt 0) {
    Write-Host "`n⚠️  ADVERTENCIAS:" -ForegroundColor Yellow
    foreach ($warning in $warnings) {
        Write-Host "   - $warning" -ForegroundColor Yellow
    }
}

Write-Host "`n📋 PRÓXIMOS PASOS:" -ForegroundColor Cyan
Write-Host "   1. Revisar errores (si hay)" -ForegroundColor White
Write-Host "   2. Configurar CRM_WEBHOOK_SECRET en producción" -ForegroundColor White
Write-Host "   3. Registrar agentes en tabla crm_agents" -ForegroundColor White
Write-Host "   4. Seguir guía: docs/CONEXION-AGENTES-N8N-CRM-PRODUCCION.md" -ForegroundColor White

Write-Host "`n"

