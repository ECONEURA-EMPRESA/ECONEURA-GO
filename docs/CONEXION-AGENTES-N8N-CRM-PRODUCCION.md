# 🔌 CONEXIÓN AGENTES N8N → CRM - PRODUCCIÓN

## ⚠️ IMPORTANTE: PRODUCTO FINAL - NO DEMOS

Esta guía es para **conectar agentes reales de N8N al CRM de ECONEURA**.  
**NO hay datos mock ni demos.** Todo es producción real.

---

## 📋 PREREQUISITOS

### 1. Backend Desplegado y Funcionando

✅ Backend corriendo en: `http://localhost:3000` (local) o `https://tu-backend.azurewebsites.net` (producción)  
✅ PostgreSQL con tablas CRM creadas  
✅ Variable `CRM_WEBHOOK_SECRET` configurada en backend

### 2. Obtener CRM_WEBHOOK_SECRET

**En producción (Azure):**
```powershell
# Obtener desde Azure Key Vault o App Settings
az webapp config appsettings list --name tu-backend-app --resource-group tu-rg --query "[?name=='CRM_WEBHOOK_SECRET'].value" -o tsv
```

**En local:**
```powershell
# Ver en packages/backend/.env
Get-Content packages/backend/.env | Select-String "CRM_WEBHOOK_SECRET"
```

**Si no existe, generarlo:**
```powershell
# PowerShell
$secret = [Convert]::ToBase64String([System.Security.Cryptography.RandomNumberGenerator]::GetBytes(32))
Write-Host "CRM_WEBHOOK_SECRET=$secret"
```

---

## 🔐 CONFIGURACIÓN EN N8N

### Paso 1: Configurar Variable de Entorno en N8N

1. Ir a **Settings → Environment Variables** en N8N
2. Agregar:
   ```
   CRM_WEBHOOK_SECRET = <tu-secret-obtenido>
   CRM_BACKEND_URL = https://tu-backend.azurewebsites.net
   ```
   O para local:
   ```
   CRM_BACKEND_URL = http://localhost:3000
   ```

### Paso 2: Crear Función para Generar HMAC

En N8N, crear una **Function Node** con este código:

```javascript
// Función para generar HMAC SHA256 signature
const crypto = require('crypto');

const secret = $env.CRM_WEBHOOK_SECRET;
const body = JSON.stringify($input.all()[0].json);

const hmac = crypto.createHmac('sha256', secret);
hmac.update(body);
const signature = hmac.digest('hex');

return {
  json: {
    ...$input.all()[0].json,
    _webhook_signature: signature
  }
};
```

**Guardar esta función como:** `generate-webhook-signature`

---

## 📡 WEBHOOK 1: CREAR LEAD

### Endpoint
```
POST {{CRM_BACKEND_URL}}/api/crm/webhooks/lead-created
```

### Headers
```
Content-Type: application/json
X-Webhook-Signature: {{_webhook_signature}}
```

### Body (JSON)
```json
{
  "email": "lead@example.com",
  "nombre": "Juan Pérez",
  "empresa": "Empresa S.A.",
  "telefono": "+34 600 000 000",
  "cargo": "CEO",
  "score": 8,
  "department": "cmo",
  "agent_name": "Lead_Prospector",
  "source_channel": "linkedin",
  "enrichment_data": {
    "linkedin": "https://linkedin.com/in/juanperez",
    "company_size": "50-100",
    "industry": "Technology"
  }
}
```

### Workflow N8N Ejemplo

```
[Trigger: Webhook/Manual] 
  → [Function: generate-webhook-signature]
  → [HTTP Request: POST /api/crm/webhooks/lead-created]
  → [IF: Response OK]
    → [Log: Lead creado exitosamente]
  → [ELSE]
    → [Log: Error al crear lead]
```

### Validaciones del Backend

✅ Email válido  
✅ Nombre requerido  
✅ Department: `cmo` o `cso`  
✅ Agent name debe existir en tabla `crm_agents`  
✅ Score: 1-10 (opcional, default: 5)  
✅ Idempotencia: Si el lead ya existe (por email), retorna el existente

### Respuesta Exitosa (201)
```json
{
  "success": true,
  "data": {
    "id": "uuid-del-lead",
    "email": "lead@example.com",
    "nombre": "Juan Pérez",
    "empresa": "Empresa S.A.",
    "score": 8,
    "status": "new",
    "department": "cmo",
    "assigned_agent": "Lead_Prospector",
    "created_at": "2025-01-17T10:00:00Z"
  }
}
```

### Respuesta Error (400/401/500)
```json
{
  "success": false,
  "error": "Mensaje de error",
  "code": "ERROR_CODE"
}
```

