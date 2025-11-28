## CI/CD ECONEURA-FULL

Este documento resume el flujo de CI/CD pensado para ECONEURA-FULL.

### CI Backend

- Workflow: `.github/workflows/backend-ci.yml`
- Disparadores:
  - `push` / `pull_request` sobre `packages/backend/**`, `tsconfig.base.json`, `package.json`.
- Pasos:
  - `npm install`
  - `npm run type-check:backend`
  - `npm run test:backend`

### CI Frontend

- Workflow: `.github/workflows/frontend-ci.yml`
- Disparadores:
  - `push` / `pull_request` sobre `packages/frontend/**`, `tsconfig.base.json`, `package.json`.
- Pasos:
  - `npm install`
  - `npm run type-check:frontend`

### Despliegue de Infraestructura

- Workflow: `.github/workflows/infra-deploy.yml`
- Disparador:
  - `workflow_dispatch` con input `environment` (`dev`/`staging`/`prod`).
  - `resourceGroupName` (Resource Group existente donde desplegar).
- Requiere:
  - `AZURE_CREDENTIALS` configurado en GitHub Secrets (service principal con permisos sobre el RG).
- Acción:
  - `az deployment group create` sobre el RG indicado con `infrastructure/azure/main.bicep` (scope grupo de recursos).

### Despliegue de Aplicación

- Workflow: `.github/workflows/app-deploy.yml`
- Disparador:
  - `workflow_dispatch` con input `environment`.
- Pasos actuales:
  - `npm install`
  - `npm run build:backend`
  - `npm run build:frontend`
  - Deploy backend a App Service con `azure/webapps-deploy@v3`.
  - Deploy frontend a Static Web Apps con `Azure/static-web-apps-deploy@v1`.
  - Smoke tests HTTP:
    - `GET /health` → verifica que el backend responde.
    - `GET /api/neuras/neura-ceo/chat` (mockeado o con token dev) → verifica que la cadena completa funciona.

### Smoke Tests Post-Deploy

Los smoke tests se ejecutan después de cada despliegue para verificar que:
1. El backend está levantado y responde en `/health`.
2. Los endpoints de API están accesibles (aunque sea con autenticación mock en dev).
3. El frontend se ha desplegado correctamente (verificación manual o automatizada).

**Nota:** En producción, los smoke tests deberían usar tokens reales o un usuario de prueba con permisos limitados.

### Secrets Requeridos

**Infraestructura:**
- `AZURE_CREDENTIALS` – Service principal JSON para login (formato: `{"clientId":"...","clientSecret":"...","subscriptionId":"...","tenantId":"..."}`).

**Aplicación:**
- `AZURE_WEBAPP_NAME_BACKEND` – Nombre del App Service backend (ej: `app-econeura-full-staging-backend`).
- `AZURE_WEBAPP_PUBLISH_PROFILE_BACKEND` – Publish profile XML del App Service backend (descargado desde Azure Portal → App Service → Get publish profile).
- `AZURE_STATIC_WEB_APPS_API_TOKEN` – Token de Static Web Apps (generado desde Azure Portal → Static Web App → Manage deployment token).

**Runtime (Key Vault o GitHub Secrets):**
- `DATABASE_URL` – Connection string completa de PostgreSQL.
- `OPENAI_API_KEY` – API key de OpenAI.
- `EVENTSTORE_COSMOS_ENDPOINT`, `EVENTSTORE_COSMOS_KEY` – (Opcional, futuro) Para Event Store.
- `READMODELS_COSMOS_ENDPOINT`, `READMODELS_COSMOS_KEY` – (Opcional, futuro) Para Read Models.

**Nota:** Los secrets de runtime se validan en `packages/backend/src/config/envSchema.ts` usando Zod. Si faltan, el backend no arrancará con un error claro.


