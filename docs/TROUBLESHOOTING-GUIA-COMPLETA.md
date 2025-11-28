# 🔧 GUÍA COMPLETA DE TROUBLESHOOTING - ECONEURA-FULL

**Fecha:** 2025-11-16  
**Objetivo:** Soluciones paso a paso para TODOS los problemas comunes

---

## 📋 ÍNDICE RÁPIDO

- [Problemas de Deployment](#problemas-de-deployment)
- [Problemas de Backend](#problemas-de-backend)
- [Problemas de Frontend](#problemas-de-frontend)
- [Problemas de Base de Datos](#problemas-de-base-de-datos)
- [Problemas de Redis](#problemas-de-redis)
- [Problemas de Key Vault](#problemas-de-key-vault)
- [Problemas de Application Insights](#problemas-de-application-insights)
- [Problemas de Conectividad](#problemas-de-conectividad)
- [Problemas de Performance](#problemas-de-performance)
- [Comandos de Emergencia](#comandos-de-emergencia)

---

## 🚀 PROBLEMAS DE DEPLOYMENT

### ❌ **Error: "AZURE_CREDENTIALS is missing"**

**Síntoma:**
```
❌ AZURE_CREDENTIALS is missing
```

**Solución Paso a Paso:**

1. **Crear Service Principal:**
```powershell
az ad sp create-for-rbac `
  --name "econeura-github-actions" `
  --role contributor `
  --scopes /subscriptions/a0991f95-16e0-4f03-85df-db3d69004d94/resourceGroups/rg-econeura-full-staging `
  --sdk-auth > azure-credentials.json
```

2. **Copiar contenido de `azure-credentials.json`**

3. **Agregar a GitHub:**
   - Ir a: `https://github.com/TU-REPO/settings/secrets/actions`
   - Click "New repository secret"
   - Name: `AZURE_CREDENTIALS`
   - Value: Pegar JSON completo
   - Click "Add secret"

4. **Verificar:**
```powershell
# Ejecutar script de validación
.\scripts\validate-pre-deploy.ps1
```

---

### ❌ **Error: "Backend build failed: dist folder not found"**

**Síntoma:**
```
❌ Backend build failed: dist folder not found
```

**Solución Paso a Paso:**

1. **Verificar build localmente:**
```powershell
cd packages/backend
npm run build
```

2. **Si falla, verificar errores:**
```powershell
npm run type-check
```

3. **Corregir errores de TypeScript**

4. **Verificar `tsconfig.json`:**
```json
{
  "extends": "../../tsconfig.base.json",
  "compilerOptions": {
    "outDir": "./dist",
    "rootDir": "./src"
  }
}
```

5. **Verificar que `package.json` tiene script:**
```json
{
  "scripts": {
    "build": "tsc -p tsconfig.json"
  }
}
```

---

### ❌ **Error: "PostgreSQL deployment failed: LocationIsOfferRestricted"**

**Síntoma:**
```
Error: LocationIsOfferRestricted
Subscriptions are restricted from provisioning in location 'westeurope'
```

**Solución Paso a Paso:**

1. **Verificar locations disponibles:**
```powershell
az postgres flexible-server list-skus --location westeurope
```

2. **Si no está disponible, cambiar location:**
```powershell
# Editar infrastructure/azure/main.bicep
param location string = 'northeurope'  # Cambiar de westeurope
```

3. **O crear manualmente en location disponible:**
```powershell
az postgres flexible-server create `
  --name pg-econeura-full-staging-ne `
  --resource-group rg-econeura-full-staging `
  --location northeurope `
  --admin-user econeuraadmin `
  --admin-password "TU_PASSWORD_SEGURO" `
  --sku-name Standard_B1ms `
  --tier Burstable `
  --version 16
```

---

## 🔧 PROBLEMAS DE BACKEND

### ❌ **Error: "503 Service Unavailable"**

**Síntoma:**
```
503 Service Unavailable
```

**Solución Paso a Paso:**

1. **Verificar logs:**
```powershell
az webapp log tail `
  --name app-econeura-full-staging-backend `
  --resource-group rg-econeura-full-staging
```

2. **Verificar variables de entorno:**
```powershell
az webapp config appsettings list `
  --name app-econeura-full-staging-backend `
  --resource-group rg-econeura-full-staging
```

3. **Verificar que `PORT=8080` está configurado**

4. **Verificar que `NODE_ENV=production` está configurado**

5. **Si hay errores de dependencias:**
```powershell
# Verificar que App Service tiene Node 20
az webapp config show `
  --name app-econeura-full-staging-backend `
  --resource-group rg-econeura-full-staging `
  --query "linuxFxVersion"
```

6. **Reiniciar App Service:**
```powershell
az webapp restart `
  --name app-econeura-full-staging-backend `
  --resource-group rg-econeura-full-staging
```

---

### ❌ **Error: "OPENAI_API_KEY is required"**

**Síntoma:**
```
Error: OPENAI_API_KEY is required
```

**Solución Paso a Paso:**

1. **Opción 1: Agregar en App Service Settings**
```powershell
az webapp config appsettings set `
  --name app-econeura-full-staging-backend `
  --resource-group rg-econeura-full-staging `
  --settings OPENAI_API_KEY="[REDACTED]"
```

2. **Opción 2: Agregar en Key Vault (recomendado)**
```powershell
az keyvault secret set `
  --vault-name kv-econeura-full-staging `
  --name "OPENAI-API-KEY" `
  --value "[REDACTED]"
```

3. **Configurar App Service para leer de Key Vault:**
```powershell
# En App Service Settings, agregar:
KEY_VAULT_URL=https://kv-econeura-full-staging.vault.azure.net/
```

4. **Verificar que Managed Identity tiene permisos en Key Vault:**
```powershell
# Obtener Principal ID
$principalId = (az webapp identity show `
  --name app-econeura-full-staging-backend `
  --resource-group rg-econeura-full-staging | ConvertFrom-Json).principalId

# Agregar permisos
az keyvault set-policy `
  --name kv-econeura-full-staging `
  --object-id $principalId `
  --secret-permissions get list
```

---

### ❌ **Error: "Redis connection failed"**

**Síntoma:**
```
[Redis] Error de conexión
```

**Solución Paso a Paso:**

1. **Verificar que Redis está corriendo:**
```powershell
az redis show `
  --name redis-econeura-full-staging `
  --resource-group rg-econeura-full-staging `
  --query "provisioningState"
```

2. **Si está pausado, despertar:**
```powershell
# Redis no tiene comando "start", pero se despierta automáticamente al usar
# Verificar firewall
```

3. **Verificar firewall:**
```powershell
az redis firewall-rule list `
  --name redis-econeura-full-staging `
  --resource-group rg-econeura-full-staging
```

4. **Agregar regla de firewall para App Service:**
```powershell
# Obtener IP del App Service (puede ser dinámica)
# Mejor: Permitir todas las IPs de Azure (temporal)
az redis firewall-rule create `
  --name redis-econeura-full-staging `
  --resource-group rg-econeura-full-staging `
  --rule-name "AllowAzureServices" `
  --start-ip "0.0.0.0" `
  --end-ip "0.0.0.0"
```

5. **Verificar `REDIS_URL` en App Service:**
```powershell
# Obtener connection string
az redis list-keys `
  --name redis-econeura-full-staging `
  --resource-group rg-econeura-full-staging

# Formato: rediss://:PASSWORD@HOST:6380
# Agregar a App Service Settings
```

---

## 🗄️ PROBLEMAS DE BASE DE DATOS

### ❌ **Error: "Connection refused" o "Connection timeout"**

**Síntoma:**
```
Error: Connection refused
Error: Connection timeout
```

**Solución Paso a Paso:**

1. **Verificar que PostgreSQL está corriendo:**
```powershell
az postgres flexible-server show `
  --name pg-econeura-full-staging `
  --resource-group rg-econeura-full-staging `
  --query "state"
```

2. **Si está pausado (Stopped), despertar:**
```powershell
az postgres flexible-server start `
  --name pg-econeura-full-staging `
  --resource-group rg-econeura-full-staging

# Esperar 2-3 minutos
```

3. **Verificar firewall:**
```powershell
az postgres flexible-server firewall-rule list `
  --name pg-econeura-full-staging `
  --resource-group rg-econeura-full-staging
```

4. **Agregar regla para Azure services:**
```powershell
az postgres flexible-server firewall-rule create `
  --name pg-econeura-full-staging `
  --resource-group rg-econeura-full-staging `
  --rule-name "AllowAzureServices" `
  --start-ip-address "0.0.0.0" `
  --end-ip-address "0.0.0.0"
```

5. **Verificar `DATABASE_URL` en App Service:**
```powershell
# Formato correcto:
# postgresql://USER:PASSWORD@HOST:5432/DATABASE?sslmode=require

az webapp config appsettings set `
  --name app-econeura-full-staging-backend `
  --resource-group rg-econeura-full-staging `
  --settings DATABASE_URL="postgresql://econeuraadmin:PASSWORD@pg-econeura-full-staging.postgres.database.azure.com:5432/econeura_full_staging?sslmode=require"
```

---

### ❌ **Error: "database does not exist"**

**Síntoma:**
```
Error: database "econeura_full_staging" does not exist
```

**Solución Paso a Paso:**

1. **Crear database:**
```powershell
az postgres flexible-server db create `
  --name econeura_full_staging `
  --server-name pg-econeura-full-staging `
  --resource-group rg-econeura-full-staging
```

2. **O crear manualmente:**
```sql
-- Conectar a PostgreSQL
psql -h pg-econeura-full-staging.postgres.database.azure.com -U econeuraadmin -d postgres

-- Crear database
CREATE DATABASE econeura_full_staging;

-- Salir
\q
```

3. **Ejecutar migraciones (si existen):**
```powershell
# Si hay schema.sql
psql -h pg-econeura-full-staging.postgres.database.azure.com -U econeuraadmin -d econeura_full_staging -f schema.sql
```

---

## 🔐 PROBLEMAS DE KEY VAULT

### ❌ **Error: "Access denied to Key Vault"**

**Síntoma:**
```
Error: Access denied to Key Vault
```

**Solución Paso a Paso:**

1. **Habilitar Managed Identity en App Service:**
```powershell
az webapp identity assign `
  --name app-econeura-full-staging-backend `
  --resource-group rg-econeura-full-staging
```

2. **Obtener Principal ID:**
```powershell
$principalId = (az webapp identity show `
  --name app-econeura-full-staging-backend `
  --resource-group rg-econeura-full-staging | ConvertFrom-Json).principalId

Write-Host "Principal ID: $principalId"
```

3. **Agregar permisos en Key Vault:**
```powershell
az keyvault set-policy `
  --name kv-econeura-full-staging `
  --object-id $principalId `
  --secret-permissions get list
```

4. **Verificar en Azure Portal:**
   - Key Vault → Access policies
   - Verificar que App Service Managed Identity tiene permisos `Get` y `List`

---

## 📊 PROBLEMAS DE APPLICATION INSIGHTS

### ❌ **Error: "Application Insights not initialized"**

**Síntoma:**
```
[ApplicationInsights] Connection string no configurado
```

**Solución Paso a Paso:**

1. **Obtener Connection String:**
```powershell
az monitor app-insights component show `
  --app appi-econeura-full-staging `
  --resource-group rg-econeura-full-staging `
  --query "connectionString" -o tsv
```

2. **Agregar a App Service Settings:**
```powershell
az webapp config appsettings set `
  --name app-econeura-full-staging-backend `
  --resource-group rg-econeura-full-staging `
  --settings APPLICATIONINSIGHTS_CONNECTION_STRING="InstrumentationKey=xxx;IngestionEndpoint=https://..."
```

3. **Reiniciar App Service:**
```powershell
az webapp restart `
  --name app-econeura-full-staging-backend `
  --resource-group rg-econeura-full-staging
```

---

## 🚨 COMANDOS DE EMERGENCIA

### Reiniciar Todo

```powershell
# Reiniciar App Service
az webapp restart --name app-econeura-full-staging-backend --resource-group rg-econeura-full-staging

# Despertar PostgreSQL
az postgres flexible-server start --name pg-econeura-full-staging --resource-group rg-econeura-full-staging

# Ver logs en tiempo real
az webapp log tail --name app-econeura-full-staging-backend --resource-group rg-econeura-full-staging
```

### Verificar Estado de Todo

```powershell
# Estado de App Service
az webapp show --name app-econeura-full-staging-backend --resource-group rg-econeura-full-staging --query "state"

# Estado de PostgreSQL
az postgres flexible-server show --name pg-econeura-full-staging --resource-group rg-econeura-full-staging --query "state"

# Estado de Redis
az redis show --name redis-econeura-full-staging --resource-group rg-econeura-full-staging --query "provisioningState"
```

### Script de Corrección Automática

```powershell
# Ejecutar script de corrección
.\scripts\fix-common-issues.ps1 -ResourceGroup "rg-econeura-full-staging" -Environment "staging" -FixAll
```

---

## 📞 SOPORTE Y LOGS

### Ver Logs en Tiempo Real

```powershell
az webapp log tail `
  --name app-econeura-full-staging-backend `
  --resource-group rg-econeura-full-staging
```

### Ver Logs de Application Insights

1. Ir a Azure Portal
2. Application Insights → appi-econeura-full-staging
3. Logs → Ejecutar queries Kusto (ver `docs/KUSTO-QUERIES.md`)

### Ver Logs de PostgreSQL

```powershell
az postgres flexible-server server-logs list `
  --name pg-econeura-full-staging `
  --resource-group rg-econeura-full-staging
```

---

**Última actualización:** 2025-11-16  
**Scripts disponibles:** `scripts/validate-pre-deploy.ps1`, `scripts/validate-azure-resources.ps1`, `scripts/health-check-complete.ps1`, `scripts/fix-common-issues.ps1`

