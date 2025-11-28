## Seguridad en ECONEURA-FULL

Este documento resume las prácticas de seguridad mínimas que deben cumplirse al trabajar con ECONEURA-FULL.

### Gestión de secretos

- Ningún secreto (API keys, cadenas de conexión, credenciales) debe commitearse al repositorio.
- Todos los secretos deben almacenarse en **Azure Key Vault** y exponerse al runtime vía:
  - App Service / Static Web App settings.
  - Variables de entorno seguras en GitHub Actions.
- Variables críticas (por ejemplo `OPENAI_API_KEY`, connection strings de DB, Redis, EventStore) se validan en runtime con Zod en `src/config/envSchema.ts`.

### Acceso a entornos

- Acceso a suscripción Azure solo mediante cuentas corporativas o Service Principals con permisos mínimos necesarios.
- Los pipelines de CI/CD usan un Service Principal dedicado con permisos limitados al Resource Group de ECONEURA.
- El acceso a producción debe estar protegido mediante RBAC de Azure y registros de auditoría.

### Autenticación y autorización

- El backend implementará un modelo de `User` + `Tenant` + `Role` + `Permission` (ver `docs/RBAC-MODEL.md`).
- Las rutas críticas (ejecución de agentes, acceso a conversaciones, configuración NEURAS) deben protegerse con middleware de auth + RBAC.

### Logging y auditoría

- Todo logging debe usar el logger estructurado (`src/shared/logger.ts`), nunca `console.log` en código de producción.
- Acciones sensibles (ejecución de agentes, cambios de roles, login admin) deben generar eventos de auditoría (`src/audit`).

### Reporte de vulnerabilidades

- Los problemas de seguridad detectados deben reportarse de forma privada al propietario del repositorio, no vía issues públicos.
- Cualquier cambio relacionado con seguridad debe documentarse en `CHANGELOG.md` y, si aplica, en `SECURITY.md`.


