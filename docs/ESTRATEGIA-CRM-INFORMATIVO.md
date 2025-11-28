# 🎯 ESTRATEGIA: CRM INFORMATIVO - AGENTES AUTOMATIZADOS GESTIONAN

## 📋 PRINCIPIO FUNDAMENTAL

**Los agentes automatizados gestionan todo. El CRM solo informa.**

```
AGENTES N8N (GESTIÓN) → Backend CRM → PostgreSQL → Dashboard CRM (INFORMACIÓN)
```

---

## 🏗️ ARQUITECTURA

### 1. AGENTES AUTOMATIZADOS (N8N/Make) - GESTIÓN ACTIVA

Los agentes son los que **hacen el trabajo**:

#### A. Agente: "Lead Capture"
- **Función**: Captura leads desde múltiples fuentes
- **Acciones**:
  - Escanea formularios web
  - Monitorea LinkedIn
  - Recolecta de eventos
- **Webhook**: `POST /api/crm/webhooks/lead-created`
- **Payload**:
  ```json
  {
    "email": "lead@empresa.com",
    "nombre": "Juan Pérez",
    "empresa": "TechCorp",
    "department": "cmo",
    "agent_name": "Lead Capture",
    "source": "formulario_web"
  }
  ```

#### B. Agente: "Lead Scoring"
- **Función**: Califica automáticamente los leads
- **Acciones**:
  - Analiza engagement (emails abiertos, clicks)
  - Evalúa empresa (tamaño, industria)
  - Calcula score (0-100)
- **Webhook**: `PUT /api/crm/webhooks/lead-updated`
- **Payload**:
  ```json
  {
    "lead_id": "123",
    "score": 85,
    "status": "Qualified",
    "agent_name": "Lead Scoring"
  }
  ```

#### C. Agente: "Email Nurturing"
- **Función**: Envía secuencias de emails automáticas
- **Acciones**:
  - Detecta leads que necesitan nurturing
  - Envía emails personalizados
  - Actualiza estado del lead
- **Webhook**: `POST /api/crm/webhooks/nurture-sent`
- **Payload**:
  ```json
  {
    "lead_id": "123",
    "email_sent": true,
    "sequence_step": 3,
    "agent_name": "Email Nurturing"
  }
  ```

#### D. Agente: "Deal Creation"
- **Función**: Crea deals automáticamente cuando detecta oportunidad
- **Acciones**:
  - Detecta leads con score > 85
  - Crea deal en CRM
  - Asigna a agente de ventas
- **Webhook**: `POST /api/crm/webhooks/deal-created`
- **Payload**:
  ```json
  {
    "lead_id": "123",
    "deal_value": 50000,
    "stage": "Qualified",
    "agent_name": "Deal Creation"
  }
  ```

#### E. Agente: "Pipeline Health"
- **Función**: Monitorea salud del pipeline
- **Acciones**:
  - Detecta deals en riesgo (sin actividad > 14 días)
  - Identifica deals estancados
  - Genera alertas
- **Webhook**: `POST /api/crm/webhooks/alert`
- **Payload**:
  ```json
  {
    "type": "warning",
    "message": "Deal NovaHR lleva 18 días sin actividad",
    "deal_id": "456",
    "agent_name": "Pipeline Health"
  }
  ```

#### F. Agente: "Revenue Tracking"
- **Función**: Calcula revenue generado por cada agente
- **Acciones**:
  - Agrega revenue de deals cerrados
  - Asocia revenue a agentes
  - Actualiza métricas diarias
- **Webhook**: `POST /api/crm/webhooks/revenue-updated`
- **Payload**:
  ```json
  {
    "agent_name": "Deal Creation",
    "revenue": 50000,
    "deals_count": 1,
    "period": "month"
  }
  ```

---

## 📊 CRM DASHBOARD - SOLO INFORMACIÓN

El CRM **NO gestiona**, solo **muestra**:

### Componentes del Dashboard:

1. **KPIs (Solo lectura)**
   - MRR: Revenue mensual
   - Nuevos Leads: Total capturados
   - Deals Activos: Oportunidades abiertas
   - Tiempo Respuesta: Promedio de agentes

2. **Pipeline (Visualización)**
   - Leads → Qualified → Proposal → Closed Won
   - Conversión por etapa
   - Revenue por etapa

3. **Tabla de Leads (Solo lectura)**
   - Lista de leads capturados por agentes
   - Score calculado por agentes
   - Status actualizado por agentes
   - Última actividad registrada por agentes

4. **Impacto de Agentes (Información)**
   - Revenue generado por cada agente
   - Deals creados por agente
   - Alertas generadas por agente

