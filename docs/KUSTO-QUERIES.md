# 📊 KUSTO QUERIES - Application Insights

**Documentación de queries útiles para Application Insights (Kusto Query Language)**

---

## 🔍 QUERIES BÁSICAS

### 1. Buscar errores de un tenant específico

```kusto
traces
| where customDimensions.tenantId == "abc123"
| where severityLevel >= 3
| order by timestamp desc
| project timestamp, message, customDimensions
```

### 2. Buscar flujo completo de una request (correlation ID)

```kusto
traces
| where customDimensions.correlationId == "xyz789"
| order by timestamp asc
| project timestamp, message, customDimensions, severityLevel
```

### 3. Top 10 errores más frecuentes

```kusto
traces
| where severityLevel >= 3
| summarize count() by message
| top 10 by count_
| order by count_ desc
```

### 4. Request duration por endpoint (P50, P95, P99)

```kusto
requests
| summarize 
    p50 = percentile(duration, 50),
    p95 = percentile(duration, 95),
    p99 = percentile(duration, 99),
    avg = avg(duration),
    count = count()
    by name
| order by p95 desc
```

### 5. Error rate por endpoint

```kusto
requests
| summarize 
    total = count(),
    errors = countif(success == false)
    by name
| extend errorRate = (errors * 100.0) / total
| order by errorRate desc
| project name, total, errors, errorRate
```

---

## 📈 MÉTRICAS DE NEGOCIO

### 6. Conversaciones iniciadas por NEURA

```kusto
customEvents
| where name == "ConversationStarted"
| summarize count() by tostring(customDimensions.neuraId)
| order by count_ desc
```

### 7. Mensajes enviados por hora

```kusto
customEvents
| where name == "MessageSent"
| summarize count() by bin(timestamp, 1h)
| order by timestamp asc
| render timechart
```

### 8. Agentes Automation ejecutados

```kusto
customEvents
| where name == "AutomationAgentExecuted"
| summarize 
    count = count(),
    success = countif(tostring(customDimensions.success) == "true")
    by tostring(customDimensions.agentId)
| extend successRate = (success * 100.0) / count
| order by count desc
```

---

## 🔧 DEPENDENCIAS Y LLAMADAS EXTERNAS

### 9. Llamadas a OpenAI (duración y errores)

```kusto
dependencies
| where name contains "OpenAI" or name contains "openai"
| summarize 
    count = count(),
    avgDuration = avg(duration),
    errors = countif(success == false)
    by name
| order by avgDuration desc
```

### 10. Llamadas a Cosmos DB / PostgreSQL

```kusto
dependencies
| where type == "SQL" or type == "Azure DocumentDB"
| summarize 
    count = count(),
    avgDuration = avg(duration),
    errors = countif(success == false)
    by name, type
| order by avgDuration desc
```

---

## 🚨 ALERTAS Y MONITOREO

### 11. Requests con duración > 2 segundos

```kusto
requests
| where duration > 2000
| project timestamp, name, duration, url, customDimensions.correlationId
| order by duration desc
```

### 12. Error rate > 5% en últimos 15 minutos

```kusto
requests
| where timestamp > ago(15m)
| summarize 
    total = count(),
    errors = countif(success == false)
    by name
| extend errorRate = (errors * 100.0) / total
| where errorRate > 5
| order by errorRate desc
```

### 13. Failed dependencies > 10/min

```kusto
dependencies
| where timestamp > ago(1h)
| where success == false
| summarize count() by bin(timestamp, 1m), name
| where count_ > 10
| order by timestamp desc
```

---

## 👥 MULTI-TENANCY

### 14. Actividad por tenant (últimas 24h)

```kusto
traces
| where timestamp > ago(24h)
| summarize 
    requests = count(),
    errors = countif(severityLevel >= 3)
    by tostring(customDimensions.tenantId)
| order by requests desc
```

### 15. Usuarios más activos por tenant

```kusto
traces
| where timestamp > ago(24h)
| where isnotempty(customDimensions.userId)
| summarize count() by 
    tostring(customDimensions.tenantId),
    tostring(customDimensions.userId)
| order by count_ desc
```

---

## 📊 DASHBOARD QUERIES

### 16. Resumen general (última hora)

```kusto
let requests = requests | where timestamp > ago(1h);
let errors = traces | where timestamp > ago(1h) and severityLevel >= 3;
let dependencies = dependencies | where timestamp > ago(1h);

print 
    totalRequests = toscalar(requests | summarize count()),
    errorCount = toscalar(errors | summarize count()),
    avgResponseTime = toscalar(requests | summarize avg(duration)),
    failedDependencies = toscalar(dependencies | where success == false | summarize count())
```

### 17. Health score (0-100)

```kusto
let requests = requests | where timestamp > ago(1h);
let errors = traces | where timestamp > ago(1h) and severityLevel >= 3;
let dependencies = dependencies | where timestamp > ago(1h);

let totalRequests = toscalar(requests | summarize count());
let errorCount = toscalar(errors | summarize count());
let failedDeps = toscalar(dependencies | where success == false | summarize count());

print 
    healthScore = 100 - 
        (min_of((errorCount * 100.0) / max_of(totalRequests, 1), 50)) - 
        (min_of((failedDeps * 10.0), 50))
```

---

## 🔐 SEGURIDAD

### 18. Intentos de autenticación fallidos

```kusto
traces
| where message contains "Auth" and severityLevel >= 2
| where timestamp > ago(24h)
| summarize count() by bin(timestamp, 1h), tostring(customDimensions.ip)
| order by count_ desc
```

### 19. Rate limit exceeded

```kusto
traces
| where message contains "RateLimit" or message contains "rate limit"
| where timestamp > ago(24h)
| summarize count() by tostring(customDimensions.ip)
| order by count_ desc
```

---

## 💡 TIPS

1. **Usar `bin()` para agrupar por tiempo**: `bin(timestamp, 1h)` agrupa por hora
2. **Usar `render timechart`** para visualizar series temporales
3. **Usar `top 10 by count_`** para obtener los más frecuentes
4. **Usar `customDimensions`** para acceder a propiedades personalizadas
5. **Usar `ago(1h)`** para filtrar por tiempo relativo

---

**Última actualización:** 2025-11-16

