# 🔐 Comandos Manuales (Solución Error MFA)

El script falló porque tu organización requiere **Autenticación Multifactor (MFA)** y bloquea la automatización.
Debes ejecutar estos comandos **manualmente** en tu terminal para aprobar el acceso en tu móvil/navegador.

## 1. Login Fresco (Requerido)
Ejecuta esto primero para renovar tu token:
```powershell
az login
```

## 2. Obtener `AZURE_CREDENTIALS`
Copia y pega este comando exacto:
```powershell
az ad sp create-for-rbac --name "econeura-gh-actions" --role contributor --scopes /subscriptions/a0991f95-16e0-4f03-85df-db3d69004d94 --sdk-auth
```
👉 **Acción:** Copia todo el JSON resultante (desde `{` hasta `}`) y guárdalo en GitHub.

## 3. Obtener `AZURE_WEBAPP_PUBLISH_PROFILE_BACKEND`
```powershell
az webapp deployment list-publishing-profiles --name econeura-backend-production --resource-group econeura-rg --xml
```
👉 **Acción:** Copia todo el XML resultante y guárdalo en GitHub.

## 4. Obtener `AZURE_STATIC_WEB_APPS_API_TOKEN`
```powershell
az staticwebapp secrets list --name econeura-frontend --resource-group econeura-rg --query "properties.apiKey" --output tsv
```
👉 **Acción:** Copia el token alfanumérico y guárdalo en GitHub.

---
**Resumen de Secretos Faltantes:**
1.  `AZURE_CREDENTIALS`
2.  `AZURE_WEBAPP_PUBLISH_PROFILE_BACKEND`
3.  `AZURE_STATIC_WEB_APPS_API_TOKEN`

(Los otros 7 ya los tienes listos).
