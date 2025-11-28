# 🤖 CONFIGURACIÓN COMPLETA: AGENTES N8N PARA CRM MARKETING Y VENTAS

## 📋 AGENTES AUTOMATIZADOS - NOMBRES Y CONEXIONES

### 🔗 FLUJO COMPLETO DE AGENTES

```
1. Embudo Comercial (a-mkt-01)
   ↓
2. Calidad de Leads (a-mkt-03)
   ↓
3. Salud de Pipeline (a-mkt-02)
   ↓
4. Post-Campaña (a-mkt-04)
```

---

## 🤖 AGENTE 1: "Embudo Comercial" (a-mkt-01)

### **Nombre en N8N**: `ECONEURA-Embudo-Comercial`

### **Descripción**: 
Captura leads desde múltiples fuentes y los registra en el CRM.

### **Fuentes de Datos**:
- Formularios web (Google Forms, Typeform, Webflow)
- LinkedIn (nuevos contactos, mensajes)
- Eventos (webinars, conferencias)
- Email (respuestas automáticas)

### **Webhook de Salida**:
```
POST https://tu-backend.com/api/crm/webhooks/lead-created
```

### **Headers**:
```
Content-Type: application/json
X-Webhook-Signature: [HMAC_SHA256 del body con CRM_WEBHOOK_SECRET]
```

### **Payload Ejemplo**:
```json
{
  "email": "juan.perez@empresa.com",
  "nombre": "Juan Pérez",
  "empresa": "TechCorp S.L.",
  "telefono": "+34 600 123 456",
  "cargo": "CTO",
  "score": 5,
  "department": "cmo",
  "agent_name": "Embudo Comercial",
  "source_channel": "formulario_web",
  "enrichment_data": {
    "linkedin_url": "https://linkedin.com/in/juanperez",
    "company_size": "50-200",
    "industry": "Technology"
  }
}
```

### **Trigger**: 
- Cada vez que se detecta un nuevo lead en cualquier fuente
- Frecuencia: Tiempo real

### **Conexión con otros agentes**:
- ✅ **Dispara**: `Calidad de Leads` (a-mkt-03) cuando se crea un lead

---

## 🤖 AGENTE 2: "Calidad de Leads" (a-mkt-03)

### **Nombre en N8N**: `ECONEURA-Calidad-de-Leads`

### **Descripción**: 
Analiza y califica automáticamente los leads con score (1-100).

### **Trigger**:
- Webhook desde `Embudo Comercial` cuando se crea un lead
- También se ejecuta cada hora para recalificar leads existentes

### **Lógica de Scoring**:
1. **Engagement** (4.0 puntos máximo):
   - Emails abiertos: +1.0 punto
   - Clicks en emails: +1.5 puntos
   - Visitas a web: +1.0 punto
   - Descargas de recursos: +0.5 puntos

2. **Empresa** (3.0 puntos máximo):
   - Tamaño empresa (50-200 empleados): +1.5 puntos
   - Industria relevante: +1.0 punto
   - Presupuesto estimado: +0.5 puntos

3. **Fuente** (2.0 puntos máximo):
   - Referral: +2.0 puntos
   - Evento: +1.5 puntos
   - Formulario web: +1.0 punto
   - LinkedIn: +0.5 puntos

4. **Cargo** (1.0 punto máximo):
   - C-Level: +1.0 punto
   - Director: +0.7 puntos
   - Manager: +0.5 puntos

**Score Final**: Suma de todos los puntos (máximo 10.0), redondeado a 1 decimal.

### **Webhook de Salida**:
```
POST https://tu-backend.com/api/crm/webhooks/lead-updated
```

### **Headers**:
```
Content-Type: application/json
X-Webhook-Signature: [HMAC_SHA256 del body con CRM_WEBHOOK_SECRET]
```

### **Payload Ejemplo**:
```json
{
  "lead_id": "uuid-del-lead",
  "score": 8,
  "status": "qualified",
  "agent_name": "Calidad de Leads",
  "scoring_details": {
    "engagement_score": 3.5,
    "company_score": 2.5,
    "source_score": 1.5,
    "role_score": 1.0
  }
}
```

**NOTA IMPORTANTE**: El `score` es de 1-10 (no 1-100). El scoring_details puede tener valores más altos para cálculo interno, pero el score final debe estar entre 1-10.

**NOTA**: El `lead_id` se obtiene de la respuesta del webhook `lead-created` del agente "Embudo Comercial".

### **Conexión con otros agentes**:
- ✅ **Dispara**: `Salud de Pipeline` (a-mkt-02) si score >= 7 (score alto)
- ✅ **Dispara**: `Email Nurturing` (interno) si score < 7 (score bajo)

---

## 🤖 AGENTE 3: "Salud de Pipeline" (a-mkt-02)

### **Nombre en N8N**: `ECONEURA-Salud-de-Pipeline`

### **Descripción**: 
Monitorea el pipeline, detecta deals en riesgo y genera alertas.

