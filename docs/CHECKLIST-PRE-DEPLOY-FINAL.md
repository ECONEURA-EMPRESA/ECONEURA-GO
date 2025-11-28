# ✅ CHECKLIST PRE-DEPLOY FINAL - NO FALLAR

**Fecha:** 2025-11-16  
**Objetivo:** Checklist exhaustivo para garantizar deployment exitoso

---

## 🚨 ANTES DE HACER DEPLOY - VERIFICAR TODO

### ✅ 1. VALIDACIÓN LOCAL (OBLIGATORIO)

```powershell
# Ejecutar script de validación
.\scripts\validate-pre-deploy.ps1 -Environment staging
```

**Debe pasar con 0 errores antes de continuar.**

- [ ] ✅ TypeScript: 0 errores (backend + frontend)
- [ ] ✅ Build: Backend compila sin errores
- [ ] ✅ Build: Frontend compila sin errores
- [ ] ✅ Tests: Todos los tests pasan (si existen)
- [ ] ✅ Estructura: Todos los archivos críticos existen

---

### ✅ 2. GITHUB SECRETS (OBLIGATORIO)

**Ir a:** `https://github.com/TU-REPO/settings/secrets/actions`

- [ ] ✅ `AZURE_CREDENTIALS` - Service Principal JSON completo
- [ ] ✅ `AZURE_WEBAPP_NAME_BACKEND` - Nombre exacto del App Service
- [ ] ✅ `AZURE_WEBAPP_PUBLISH_PROFILE_BACKEND` - Publish Profile XML
- [ ] ✅ `AZURE_STATIC_WEB_APPS_API_TOKEN` - Token de Static Web App
- [ ] ✅ `POSTGRES_ADMIN_PASSWORD` - Password de PostgreSQL (mínimo 8 caracteres, mayúsculas, minúsculas, números)
- [ ] ✅ `OPENAI_API_KEY` - API Key de OpenAI (formato: `[REDACTED]`)

**Verificar formato:**
- `AZURE_CREDENTIALS`: JSON válido con `clientId`, `clientSecret`, `subscriptionId`, `tenantId`
- `AZURE_WEBAPP_PUBLISH_PROFILE_BACKEND`: XML válido descargado desde Azure Portal

---

### ✅ 3. AZURE RESOURCES (OBLIGATORIO)

```powershell
# Ejecutar script de validación Azure
.\scripts\validate-azure-resources.ps1 -ResourceGroup "rg-econeura-full-staging" -Environment "staging"
```

- [ ] ✅ Resource Group existe
- [ ] ✅ App Service Plan existe (SKU B1 o superior)
- [ ] ✅ App Service (Backend) existe
- [ ] ✅ Static Web App existe (o se creará automáticamente)
- [ ] ✅ PostgreSQL existe y está corriendo (no pausado)
- [ ] ✅ Redis existe (opcional pero recomendado)
- [ ] ✅ Key Vault existe
- [ ] ✅ Storage Account existe
- [ ] ✅ Application Insights existe

---

### ✅ 4. CONFIGURACIÓN APP SERVICE (OBLIGATORIO)

**Verificar en Azure Portal → App Service → Configuration → Application settings:**

- [ ] ✅ `NODE_ENV=production`
- [ ] ✅ `PORT=8080`
- [ ] ✅ `OPENAI_API_KEY=[REDACTED]` (o configurado en Key Vault)
- [ ] ✅ `DATABASE_URL=postgresql://...` (formato correcto con `?sslmode=require`)
- [ ] ✅ `APPLICATIONINSIGHTS_CONNECTION_STRING=InstrumentationKey=...`
- [ ] ✅ `REDIS_URL=rediss://...` (si se usa Redis)
- [ ] ✅ `KEY_VAULT_URL=https://kv-econeura-full-staging.vault.azure.net/` (si se usa Key Vault)
- [ ] ✅ `AZURE_STORAGE_CONNECTION_STRING=DefaultEndpointsProtocol=...` (si se usa Storage)

**Formato de DATABASE_URL:**
```
postgresql://USER:PASSWORD@HOST:5432/DATABASE?sslmode=require
```

---

### ✅ 5. PERMISOS Y ACCESOS (OBLIGATORIO)

- [ ] ✅ **Service Principal** tiene rol `Contributor` o `Owner` en Resource Group
- [ ] ✅ **Managed Identity** habilitada en App Service
- [ ] ✅ **Key Vault Access Policy** configurada para Managed Identity con permisos `Get` y `List`
- [ ] ✅ **PostgreSQL Firewall** permite Azure services (0.0.0.0 - 0.0.0.0)
- [ ] ✅ **Redis Firewall** permite Azure services (si se usa)

**Verificar Managed Identity:**
```powershell
az webapp identity show --name app-econeura-full-staging-backend --resource-group rg-econeura-full-staging
```

**Verificar Key Vault permisos:**
```powershell
# Obtener Principal ID
$principalId = (az webapp identity show --name app-econeura-full-staging-backend --resource-group rg-econeura-full-staging | ConvertFrom-Json).principalId

# Verificar permisos
az keyvault show --name kv-econeura-full-staging --resource-group rg-econeura-full-staging --query "properties.accessPolicies[?objectId=='$principalId']"
```

---

### ✅ 6. KEY VAULT SECRETS (OBLIGATORIO si se usa Key Vault)

**Verificar en Azure Portal → Key Vault → Secrets:**

- [ ] ✅ `OPENAI-API-KEY` existe
- [ ] ✅ `JWT-SECRET` existe (mínimo 64 caracteres)
- [ ] ✅ `SESSION-SECRET` existe (mínimo 32 caracteres)
- [ ] ✅ `DATABASE-URL` existe (opcional, puede estar en App Settings)

