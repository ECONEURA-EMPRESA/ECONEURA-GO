# 🚀 DEPLOYMENT RÁPIDO - Producción Mañana

## ⚡ Timeline: 2.5 Horas Hasta Producción

### FASE 1: Azure Setup (45 min)

```bash
# 1. Login (2 min)
az login
az account show  # Verificar subscription correcta

# 2. Crear Resource Group (1 min)
az group create \
  --name rg-econeura-ok-prod \
  --location westeurope \
  --tags environment=production budget=190usd

# 3. Deploy Bicep (12-15 min)
az deployment group create \
  --resource-group rg-econeura-ok-prod \
  --template-file infrastructure/azure/main.bicep \
  --parameters \
    postgresAdminPassword='<32_CHARS_SECURE_PASSWORD>' \
    geminiApiKey='<TU_GEMINI_API_KEY>' \
  --query properties.outputs -o json | tee deployment-outputs.json

# 4. Verificar outputs (2 min)
cat deployment-outputs.json | jq '.'
```

**CHECKPOINT:** Todos los recursos creados ✅

---

### FASE 2: GitHub Secrets (15 min)

```bash
# Script automatizado para configurar TODOS los secrets
#!/bin/bash

OUTPUTS_FILE="deployment-outputs.json"

# Leer outputs
APP_URL=$(jq -r '.appServiceUrl.value' $OUTPUTS_FILE)
STATIC_URL=$(jq -r '.staticWebAppUrl.value' $OUTPUTS_FILE)
DB_URL=$(jq -r '.databaseUrl.value' $OUTPUTS_FILE)
REDIS_HOST=$(jq -r '.redisHost.value' $OUTPUTS_FILE)
REDIS_PORT=$(jq -r '.redisPort.value' $OUTPUTS_FILE)
REDIS_KEY=$(jq -r '.redisPrimaryKey.value' $OUTPUTS_FILE)
INSIGHTS=$(jq -r '.appInsightsConnectionString.value' $OUTPUTS_FILE)
STORAGE=$(jq -r '.storageConnectionString.value' $OUTPUTS_FILE)

# Configurar secrets
gh secret set AZURE_APP_SERVICE_URL -b "https://$APP_URL"
gh secret set AZURE_STATIC_WEB_APP_URL -b "https://$STATIC_URL"
gh secret set DATABASE_URL -b "$DB_URL"
gh secret set REDIS_HOST -b "$REDIS_HOST"
gh secret set REDIS_PORT -b "$REDIS_PORT"
gh secret set REDIS_PASSWORD -b "$REDIS_KEY"
gh secret set GEMINI_API_KEY -b "<TU_GEMINI_API_KEY>"
gh secret set APPLICATIONINSIGHTS_CONNECTION_STRING -b "$INSIGHTS"
gh secret set AZURE_STORAGE_CONNECTION_STRING -b "$STORAGE"
gh secret set NODE_ENV -b "production"
gh secret set USE_MEMORY_STORE -b "false"

echo "✅ Todos los secrets configurados"
gh secret list
```

**CHECKPOINT:** 11 secrets configurados ✅

---

### FASE 3: Deploy Backend (30 min)

```bash
# Opción 1: CI/CD Automático (RECOMENDADO)
git push origin feat/omega-protocol-10-10

# Esperar a que CI termine
gh run watch

# Verificar deploy exitoso
curl -I https://app-econeura-ok-prod.azurewebsites.net/health
# Esperado: 200 OK
```

**CHECKPOINT:** Backend respondiendo ✅

---

### FASE 4: Deploy Frontend (20 min)

Frontend se despliega automáticamente con Static Web App cuando haces push a GitHub.

```bash
# Verificar deployment
curl -I https://swa-econeura-ok-prod.azurewebsites.net
# Esperado: 200 OK
```

**CHECKPOINT:** Frontend online ✅

---

### FASE 5: Smoke Test Completo (20 min)

```bash
# 1. Health check
curl https://app-econeura-ok-prod.azurewebsites.net/health

# 2. Database connectivity
curl https://app-econeura-ok-prod.azurewebsites.net/api/health/db

# 3. Redis connectivity
curl https://app-econeura-ok-prod.azurewebsites.net/api/health/redis

# 4. Test NEURA CEO
curl -X POST https://app-econeura-ok-prod.azurewebsites.net/api/neura-chat \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <TOKEN>" \
  -d '{
    "message": "Hola, soy el CEO de ECONEURA. ¿Cuál es la estrategia de crecimiento?",
    "neuraId": "ceo"
  }'

# 5. Verificar telemetría en Application Insights
az monitor app-insights query \
  --app appi-econeura-ok-prod \
  --analytics-query "traces | where timestamp > ago(5m) | take 10"
```

**CHECKPOINT:** Todo funcionando ✅

---

## 📊 Por Qué Este Plan es EFICIENTE

| Decisión | Por Qué | Ahorro de Tiempo |
|----------|---------|------------------|
| **App Service B3** | 4 cores = Sin OOM errors, sin lentitud | No debugging de memory leaks |
| **PostgreSQL B2s** | 200 conexiones = Sin pool exhaustion | No debugging de connection errors |
| **Redis C1** | 1GB cache = Sin race conditions | No debugging de rate limiting |
| **Application Insights** | Telemetría completa = Debugging instantáneo | Encontrar errores en minutos vs horas |
| **Blob Storage** | Documentos RAG persistentes | No perder embeddings |
| **Bicep completo** | Todo configurado automáticamente | No configuración manual |

---

## ✅ GitHub Secrets - Lista Completa

