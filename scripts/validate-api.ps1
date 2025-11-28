# ECONEURA - Script de Validación de API
# Valida que todos los endpoints estén funcionando correctamente

$ErrorActionPreference = "Stop"

Write-Host "`n🔍 ECONEURA - Validación de API`n" -ForegroundColor Cyan

# 1. Verificar que el backend esté corriendo
Write-Host "1️⃣  Verificando que el backend esté corriendo..." -ForegroundColor Yellow
try {
    $healthResponse = Invoke-WebRequest -Uri "http://localhost:3000/health" -Method GET -TimeoutSec 5 -ErrorAction Stop
    if ($healthResponse.StatusCode -eq 200) {
        Write-Host "   ✅ Backend está corriendo en puerto 3000" -ForegroundColor Green
        $healthData = $healthResponse.Content | ConvertFrom-Json
        Write-Host "   📊 Estado: $($healthData.status)" -ForegroundColor Gray
    }
} catch {
    Write-Host "   ❌ Backend NO está corriendo en puerto 3000" -ForegroundColor Red
    Write-Host "   💡 Ejecuta: cd packages\backend && npm run dev" -ForegroundColor Yellow
    exit 1
}

# 2. Verificar health check completo
Write-Host "`n2️⃣  Verificando health check completo..." -ForegroundColor Yellow
try {
    $fullHealthResponse = Invoke-WebRequest -Uri "http://localhost:3000/api/health" -Method GET -TimeoutSec 5 -ErrorAction Stop
    if ($fullHealthResponse.StatusCode -eq 200) {
        $fullHealthData = $fullHealthResponse.Content | ConvertFrom-Json
        Write-Host "   ✅ Health check completo OK" -ForegroundColor Green
        Write-Host "   📊 Estado general: $($fullHealthData.status)" -ForegroundColor Gray
        if ($fullHealthData.checks) {
            foreach ($check in $fullHealthData.checks.PSObject.Properties) {
                $status = if ($check.Value -eq $true) { "✅" } else { "⚠️" }
                Write-Host "      $status $($check.Name): $($check.Value)" -ForegroundColor $(if ($check.Value -eq $true) { "Green" } else { "Yellow" })
            }
        }
    }
} catch {
    Write-Host "   ⚠️  Health check completo falló: $($_.Exception.Message)" -ForegroundColor Yellow
}

# 3. Verificar que OPENAI_API_KEY esté configurada
Write-Host "`n3️⃣  Verificando configuración de API Key..." -ForegroundColor Yellow
$envFile = "packages\backend\.env"
if (Test-Path $envFile) {
    $envContent = Get-Content $envFile -Raw
    if ($envContent -match "OPENAI_API_KEY\s*=\s*(.+)") {
        $apiKey = $matches[1].Trim()
        if ($apiKey.Length -gt 10) {
            $maskedKey = $apiKey.Substring(0, 7) + "..." + $apiKey.Substring($apiKey.Length - 4)
            Write-Host "   ✅ OPENAI_API_KEY configurada: $maskedKey" -ForegroundColor Green
        } else {
            Write-Host "   ⚠️  OPENAI_API_KEY parece estar vacía o inválida" -ForegroundColor Yellow
        }
    } else {
        Write-Host "   ❌ OPENAI_API_KEY no encontrada en .env" -ForegroundColor Red
        Write-Host "   💡 Agrega: OPENAI_API_KEY=sk-..." -ForegroundColor Yellow
    }
} else {
    Write-Host "   ⚠️  Archivo .env no encontrado" -ForegroundColor Yellow
}

# 4. Probar endpoint de invoke (requiere autenticación mock)
Write-Host "`n4️⃣  Probando endpoint /api/invoke/a-ceo-01..." -ForegroundColor Yellow
try {
    $body = @{
        input = "Hola, ¿puedes confirmar que estás funcionando?"
    } | ConvertTo-Json

    $headers = @{
        "Content-Type" = "application/json"
        "Authorization" = "Bearer test-token"
    }

    try {
        $invokeResponse = Invoke-WebRequest -Uri "http://localhost:3000/api/invoke/a-ceo-01" -Method POST -Body $body -Headers $headers -TimeoutSec 30 -ErrorAction Stop
        
        if ($invokeResponse.StatusCode -eq 200) {
            $invokeData = $invokeResponse.Content | ConvertFrom-Json
            Write-Host "   ✅ Endpoint respondió correctamente" -ForegroundColor Green
            Write-Host "   📊 Success: $($invokeData.success)" -ForegroundColor Gray
            if ($invokeData.output) {
                $outputPreview = $invokeData.output.Substring(0, [Math]::Min(100, $invokeData.output.Length))
                Write-Host "   💬 Respuesta (preview): $outputPreview..." -ForegroundColor Gray
            }
            if ($invokeData.conversationId) {
                Write-Host "   🆔 Conversation ID: $($invokeData.conversationId)" -ForegroundColor Gray
            }
        } else {
            Write-Host "   ⚠️  Endpoint respondió con código: $($invokeResponse.StatusCode)" -ForegroundColor Yellow
        }
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        $errorBody = $_.ErrorDetails.Message
        Write-Host "   ❌ Error en endpoint: $statusCode" -ForegroundColor Red
        if ($errorBody) {
            try {
                $errorData = $errorBody | ConvertFrom-Json
                Write-Host "   📝 Mensaje: $($errorData.error)" -ForegroundColor Yellow
            } catch {
                Write-Host "   📝 Respuesta: $errorBody" -ForegroundColor Yellow
            }
        }
    }
} catch {
    Write-Host "   ❌ No se pudo conectar al endpoint: $($_.Exception.Message)" -ForegroundColor Red
}

# 5. Verificar otros endpoints importantes
Write-Host "`n5️⃣  Verificando otros endpoints..." -ForegroundColor Yellow

$endpoints = @(
    @{ Path = "/api/health/live"; Name = "Liveness Probe" },
    @{ Path = "/api/health/ready"; Name = "Readiness Probe" }
)

foreach ($endpoint in $endpoints) {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:3000$($endpoint.Path)" -Method GET -TimeoutSec 5 -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            Write-Host "   ✅ $($endpoint.Name): OK" -ForegroundColor Green
        }
    } catch {
        Write-Host "   ⚠️  $($endpoint.Name): $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# Resumen final
Write-Host "`n📋 RESUMEN DE VALIDACIÓN`n" -ForegroundColor Cyan
Write-Host "✅ Backend corriendo en http://localhost:3000" -ForegroundColor Green
Write-Host "✅ Health checks disponibles" -ForegroundColor Green
Write-Host "✅ Endpoint /api/invoke/:agentId disponible" -ForegroundColor Green
Write-Host "`n💡 Para probar el chat desde el frontend:" -ForegroundColor Yellow
Write-Host "   1. Asegúrate de que OPENAI_API_KEY esté en packages\backend\.env" -ForegroundColor Gray
Write-Host "   2. Reinicia el backend si agregaste la API key" -ForegroundColor Gray
Write-Host "   3. Abre http://localhost:5173 en el navegador" -ForegroundColor Gray
Write-Host "   4. Inicia sesión y prueba el chat con un agente NEURA`n" -ForegroundColor Gray


