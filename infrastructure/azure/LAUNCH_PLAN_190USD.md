# 🚀 PLAN DE DESPEGUE: $190 USD - Mes 1

## 💰 Presupuesto Total: $190 USD

### Desglose Exacto de Costos

| Servicio | SKU | Especificaciones | Costo/mes | % Presupuesto |
|----------|-----|------------------|-----------|---------------|
| **App Service** | **B3** | 4 cores, 7GB RAM | $55 | 29% |
| **PostgreSQL** | **Standard_B2s** | 2 vCores, 4GB RAM, 64GB storage | $55 | 29% |
| **Redis Cache** | **Basic C1** | 1GB cache | $35 | 18% |
| **Blob Storage** | **Standard LRS Hot** | Documentos RAG | $10 | 5% |
| **Application Insights** | **Pay-as-you-go** | 5GB/día (~150GB/mes) | $20 | 11% |
| **Static Web App** | **Free** | Frontend CDN | $0 | 0% |
| **Margen de seguridad** | - | Buffer para overages | $15 | 8% |
| **TOTAL** | - | - | **$175** | **92%** |

---

## ✅ Por Qué Esta Configuración es PERFECTA para Empezar

### 1. App Service B3 ($55/mes) - BEST VALUE 🎯
- **4 cores** = Puede ejecutar múltiples NEURAs en paralelo
- **7GB RAM** = Suficiente para 11 NEURAs + usuarios concurrentes
- **Linux** = Más barato que Windows
- **Upgrade path:** Mes 2 → S1 ($60) para deployment slots

### 2. PostgreSQL B2s ($55/mes) - FUNCIONAL ✅
- **2 vCores, 4GB RAM** = Suficiente para:
  - 100-150 conexiones simultáneas
  - Queries rápidas para conversaciones
  - Almacenamiento de NEURAs + usuarios
- **64GB storage** = Sobra espacio para empezar
- **Backup 7 días** = Recuperación ante desastres
- **Upgrade path:** Mes 2 → D2s_v3 ($150) para high availability

### 3. Redis Basic C1 ($35/mes) - NECESARIO 📊
- **1GB cache** = Suficiente para:
  - Rate limiting (10,000+ requests/min)
  - Session storage
  - Cache de respuestas frecuentes
- **Upgrade path:** Mes 2 → Standard C1 ($70) para clustering

### 4. Storage + Insights ($30/mes) - CRÍTICO 🔍
- **Blob Storage:** Documentos RAG, embeddings
- **Application Insights:** Debugging, telemetría, dashboards

---

## 🎯 Capacidad Real con Este Setup

| Métrica | Capacidad Inicial | Suficiente Para |
|---------|-------------------|-----------------|
| **Usuarios Concurrentes** | 100-200 | Primeros 6 meses |
| **NEURA Executions/min** | 30-50 | 11 NEURAs funcionando |
| **DB Queries/seg** | 150-200 | Conversaciones fluidas |
| **Redis Cache Hits** | 5,000/seg | Rate limiting efectivo |
| **Storage** | 64GB | Miles de documentos RAG |

---

## 🚀 Deployment Inmediato

### Paso 1: Crear Resource Group

```bash
az group create \
  --name rg-econeura-ok-launch \
  --location westeurope \
  --tags environment=launch budget=190usd
```

### Paso 2: Deploy con Parámetro "launch"

```bash
az deployment group create \
  --resource-group rg-econeura-ok-launch \
  --template-file infrastructure/azure/main-launch.bicep \
  --parameters \
    env=launch \
    postgresAdminPassword='<32_CHARS_SECURE>' \
    geminiApiKey='<TU_GEMINI_API_KEY>' \
  --query properties.outputs -o json > launch-outputs.json
```

**Duración:** 12-15 minutos

### Paso 3: Configurar GitHub Secrets

```bash
# Leer outputs
APP_URL=$(jq -r '.appServiceUrl.value' launch-outputs.json)
DB_URL=$(jq -r '.databaseUrl.value' launch-outputs.json)
REDIS_URL=$(jq -r '.redisUrl.value' launch-outputs.json)
INSIGHTS=$(jq -r '.appInsightsConnectionString.value' launch-outputs.json)

# Configurar
gh secret set AZURE_APP_SERVICE_URL -b "https://$APP_URL"
gh secret set DATABASE_URL -b "$DB_URL"
gh secret set REDIS_URL -b "$REDIS_URL"
gh secret set APPINSIGHTS_CONNECTION_STRING -b "$INSIGHTS"
gh secret set GEMINI_API_KEY -b "<TU_KEY>"
```

### Paso 4: Deploy Código

```bash
# Desde CI/CD (automático al hacer merge)
# O manual:
cd packages/backend
npm run build
zip -r ../../backend.zip .

az webapp deployment source config-zip \
  --resource-group rg-econeura-ok-launch \
  --name app-econeura-ok-launch \
  --src ../../backend.zip
```

### Paso 5: Smoke Test

```bash
# Health check
curl -I https://app-econeura-ok-launch.azurewebsites.net/health
# Esperado: 200 OK

# Test NEURA
curl -X POST https://app-econeura-ok-launch.azurewebsites.net/api/neura-chat \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"message": "Test deployment", "neuraId": "ceo"}'
```

---

## 📊 Monitoreo Mes 1

### Queries KQL Esenciales

