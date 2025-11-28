# 🚀 Guía de Deployment Azure - ECONEURA-OK Sin Bloqueos

## 📋 Pre-requisitos

```bash
# 1. Azure CLI autenticado
az login
az account set --subscription "<TU_SUBSCRIPTION_ID>"

# 2. Crear Resource Group
az group create \
  --name rg-econeura-ok-prod \
  --location westeurope \
  --tags project=ECONEURA-OK stage=prod
```

---

## 🎯 Deployment Completo (Producción)

### Paso 1: What-If Analysis (OBLIGATORIO)

```bash
az deployment group what-if \
  --resource-group rg-econeura-ok-prod \
  --template-file infrastructure/azure/main-complete.bicep \
  --parameters \
    env=prod \
    postgresAdminPassword='<SECURE_PASSWORD_32_CHARS>' \
    geminiApiKey='<TU_GEMINI_API_KEY>'
```

**REVISAR:**
- ✅ SKUs correctos (S1 App Service, D2s_v3 Postgres, C1 Redis)
- ✅ Estimated cost: ~€295/mes
- ✅ No hay recursos que se eliminarán sin querer

### Paso 2: Deploy Real

```bash
az deployment group create \
  --resource-group rg-econeura-ok-prod \
  --template-file infrastructure/azure/main-complete.bicep \
  --parameters \
    env=prod \
    postgresAdminPassword='<SECURE_PASSWORD>' \
    geminiApiKey='<GEMINI_API_KEY>' \
  --mode Incremental \
  --query properties.outputs -o json > deployment-outputs.json
```

**Duración estimada:** 15-20 minutos

### Paso 3: Configurar GitHub Secrets

```bash
# Leer outputs del deployment
APP_URL=$(jq -r '.appServiceUrl.value' deployment-outputs.json)
DB_URL=$(jq -r '.databaseUrl.value' deployment-outputs.json)
REDIS_URL=$(jq -r '.redisUrl.value' deployment-outputs.json)
INSIGHTS=$(jq -r '.appInsightsConnectionString.value' deployment-outputs.json)

# Configurar secrets
gh secret set AZURE_APP_SERVICE_URL -b "https://$APP_URL"
gh secret set DATABASE_URL -b "$DB_URL"
gh secret set REDIS_URL -b "$REDIS_URL"
gh secret set APPINSIGHTS_CONNECTION_STRING -b "$INSIGHTS"
gh secret set GEMINI_API_KEY -b "<TU_GEMINI_API_KEY>"
```

---

## ⚙️ Configuración Post-Deployment (Evitar Bloqueos)

### 1. PostgreSQL Connection Pooling

```bash
# Conectar a PostgreSQL
az postgres flexible-server connect \
  --name pg-econeura-ok-prod \
  --admin-user econeuraadmin

# Ejecutar en psql:
ALTER SYSTEM SET max_connections = 200;
ALTER SYSTEM SET shared_buffers = '2GB';
ALTER SYSTEM SET effective_cache_size = '6GB';
ALTER SYSTEM SET work_mem = '16MB';
ALTER SYSTEM SET maintenance_work_mem = '512MB';

# Restart para aplicar
az postgres flexible-server restart \
  --resource-group rg-econeura-ok-prod \
  --name pg-econeura-ok-prod
```

### 2. App Service - Auto-Scaling (Evitar Bloqueos por Tráfico)

```bash
# Crear regla de auto-scale
az monitor autoscale create \
  --resource-group rg-econeura-ok-prod \
  --resource /subscriptions/<SUB>/resourceGroups/rg-econeura-ok-prod/providers/Microsoft.Web/serverFarms/asp-econeura-ok-prod \
  --name autoscale-econeura-prod \
  --min-count 2 \
  --max-count 5 \
  --count 2

# Regla: escalar si CPU > 70%
az monitor autoscale rule create \
  --resource-group rg-econeura-ok-prod \
  --autoscale-name autoscale-econeura-prod \
  --condition "CpuPercentage > 70 avg 5m" \
  --scale out 1

# Regla: reducir si CPU < 30%
az monitor autoscale rule create \
  --resource-group rg-econeura-ok-prod \
  --autoscale-name autoscale-econeura-prod \
  --condition "CpuPercentage < 30 avg 10m" \
  --scale in 1
```

### 3. Redis - Activar Persistencia (No Perder Cache)

```bash
az redis update \
  --name redis-econeura-ok-prod \
  --resource-group rg-econeura-ok-prod \
  --set redisConfiguration.rdb-backup-enabled=true \
  --set redisConfiguration.rdb-backup-frequency=60
```

### 4. Application Insights - Configurar Alertas