### **Trigger**:
- Webhook desde `Calidad de Leads` cuando score > 70
- Ejecución programada cada 6 horas
- Webhook desde `Embudo Comercial` cuando se crea deal

### **Lógica de Detección**:
1. **Deals en Riesgo**:
   - Sin actividad > 14 días → Alerta "warning"
   - Sin actividad > 21 días → Alerta "critical"
   - Score bajó > 10 puntos → Alerta "warning"

2. **Oportunidades**:
   - Score >= 8.5 → Crea deal automáticamente
   - Score 7.0-8.5 → Marca como "qualified"

### **Webhook de Salida** (Alerta):
```
POST https://tu-backend.com/api/crm/webhooks/alert
```

### **Headers**:
```
Content-Type: application/json
X-Webhook-Signature: [HMAC_SHA256 del body con CRM_WEBHOOK_SECRET]
```

### **Payload Ejemplo (Alerta)**:
```json
{
  "type": "warning",
  "message": "Deal NovaHR lleva 18 días sin actividad. Recomendada acción.",
  "deal_id": "uuid-del-deal",
  "lead_id": "uuid-del-lead",
  "agent_name": "Salud de Pipeline",
  "risk_level": "medium",
  "recommended_action": "Contactar lead para reactivar"
}
```

**Tipos de alerta válidos**: `success`, `warning`, `critical`, `info`

### **Webhook de Salida** (Deal Stage Change):
```
POST https://tu-backend.com/api/crm/webhooks/deal-stage-change
```

### **Payload Ejemplo (Deal Creado)**:
```json
{
  "lead_id": "uuid-del-lead",
  "new_stage": "meeting_scheduled",
  "agent_name": "Salud de Pipeline",
  "meeting_date": "2025-01-20T10:00:00Z"
}
```

### **Conexión con otros agentes**:
- ✅ **Dispara**: `Post-Campaña` (a-mkt-04) cuando deal se cierra (won/lost)
- ✅ **Recibe**: Datos de `Embudo Comercial` y `Calidad de Leads`

---

## 🤖 AGENTE 4: "Post-Campaña" (a-mkt-04)

### **Nombre en N8N**: `ECONEURA-Post-Campana`

### **Descripción**: 
Analiza ROI de campañas, genera reportes y recomendaciones.

### **Trigger**:
- Webhook desde `Salud de Pipeline` cuando deal se cierra (won/lost)
- Ejecución programada diaria (análisis de campañas)
- Ejecución semanal (reportes consolidados)

### **Lógica de Análisis**:
1. **ROI por Campaña**:
   - Revenue generado / Coste campaña
   - Leads generados / Coste campaña
   - Conversión por etapa

2. **Recomendaciones**:
   - Campañas con ROI > 300% → Aumentar presupuesto
   - Campañas con ROI < 100% → Reducir o pausar
   - Canales más efectivos → Priorizar

### **Webhook de Salida** (Deal Closed):
```
POST https://tu-backend.com/api/crm/webhooks/deal-stage-change
```

### **Headers**:
```
Content-Type: application/json
X-Webhook-Signature: [HMAC_SHA256 del body con CRM_WEBHOOK_SECRET]
```

### **Payload Ejemplo (Deal Won)**:
```json
{
  "lead_id": "uuid-del-lead",
  "new_stage": "closed_won",
  "agent_name": "Post-Campaña",
  "revenue": 50000,
  "closed_date": "2025-01-20T14:30:00Z"
}
```

**NOTA**: El revenue se calcula automáticamente desde los deals cerrados. No hay webhook `revenue-updated` separado.

### **Webhook de Salida** (Deal Closed - ya documentado arriba):
Usa el mismo webhook `deal-stage-change` con `new_stage: "closed_won"` y `revenue`.

### **Conexión con otros agentes**:
- ✅ **Recibe**: Datos de `Salud de Pipeline` cuando deals se cierran
- ✅ **Actualiza**: Métricas de revenue para todos los agentes

---

## 🔄 FLUJO COMPLETO DE CONEXIONES

### **Escenario 1: Nuevo Lead desde Formulario Web**

```
1. Usuario completa formulario web
   ↓
2. [Embudo Comercial] Detecta nuevo lead
   ↓ POST /api/crm/webhooks/lead-created
3. Backend guarda lead en PostgreSQL
   ↓
4. [Calidad de Leads] Recibe notificación
   ↓ Analiza lead (engagement, empresa, fuente, cargo)
   ↓ POST /api/crm/webhooks/lead-updated (score: 85)
5. Backend actualiza score y status
   ↓
6. [Salud de Pipeline] Detecta score > 70
   ↓ Crea deal automáticamente
   ↓ POST /api/crm/webhooks/deal-stage-change (stage: meeting_scheduled)
7. Backend crea deal en PostgreSQL
   ↓
8. Dashboard CRM muestra:
   - Nuevo lead con score 85
   - Deal creado automáticamente
   - Pipeline actualizado
```

### **Escenario 2: Deal en Riesgo**