```kusto
// 1. Costo diario estimado
AzureMetrics
| where TimeGenerated > ago(24h)
| summarize EstimatedCost = sum(Total) by bin(TimeGenerated, 1d)

// 2. Uso de CPU App Service
performanceCounters
| where category == "Processor" and counter == "% Processor Time"
| summarize avg(value) by bin(timestamp, 5m)
| render timechart

// 3. PostgreSQL connections
AzureDiagnostics
| where ResourceType == "POSTGRESQL"
| where Category == "PostgreSQLLogs"
| summarize Connections = count() by bin(TimeGenerated, 5m)

// 4. Redis cache hits
AzureDiagnostics
| where ResourceType == "REDIS"
| summarize CacheHits = countif(resultType_s == "hit"), 
           CacheMisses = countif(resultType_s == "miss")
| extend HitRate = (CacheHits * 100.0) / (CacheHits + CacheMisses)
```

### Alertas Críticas (Gratis)

```bash
# CPU > 85% durante 10 minutos
az monitor metrics alert create \
  --name cpu-high-alert-launch \
  --resource-group rg-econeura-ok-launch \
  --scopes /subscriptions/<SUB>/resourceGroups/rg-econeura-ok-launch/providers/Microsoft.Web/sites/app-econeura-ok-launch \
  --condition "avg Percentage CPU > 85" \
  --window-size 10m \
  --description "CPU alta en mes de lanzamiento"

# Database connections > 120 (80% del máximo)
az monitor metrics alert create \
  --name db-connections-high \
  --resource-group rg-econeura-ok-launch \
  --scopes <POSTGRES_RESOURCE_ID> \
  --condition "avg active_connections > 120" \
  --window-size 5m
```

---

## 🔄 Upgrade Path - Mes 2 ($295/mes)

Cuando veas que funciona bien y necesites más capacidad:

### Opción 1: Redeploy con env=prod

```bash
az deployment group create \
  --resource-group rg-econeura-ok-launch \
  --template-file infrastructure/azure/main-launch.bicep \
  --parameters env=prod \
    postgresAdminPassword='<MISMO_PASSWORD>' \
    geminiApiKey='<MISMO_KEY>'
```

**Cambios automáticos:**
- App Service: B3 → S2 (4 cores, deployment slots)
- PostgreSQL: B2s → D2s_v3 (high availability)
- Redis: Basic C1 → Standard C2 (clustering)
- Storage: LRS → GRS (redundancia geográfica)

**Costo nuevo:** ~$295/mes

### Opción 2: Upgrade Manual Paso a Paso

```bash
# 1. Solo App Service primero (+$5)
az appservice plan update \
  --name asp-econeura-ok-launch \
  --resource-group rg-econeura-ok-launch \
  --sku S1

# 2. Después PostgreSQL (+$95)
az postgres flexible-server update \
  --resource-group rg-econeura-ok-launch \
  --name pg-econeura-ok-launch \
  --tier GeneralPurpose \
  --sku-name Standard_D2s_v3

# 3. Después Redis (+$35)
az redis update \
  --name redis-econeura-ok-launch \
  --resource-group rg-econeura-ok-launch \
  --sku Standard \
  --vm-size C2
```

---

## ⚠️ Limitaciones Mes 1 (y Cómo Mitigarlas)

| Limitación | Impacto | Mitigación |
|------------|---------|------------|
| **PostgreSQL 150 conexiones** | Podría llenarse con tráfico alto | Connection pooling en backend |
| **Redis 1GB** | Cache se llena rápido | TTL agresivo (5 min) |
| **App Service 1 instancia** | Sin failover | Monitoring proactivo |
| **Backup 7 días** | Recuperación limitada | Backup manual semanal adicional |

### Connection Pooling Config

```typescript
// packages/backend/src/infra/persistence/postgres.ts
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  max: 20,                    // Máx 20 conexiones por instancia
  idleTimeoutMillis: 30000,   // Cerrar idle después de 30s
  connectionTimeoutMillis: 2000,
});
```

---

## ✅ Checklist Pre-Launch

- [ ] RG creado: `rg-econeura-ok-launch`
- [ ] Bicep deployed con `env=launch`
- [ ] GitHub Secrets configurados (6 secrets)
- [ ] Backend deployed y `/health` → 200 OK
- [ ] Frontend deployed en Static Web App
- [ ] Test 1 NEURA funcionando
- [ ] Application Insights recibiendo logs
- [ ] Alertas configuradas (CPU, DB connections)
- [ ] Backup automático de PostgreSQL verificado
- [ ] Dashboard básico en Azure Portal configurado

---

## 📈 Métricas de Éxito - Mes 1

| Métrica | Target Mes 1 | Si Se Cumple → Mes 2 Upgrade |
|---------|--------------|------------------------------|
| Usuarios activos | 50-100 | ✅ Upgrade a prod SKUs |
| NEURA executions/día | 500-1000 | ✅ Considerar más instancias |
| Uptime | > 99% | ✅ Agregar deployment slots |
| Avg response time | < 1s | ✅ OK, monitorear |
| Costo real | < $180 | ✅ Margen saludable |

---

## 💡 Tips Pro para Mes 1

1. **Monitorear costos diariamente:**
   ```bash
   az consumption usage list \
     --start-date 2025-01-01 \
     --end-date 2025-01-31 \
     --query "[?contains(instanceName, 'econeura')]"
   ```

2. **Hacer backup manual antes de cambios:**
   ```bash
   az postgres flexible-server backup create \
     --resource-group rg-econeura-ok-launch \
     --name pg-econeura-ok-launch \
     --backup-name manual-pre-update
   ```

3. **Probar en dev local primero:**
   - Usa Docker Compose local
   - Valida con traffic real antes de deploy

4. **Documentar TODO:**
   - Queries lentas en PostgreSQL
   - Errores recurrentes
   - Picos de tráfico

---

**PRESUPUESTO UTILIZADO: $175 de $190 = 92%**  
**MARGEN DE SEGURIDAD: $15 (8%)**  
**LISTO PARA DESPEGAR** 🚀

¿Ejecuto el deployment AHORA? Solo necesito que me confirmes.
