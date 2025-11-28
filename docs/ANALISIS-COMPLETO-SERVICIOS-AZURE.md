# 🔍 ANÁLISIS COMPLETO: SERVICIOS AZURE ECONEURA-FULL

**Fecha:** 2025-11-16  
**Presupuesto:** $170 USD  
**Objetivo:** Análisis exhaustivo de todos los servicios Azure configurados

---

## 📊 RESUMEN EJECUTIVO

### ✅ Servicios Configurados: **9 Servicios**

| # | Servicio | Estado | SKU/Tier | Costo/mes | Crítico |
|---|----------|--------|----------|-----------|---------|
| 1 | App Service Plan | ✅ | B1 Basic | $13 | ✅ |
| 2 | App Service (Backend) | ✅ | Linux Node 20 | Incluido | ✅ |
| 3 | Static Web App (Frontend) | ✅ | Free | $0 | ✅ |
| 4 | PostgreSQL Flexible Server | ✅ | Standard_B1ms | $25 | ✅ |
| 5 | Redis Cache | ✅ | C0 (250MB) | $15 | ✅ |
| 6 | Storage Account | ✅ | Hot LRS | $1 | ✅ |
| 7 | Key Vault | ✅ | Standard | $0.10 | ✅ |
| 8 | Application Insights | ✅ | Pay-as-you-go | $2 | ✅ |
| 9 | Log Analytics Workspace | ✅ | Pay-as-you-go | $2 | ✅ |
| **TOTAL** | | | | **~$58/mes** | |

### ⚠️ Servicios Opcionales (No Implementados):
- Cosmos DB (Event Store) - Deshabilitado por defecto
- Cosmos DB (Read Models) - Deshabilitado por defecto

---

## 1️⃣ APP SERVICE PLAN + APP SERVICE (BACKEND)

### 📋 Configuración

**Archivo:** `infrastructure/azure/app-backend.bicep`

**App Service Plan:**
- **Nombre:** `plan-{baseName}-{environment}`
- **SKU:** `B1` (Basic Tier)
- **Tier:** `Basic`
- **OS:** Linux
- **Reservado:** `true` (Linux containers)

**App Service:**
- **Nombre:** `{baseName}-backend-{environment}`
- **Kind:** `app,linux`
- **Runtime:** `NODE|20-lts`
- **HTTPS Only:** `true`
- **Port:** `8080`

### 💰 Costos

- **App Service Plan B1:** ~$13/mes
- **App Service:** Incluido en el plan
- **Total:** ~$13/mes

### ⚙️ Configuración de Variables de Entorno

```typescript
NODE_ENV: 'production'
PORT: '8080'
DATABASE_URL: 'postgresql://<user>:<password>@${databaseHost}:5432/${databaseName}?sslmode=require'
APPLICATIONINSIGHTS_CONNECTION_STRING: ${appInsightsConnectionString}
REDIS_URL: 'rediss://${redisHost}' (si está configurado)
AZURE_STORAGE_CONNECTION_STRING: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=<key>;EndpointSuffix=core.windows.net'
AZURE_BLOB_CONTAINER: 'documents'
```

### 🔗 Dependencias

- ✅ **Monitoring** (Application Insights) - Requerido
- ✅ **Database** (PostgreSQL) - Requerido
- ✅ **Redis** - Opcional (para rate limiting distribuido)
- ✅ **Storage** - Opcional (para Blob Storage)

### 🔒 Seguridad

- ✅ HTTPS Only habilitado
- ✅ TLS 1.2 mínimo (por defecto en App Service)
- ✅ Variables de entorno para secrets (no hardcodeadas)

### ⚠️ Limitaciones B1 Basic

- **1 vCPU compartido**
- **1.75 GB RAM**
- **10 GB storage**
- **Sin auto-scaling**
- **Sin staging slots**

### 💡 Optimizaciones Recomendadas

1. **Auto-shutdown en dev:** Ahorro ~$10/mes (apagar 12h/día)
2. **Upgrade a S1 en producción:** Mejor rendimiento ($55/mes)
3. **Staging slots:** Para blue-green deployments (requiere S1+)

---

## 2️⃣ STATIC WEB APP (FRONTEND)

### 📋 Configuración