| Secret | Valor | Dónde Obtenerlo |
|--------|-------|-----------------|
| `AZURE_APP_SERVICE_URL` | `https://app-econeura-ok-prod.azurewebsites.net` | Output `appServiceUrl` |
| `AZURE_STATIC_WEB_APP_URL` | `https://swa-econeura-ok-prod.azurewebsites.net` | Output `staticWebAppUrl` |
| `DATABASE_URL` | `postgresql://econeuraadmin:...` | Output `databaseUrl` |
| `REDIS_HOST` | `redis-econeura-ok-prod.redis.cache.windows.net` | Output `redisHost` |
| `REDIS_PORT` | `6380` | Output `redisPort` |
| `REDIS_PASSWORD` | `<PRIMARY_KEY>` | Output `redisPrimaryKey` |
| `GEMINI_API_KEY` | `<TU_KEY>` | Tu API key de Gemini |
| `APPLICATIONINSIGHTS_CONNECTION_STRING` | `InstrumentationKey=...` | Output `appInsightsConnectionString` |
| `AZURE_STORAGE_CONNECTION_STRING` | `DefaultEndpointsProtocol=https...` | Output `storageConnectionString` |
| `NODE_ENV` | `production` | Hardcoded |
| `USE_MEMORY_STORE` | `false` | Hardcoded (usar Redis) |

---

## 🎯 Ventajas de Gastar $175 vs $20

| Aspecto | Plan $20 | Plan $175 | Diferencia |
|---------|----------|-----------|------------|
| **Debugging time** | 2-4 horas | 10-20 min | **10x más rápido** |
| **OOM errors** | Probables | Nunca | **Cero downtime** |
| **Connection pool** | 50 (puede fallar) | 200 (sobra) | **Cero errors** |
| **Rate limiting** | In-memory (reinicia) | Redis (persiste) | **Cero race conditions** |
| **Telemetría** | Básica | Completa | **Debugging instantáneo** |
| **Time to production** | 6-8 horas | 2.5 horas | **3x más rápido** |

---

## 💰 Desglose de $175 USD

| Servicio | Costo/mes | Por Qué Vale la Pena |
|----------|-----------|----------------------|
| App Service B3 | $55 | 4 cores = sin lentitud, sin OOM |
| PostgreSQL B2s | $55 | 200 conexiones = sin pool exhaustion |
| Redis Basic C1 | $35 | Persistencia = sin race conditions |
| Storage + Insights | $30 | Debugging rápido + RAG storage |
| **TOTAL** | **$175** | **Deployment en 2.5h vs 6h** |

---

## 🔧 Configuración Post-Deployment (Opcional, 10 min)

### PostgreSQL: Optimizar para NEURAs

```sql
-- Conectar a PostgreSQL
az postgres flexible-server connect \
  --name pg-econeura-ok-prod \
  --admin-user econeuraadmin \
  --database econeura_app

-- Ejecutar:
CREATE INDEX CONCURRENTLY idx_conversations_tenant ON conversations(tenant_id);
CREATE INDEX CONCURRENTLY idx_messages_conversation ON messages(conversation_id);
CREATE INDEX CONCURRENTLY idx_messages_created ON messages(created_at DESC);

-- Verificar
\d+ conversations
```

---

## ⚠️ Troubleshooting (Si Algo Falla)

### Backend no responde en /health

```bash
# Ver logs en tiempo real
az webapp log tail \
  --name app-econeura-ok-prod \
  --resource-group rg-econeura-ok-prod

# Ver últimos 100 logs
az webapp log download \
  --name app-econeura-ok-prod \
  --resource-group rg-econeura-ok-prod \
  --log-file app-logs.zip
```

### Database connection failed

```bash
# Verificar firewall rules
az postgres flexible-server firewall-rule list \
  --name pg-econeura-ok-prod \
  --resource-group rg-econeura-ok-prod

# Agregar IP si necesario
az postgres flexible-server firewall-rule create \
  --name AllowMyIP \
  --resource-group rg-econeura-ok-prod \
  --server-name pg-econeura-ok-prod \
  --start-ip-address <YOUR_IP> \
  --end-ip-address <YOUR_IP>
```

### Redis connection failed

```bash
# Verificar Redis
az redis show \
  --name redis-econeura-ok-prod \
  --resource-group rg-econeura-ok-prod

# Test connection
redis-cli -h redis-econeura-ok-prod.redis.cache.windows.net \
  -p 6380 -a "<PRIMARY_KEY>" --tls ping
```

---

## 📈 Métricas de Éxito - Primeras 24h

| Métrica | Target | Cómo Verificar |
|---------|--------|----------------|
| Uptime | > 99% | Azure Portal → App Service → Metrics |
| Response time | < 500ms | Application Insights → Performance |
| DB connections | < 50 (de 200) | Azure Portal → PostgreSQL → Metrics |
| Redis hits | > 80% | Azure Portal → Redis → Metrics |
| Errores 5xx | 0 | Application Insights → Failures |

---

## ✅ Checklist Final

- [ ] RG `rg-econeura-ok-prod` creado
- [ ] Bicep deployed (15 min)
- [ ] 11 GitHub Secrets configurados
- [ ] Backend deployed
- [ ] Frontend deployed
- [ ] `/health` → 200 OK
- [ ] Test 1 NEURA → respuesta OK
- [ ] Application Insights recibiendo logs
- [ ] PostgreSQL índices creados
- [ ] Monitoring dashboard configurado

---

**TIEMPO TOTAL ESTIMADO: 2.5 HORAS**  
**COSTO: $175 USD/mes**  
**EFICIENCIA: MÁXIMA** ✅

**¿Listo para deployar? Solo dame luz verde y ejecuto todo.**