**Crear secrets si faltan:**
```powershell
az keyvault secret set --vault-name kv-econeura-full-staging --name "OPENAI-API-KEY" --value "[REDACTED]"
az keyvault secret set --vault-name kv-econeura-full-staging --name "JWT-SECRET" --value "TU_SECRET_64_CARACTERES_MINIMO"
az keyvault secret set --vault-name kv-econeura-full-staging --name "SESSION-SECRET" --value "TU_SECRET_32_CARACTERES_MINIMO"
```

---

### ✅ 7. POSTGRESQL (OBLIGATORIO)

- [ ] ✅ PostgreSQL está corriendo (estado: `Ready`, no `Stopped`)
- [ ] ✅ Database `econeura_full_staging` existe
- [ ] ✅ Firewall permite Azure services
- [ ] ✅ Credenciales correctas en `DATABASE_URL`

**Si está pausado:**
```powershell
az postgres flexible-server start --name pg-econeura-full-staging --resource-group rg-econeura-full-staging
```

**Si database no existe:**
```powershell
az postgres flexible-server db create --name econeura_full_staging --server-name pg-econeura-full-staging --resource-group rg-econeura-full-staging
```

---

### ✅ 8. REDIS (OPCIONAL pero recomendado)

- [ ] ✅ Redis está corriendo (provisioningState: `Succeeded`)
- [ ] ✅ Firewall permite conexiones
- [ ] ✅ `REDIS_URL` configurada correctamente en App Service

**Formato de REDIS_URL:**
```
rediss://:PASSWORD@HOST:6380
```

---

### ✅ 9. STORAGE ACCOUNT (OPCIONAL pero recomendado)

- [ ] ✅ Storage Account existe
- [ ] ✅ Container `documents` existe (o se crea automáticamente)
- [ ] ✅ `AZURE_STORAGE_CONNECTION_STRING` configurada en App Service

---

### ✅ 10. APPLICATION INSIGHTS (OBLIGATORIO)

- [ ] ✅ Application Insights existe
- [ ] ✅ `APPLICATIONINSIGHTS_CONNECTION_STRING` configurada en App Service
- [ ] ✅ Connection String tiene formato correcto: `InstrumentationKey=xxx;IngestionEndpoint=https://...`

**Obtener Connection String:**
```powershell
az monitor app-insights component show --app appi-econeura-full-staging --resource-group rg-econeura-full-staging --query "connectionString" -o tsv
```

---

## 🚀 PROCESO DE DEPLOY

### Paso 1: Deploy Infraestructura (si es primera vez)

```powershell
# Ejecutar workflow: infra-deploy.yml
# O manualmente:
az deployment group create `
  --resource-group rg-econeura-full-staging `
  --template-file infrastructure/azure/main.bicep `
  --parameters environment=staging location=westeurope baseName=econeura-full postgresAdminPassword='${{ secrets.POSTGRES_ADMIN_PASSWORD }}' openAiApiKey='${{ secrets.OPENAI_API_KEY }}'
```

### Paso 2: Configurar App Service Settings

```powershell
# Ejecutar script de corrección
.\scripts\fix-common-issues.ps1 -ResourceGroup "rg-econeura-full-staging" -Environment "staging" -FixAll
```

### Paso 3: Deploy Aplicación

```powershell
# Ejecutar workflow: app-deploy.yml
# O manualmente desde GitHub Actions
```

### Paso 4: Health Check

```powershell
# Ejecutar health check completo
.\scripts\health-check-complete.ps1 -BackendUrl "https://app-econeura-full-staging-backend.azurewebsites.net"
```

---

## 🔍 VERIFICACIÓN POST-DEPLOY

- [ ] ✅ Health endpoint responde: `/health` → HTTP 200
- [ ] ✅ API endpoints responden: `/api/neuras` → HTTP 401 (esperado sin auth)
- [ ] ✅ Frontend carga correctamente (si URL proporcionada)
- [ ] ✅ Application Insights recibe telemetría
- [ ] ✅ Logs sin errores críticos
- [ ] ✅ PostgreSQL conectado (verificar en logs)
- [ ] ✅ Redis conectado (si se usa, verificar en logs)

---

## 🚨 SI ALGO FALLA

1. **Ver logs inmediatamente:**
```powershell
az webapp log tail --name app-econeura-full-staging-backend --resource-group rg-econeura-full-staging
```

2. **Ejecutar script de corrección:**
```powershell
.\scripts\fix-common-issues.ps1 -ResourceGroup "rg-econeura-full-staging" -Environment "staging" -FixAll
```

3. **Consultar guía de troubleshooting:**
```powershell
# Ver: docs/TROUBLESHOOTING-GUIA-COMPLETA.md
```

4. **Verificar Application Insights:**
   - Azure Portal → Application Insights → Logs
   - Ejecutar queries (ver `docs/KUSTO-QUERIES.md`)

---

## ✅ CRITERIO DE ÉXITO

**Deployment exitoso cuando:**
- ✅ Todos los checks pasan
- ✅ Health endpoint responde HTTP 200
- ✅ API endpoints accesibles (aunque sea con 401)
- ✅ Application Insights recibe telemetría
- ✅ Logs sin errores críticos

---

**Última actualización:** 2025-11-16  
**Scripts:** `scripts/validate-pre-deploy.ps1`, `scripts/validate-azure-resources.ps1`, `scripts/health-check-complete.ps1`, `scripts/fix-common-issues.ps1`