**Archivo:** `infrastructure/azure/app-frontend.bicep`

**Static Web App:**
- **Nombre:** `{baseName}-frontend-{environment}`
- **Tier:** `Free`
- **SKU:** `Free`
- **Location:** `westeurope`
- **Build Properties:**
  - `appLocation`: `packages/frontend`
  - `outputLocation`: `dist`

### 💰 Costos

- **Tier Free:** $0/mes
- **Total:** $0

### ⚙️ Configuración

- **Repository URL:** Vacío (se despliega vía GitHub Actions)
- **Branch:** Vacío
- **Backend URL:** Configurado vía `backendUrl` parameter

### 🔗 Dependencias

- ✅ **App Service Backend** - Para obtener `backendUrl`

### 🔒 Seguridad

- ✅ HTTPS habilitado por defecto
- ✅ Custom domain disponible (requiere configuración adicional)

### ⚠️ Limitaciones Free Tier

- **100 GB bandwidth/mes**
- **100 builds/mes**
- **Sin custom domains** (solo subdominio `.azurestaticapps.net`)
- **Sin staging environments**

### 💡 Optimizaciones Recomendadas

1. **Upgrade a Standard:** Si se necesita más bandwidth ($9/mes)
2. **Custom domains:** Requiere Standard tier
3. **Staging environments:** Requiere Standard tier

---

## 3️⃣ POSTGRESQL FLEXIBLE SERVER

### 📋 Configuración

**Archivo:** `infrastructure/azure/database.bicep`

**PostgreSQL Server:**
- **Nombre:** `pg-{baseName}-{environment}`
- **SKU:** `Standard_B1ms`
- **Tier:** `Burstable`
- **Version:** `16`
- **Storage:** `32 GB`
- **High Availability:** `Disabled`
- **Backup Retention:** `7 días`

**Database:**
- **Nombre:** `econeura_app`
- **Charset:** UTF8 (por defecto)
- **Collation:** en_US.utf8 (por defecto)

### 💰 Costos

- **Standard_B1ms:** ~$25/mes
- **Storage (32GB):** Incluido
- **Backups (7 días):** Incluido
- **Total:** ~$25/mes

### ⚙️ Configuración

- **Admin User:** `econeuraadmin`
- **Admin Password:** Pasado como parámetro seguro
- **SSL Mode:** `require` (forzado en connection string)

### 🔗 Dependencias

- ✅ **Ninguna** - Servicio independiente

### 🔒 Seguridad

- ✅ SSL/TLS requerido (`sslmode=require`)
- ✅ Password gestionado vía parámetros seguros
- ✅ Firewall rules (se configuran manualmente o vía script)

### ⚠️ Limitaciones Standard_B1ms

- **1 vCore Burstable**
- **2 GB RAM**
- **32 GB storage máximo** (configurado)
- **Sin high availability**
- **Sin read replicas**

### 💡 Optimizaciones Recomendadas

1. **Auto-pause en dev:** Ahorro ~$20/mes (pausa después de 1h inactividad)
2. **Upgrade a Standard_D2s_v3 en producción:** Mejor rendimiento ($150/mes)
3. **High Availability:** Para producción crítica (requiere Standard tier)

---

## 4️⃣ REDIS CACHE

### 📋 Configuración

**Archivo:** `infrastructure/azure/redis.bicep`

**Redis Cache:**
- **Nombre:** `redis-{baseName}-{environment}`
- **SKU:** `C0` (configurable: C0, C1, C2)
- **Family:** `C`
- **Capacity:** `0` (C0 = 0, C1 = 1, C2 = 2)
- **Version:** `7`
- **Non-SSL Port:** `false` (deshabilitado)
- **Minimum TLS:** `1.2`

### 💰 Costos

- **C0 (250MB):** ~$15/mes
- **C1 (1GB):** ~$30/mes
- **C2 (2.5GB):** ~$60/mes
- **Total (C0):** ~$15/mes

### ⚙️ Configuración

- **Connection String:** `rediss://${redisCache.name}.redis.cache.windows.net:6380`
- **Port:** `6380` (SSL)
- **Auto-pause:** Solo disponible en Basic tier (C0), configurado para dev

### 🔗 Dependencias

