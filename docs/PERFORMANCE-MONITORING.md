# 📊 PERFORMANCE MONITORING - Application Insights

**Configuración de alertas y dashboards para ECONEURA**

---

## 🚨 ALERTAS CONFIGURADAS

### 1. Error Rate > 5%

**Condición:**
- Error rate > 5% en últimos 15 minutos
- Se dispara si más del 5% de requests fallan

**Query Kusto:**
```kusto
requests
| where timestamp > ago(15m)
| summarize 
    total = count(),
    errors = countif(success == false)
    by name
| extend errorRate = (errors * 100.0) / total
| where errorRate > 5
```

**Acción:** Notificar al equipo de desarrollo

---

### 2. P95 Latency > 2000ms

**Condición:**
- Percentil 95 de duración > 2000ms en últimos 15 minutos

**Query Kusto:**
```kusto
requests
| where timestamp > ago(15m)
| summarize p95 = percentile(duration, 95) by name
| where p95 > 2000
```

**Acción:** Investigar endpoints lentos

---

### 3. Failed Dependencies > 10/min

**Condición:**
- Más de 10 dependencias fallidas por minuto

**Query Kusto:**
```kusto
dependencies
| where timestamp > ago(1h)
| where success == false
| summarize count() by bin(timestamp, 1m), name
| where count_ > 10
```

**Acción:** Verificar servicios externos (OpenAI, Cosmos DB, PostgreSQL)

---

### 4. Exception Rate > 1%

**Condición:**
- Más del 1% de requests resultan en excepciones

**Query Kusto:**
```kusto
exceptions
| where timestamp > ago(15m)
| summarize exceptionCount = count() by bin(timestamp, 1m)
| join kind=inner (
    requests
    | where timestamp > ago(15m)
    | summarize requestCount = count() by bin(timestamp, 1m)
) on timestamp
| extend exceptionRate = (exceptionCount * 100.0) / requestCount
| where exceptionRate > 1
```

**Acción:** Revisar logs de excepciones

---

## 📊 DASHBOARDS

### Dashboard Principal: ECONEURA Health

**Componentes:**

1. **Request Rate (última hora)**
   ```kusto
   requests
   | where timestamp > ago(1h)
   | summarize count() by bin(timestamp, 5m)
   | render timechart
   ```

2. **Error Rate (última hora)**
   ```kusto
   requests
   | where timestamp > ago(1h)
   | summarize 
       total = count(),
       errors = countif(success == false)
       by bin(timestamp, 5m)
   | extend errorRate = (errors * 100.0) / total
   | render timechart
   ```

3. **Response Time (P50, P95, P99)**
   ```kusto
   requests
   | where timestamp > ago(1h)
   | summarize 
       p50 = percentile(duration, 50),
       p95 = percentile(duration, 95),
       p99 = percentile(duration, 99)
       by bin(timestamp, 5m)
   | render timechart
   ```

4. **Top 10 Endpoints por Request Count**
   ```kusto
   requests
   | where timestamp > ago(1h)
   | summarize count() by name
   | top 10 by count_
   | order by count_ desc
   ```

5. **Dependencies Status**
   ```kusto
   dependencies
   | where timestamp > ago(1h)
   | summarize 
       total = count(),
       failed = countif(success == false)
       by name, type
   | extend successRate = ((total - failed) * 100.0) / total
   | order by total desc
   ```

---

### Dashboard de Negocio: ECONEURA Metrics

**Componentes:**

1. **Conversaciones Iniciadas (últimas 24h)**
   ```kusto
   customEvents
   | where name == "ConversationStarted"
   | where timestamp > ago(24h)
   | summarize count() by bin(timestamp, 1h)
   | render timechart
   ```

2. **Mensajes Enviados (últimas 24h)**
   ```kusto
   customEvents
   | where name == "MessageSent"
   | where timestamp > ago(24h)
   | summarize count() by bin(timestamp, 1h)
   | render timechart
   ```

3. **NEURAs Más Usadas**
   ```kusto
   customEvents
   | where name == "ConversationStarted"
   | where timestamp > ago(24h)
   | summarize count() by tostring(customDimensions.neuraId)
   | top 10 by count_
   | order by count_ desc
   ```

4. **Agentes Automation Ejecutados**
   ```kusto
   customEvents
   | where name == "AutomationAgentExecuted"
   | where timestamp > ago(24h)
   | summarize 
       total = count(),
       success = countif(tostring(customDimensions.success) == "true")
       by tostring(customDimensions.agentId)
   | extend successRate = (success * 100.0) / total
   | order by total desc
   ```

---

## 🔧 CONFIGURACIÓN EN AZURE PORTAL

### Crear Alertas

1. Ir a **Application Insights** → **Alerts** → **New alert rule**
2. Seleccionar **Custom log search**
3. Pegar query Kusto correspondiente
4. Configurar:
   - **Threshold:** Valor de disparo
   - **Period:** Ventana de tiempo (15 minutos)
   - **Frequency:** Frecuencia de evaluación (5 minutos)
5. Configurar **Action Group** (email, webhook, etc.)

### Crear Dashboards

1. Ir a **Application Insights** → **Dashboards** → **New dashboard**
2. Añadir **Query** tiles
3. Pegar queries Kusto
4. Configurar visualización (timechart, table, etc.)
5. Guardar dashboard

---

## 📈 MÉTRICAS PERSONALIZADAS

### Métricas que se trackean automáticamente:

1. **http_request_duration_ms** - Duración de requests HTTP
2. **http_request_status** - Status code de requests
3. **neura_count** - Número de NEURAs creadas
4. **conversation_count** - Número de conversaciones iniciadas
5. **message_count** - Número de mensajes enviados
6. **automation_agent_executed** - Agentes automation ejecutados

### Cómo trackear métricas personalizadas:

```typescript
import { trackMetric } from '../infra/observability/applicationInsights';

// Ejemplo: trackear tiempo de procesamiento
const startTime = Date.now();
// ... procesamiento ...
const duration = Date.now() - startTime;
trackMetric('document_processing_duration_ms', duration, {
  documentType: 'pdf',
  tenantId: 'abc123'
});
```

---

## 🎯 OBJETIVOS DE RENDIMIENTO (SLA)

- **P50 Response Time:** < 200ms
- **P95 Response Time:** < 1000ms
- **P99 Response Time:** < 2000ms
- **Error Rate:** < 1%
- **Availability:** > 99.9%

---

**Última actualización:** 2025-11-16

