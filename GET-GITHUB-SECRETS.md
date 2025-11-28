# 🔑 GUÍA COMPLETA: OBTENER SECRETOS GITHUB DESDE AZURE

**Ejecutar DESPUÉS de que termine el deployment Bicep**

---

## ✅ SECRETOS YA CONFIGURADOS (5)

1. ✅ GEMINI_API_KEY → [tu clave]
2. ✅ NODE_ENV → `production`
3. ✅ USE_MEMORY_STORE → `false`
4. ✅ REDIS_PORT → `6380`
5. ✅ AZURE_WEBAPP_NAME_BACKEND → `econeura-backend-production`
6. ✅ AZURE_CREDENTIALS → [JSON del service principal]

---

## 📋 SECRETOS PENDIENTES (9)

### 1. DATABASE_URL

**Ejecutar**:
```powershell
# Obtener host de PostgreSQL
$dbHost = az postgres flexible-server show `
  --resource-group econeura-rg `
  --name econeura-psql-production `
  --query "fullyQualifiedDomainName" -o tsv

# Construir connection string
$dbUrl = "postgresql://econadmin:EcoNeura2025!Secure@$dbHost:5432/econeura_db?sslmode=require"
Write-Host $dbUrl
```

**Copiar** todo el output y pegarlo en GitHub Secrets → `DATABASE_URL`

---

### 2. REDIS_HOST

**Ejecutar**:
```powershell
az redis show `
  --name econeura-redis-production `
  --resource-group econeura-rg `
  --query "hostName" -o tsv
```

**Copiar** el resultado (ej: `econeura-redis-production.redis.cache.windows.net`)

---

### 3. REDIS_PASSWORD

**Ejecutar**:
```powershell
az redis list-keys `
  --name econeura-redis-production `
  --resource-group econeura-rg `
  --query "primaryKey" -o tsv
```

**Copiar** la clave primaria

---

### 4. AZURE_STORAGE_CONNECTION_STRING

**Ejecutar**:
```powershell
az storage account show-connection-string `
  --name econeurastorageprod `
  --resource-group econeura-rg -o tsv
```

**Copiar** todo el connection string

---

### 5. APPLICATIONINSIGHTS_CONNECTION_STRING

**Ejecutar**:
```powershell
az monitor app-insights component show `
  --app econeura-insights-production `
  --resource-group econeura-rg `
  --query "connectionString" -o tsv
```

**Copiar** el connection string completo

---

### 6. AZURE_APP_SERVICE_URL

**Ejecutar**:
```powershell
$backendHost = az webapp show `
  --name econeura-backend-production `
  --resource-group econeura-rg `
  --query "defaultHostName" -o tsv

Write-Host "https://$backendHost"
```

**Copiar** la URL completa con `https://`

---

### 7. AZURE_STATIC_WEB_APP_URL

**Ejecutar**:
```powershell
$frontendHost = az staticwebapp show `
  --name econeura-frontend-production `
  --resource-group econeura-rg `
  --query "defaultHostname" -o tsv

Write-Host "https://$frontendHost"
```

**Copiar** la URL completa con `https://`

---

### 8. AZURE_STATIC_WEB_APPS_API_TOKEN

**Ejecutar**:
```powershell
az staticwebapp secrets list `
  --name econeura-frontend-production `
  --resource-group econeura-rg `
  --query "properties.apiKey" -o tsv
```

**Copiar** el token API

---

### 9. AZURE_WEBAPP_PUBLISH_PROFILE_BACKEND

**Ejecutar**:
```powershell
az webapp deployment list-publishing-profiles `
  --name econeura-backend-production `
  --resource-group econeura-rg `
  --xml
```

**Copiar** TODO el XML que devuelve (será largo, ~100 líneas)

---

## 🚀 SCRIPT AUTOMATIZADO TODO-EN-UNO

Para obtener TODOS los valores de una vez:

```powershell
# SCRIPT AUTOMATIZADO - OBTENER TODOS LOS SECRETOS
Write-Host "=== SECRETOS GITHUB DESDE AZURE ===" -ForegroundColor Cyan

# 1. DATABASE_URL
Write-Host "`n1. DATABASE_URL:" -ForegroundColor Yellow
$dbHost = az postgres flexible-server show --resource-group econeura-rg --name econeura-psql-production --query "fullyQualifiedDomainName" -o tsv
$dbUrl = "postgresql://econadmin:EcoNeura2025!Secure@$dbHost:5432/econeura_db?sslmode=require"
Write-Host $dbUrl -ForegroundColor Green