- ✅ **Ninguna** - Servicio independiente

### 🔒 Seguridad

- ✅ SSL/TLS requerido (`rediss://`)
- ✅ Non-SSL port deshabilitado
- ✅ TLS 1.2 mínimo
- ✅ Firewall rules (se configuran manualmente)

### ⚠️ Limitaciones C0

- **250 MB memoria**
- **Sin high availability**
- **Sin clustering**
- **Auto-pause disponible** (solo Basic tier)

### 💡 Optimizaciones Recomendadas

1. **Upgrade a C1 en producción:** Más memoria ($30/mes)
2. **Standard tier (C1+):** High availability disponible
3. **Clustering:** Para escalabilidad horizontal (requiere Premium tier)

### 📝 Uso en Código

**Estado actual:** Configurado pero no integrado en código
- `REDIS_URL` configurado en App Service
- `rateLimiter.ts` usa memory store (no Redis)
- **Pendiente:** Integrar Redis en `rateLimiter.ts`

---

## 5️⃣ STORAGE ACCOUNT (BLOB STORAGE)

### 📋 Configuración

**Archivo:** `infrastructure/azure/storage.bicep`

**Storage Account:**
- **Nombre:** `st{baseName}{environment}{uniqueSuffix}` (único globalmente)
- **Kind:** `StorageV2`
- **SKU:** `Standard_LRS` (configurable: LRS, GRS, ZRS)
- **Access Tier:** `Hot` (configurable: Hot, Cool)
- **HTTPS Only:** `true`
- **Minimum TLS:** `TLS1_2`
- **Blob Public Access:** `false` (seguridad)
- **Shared Key Access:** `true`

**Containers:**
- **`documents`:** Para documentos RAG
- **`files`:** Para archivos generales
- **Public Access:** `None` (privado)

### 💰 Costos

- **Storage (Hot LRS):** ~$0.02/GB/mes
- **Transacciones:** ~$0.004/10,000 operaciones
- **Total estimado (50GB):** ~$1/mes

### ⚙️ Configuración

- **Connection String:** `DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=<key>;EndpointSuffix=core.windows.net`
- **Container:** `documents` (configurado en App Service)

### 🔗 Dependencias

- ✅ **Ninguna** - Servicio independiente

### 🔒 Seguridad

- ✅ HTTPS Only habilitado
- ✅ TLS 1.2 mínimo
- ✅ Blob public access deshabilitado
- ✅ Containers privados (solo acceso vía connection string)

### ⚠️ Limitaciones LRS

- **Redundancia local** (no geo-redundante)
- **Sin backup automático** (requiere GRS para geo-redundancia)

### 💡 Optimizaciones Recomendadas

1. **Upgrade a GRS en producción:** Geo-redundancia ($0.04/GB/mes)
2. **Lifecycle management:** Mover a Cool tier después de 30 días
3. **Archive tier:** Para documentos antiguos (muy barato)

### 📝 Uso en Código

**Estado actual:** Integrado
- `AZURE_STORAGE_CONNECTION_STRING` configurado en App Service
- `AzureBlobAdapter` implementado
- `knowledge/` domain usa Storage Service

---

## 6️⃣ KEY VAULT

### 📋 Configuración

**Archivo:** `infrastructure/azure/keyvault.bicep`

**Key Vault:**
- **Nombre:** `kv-{baseName}-{environment}`
- **SKU:** `standard` (Family A)
- **Soft Delete:** `true`
- **Purge Protection:** `true`
- **Access Policies:** Vacío (se gestionan vía RBAC)

**Secrets:**
- **`openai-api-key`:** API key de OpenAI
- **`database-url`:** Connection string de PostgreSQL (placeholder)

### 💰 Costos

- **Standard tier:** $0.03/secret/mes
- **Total (2 secrets):** ~$0.10/mes

### ⚙️ Configuración

- **Soft Delete:** Habilitado (30 días retention)
- **Purge Protection:** Habilitado (protección contra eliminación permanente)
- **Access Policies:** Vacío (usar RBAC recomendado)

### 🔗 Dependencias

- ✅ **Ninguna** - Servicio independiente

### 🔒 Seguridad

