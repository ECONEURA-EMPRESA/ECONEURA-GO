## Infraestructura Azure – ECONEURA-FULL (visión 2025)

Esta sección describe cómo se mapea la arquitectura de `ECONEURA-FULL` a recursos de Azure,
tomando como referencia el despliegue actual de ECONEURA (`App Service + PostgreSQL + Static Web Apps`)
y extendiéndolo con Event Sourcing mínimo.

### Recursos principales

- **App Service Backend**  
  - Hospeda el backend Node.js (`packages/backend`).  
  - Usa `DATABASE_URL` para conectar con PostgreSQL.  
  - Tendrá acceso a Key Vault para secretos (OpenAI keys, cadenas de conexión, etc.).

- **Static Web App / App Service Frontend**  
  - Hospeda el frontend React (`packages/frontend`).  
  - Se comunica con el backend vía HTTPS (ruta `/api/*`).

- **PostgreSQL (DB transaccional)**  
  - Equivalente a la tabla `users/sessions/chats` del `schema.sql` actual.  
  - Conectado mediante `DATABASE_URL` validado en `envSchema.ts`.

- **Cosmos DB (Event Store + Read Models - futuro)**  
  - Event Store: contenedor para eventos de dominio (por ejemplo, conversaciones).  
    - Configuración vía:
      - `EVENTSTORE_COSMOS_ENDPOINT`
      - `EVENTSTORE_COSMOS_KEY`
      - `EVENTSTORE_COSMOS_DATABASE_ID`
      - `EVENTSTORE_COSMOS_CONTAINER_ID`
  - Read Models: contenedor para proyecciones denormalizadas.
    - Configuración vía:
      - `READMODELS_COSMOS_ENDPOINT`
      - `READMODELS_COSMOS_KEY`
      - `READMODELS_COSMOS_DATABASE_ID`
      - `READMODELS_COSMOS_CONTAINER_ID`

- **Key Vault**  
  - Almacena secretos críticos: `OPENAI_API_KEY`, `DATABASE_URL`, claves de Cosmos, etc.

- **Monitoring (Application Insights / Log Analytics)**  
  - Recibe logs del backend (logger estructurado) y métricas de disponibilidad/errores.

### Bicep (Fase 7)

En la Fase 7 se ha creado un `main.bicep` que orquesta módulos a nivel de **Resource Group**:

- `core.bicep`: Resource Group, naming, tags.  
- `monitoring.bicep`: Log Analytics + Application Insights, exportando `appInsightsConnectionString`.  
- `database.bicep`: PostgreSQL Flexible Server + database, exportando `databaseHost` y `databaseName` (sin credenciales).  
- `keyvault.bicep`: Key Vault y dos secrets dummy (`OPENAI_API_KEY`, `DATABASE_URL`).  
- `app-backend.bicep`: App Service backend (Linux, B1) consumiendo `appInsightsConnectionString` y documentando el formato de `DATABASE_URL`.  
- `app-frontend.bicep`: Static Web App frontend con `VITE_API_URL` configurable vía settings y CI/CD.  
- `eventstore.bicep`: Cosmos DB para Event Store.  
- `readmodels.bicep`: Cosmos DB para Read Models.  

### Estrategia de Despliegue: Bicep vs CLI

**Recursos desplegados vía Bicep:**
- Resource Group (`rg-econeura-full-{environment}`)
- Key Vault (`kv-econeura-full-{environment}`)
- Log Analytics Workspace + Application Insights
- App Service Plan + App Service (backend)
- Static Web App (frontend)
- Cosmos DB (EventStore y ReadModels)

**Recursos desplegados vía CLI (por restricciones de ubicación o nombres):**
- PostgreSQL Flexible Server: debido a restricciones de ubicación (`westeurope` no disponible), se crea manualmente con:
  ```bash
  az postgres flexible-server create \
    --resource-group rg-econeura-full-staging \
    --name pg-econeura-full-staging-ne \
    --location northeurope \
    --admin-user econeuraadmin \
    --admin-password <password> \
    --sku-name Standard_B1ms \
    --tier Burstable \
    --version 16
  ```

**Nota:** En futuras iteraciones, el PostgreSQL se puede incluir en Bicep usando `northeurope` como ubicación por defecto, o parametrizando la ubicación.

El workflow `.github/workflows/infra-deploy.yml` ejecuta:

- `az deployment group create` contra un `resourceGroupName` existente.  
- `main.bicep` con parámetros `environment`, `location` y `baseName`.  

La `DATABASE_URL` final que valida `envSchema.ts` se construye a partir de:

- `databaseHost` y `databaseName` (outputs de `database.bicep` o valores conocidos si se creó vía CLI).  
- Usuario/password gestionados como secrets (Key Vault o GitHub Secrets), no en el template.

### Checklist de GitHub Secrets

Para que los workflows de CI/CD funcionen correctamente, se requieren los siguientes secrets en GitHub:

**Infraestructura (`infra-deploy.yml`):**
- `AZURE_CREDENTIALS`: Service principal JSON con permisos de `Owner` o `Contributor` sobre el Resource Group.

**Aplicación (`app-deploy.yml`):**
- `AZURE_CREDENTIALS`: Mismo que arriba.
- `AZURE_WEBAPP_NAME_BACKEND`: Nombre del App Service backend (ej: `app-econeura-full-staging-backend`).
- `AZURE_WEBAPP_PUBLISH_PROFILE_BACKEND`: Publish profile XML del App Service backend (descargado desde Azure Portal).
- `AZURE_STATIC_WEB_APPS_API_TOKEN`: Token de Static Web Apps (generado desde Azure Portal → Static Web App → Manage deployment token).

**Runtime (Key Vault o GitHub Secrets):**
- `DATABASE_URL`: Connection string completa de PostgreSQL (formato: `postgresql://user:password@host:port/database?sslmode=require`).
- `OPENAI_API_KEY`: API key de OpenAI.
- `EVENTSTORE_COSMOS_ENDPOINT`: (Opcional, futuro) Endpoint de Cosmos DB para Event Store.
- `EVENTSTORE_COSMOS_KEY`: (Opcional, futuro) Key de Cosmos DB para Event Store.
- `READMODELS_COSMOS_ENDPOINT`: (Opcional, futuro) Endpoint de Cosmos DB para Read Models.
- `READMODELS_COSMOS_KEY`: (Opcional, futuro) Key de Cosmos DB para Read Models.

**Nota:** Los secrets de runtime se pueden gestionar vía Key Vault (recomendado para producción) o directamente en GitHub Secrets (útil para desarrollo/staging). El backend lee estos valores desde variables de entorno validadas por `envSchema.ts`.


