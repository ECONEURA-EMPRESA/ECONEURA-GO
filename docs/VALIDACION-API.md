# 🔍 Validación de API - ECONEURA

## 📋 Checklist de Validación

### 1. Verificar que el Backend esté Corriendo

```powershell
# Verificar si el puerto 3000 está en uso
netstat -ano | findstr :3000

# Probar health check básico
Invoke-WebRequest -Uri "http://localhost:3000/health" -Method GET
```

**Resultado esperado:**
```json
{
  "status": "ok",
  "message": "Backend is running"
}
```

### 2. Verificar Health Check Completo

```powershell
Invoke-WebRequest -Uri "http://localhost:3000/api/health" -Method GET
```

**Resultado esperado:**
```json
{
  "status": "ok",
  "checks": {
    "database": true,
    "redis": "Not configured or not available"
  }
}
```

### 3. Verificar Liveness y Readiness Probes

```powershell
# Liveness probe
Invoke-WebRequest -Uri "http://localhost:3000/api/health/live" -Method GET

# Readiness probe
Invoke-WebRequest -Uri "http://localhost:3000/api/health/ready" -Method GET
```

**Resultado esperado:**
```json
{
  "status": "live"
}
```

```json
{
  "status": "ready"
}
```

### 4. Verificar Configuración de API Key

```powershell
# Verificar que OPENAI_API_KEY esté en .env
cd packages\backend
Get-Content .env | Select-String "OPENAI_API_KEY"
```

**Resultado esperado:**
```
OPENAI_API_KEY=[REDACTED]
```

### 5. Probar Endpoint de Invoke (Chat)

```powershell
$body = @{
    input = "Hola, ¿puedes confirmar que estás funcionando?"
} | ConvertTo-Json

$headers = @{
    "Content-Type" = "application/json"
    "Authorization" = "Bearer test-token"
}

Invoke-WebRequest -Uri "http://localhost:3000/api/invoke/a-ceo-01" -Method POST -Body $body -Headers $headers
```

**Resultado esperado:**
```json
{
  "success": true,
  "output": "Respuesta del agente NEURA CEO...",
  "message": "Respuesta del agente NEURA CEO...",
  "conversationId": "conv_...",
  "model": "gpt-4.1",
  "tokens": 0,
  "cost": 0
}
```

### 6. Probar Otros Agentes

```powershell
# CTO
Invoke-WebRequest -Uri "http://localhost:3000/api/invoke/a-cto-01" -Method POST -Body $body -Headers $headers

# CFO
Invoke-WebRequest -Uri "http://localhost:3000/api/invoke/a-cfo-01" -Method POST -Body $body -Headers $headers

# CMO
Invoke-WebRequest -Uri "http://localhost:3000/api/invoke/a-cmo-01" -Method POST -Body $body -Headers $headers
```

## ⚠️ Problemas Comunes y Soluciones

### Error: "Backend NO está corriendo"
**Solución:**
```powershell
cd packages\backend
npm run dev
```

### Error: "OPENAI_API_KEY no configurada"
**Solución:**
```powershell
cd packages\backend
if (-not (Test-Path ".env")) { New-Item -Path ".env" -ItemType File }
Add-Content -Path ".env" -Value "OPENAI_API_KEY=[REDACTED]"
# Reiniciar el backend
```

### Error: "401 Unauthorized" o "403 Forbidden"
**Causa:** El endpoint requiere autenticación.
**Solución:** Asegúrate de incluir el header `Authorization: Bearer <token>` en las peticiones.

### Error: "404 Not Found" en `/api/invoke/:agentId`
**Causa:** El `agentId` no está en el mapeo.
**Solución:** Verifica que el `agentId` sea uno de los siguientes:
- `a-ceo-01`
- `a-cto-01`
- `a-cfo-01`
- `a-cmo-01`
- `a-ventas-01`
- `a-atencion-cliente-01`
- `a-rrhh-01`
- `a-operaciones-01`
- `a-legal-01`
- `a-datos-01`
- `a-innovacion-01`

### Error: "500 Internal Server Error"
**Causa:** Error en el backend al procesar la petición.
**Solución:**
1. Revisa los logs del backend
2. Verifica que `OPENAI_API_KEY` sea válida
3. Verifica que el modelo LLM esté disponible

## 📊 Script de Validación Automática

Ejecuta el script de validación completo:

```powershell
cd C:\Users\Usuario\ECONEURA-FULL
.\scripts\validate-api.ps1
```

## ✅ Criterios de Éxito

- [ ] Backend responde en `http://localhost:3000`
- [ ] Health check básico devuelve `200 OK`
- [ ] Health check completo verifica DB y Redis
- [ ] Liveness probe devuelve `200 OK`
- [ ] Readiness probe devuelve `200 OK`
- [ ] `OPENAI_API_KEY` está configurada en `.env`
- [ ] Endpoint `/api/invoke/a-ceo-01` responde correctamente
- [ ] El agente NEURA devuelve una respuesta válida

## 🚀 Próximos Pasos

Una vez validada la API:

1. **Probar desde el Frontend:**
   - Abre `http://localhost:5173`
   - Inicia sesión
   - Prueba el chat con un agente NEURA

2. **Verificar Logs:**
   - Revisa los logs del backend para confirmar que las peticiones se procesan correctamente
   - Verifica que no haya errores de autenticación o validación

3. **Probar Integración Completa:**
   - Prueba el flujo completo: Login → Seleccionar Departamento → Chat con Agente → Verificar Respuesta