- ✅ Soft Delete habilitado
- ✅ Purge Protection habilitado
- ✅ RBAC recomendado (no access policies legacy)
- ✅ Secrets encriptados en reposo

### ⚠️ Limitaciones

- **10,000 secrets máximo** (suficiente para la mayoría de casos)
- **Access policies legacy** (no recomendado, usar RBAC)

### 💡 Optimizaciones Recomendadas

1. **RBAC:** Configurar roles en lugar de access policies
2. **Rotation:** Implementar rotación automática de secrets
3. **Monitoring:** Alertas cuando se accede a secrets críticos

---

## 7️⃣ APPLICATION INSIGHTS

### 📋 Configuración

**Archivo:** `infrastructure/azure/monitoring.bicep`

**Application Insights:**
- **Nombre:** `ai-{baseName}-{environment}`
- **Kind:** `web`
- **Application Type:** `web`
- **Flow Type:** `Bluefield`
- **Workspace:** Vinculado a Log Analytics Workspace

### 💰 Costos

- **Pay-as-you-go:** Primeros 5GB gratis, luego $2.30/GB
- **Total estimado:** ~$2/mes (asumiendo <5GB/mes)

### ⚙️ Configuración

- **Connection String:** Exportado para App Service
- **Workspace:** Vinculado a Log Analytics Workspace

### 🔗 Dependencias

- ✅ **Log Analytics Workspace** - Requerido

### 🔒 Seguridad

- ✅ Datos encriptados en reposo
- ✅ Acceso vía connection string (seguro)

### ⚠️ Limitaciones

- **5GB gratis/mes** (luego pay-as-you-go)
- **90 días retention** (gratis), 730 días (pay-as-you-go)

### 💡 Optimizaciones Recomendadas

1. **Sampling:** Reducir volumen de logs (ahorro de costos)
2. **Retention:** Ajustar según necesidades (90 días suele ser suficiente)
3. **Alerts:** Configurar alertas para errores críticos

---

## 8️⃣ LOG ANALYTICS WORKSPACE

### 📋 Configuración

**Archivo:** `infrastructure/azure/monitoring.bicep`

**Log Analytics Workspace:**
- **Nombre:** `logs-{baseName}-{environment}`
- **Retention:** `30 días`
- **Log Access:** Solo vía resource permissions

### 💰 Costos

- **Pay-as-you-go:** Primeros 5GB gratis, luego $2.30/GB
- **Total estimado:** ~$2/mes (asumiendo <5GB/mes)

### ⚙️ Configuración

- **Retention:** 30 días
- **Resource Permissions:** Habilitado (más seguro)

### 🔗 Dependencias

- ✅ **Ninguna** - Servicio independiente

### 🔒 Seguridad

- ✅ Datos encriptados en reposo
- ✅ Resource permissions (más seguro que workspace permissions)

### ⚠️ Limitaciones

- **30 días retention** (configurado)
- **5GB gratis/mes** (luego pay-as-you-go)

### 💡 Optimizaciones Recomendadas

1. **Retention:** Reducir a 7 días en dev (ahorro)
2. **Data collection rules:** Filtrar logs innecesarios
3. **Archive:** Mover logs antiguos a Archive tier

---

## 9️⃣ COSMOS DB (EVENT STORE / READ MODELS)

### 📋 Configuración

**Archivo:** `infrastructure/azure/eventstore.bicep` / `readmodels.bicep`

**Estado:** ⚠️ **NO IMPLEMENTADO** (solo placeholders)

**Configuración:**
- **Habilitado:** Solo si `enableEventStore = true`
- **Módulos:** Placeholders vacíos

### 💰 Costos

- **Estimado:** ~$25/mes (si se implementa)
- **Total:** $0 (actualmente deshabilitado)

### ⚙️ Configuración

- **No configurado** - Pendiente implementación

### 🔗 Dependencias

- ✅ **Ninguna** - Servicio independiente (cuando se implemente)

### 🔒 Seguridad

- **No aplicable** - No implementado

### ⚠️ Estado Actual

- ❌ **No implementado**
- ⚠️ **Solo placeholders** en Bicep
- 📝 **Pendiente:** Implementación completa

### 💡 Recomendaciones