# 2. REDIS_HOST
Write-Host "`n2. REDIS_HOST:" -ForegroundColor Yellow
$redisHost = az redis show --name econeura-redis-production --resource-group econeura-rg --query "hostName" -o tsv
Write-Host $redisHost -ForegroundColor Green

# 3. REDIS_PASSWORD
Write-Host "`n3. REDIS_PASSWORD:" -ForegroundColor Yellow
$redisPass = az redis list-keys --name econeura-redis-production --resource-group econeura-rg --query "primaryKey" -o tsv
Write-Host $redisPass -ForegroundColor Green

# 4. AZURE_STORAGE_CONNECTION_STRING
Write-Host "`n4. AZURE_STORAGE_CONNECTION_STRING:" -ForegroundColor Yellow
$storageConn = az storage account show-connection-string --name econeurastorageprod --resource-group econeura-rg -o tsv
Write-Host $storageConn -ForegroundColor Green

# 5. APPLICATIONINSIGHTS_CONNECTION_STRING
Write-Host "`n5. APPLICATIONINSIGHTS_CONNECTION_STRING:" -ForegroundColor Yellow
$aiConn = az monitor app-insights component show --app econeura-insights-production --resource-group econeura-rg --query "connectionString" -o tsv
Write-Host $aiConn -ForegroundColor Green

# 6. AZURE_APP_SERVICE_URL
Write-Host "`n6. AZURE_APP_SERVICE_URL:" -ForegroundColor Yellow
$backendHost = az webapp show --name econeura-backend-production --resource-group econeura-rg --query "defaultHostName" -o tsv
Write-Host "https://$backendHost" -ForegroundColor Green

# 7. AZURE_STATIC_WEB_APP_URL
Write-Host "`n7. AZURE_STATIC_WEB_APP_URL:" -ForegroundColor Yellow
$frontendHost = az staticwebapp show --name econeura-frontend-production --resource-group econeura-rg --query "defaultHostname" -o tsv
Write-Host "https://$frontendHost" -ForegroundColor Green

# 8. AZURE_STATIC_WEB_APPS_API_TOKEN
Write-Host "`n8. AZURE_STATIC_WEB_APPS_API_TOKEN:" -ForegroundColor Yellow
$swaToken = az staticwebapp secrets list --name econeura-frontend-production --resource-group econeura-rg --query "properties.apiKey" -o tsv
Write-Host $swaToken -ForegroundColor Green

Write-Host "`n=== COPIANDO AL PORTAPAPELES ===" -ForegroundColor Cyan
$allSecrets = @"
DATABASE_URL=$dbUrl
REDIS_HOST=$redisHost
REDIS_PASSWORD=$redisPass
AZURE_STORAGE_CONNECTION_STRING=$storageConn
APPLICATIONINSIGHTS_CONNECTION_STRING=$aiConn
AZURE_APP_SERVICE_URL=https://$backendHost
AZURE_STATIC_WEB_APP_URL=https://$frontendHost
AZURE_STATIC_WEB_APPS_API_TOKEN=$swaToken
"@

Set-Clipboard $allSecrets
Write-Host "Todos los secretos copiados al portapapeles!" -ForegroundColor Green
Write-Host "Pegalo en un archivo de texto para referenciar" -ForegroundColor Yellow
```

Guarda esto como `get-all-secrets.ps1` y ejecútalo después del deployment.

---

## ⚠️ IMPORTANTE

**Nota sobre AZURE_WEBAPP_PUBLISH_PROFILE_BACKEND**:

Este es XML largo. Ejecútalo separado:
```powershell
az webapp deployment list-publishing-profiles --name econeura-backend-production --resource-group econeura-rg --xml > publish-profile.xml
notepad publish-profile.xml
```

Luego copia TODO el contenido del archivo XML a GitHub Secrets.

---

## ✅ CHECKLIST FINAL

- [ ] Esperar a que termine deployment Bicep (~15 min)
- [ ] Ejecutar `get-all-secrets.ps1`
- [ ] Copiar cada valor a GitHub Secrets
- [ ] Obtener publish profile separadamente
- [ ] Verificar que los 15 secretos estén configurados
- [ ] Hacer push a GitHub para activar workflow

---

**Total secretos**: 15  
**Ya configurados**: 6 ✅  
**Pendientes**: 9 (se obtienen con este script)