---

## 💬 WEBHOOK 2: REGISTRAR CONVERSACIÓN

### Endpoint
```
POST {{CRM_BACKEND_URL}}/api/crm/webhooks/conversation
```

### Headers
```
Content-Type: application/json
X-Webhook-Signature: {{_webhook_signature}}
```

### Body (JSON)
```json
{
  "lead_id": "uuid-del-lead",
  "mensaje": "Hola, estoy interesado en conocer más sobre vuestros servicios.",
  "agent_name": "Lead_Prospector",
  "direction": "inbound",
  "intent": "positivo"
}
```

### Campos

- `lead_id` (UUID): ID del lead (obtenido del webhook lead-created)
- `mensaje` (string): Texto de la conversación
- `agent_name` (string): Nombre del agente que procesó
- `direction`: `inbound` (lead → agente) o `outbound` (agente → lead)
- `intent` (opcional): `positivo`, `neutro`, `negativo`

### Workflow N8N Ejemplo

```
[Trigger: Cuando agente responde a lead]
  → [Function: generate-webhook-signature]
  → [HTTP Request: POST /api/crm/webhooks/conversation]
  → [IF: Intent positivo]
    → [Webhook: deal-stage-change] (avanzar deal)
```

---

## 💰 WEBHOOK 3: ACTUALIZAR DEAL (STAGE CHANGE)

### Endpoint
```
POST {{CRM_BACKEND_URL}}/api/crm/webhooks/deal-stage-change
```

### Headers
```
Content-Type: application/json
X-Webhook-Signature: {{_webhook_signature}}
```

### Body (JSON)
```json
{
  "lead_id": "uuid-del-lead",
  "stage": "closed_won",
  "revenue": 50000,
  "agent_name": "Lead_Prospector",
  "notes": "Cliente cerró contrato anual"
}
```

### Stages Válidos

- `qualified` - Lead calificado
- `proposal` - Propuesta enviada
- `negotiation` - En negociación
- `closed_won` - ✅ Cerrado ganado (requiere `revenue`)
- `closed_lost` - ❌ Cerrado perdido

### Validaciones

✅ `revenue` solo se acepta cuando `stage = closed_won`  
✅ `revenue` debe ser número positivo  
✅ Si el deal no existe, se crea automáticamente  
✅ Métricas del agente se actualizan automáticamente

### Workflow N8N Ejemplo

```
[Trigger: Lead acepta propuesta]
  → [Function: generate-webhook-signature]
  → [HTTP Request: POST /api/crm/webhooks/deal-stage-change]
  → [IF: Stage = closed_won]
    → [Notificar: Deal cerrado exitosamente]
```

---

## 🔄 WORKFLOW COMPLETO N8N: LEAD → DEAL

### Escenario: Agente encuentra lead, conversa, y cierra deal

```
1. [Webhook Trigger: Nuevo lead detectado]
   ↓
2. [Enrichment: Obtener datos adicionales (LinkedIn, etc.)]
   ↓
3. [Function: Calcular score del lead]
   ↓
4. [HTTP Request: POST /api/crm/webhooks/lead-created]
   ↓ (Lead creado en CRM)
5. [AI Agent: Iniciar conversación con lead]
   ↓
6. [Function: Analizar intent de conversación]
   ↓
7. [HTTP Request: POST /api/crm/webhooks/conversation]
   ↓ (Conversación registrada)
8. [IF: Intent positivo]
   ↓
9. [AI Agent: Enviar propuesta]
   ↓
10. [HTTP Request: POST /api/crm/webhooks/deal-stage-change]
    (Stage: proposal)
    ↓
11. [Wait: Respuesta del lead (24h)]
    ↓
12. [IF: Lead acepta]
    ↓
13. [HTTP Request: POST /api/crm/webhooks/deal-stage-change]
    (Stage: closed_won, Revenue: 50000)
    ↓
14. [Notificar: Deal cerrado exitosamente]
```

---

## 🧪 TESTING DE WEBHOOKS

### Test Manual con PowerShell

```powershell
# 1. Generar secret (si no lo tienes)
$secret = [Convert]::ToBase64String([System.Security.Cryptography.RandomNumberGenerator]::GetBytes(32))

# 2. Crear payload
$payload = @{
    email = "test@example.com"
    nombre = "Test Lead"
    empresa = "Test Company"
    score = 8
    department = "cmo"
    agent_name = "Test_Agent"
} | ConvertTo-Json

# 3. Generar HMAC
$hmac = New-Object System.Security.Cryptography.HMACSHA256
$hmac.Key = [System.Text.Encoding]::UTF8.GetBytes($secret)
$signature = [BitConverter]::ToString($hmac.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($payload))).Replace("-", "").ToLower()

# 4. Enviar request
$headers = @{
    "Content-Type" = "application/json"
    "X-Webhook-Signature" = $signature
}

Invoke-RestMethod -Uri "http://localhost:3000/api/crm/webhooks/lead-created" `
    -Method POST `
    -Headers $headers `
    -Body $payload
