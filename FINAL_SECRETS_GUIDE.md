# 🔐 GUÍA FINAL DE SECRETOS (ECONEURA-GO)

**Estado**: 7 Secretos Listos / 3 Faltantes
**Acción Requerida**: Obtener los 3 faltantes y configurar todo en GitHub.

## ✅ 1. Secretos que YA TIENES (7)
Configura estos inmediatamente en GitHub:

| Nombre | Valor (Confirmado por ti) |
| :--- | :--- |
| `AZURE_WEBAPP_NAME_BACKEND` | `econeura-backend-production` |
| `GEMINI_API_KEY` | (Tu clave API) |
| `NODE_ENV` | `production` |
| `REDIS_HOST` | `econeuraredisproduction.redis.cache.windows.net` |
| `REDIS_PASSWORD` | (Tu contraseña de Redis) |
| `REDIS_PORT` | `6380` |
| `USE_MEMORY_STORE` | `false` |

## ❌ 2. Secretos que FALTAN (3)
Necesitas obtener estos valores de Azure.

### Opción A: Automática (Recomendada)
He creado un script para ti.
1.  Abre PowerShell.
2.  Ejecuta `az login` (inicia sesión en tu cuenta Azure).
3.  Ejecuta:
    ```powershell
    ./scripts/generate-missing-secrets.ps1
    ```
    *Esto generará 3 archivos con los valores que necesitas.*

### Opción B: Manual (Si falla el script)

| Nombre | Cómo obtenerlo |
| :--- | :--- |
| `AZURE_CREDENTIALS` | Ejecuta: `az ad sp create-for-rbac --name "econeura-gh" --role contributor --scopes /subscriptions/[TU_ID] --sdk-auth` |
| `AZURE_WEBAPP_PUBLISH_PROFILE_BACKEND` | Ve al Portal Azure > App Service > "Get publish profile" (Descargar XML) |
| `AZURE_STATIC_WEB_APPS_API_TOKEN` | Ve al Portal Azure > Static Web App > "Manage deployment token" |

---
**Una vez tengas los 10 secretos configurados en GitHub, el despliegue funcionará automáticamente.**