```
1. [Salud de Pipeline] Ejecuta cada 6 horas
   ↓ Analiza todos los deals activos
   ↓ Detecta deal sin actividad > 14 días
   ↓ POST /api/crm/webhooks/alert
2. Backend guarda alerta en PostgreSQL
   ↓
3. Dashboard CRM muestra:
   - Alerta en sección "Alertas"
   - Deal marcado como "en riesgo"
```

### **Escenario 3: Deal Cerrado (Won)**

```
1. [Salud de Pipeline] Detecta deal cerrado
   ↓ POST /api/crm/webhooks/deal-stage-change (stage: closed_won, revenue: 50000)
2. Backend actualiza deal y métricas
   ↓
3. [Post-Campaña] Recibe notificación
   ↓ Analiza ROI de la campaña
   ↓ POST /api/crm/webhooks/revenue-updated
4. Backend actualiza revenue por agente
   ↓
5. Dashboard CRM muestra:
   - Deal cerrado con revenue
   - Revenue actualizado en KPIs
   - ROI de campaña en análisis
```

---

## 🔐 CONFIGURACIÓN DE SEGURIDAD

### **HMAC Signature**:

Todos los webhooks requieren firma HMAC:

```javascript
// En N8N, antes de enviar webhook:
const crypto = require('crypto');
const secret = process.env.CRM_WEBHOOK_SECRET; // Tu secret
const body = JSON.stringify(payload);
const signature = crypto
  .createHmac('sha256', secret)
  .update(body)
  .digest('hex');

// Agregar header:
headers: {
  'Content-Type': 'application/json',
  'X-Webhook-Signature': signature
}
```

### **Variables de Entorno en N8N**:
```
CRM_WEBHOOK_SECRET=tu-secret-aqui
CRM_BACKEND_URL=https://tu-backend.com
```

---

## 📊 TABLA DE CONEXIONES

| Agente Origen | Agente Destino | Webhook | Trigger |
|---------------|----------------|---------|---------|
| Embudo Comercial | Calidad de Leads | lead-created | Nuevo lead |
| Calidad de Leads | Salud de Pipeline | lead-updated | Score >= 7 |
| Salud de Pipeline | Post-Campaña | deal-stage-change | Deal cerrado |
| Salud de Pipeline | Dashboard (Alerta) | alert | Deal en riesgo |
| Post-Campaña | Dashboard (Revenue) | deal-stage-change (closed_won) | Deal cerrado con revenue |

---

## ✅ CHECKLIST DE CONFIGURACIÓN

### **Paso 1: Crear Workflows en N8N**
- [ ] Workflow: "ECONEURA-Embudo-Comercial"
- [ ] Workflow: "ECONEURA-Calidad-de-Leads"
- [ ] Workflow: "ECONEURA-Salud-de-Pipeline"
- [ ] Workflow: "ECONEURA-Post-Campana"

### **Paso 2: Configurar Triggers**
- [ ] Embudo Comercial: Formularios web, LinkedIn, Eventos
- [ ] Calidad de Leads: Webhook desde Embudo + Schedule (cada hora)
- [ ] Salud de Pipeline: Webhook desde Calidad + Schedule (cada 6h)
- [ ] Post-Campaña: Webhook desde Pipeline + Schedule (diario)

### **Paso 3: Configurar Webhooks**
- [ ] Todos los webhooks apuntan a: `https://tu-backend.com/api/crm/webhooks/*`
- [ ] Todos incluyen header `X-Webhook-Signature` con HMAC
- [ ] Todos usan `CRM_WEBHOOK_SECRET` para firma
- [ ] Webhook `lead-updated` usa `lead_id` de la respuesta de `lead-created`

### **Paso 4: Probar Flujo**
- [ ] Test: Crear lead manualmente → Verificar en dashboard
- [ ] Test: Score automático → Verificar actualización
- [ ] Test: Deal en riesgo → Verificar alerta
- [ ] Test: Deal cerrado → Verificar revenue

---

## 🎯 NOMBRES EXACTOS DE AGENTES

**IMPORTANTE**: Usar estos nombres exactos en `agent_name`:

1. `"Embudo Comercial"` (a-mkt-01)
2. `"Calidad de Leads"` (a-mkt-03)
3. `"Salud de Pipeline"` (a-mkt-02)
4. `"Post-Campaña"` (a-mkt-04)

Estos nombres deben coincidir con los agentes definidos en `packages/frontend/src/data/departments.ts`.

---

## 📝 NOTAS IMPORTANTES

1. **Idempotencia**: El backend verifica si un lead ya existe por email antes de crear
2. **Validación**: Todos los agentes son validados antes de procesar webhooks
3. **Transacciones**: Todas las operaciones son atómicas (rollback si falla)
4. **Caché**: Las métricas se invalidan automáticamente cuando hay cambios
5. **Rate Limiting**: Webhooks tienen rate limiting (100 req/min por defecto)

---

## 🚀 PRÓXIMOS PASOS

1. **Configurar N8N** con los 4 workflows
2. **Probar cada agente** individualmente
3. **Validar flujo completo** end-to-end
4. **Monitorear dashboard** para ver datos reales