5. **Alertas (Notificaciones)**
   - Alertas generadas por agentes
   - Deals en riesgo detectados
   - Oportunidades destacadas

---

## 🔄 FLUJO COMPLETO

### Ejemplo: Nuevo Lead

1. **Agente "Lead Capture"** detecta formulario web
2. **Agente** hace `POST /api/crm/webhooks/lead-created`
3. **Backend** guarda en PostgreSQL (`crm_leads`)
4. **Agente "Lead Scoring"** analiza el lead
5. **Agente** hace `PUT /api/crm/webhooks/lead-updated` con score
6. **Backend** actualiza `score` y `status` en PostgreSQL
7. **Dashboard CRM** muestra el nuevo lead con score (solo lectura)

### Ejemplo: Deal en Riesgo

1. **Agente "Pipeline Health"** detecta deal sin actividad > 14 días
2. **Agente** hace `POST /api/crm/webhooks/alert`
3. **Backend** guarda alerta en PostgreSQL
4. **Dashboard CRM** muestra alerta en sección "Alertas" (solo lectura)

---

## 🎯 RESPONSABILIDADES

### AGENTES AUTOMATIZADOS (N8N/Make):
- ✅ Capturar leads
- ✅ Calificar leads
- ✅ Enviar emails
- ✅ Crear deals
- ✅ Detectar riesgos
- ✅ Calcular revenue
- ✅ Generar alertas
- ✅ Actualizar estados

### CRM DASHBOARD:
- ✅ Mostrar KPIs
- ✅ Visualizar pipeline
- ✅ Listar leads
- ✅ Mostrar impacto de agentes
- ✅ Mostrar alertas
- ✅ Filtrar y buscar (solo lectura)
- ❌ NO crear leads
- ❌ NO editar leads
- ❌ NO crear deals
- ❌ NO gestionar pipeline

---

## 📡 WEBHOOKS DEL BACKEND

### Endpoints que los agentes usan:

1. `POST /api/crm/webhooks/lead-created`
   - Crea nuevo lead
   - Usado por: Lead Capture Agent

2. `PUT /api/crm/webhooks/lead-updated`
   - Actualiza lead existente
   - Usado por: Lead Scoring, Email Nurturing

3. `POST /api/crm/webhooks/deal-created`
   - Crea nuevo deal
   - Usado por: Deal Creation Agent

4. `POST /api/crm/webhooks/alert`
   - Crea alerta
   - Usado por: Pipeline Health Agent

5. `POST /api/crm/webhooks/revenue-updated`
   - Actualiza revenue por agente
   - Usado por: Revenue Tracking Agent

### Endpoints que el dashboard usa (solo lectura):

1. `GET /api/crm/leads?department=cmo`
   - Lista leads (solo lectura)

2. `GET /api/crm/sales-metrics?department=cmo&period=month`
   - Métricas de ventas (solo lectura)

---

## ✅ IMPLEMENTACIÓN ACTUAL

### Backend (✅ Implementado):
- ✅ Webhooks con HMAC security
- ✅ Endpoints de lectura (leads, metrics)
- ✅ PostgreSQL con tablas: `crm_leads`, `crm_deals`, `crm_conversations`
- ✅ Rate limiting y validación

### Frontend (✅ Implementado):
- ✅ `CRMPremiumPanel` - Dashboard informativo
- ✅ KPIs, Pipeline, Leads, Alertas (solo lectura)
- ✅ Integración con API (hooks `useCRMData`, `useCRMLeads`)
- ✅ Fallback a datos mock si API no disponible

### Pendiente:
- ⏳ Configurar agentes N8N con webhooks
- ⏳ Probar flujo completo: Agente → Backend → Dashboard

---

## 🚀 PRÓXIMOS PASOS

1. **Configurar Agentes N8N**:
   - Crear workflows en N8N
   - Configurar webhooks apuntando a `/api/crm/webhooks/*`
   - Probar cada agente individualmente

2. **Validar Flujo**:
   - Agente crea lead → Backend guarda → Dashboard muestra
   - Agente actualiza score → Backend actualiza → Dashboard refleja
   - Agente genera alerta → Backend guarda → Dashboard muestra

3. **Monitoreo**:
   - Verificar que agentes están funcionando
   - Revisar logs del backend
   - Confirmar que dashboard muestra datos reales

---

## 📝 RESUMEN

**AGENTES = GESTIÓN ACTIVA**
- Hacen el trabajo
- Actualizan datos
- Generan alertas
- Calculan métricas

**CRM = INFORMACIÓN PASIVA**
- Muestra datos
- Visualiza métricas
- Lista leads
- Presenta alertas

**NO HAY GESTIÓN MANUAL EN EL CRM**