1. **No implementar hasta que sea necesario** (ahorro de costos)
2. **Usar PostgreSQL para Event Store** (más barato, suficiente para MVP)
3. **Implementar Cosmos DB solo si se necesita** alta escalabilidad

---

## 📊 RESUMEN DE COSTOS

### Costos Mensuales (Producción)

| Servicio | Costo/mes | Notas |
|----------|-----------|-------|
| App Service Plan B1 | $13 | Backend |
| Static Web App Free | $0 | Frontend |
| PostgreSQL B1ms | $25 | Base de datos |
| Redis Cache C0 | $15 | Rate limiting |
| Storage Account (50GB) | $1 | Blob Storage |
| Key Vault (2 secrets) | $0.10 | Secrets |
| Application Insights | $2 | Monitoring |
| Log Analytics | $2 | Logs |
| **TOTAL** | **~$58/mes** | |

### Costos Mensuales (Dev Optimizado)

| Servicio | Costo/mes | Optimización |
|----------|-----------|--------------|
| App Service Plan B1 (50% uptime) | $6.5 | Auto-shutdown 12h/día |
| Static Web App Free | $0 | - |
| PostgreSQL B1ms (auto-pause) | $5 | Auto-pause después de 1h |
| Redis Cache C0 | $15 | - |
| Storage Account (10GB) | $0.20 | Menos storage |
| Key Vault (2 secrets) | $0.10 | - |
| Application Insights | $1 | Menos logs |
| Log Analytics (7 días retention) | $1 | Menos retention |
| **TOTAL** | **~$28.8/mes** | **Ahorro: ~$29/mes** |

### Presupuesto $170

- **Producción:** ~2.9 meses
- **Dev optimizado:** ~5.9 meses
- **Recomendación:** Usar optimizaciones en dev

---

## 🔗 DIAGRAMA DE DEPENDENCIAS

```
Resource Group (rg-econeura-full-{env})
│
├─ Monitoring (Application Insights + Log Analytics)
│  └─ Output: appInsightsConnectionString
│
├─ Database (PostgreSQL)
│  └─ Outputs: databaseHost, databaseName
│
├─ Redis Cache
│  └─ Output: redisHost
│
├─ Storage Account
│  └─ Output: storageAccountName
│
├─ Key Vault
│  └─ Secrets: openai-api-key, database-url
│
├─ App Service Plan
│  └─ App Service (Backend)
│     ├─ Depende de: Monitoring, Database, Redis, Storage
│     └─ Output: backendUrl
│
└─ Static Web App (Frontend)
   └─ Depende de: App Service (backendUrl)
```

---

## ✅ CHECKLIST DE CONFIGURACIÓN

### Servicios Críticos

- [x] App Service Plan + App Service
- [x] Static Web App
- [x] PostgreSQL Flexible Server
- [x] Redis Cache
- [x] Storage Account
- [x] Key Vault
- [x] Application Insights
- [x] Log Analytics Workspace

### Servicios Opcionales

- [ ] Cosmos DB (Event Store) - Deshabilitado
- [ ] Cosmos DB (Read Models) - Deshabilitado

### Integraciones Pendientes

- [ ] Redis en `rateLimiter.ts` (configurado pero no usado)
- [ ] Key Vault integration en código (secrets ya configurados)
- [ ] Auto-pause PostgreSQL (configuración pendiente)
- [ ] Auto-shutdown App Service (configuración pendiente)

---

## 🚀 PRÓXIMOS PASOS

### Prioridad Alta

1. **Integrar Redis en rateLimiter.ts** - Crítico para rate limiting distribuido
2. **Configurar auto-pause PostgreSQL en dev** - Ahorro de costos
3. **Configurar auto-shutdown App Service en dev** - Ahorro de costos

### Prioridad Media

4. **Implementar Key Vault integration** - Mejor gestión de secrets
5. **Configurar alertas de costo** - Monitoreo de presupuesto
6. **Optimizar retention de logs** - Reducir costos

### Prioridad Baja

7. **Implementar Cosmos DB** - Solo si es necesario
8. **Upgrade a Standard tiers** - Solo en producción

---

**Última actualización:** 2025-11-16  
**Estado:** ✅ **ANÁLISIS COMPLETO - LISTO PARA DESPLEGAR**

