# 🔐 SECRETOS LISTOS PARA COPIAR A GITHUB

**Repositorio:** `https://github.com/ECONEURA-EMPRESA/ECONEURA-GO`
**Ubicación:** Settings → Secrets and variables → Actions → New repository secret

---

## ✅ Secretos que YA TIENES (7) - No tocar
- `AZURE_WEBAPP_NAME_BACKEND`
- `GEMINI_API_KEY`
- `NODE_ENV`
- `REDIS_HOST`
- `REDIS_PASSWORD`
- `REDIS_PORT`
- `USE_MEMORY_STORE`

---

## ❌ Secretos que FALTAN (3) - COPIAR AHORA

### 1. AZURE_CREDENTIALS
**Nombre del secreto:** `AZURE_CREDENTIALS`

**Valor (JSON):**
```json
{
  "clientId": "9551aadf-6690-4a4b-8635-9e4f15643db3",
  "clientSecret": "TU_CLIENT_SECRET_AQUI",
  "subscriptionId": "a0991f95-16e0-4f03-85df-db3d69004d94",
  "tenantId": "d35f8c15-6e8e-4d56-b7e9-2d64fdfc213e",
  "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
  "resourceManagerEndpointUrl": "https://management.azure.com/",
  "activeDirectoryGraphResourceId": "https://graph.windows.net/",
  "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
  "galleryEndpointUrl": "https://gallery.azure.com/",
  "managementEndpointUrl": "https://management.core.windows.net/"
}
```

⚠️ **ACCIÓN REQUERIDA:** 
1. Ve a Azure Portal → Azure AD → App registrations → "Econeura-Deploy-Agent"
2. Copia el VALOR del Client Secret (no el ID)
3. Reemplaza `TU_CLIENT_SECRET_AQUI` con ese valor
4. Copia TODO el JSON a GitHub

---

### 2. AZURE_WEBAPP_PUBLISH_PROFILE_BACKEND
**Nombre del secreto:** `AZURE_WEBAPP_PUBLISH_PROFILE_BACKEND`

**Valor:**
- Abre el archivo XML que descargaste del App Service
- Copia TODO el contenido del archivo XML
- Pégalo como valor del secreto

---

### 3. AZURE_STATIC_WEB_APPS_API_TOKEN
**Nombre del secreto:** `AZURE_STATIC_WEB_APPS_API_TOKEN`

**Valor:**
```
6577944fbde61d73c641e7d45464a81d0c78ab6fcd9e9c966f27fa95f09efb03-281f04...
```
⚠️ Copia el token COMPLETO que copiaste al portapapeles

---

## 📋 CHECKLIST DE CONFIGURACIÓN

- [ ] 1. Obtener el Client Secret REAL de Azure AD
- [ ] 2. Crear secreto `AZURE_CREDENTIALS` con el JSON completo
- [ ] 3. Crear secreto `AZURE_WEBAPP_PUBLISH_PROFILE_BACKEND` con el XML
- [ ] 4. Crear secreto `AZURE_STATIC_WEB_APPS_API_TOKEN` con el token completo
- [ ] 5. Verificar que hay 10 secretos en total en GitHub

---
**Una vez tengas los 10 secretos configurados, el deployment a Azure será automático en el próximo push.**