```

### Test con cURL

```bash
# Generar signature (requiere Node.js)
node -e "
const crypto = require('crypto');
const secret = 'tu-secret-aqui';
const body = JSON.stringify({email:'test@example.com',nombre:'Test',department:'cmo',agent_name:'Test'});
const hmac = crypto.createHmac('sha256', secret);
hmac.update(body);
console.log(hmac.digest('hex'));
"

# Enviar request
curl -X POST http://localhost:3000/api/crm/webhooks/lead-created \
  -H "Content-Type: application/json" \
  -H "X-Webhook-Signature: <signature-generada>" \
  -d '{"email":"test@example.com","nombre":"Test","department":"cmo","agent_name":"Test"}'
```

---

## ✅ VERIFICACIÓN EN CRM

### 1. Ver Leads en Frontend

1. Iniciar sesión en ECONEURA Cockpit
2. Ir a departamento **Marketing y Ventas (CMO)**
3. Ver panel **CRM Premium**
4. Tab **Leads** → Debe aparecer el lead creado

### 2. Ver Conversaciones

- Las conversaciones se registran automáticamente
- Se pueden ver en el historial del lead (futura feature)

### 3. Ver Deals

- Los deals aparecen en el **Pipeline IA** del CRM
- Métricas se actualizan automáticamente

---

## 🚨 TROUBLESHOOTING

### Error: "Invalid signature"

**Causa:** HMAC incorrecto o secret no coincide

**Solución:**
1. Verificar que `CRM_WEBHOOK_SECRET` en backend coincide con N8N
2. Verificar que el body se serializa igual (JSON.stringify)
3. Verificar que el header `X-Webhook-Signature` se envía correctamente

### Error: "Invalid agent"

**Causa:** El `agent_name` no existe en tabla `crm_agents`

**Solución:**
1. Verificar agentes disponibles:
```sql
SELECT * FROM crm_agents WHERE department = 'cmo';
```
2. Crear agente si no existe:
```sql
INSERT INTO crm_agents (name, department, status) 
VALUES ('Lead_Prospector', 'cmo', 'active');
```

### Error: "Lead ya existe"

**Causa:** Idempotencia funcionando (lead con mismo email ya existe)

**Solución:** ✅ Esto es correcto. El webhook retorna el lead existente (200 OK).

### Error: "Revenue solo permitido en closed_won"

**Causa:** Se envió `revenue` con un stage diferente a `closed_won`

**Solución:** Solo enviar `revenue` cuando `stage = "closed_won"`

---

## 📊 MONITOREO

### Logs del Backend

Los webhooks se registran en logs con:
- `[CRM Webhooks] Lead creado`
- `[CRM Webhooks] Conversación creada`
- `[CRM Webhooks] Deal actualizado`

### Application Insights (Azure)

Si está configurado, ver métricas en:
- Azure Portal → Application Insights → Logs
- Query: `traces | where message contains "CRM Webhooks"`

---

## 🔒 SEGURIDAD

✅ **HMAC SHA256** - Todas las requests deben tener signature válida  
✅ **Rate Limiting** - 100 requests/minuto por IP  
✅ **Payload Size** - Máximo 100KB  
✅ **Validación de Agentes** - Solo agentes registrados pueden crear leads  
✅ **Idempotencia** - Leads duplicados se manejan elegantemente  
✅ **Transacciones** - Operaciones atómicas (BEGIN/COMMIT/ROLLBACK)

---

## 📝 CHECKLIST FINAL

Antes de conectar agentes reales:

- [ ] Backend desplegado y funcionando
- [ ] `CRM_WEBHOOK_SECRET` configurado en backend y N8N
- [ ] Agentes registrados en tabla `crm_agents`
- [ ] Tablas CRM creadas en PostgreSQL
- [ ] Test manual de webhook exitoso
- [ ] Workflow N8N configurado con HMAC
- [ ] Frontend accesible para verificar datos
- [ ] Logs del backend monitoreados

---

## 🚀 LISTO PARA PRODUCCIÓN

Una vez completado el checklist, **los agentes N8N pueden conectarse al CRM y empezar a generar leads, conversaciones y deals reales.**

**NO hay datos mock. Todo es producción real.**

---

**Última actualización:** 17 Enero 2025  
**Versión:** 1.0.0 - Producción