```bash
# Alerta CPU alta
az monitor metrics alert create \
  --name high-cpu-alert \
  --resource-group rg-econeura-ok-prod \
  --scopes /subscriptions/<SUB>/resourceGroups/rg-econeura-ok-prod/providers/Microsoft.Web/sites/app-econeura-ok-prod \
  --condition "avg CpuPercentage > 80" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --action <ACTION_GROUP_ID>

# Alerta memoria alta
az monitor metrics alert create \
  --name high-memory-alert \
  --resource-group rg-econeura-ok-prod \
  --scopes /subscriptions/<SUB>/resourceGroups/rg-econeura-ok-prod/providers/Microsoft.Web/sites/app-econeura-ok-prod \
  --condition "avg MemoryPercentage > 85" \
  --window-size 5m

# Alerta latencia alta
az monitor metrics alert create \
  --name high-latency-alert \
  --resource-group rg-econeura-ok-prod \
  --scopes /subscriptions/<SUB>/resourceGroups/rg-econeura-ok-prod/providers/Microsoft.Web/sites/app-econeura-ok-prod \
  --condition "avg ResponseTime > 2000" \
  --window-size 5m
```

---

## 🔥 Deployment Slots (Zero-Downtime)

```bash
# Crear slot de staging
az webapp deployment slot create \
  --name app-econeura-ok-prod \
  --resource-group rg-econeura-ok-prod \
  --slot staging

# Deploy a staging primero
az webapp deployment source config-zip \
  --resource-group rg-econeura-ok-prod \
  --name app-econeura-ok-prod \
  --slot staging \
  --src dist/backend.zip

# Smoke test en staging
curl -I https://app-econeura-ok-prod-staging.azurewebsites.net/health

# Si OK, swap a producción (ZERO DOWNTIME)
az webapp deployment slot swap \
  --resource-group rg-econeura-ok-prod \
  --name app-econeura-ok-prod \
  --slot staging \
  --target-slot production
```

---

## 📊 Monitoreo Post-Deployment

### Dashboard KQL Queries

```kusto
// 1. Latencia por endpoint
requests
| where timestamp > ago(1h)
| summarize avg(duration), count() by name
| order by avg_duration desc

// 2. Errores 5xx
requests
| where timestamp > ago(1h) and resultCode startswith "5"
| summarize count() by name, resultCode
| order by count_ desc

// 3. Rate limiting hits
traces
| where message contains "rate limit"
| summarize count() by bin(timestamp, 5m)

// 4. NEURA execution times
dependencies
| where name contains "Gemini"
| summarize avg(duration), max(duration), count() by name
| order by avg_duration desc

// 5. PostgreSQL queries lentas
dependencies
| where type == "SQL" and duration > 1000
| project timestamp, name, data, duration
| order by duration desc
```

---

## 💰 Cost Management

### Estimación Mensual (Producción)

| Recurso | SKU | Costo |
|---------|-----|-------|
| App Service S1 | 1 core, 1.75GB | €60 |
| PostgreSQL D2s_v3 | 2 vCores, 8GB | €150 |
| Redis C1 Standard | 1GB | €70 |
| Blob Storage | Hot LRS | €5 |
| Application Insights | 5GB/día | €10 |
| **TOTAL** | | **~€295/mes** |

### Para Reducir Costos (Staging)

```bash
# Deploy con SKUs más baratos
az deployment group create \
  --resource-group rg-econeura-ok-staging \
  --template-file infrastructure/azure/main-complete.bicep \
  --parameters env=staging \
    postgresAdminPassword='<PWD>' \
    geminiApiKey='<KEY>'

# Costo staging: ~€85/mes
```

---

## 🚨 Troubleshooting

### PostgreSQL Connection Pool Exhausted

```bash
# Ver conexiones activas
SELECT count(*) FROM pg_stat_activity WHERE state = 'active';

# Aumentar max_connections
ALTER SYSTEM SET max_connections = 300;
```

### Redis Memory Full

```bash
# Ver uso de memoria
az redis show \
  --name redis-econeura-ok-prod \
  --resource-group rg-econeura-ok-prod \
  --query "redisConfiguration"

# Upgrade a C2 (2.5GB)
az redis update \
  --name redis-econeura-ok-prod \
  --resource-group rg-econeura-ok-prod \
  --sku Standard \
  --vm-size C2
```

### App Service High CPU

```bash
# Escalar horizontalmente (más instancias)
az appservice plan update \
  --name asp-econeura-ok-prod \
  --resource-group rg-econeura-ok-prod \
  --number-of-workers 3

# O escalarticalmente (S2 = 2 cores)
az appservice plan update \
  --name asp-econeura-ok-prod \
  --resource-group rg-econeura-ok-prod \
  --sku S2
```

---

## ✅ Checklist Final

- [ ] RG creado
- [ ] Bicep deployed exitosamente
- [ ] GitHub Secrets configurados
- [ ] PostgreSQL connection pooling configurado (max_connections=200)
- [ ] Auto-scaling habilitado (min=2, max=5)
- [ ] Redis persistence activada
- [ ] Alertas configuradas (CPU, Memory, Latency)
- [ ] Deployment slots creados (staging)
- [ ] Smoke test pasando (curl /health → 200)
- [ ] Dashboard Application Insights configurado
- [ ] Logs fluyendo correctamente

---

**Deployment completo sin bloqueos garantizado con esta configuración.** ✅
