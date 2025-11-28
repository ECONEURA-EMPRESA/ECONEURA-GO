# 🚨 LISTA EXHAUSTIVA DE FALLOS - GITHUB Y AZURE

**Fecha:** 2025-11-16  
**Proyecto:** ECONEURA-FULL  
**Objetivo:** Identificar TODOS los posibles fallos al implementar en GitHub y Azure

---

## 📋 ÍNDICE

1. [Fallos en GitHub Actions](#1-fallos-en-github-actions)
2. [Fallos en Azure Deployment (Bicep)](#2-fallos-en-azure-deployment-bicep)
3. [Fallos de Secrets y Variables de Entorno](#3-fallos-de-secrets-y-variables-de-entorno)
4. [Fallos de Permisos y Autenticación](#4-fallos-de-permisos-y-autenticación)
5. [Fallos de Conectividad y Red](#5-fallos-de-conectividad-y-red)
6. [Fallos de Recursos Azure](#6-fallos-de-recursos-azure)
7. [Fallos de Build y Compilación](#7-fallos-de-build-y-compilación)
8. [Fallos de Runtime y Aplicación](#8-fallos-de-runtime-y-aplicación)
9. [Fallos de Integración](#9-fallos-de-integración)
10. [Fallos de Costos y Límites](#10-fallos-de-costos-y-límites)

---

## 1. FALLOS EN GITHUB ACTIONS

### 1.1 Workflow: `backend-ci.yml`

#### ❌ **Fallo 1.1.1: Node.js no encontrado**
- **Síntoma:** `Error: Node.js version '20' not found`
- **Causa:** GitHub Actions runner no tiene Node 20 disponible
- **Solución:** Cambiar a `node-version: '20.x'` o usar versión disponible

#### ❌ **Fallo 1.1.2: npm install falla**
- **Síntoma:** `npm ERR! code ERESOLVE` o `npm ERR! network`
- **Causas:**
  - Dependencias incompatibles
  - Red bloqueada
  - `package-lock.json` corrupto
- **Solución:** 
  - `npm ci` en lugar de `npm install`
  - Verificar `package-lock.json` está commitado
  - Revisar dependencias en `package.json`

#### ❌ **Fallo 1.1.3: Type-check falla**
- **Síntoma:** `error TS2345: Type 'X' is not assignable to type 'Y'`
- **Causas:**
  - Errores de TypeScript no resueltos
  - `tsconfig.json` mal configurado
  - Dependencias de tipos faltantes
- **Solución:**
  - Ejecutar `npm run type-check:backend` localmente antes de commit
  - Verificar `tsconfig.base.json` y `packages/backend/tsconfig.json`

#### ❌ **Fallo 1.1.4: Tests fallan**
- **Síntoma:** `FAIL tests/unit/xxx.test.ts`
- **Causas:**
  - Tests no actualizados
  - Mocks incorrectos
  - Variables de entorno faltantes en tests
- **Solución:**
  - Ejecutar tests localmente: `npm run test:backend`
  - Verificar `.env.test` o mocks

#### ❌ **Fallo 1.1.5: Lint falla**
- **Síntoma:** `ESLint found X problems`
- **Causa:** Código no cumple reglas de linting
- **Solución:**
  - Ejecutar `npm run lint:backend` localmente
  - Corregir errores o ajustar reglas en `.eslintrc.cjs`

---

### 1.2 Workflow: `frontend-ci.yml`

#### ❌ **Fallo 1.2.1: Build frontend falla**
- **Síntoma:** `Error: Could not resolve entry module "index.html"`
- **Causa:** `packages/frontend/index.html` no existe o mal configurado
- **Solución:** Verificar que `index.html` existe y apunta a `src/main.tsx`

#### ❌ **Fallo 1.2.2: Bundle size excede límite**
- **Síntoma:** `Bundle size: 15MB` (muy grande)
- **Causa:** Dependencias grandes sin tree-shaking
- **Solución:**
  - Analizar bundle con `npm run build:frontend -- --analyze`
  - Optimizar imports
  - Code splitting

#### ❌ **Fallo 1.2.3: Type-check frontend falla**
- **Síntoma:** `error TS2307: Cannot find module 'react'`
- **Causa:** Dependencias de tipos faltantes
- **Solución:** Verificar `@types/react`, `@types/react-dom` en `devDependencies`

---

### 1.3 Workflow: `app-deploy.yml`

#### ❌ **Fallo 1.3.1: Secret faltante**
- **Síntoma:** `❌ AZURE_CREDENTIALS is missing`
- **Causa:** Secret no configurado en GitHub
- **Solución:**
  - Ir a `Settings → Secrets and variables → Actions`
  - Agregar `AZURE_CREDENTIALS` (Service Principal JSON)

#### ❌ **Fallo 1.3.2: Azure Login falla**
- **Síntoma:** `Error: Invalid service principal credentials`
- **Causas:**
  - `AZURE_CREDENTIALS` mal formateado
  - Service Principal expirado
  - Permisos insuficientes
- **Solución:**
  - Verificar formato JSON válido
  - Regenerar Service Principal: `az ad sp create-for-rbac --sdk-auth`
  - Verificar permisos: `Owner` o `Contributor` en Resource Group

#### ❌ **Fallo 1.3.3: Build backend falla en CI**
- **Síntoma:** `❌ Backend build failed: dist folder not found`
- **Causas:**
  - Errores de TypeScript
  - `tsconfig.json` mal configurado
  - Dependencias faltantes
- **Solución:**
  - Verificar que `npm run build:backend` funciona localmente
  - Revisar `packages/backend/tsconfig.json`

#### ❌ **Fallo 1.3.4: Deploy backend falla**
- **Síntoma:** `Error: Failed to deploy to Azure App Service`
- **Causas:**
  - `AZURE_WEBAPP_NAME_BACKEND` incorrecto
  - `AZURE_WEBAPP_PUBLISH_PROFILE_BACKEND` inválido
  - App Service no existe
- **Solución:**
  - Verificar nombre del App Service en Azure Portal
  - Descargar nuevo Publish Profile desde Azure Portal
  - Verificar que App Service existe

#### ❌ **Fallo 1.3.5: Deploy frontend falla**
- **Síntoma:** `Error: Failed to deploy to Static Web App`
- **Causas:**
  - `AZURE_STATIC_WEB_APPS_API_TOKEN` inválido o expirado
  - Ruta `app_location` incorrecta
  - Static Web App no existe
- **Solución:**
  - Regenerar token: Azure Portal → Static Web App → Manage deployment token
  - Verificar `app_location: "packages/frontend"` en workflow
  - Verificar que Static Web App existe

#### ❌ **Fallo 1.3.6: Health check falla**
- **Síntoma:** `❌ Backend no respondió después de 5 minutos`
- **Causas:**
  - Backend no arrancó correctamente
  - Variables de entorno faltantes
  - Puerto incorrecto
  - Error en código de arranque
- **Solución:**
  - Verificar logs: `az webapp log tail --name APP_NAME`
  - Verificar variables de entorno en App Service
  - Verificar que `/health` endpoint existe

#### ❌ **Fallo 1.3.7: Smoke test falla**
- **Síntoma:** `API endpoint returned HTTP 500`
- **Causas:**
  - Backend con errores
  - Base de datos no conectada
  - Redis no disponible
  - Secrets faltantes
- **Solución:**
  - Revisar logs de Application Insights
  - Verificar conexión a PostgreSQL
  - Verificar `REDIS_URL` si se usa

---

### 1.4 Workflow: `infra-deploy.yml`

#### ❌ **Fallo 1.4.1: Resource Group no existe**
- **Síntoma:** `❌ Resource Group 'rg-xxx' does not exist`
- **Causa:** Resource Group no creado previamente
- **Solución:** El workflow intenta crearlo automáticamente, pero puede fallar si:
  - Location no disponible
  - Nombre ya existe en otra suscripción
  - Permisos insuficientes

#### ❌ **Fallo 1.4.2: Bicep deployment falla**
- **Síntoma:** `Error: Deployment failed`
- **Causas:**
  - Parámetros inválidos
  - Recursos ya existen con nombres conflictivos
  - Location no disponible para el servicio
  - SKU no disponible en la región
- **Solución:**
  - Verificar parámetros en workflow
  - Verificar que nombres de recursos son únicos
  - Cambiar location si no está disponible
  - Verificar SKU disponible: `az vm list-skus --location westeurope`

#### ❌ **Fallo 1.4.3: PostgreSQL deployment falla**
- **Síntoma:** `Error: LocationIsOfferRestricted`
- **Causa:** PostgreSQL Flexible Server no disponible en la región
- **Solución:**
  - Cambiar location: `northeurope`, `eastus`, etc.
  - Verificar disponibilidad: `az postgres flexible-server list-skus --location westeurope`

#### ❌ **Fallo 1.4.4: Key Vault deployment falla**
- **Síntoma:** `Error: BadRequest` o `DeploymentFailed`
- **Causas:**
  - Nombre de Key Vault no válido (debe ser único globalmente)
  - Políticas de acceso no configuradas
- **Solución:**
  - Usar nombre único: `kv-{baseName}-{environment}-{random}`
  - Verificar que no existe otro Key Vault con el mismo nombre

---

## 2. FALLOS EN AZURE DEPLOYMENT (BICEP)

### 2.1 Errores de Sintaxis Bicep

#### ❌ **Fallo 2.1.1: Sintaxis Bicep inválida**
- **Síntoma:** `Error: The language expression is invalid`
- **Causa:** Sintaxis incorrecta en archivo `.bicep`
- **Solución:**
  - Validar Bicep: `az bicep build --file infrastructure/azure/main.bicep`
  - Revisar documentación: https://learn.microsoft.com/azure/azure-resource-manager/bicep/

#### ❌ **Fallo 2.1.2: Parámetros faltantes**
- **Síntoma:** `Error: Missing required parameter 'postgresAdminPassword'`
- **Causa:** Parámetro requerido no proporcionado
- **Solución:** Verificar que todos los parámetros `@description` sin `default` están en workflow

#### ❌ **Fallo 2.1.3: Referencias circulares**
- **Síntoma:** `Error: Circular dependency detected`
- **Causa:** Módulos Bicep se referencian entre sí circularmente
- **Solución:** Reorganizar dependencias en `main.bicep`

---

### 2.2 Errores de Recursos Azure

#### ❌ **Fallo 2.2.1: Nombre de recurso inválido**
- **Síntoma:** `Error: Invalid resource name`
- **Causas:**
  - Nombre demasiado largo (>63 caracteres)
  - Caracteres no permitidos
  - Nombre ya existe (debe ser único globalmente)
- **Solución:**
  - Usar nombres cortos: `{baseName}-{env}-{resource}`
  - Verificar reglas de naming por servicio
  - Agregar sufijo aleatorio si necesario

#### ❌ **Fallo 2.2.2: SKU no disponible**
- **Síntoma:** `Error: The requested tier is not available in this location`
- **Causa:** SKU no disponible en la región seleccionada
- **Solución:**
  - Listar SKUs disponibles: `az postgres flexible-server list-skus --location westeurope`
  - Cambiar SKU o location

#### ❌ **Fallo 2.2.3: Cuota excedida**
- **Síntoma:** `Error: Quota exceeded`
- **Causa:** Límite de recursos alcanzado en la suscripción
- **Solución:**
  - Verificar cuotas: `az vm list-usage --location westeurope`
  - Solicitar aumento de cuota
  - Eliminar recursos no usados

---

## 3. FALLOS DE SECRETS Y VARIABLES DE ENTORNO

### 3.1 GitHub Secrets

#### ❌ **Fallo 3.1.1: Secret no configurado**
- **Síntoma:** `Error: Secret 'AZURE_CREDENTIALS' not found`
- **Causa:** Secret no agregado en GitHub
- **Solución:**
  - Ir a `Settings → Secrets and variables → Actions`
  - Agregar todos los secrets requeridos (ver checklist abajo)

#### ❌ **Fallo 3.1.2: Secret mal formateado**
- **Síntoma:** `Error: Invalid JSON in AZURE_CREDENTIALS`
- **Causa:** JSON inválido o incompleto
- **Solución:**
  - Verificar formato JSON válido
  - Regenerar Service Principal: `az ad sp create-for-rbac --sdk-auth`

#### ❌ **Fallo 3.1.3: Secret expirado**
- **Síntoma:** `Error: Authentication failed`
- **Causa:** Service Principal o token expirado
- **Solución:**
  - Regenerar Service Principal
  - Regenerar Static Web Apps token

---

### 3.2 Azure App Service Settings

#### ❌ **Fallo 3.2.1: Variable de entorno faltante**
- **Síntoma:** `Error: OPENAI_API_KEY is required`
- **Causa:** Variable no configurada en App Service
- **Solución:**
  - Azure Portal → App Service → Configuration → Application settings
  - Agregar variable: `OPENAI_API_KEY=[REDACTED]`

#### ❌ **Fallo 3.2.2: Variable mal formateada**
- **Síntoma:** `Error: Invalid DATABASE_URL format`
- **Causa:** Connection string mal formateada
- **Solución:**
  - Formato correcto: `postgresql://user:password@host:5432/db?sslmode=require`
  - Verificar que no tiene espacios extra

#### ❌ **Fallo 3.2.3: Variable sobrescrita**
- **Síntoma:** Variable tiene valor incorrecto
- **Causa:** Múltiples fuentes (App Settings, Key Vault, workflow)
- **Solución:**
  - Verificar orden de precedencia
  - Usar Key Vault para secrets sensibles

---

### 3.3 Azure Key Vault

#### ❌ **Fallo 3.3.1: Key Vault no accesible**
- **Síntoma:** `Error: Access denied to Key Vault`
- **Causa:** Managed Identity sin permisos
- **Solución:**
  - Azure Portal → Key Vault → Access policies
  - Agregar App Service Managed Identity con permisos `Get` y `List`

#### ❌ **Fallo 3.3.2: Secret no existe en Key Vault**
- **Síntoma:** `Error: Secret 'OPENAI-API-KEY' not found`
- **Causa:** Secret no creado en Key Vault
- **Solución:**
  - Azure Portal → Key Vault → Secrets
  - Crear secret: `OPENAI-API-KEY` con valor

#### ❌ **Fallo 3.3.3: Key Vault URL incorrecta**
- **Síntoma:** `Error: Invalid KEY_VAULT_URL`
- **Causa:** URL mal formateada o incorrecta
- **Solución:**
  - Formato: `https://{vault-name}.vault.azure.net/`
  - Verificar en Azure Portal → Key Vault → Properties

---

## 4. FALLOS DE PERMISOS Y AUTENTICACIÓN

### 4.1 Service Principal

#### ❌ **Fallo 4.1.1: Permisos insuficientes**
- **Síntoma:** `Error: Authorization failed`
- **Causa:** Service Principal sin permisos `Owner` o `Contributor`
- **Solución:**
  - Azure Portal → Resource Group → Access control (IAM)
  - Agregar Service Principal con rol `Contributor`

#### ❌ **Fallo 4.1.2: Scope incorrecto**
- **Síntoma:** `Error: Cannot access resource outside scope`
- **Causa:** Service Principal limitado a un Resource Group pero intenta acceder a otro
- **Solución:**
  - Crear Service Principal con scope de suscripción o Resource Group correcto
  - Regenerar: `az ad sp create-for-rbac --scopes /subscriptions/{sub-id}/resourceGroups/{rg-name}`

---

### 4.2 Managed Identity

#### ❌ **Fallo 4.2.1: Managed Identity no habilitada**
- **Síntoma:** `Error: Managed Identity not enabled`
- **Causa:** App Service sin Managed Identity habilitada
- **Solución:**
  - Azure Portal → App Service → Identity
  - Habilitar "System assigned identity"

#### ❌ **Fallo 4.2.2: Managed Identity sin permisos**
- **Síntoma:** `Error: Access denied`
- **Causa:** Managed Identity sin permisos en Key Vault o Storage
- **Solución:**
  - Key Vault → Access policies → Agregar Managed Identity
  - Storage Account → Access control → Agregar Managed Identity con rol `Storage Blob Data Contributor`

---

## 5. FALLOS DE CONECTIVIDAD Y RED

### 5.1 PostgreSQL

#### ❌ **Fallo 5.1.1: Firewall bloquea conexión**
- **Síntoma:** `Error: Connection refused` o `timeout`
- **Causa:** Firewall de PostgreSQL no permite IP del App Service
- **Solución:**
  - Azure Portal → PostgreSQL → Networking
  - Agregar regla de firewall: `0.0.0.0 - 255.255.255.255` (temporal) o IP específica del App Service
  - Habilitar "Allow Azure services"

#### ❌ **Fallo 5.1.2: SSL requerido**
- **Síntoma:** `Error: SSL connection required`
- **Causa:** PostgreSQL requiere SSL pero connection string no lo especifica
- **Solución:**
  - Agregar `?sslmode=require` a `DATABASE_URL`
  - O deshabilitar SSL requirement (no recomendado en producción)

#### ❌ **Fallo 5.1.3: Credenciales incorrectas**
- **Síntoma:** `Error: password authentication failed`
- **Causa:** Usuario o password incorrectos
- **Solución:**
  - Verificar `POSTGRES_USER` y `POSTGRES_PASSWORD` en Key Vault
  - Resetear password: `az postgres flexible-server update --admin-password NEW_PASSWORD`

---

### 5.2 Redis

#### ❌ **Fallo 5.2.1: Redis no accesible**
- **Síntoma:** `Error: Redis connection failed`
- **Causas:**
  - Redis no está corriendo (auto-pause en dev)
  - Firewall bloquea conexión
  - URL incorrecta
- **Solución:**
  - Verificar que Redis está corriendo: `az redis show --name NAME --resource-group RG`
  - Verificar firewall: Azure Portal → Redis → Networking
  - Verificar `REDIS_URL` formato: `rediss://:password@host:6380`

#### ❌ **Fallo 5.2.2: Redis password incorrecta**
- **Síntoma:** `Error: NOAUTH Authentication required`
- **Causa:** Password incorrecta o no configurada
- **Solución:**
  - Obtener access keys: `az redis list-keys --name NAME --resource-group RG`
  - Actualizar `REDIS_URL` con password correcta

---

### 5.3 Storage Account

#### ❌ **Fallo 5.3.1: Storage connection string incorrecta**
- **Síntoma:** `Error: Invalid storage connection string`
- **Causa:** Connection string mal formateada o expirada
- **Solución:**
  - Obtener nueva connection string: Azure Portal → Storage Account → Access keys
  - Formato: `DefaultEndpointsProtocol=https;AccountName=xxx;AccountKey=xxx;EndpointSuffix=core.windows.net`

#### ❌ **Fallo 5.3.2: Container no existe**
- **Síntoma:** `Error: Container 'documents' does not exist`
- **Causa:** Container no creado en Storage Account
- **Solución:**
  - Crear container: Azure Portal → Storage Account → Containers → Add container
  - O crear automáticamente en código: `containerClient.createIfNotExists()`

---

## 6. FALLOS DE RECURSOS AZURE

### 6.1 App Service

#### ❌ **Fallo 6.1.1: App Service no arranca**
- **Síntoma:** `503 Service Unavailable` o `Application Error`
- **Causas:**
  - Variables de entorno faltantes
  - Error en código de arranque
  - Puerto incorrecto
  - Dependencias no instaladas
- **Solución:**
  - Verificar logs: `az webapp log tail --name APP_NAME`
  - Verificar `PORT=8080` en App Settings
  - Verificar que `npm install` se ejecutó correctamente

#### ❌ **Fallo 6.1.2: App Service se reinicia constantemente**
- **Síntoma:** App Service reinicia cada pocos minutos
- **Causas:**
  - Error no capturado en código
  - Memoria insuficiente (B1 tiene 1.75GB)
  - Timeout de requests
- **Solución:**
  - Revisar logs de Application Insights
  - Verificar uso de memoria
  - Considerar upgrade a S1 (3.5GB RAM)

#### ❌ **Fallo 6.1.3: Cold start muy lento**
- **Síntoma:** Primera request tarda >30 segundos
- **Causa:** App Service en "cold start" (no usado recientemente)
- **Solución:**
  - Habilitar "Always On" (requiere S1+)
  - O usar warm-up requests periódicas

---

### 6.2 Static Web App

#### ❌ **Fallo 6.2.1: Frontend no carga**
- **Síntoma:** Página en blanco o 404
- **Causas:**
  - Build falló
  - `output_location` incorrecta
  - Rutas no configuradas
- **Solución:**
  - Verificar que `dist` folder existe después de build
  - Verificar `output_location: "dist"` en workflow
  - Configurar `routes.json` para SPA routing

#### ❌ **Fallo 6.2.2: API routes no funcionan**
- **Síntoma:** `/api/*` retorna 404
- **Causa:** Static Web App no configurado para API routes
- **Solución:**
  - Configurar `routes.json` con rewrite rules
  - O usar Azure Functions para API (más complejo)

---

### 6.3 PostgreSQL

#### ❌ **Fallo 6.3.1: Database no existe**
- **Síntoma:** `Error: database "econeura_full_staging" does not exist`
- **Causa:** Database no creada en PostgreSQL
- **Solución:**
  - Crear database: `az postgres flexible-server db create --name DB_NAME --server-name SERVER_NAME --resource-group RG`
  - O crear en Bicep: `database.bicep` debe crear la database

#### ❌ **Fallo 6.3.2: Tablas no existen**
- **Síntoma:** `Error: relation "users" does not exist`
- **Causa:** Migraciones no ejecutadas
- **Solución:**
  - Ejecutar migraciones: `npm run migrate` (si existe)
  - O crear tablas manualmente desde `schema.sql`

#### ❌ **Fallo 6.3.3: PostgreSQL en pausa (dev)**
- **Síntoma:** `Error: Connection timeout`
- **Causa:** PostgreSQL Flexible Server en pausa (auto-pause habilitado)
- **Solución:**
  - Despertar: `az postgres flexible-server start --name SERVER_NAME --resource-group RG`
  - O deshabilitar auto-pause en producción

---

### 6.4 Redis

#### ❌ **Fallo 6.4.1: Redis en pausa (dev)**
- **Síntoma:** `Error: Redis connection timeout`
- **Causa:** Redis Cache en pausa (auto-pause habilitado)
- **Solución:**
  - Despertar: `az redis update --name NAME --resource-group RG --set redisConfiguration.maxmemory-reserved=0`
  - O deshabilitar auto-pause: `enableAutoPause: false` en `redis.bicep`

---

## 7. FALLOS DE BUILD Y COMPILACIÓN

### 7.1 Backend Build

#### ❌ **Fallo 7.1.1: TypeScript errors**
- **Síntoma:** `error TS2345: Type 'X' is not assignable`
- **Causa:** Errores de tipos no resueltos
- **Solución:**
  - Ejecutar `npm run type-check:backend` localmente
  - Corregir errores antes de commit

#### ❌ **Fallo 7.1.2: Dependencias faltantes**
- **Síntoma:** `Error: Cannot find module 'express'`
- **Causa:** `package.json` no tiene dependencia o `node_modules` corrupto
- **Solución:**
  - Verificar `package.json` tiene todas las dependencias
  - Ejecutar `npm install` localmente
  - Verificar `package-lock.json` está commitado

#### ❌ **Fallo 7.1.3: Out of memory**
- **Síntoma:** `Error: JavaScript heap out of memory`
- **Causa:** Build consume demasiada memoria
- **Solución:**
  - Aumentar memoria: `NODE_OPTIONS=--max-old-space-size=4096 npm run build:backend`
  - O optimizar código (menos imports, code splitting)

---

### 7.2 Frontend Build

#### ❌ **Fallo 7.2.1: Vite build falla**
- **Síntoma:** `Error: Could not resolve entry module`
- **Causa:** `vite.config.ts` mal configurado o `index.html` no existe
- **Solución:**
  - Verificar `packages/frontend/index.html` existe
  - Verificar `vite.config.ts` tiene `root: '.'` y `entry: 'src/main.tsx'`

#### ❌ **Fallo 7.2.2: Assets no encontrados**
- **Síntoma:** `Error: Failed to load resource: /assets/xxx.js`
- **Causa:** Rutas de assets incorrectas
- **Solución:**
  - Verificar `base` en `vite.config.ts`
  - Verificar que `dist/assets` contiene los archivos

---

## 8. FALLOS DE RUNTIME Y APLICACIÓN

### 8.1 Backend Runtime

#### ❌ **Fallo 8.1.1: Application Insights no inicializa**
- **Síntoma:** `[ApplicationInsights] Connection string no configurado`
- **Causa:** `APPLICATIONINSIGHTS_CONNECTION_STRING` no configurada
- **Solución:**
  - Agregar en App Service Settings
  - O desde Key Vault: `KEY_VAULT_URL` + secret `APPLICATIONINSIGHTS-CONNECTION-STRING`

#### ❌ **Fallo 8.1.2: Redis no conecta**
- **Síntoma:** `[Redis] Error de conexión`
- **Causa:** `REDIS_URL` incorrecta o Redis no disponible
- **Solución:**
  - Verificar `REDIS_URL` formato correcto
  - Verificar Redis está corriendo
  - Verificar firewall permite conexión

#### ❌ **Fallo 8.1.3: Secrets Manager falla**
- **Síntoma:** `Error: Secret OPENAI-API-KEY no encontrado`
- **Causa:** Secret no existe en Key Vault o Env
- **Solución:**
  - Verificar secret existe en Key Vault
  - O agregar en App Service Settings como fallback

#### ❌ **Fallo 8.1.4: DI Container no resuelve servicios**
- **Síntoma:** `Error: Service not registered: DocumentStore`
- **Causa:** Servicio no registrado en DI Container
- **Solución:**
  - Verificar `initializeServices()` se llama en `index.ts`
  - Verificar servicio está en `registrations.ts`

---

### 8.2 Frontend Runtime

#### ❌ **Fallo 8.2.1: API calls fallan**
- **Síntoma:** `Failed to fetch` o `CORS error`
- **Causas:**
  - Backend no accesible
  - CORS no configurado
  - URL incorrecta
- **Solución:**
  - Verificar `API_URL` en `packages/frontend/src/config/api.ts`
  - Verificar CORS en backend: `cors()` middleware
  - Verificar backend está corriendo

#### ❌ **Fallo 8.2.2: Auth no funciona**
- **Síntoma:** `401 Unauthorized` en todas las requests
- **Causa:** Token JWT no se envía o es inválido
- **Solución:**
  - Verificar `authMiddleware` en backend
  - Verificar frontend envía token en headers
  - Verificar `JWT_SECRET` está configurado

---

## 9. FALLOS DE INTEGRACIÓN

### 9.1 Backend ↔ Frontend

#### ❌ **Fallo 9.1.1: CORS bloquea requests**
- **Síntoma:** `Access to fetch at 'https://...' from origin 'https://...' has been blocked by CORS policy`
- **Causa:** CORS no configurado o origins incorrectos
- **Solución:**
  - Verificar `CORS_ORIGIN` en App Service Settings
  - O configurar en código: `cors({ origin: process.env.CORS_ORIGIN })`

#### ❌ **Fallo 9.1.2: API endpoints no coinciden**
- **Síntoma:** `404 Not Found` en `/api/neuras`
- **Causa:** Rutas no coinciden entre frontend y backend
- **Solución:**
  - Verificar rutas en `packages/backend/src/api/http/routes/`
  - Verificar `packages/frontend/src/services/neurasApi.ts` usa rutas correctas

---

### 9.2 Backend ↔ Database

#### ❌ **Fallo 9.2.1: Connection pool agotado**
- **Síntoma:** `Error: Sorry, too many clients already`
- **Causa:** Múltiples conexiones abiertas sin cerrar
- **Solución:**
  - Implementar connection pooling
  - Cerrar conexiones después de usar
  - Limitar número de conexiones concurrentes

---

### 9.3 Backend ↔ Redis

#### ❌ **Fallo 9.3.1: Rate limiting no funciona**
- **Síntoma:** Rate limiting no se aplica
- **Causa:** Redis no disponible, usando memory store
- **Solución:**
  - Verificar `REDIS_URL` está configurada
  - Verificar Redis está corriendo
  - Verificar `isRedisAvailable()` retorna `true`

---

## 10. FALLOS DE COSTOS Y LÍMITES

### 10.1 Cuotas Azure

#### ❌ **Fallo 10.1.1: Cuota de App Services excedida**
- **Síntoma:** `Error: Quota exceeded for App Services`
- **Causa:** Límite de App Services en suscripción alcanzado
- **Solución:**
  - Verificar cuota: `az vm list-usage --location westeurope`
  - Eliminar App Services no usados
  - Solicitar aumento de cuota

#### ❌ **Fallo 10.1.2: Cuota de Storage excedida**
- **Síntoma:** `Error: Storage account quota exceeded`
- **Causa:** Límite de Storage Accounts alcanzado (250 por suscripción)
- **Solución:**
  - Eliminar Storage Accounts no usados
  - Usar Storage Account existente si es posible

---

### 10.2 Límites de SKU

#### ❌ **Fallo 10.2.1: B1 Basic insuficiente**
- **Síntoma:** App Service lento o se reinicia por memoria
- **Causa:** B1 tiene solo 1.75GB RAM
- **Solución:**
  - Upgrade a S1 (3.5GB RAM) o superior
  - Optimizar código para usar menos memoria

#### ❌ **Fallo 10.2.2: Redis C0 insuficiente**
- **Síntoma:** Redis lento o errores de memoria
- **Causa:** C0 tiene solo 250MB
- **Solución:**
  - Upgrade a C1 (1GB) o superior
  - Optimizar datos en caché

---

## 📋 CHECKLIST DE PREVENCIÓN

### Antes de Deploy

- [ ] Todos los secrets configurados en GitHub
- [ ] Service Principal con permisos correctos
- [ ] Resource Group existe o se puede crear
- [ ] Location disponible para todos los servicios
- [ ] SKUs disponibles en la región
- [ ] Cuotas no excedidas
- [ ] Build funciona localmente (`npm run build`)
- [ ] Tests pasan localmente (`npm run test`)
- [ ] Type-check pasa (`npm run type-check`)

### Durante Deploy

- [ ] Workflow ejecuta sin errores
- [ ] Bicep deployment exitoso
- [ ] App Service arranca correctamente
- [ ] Health check pasa
- [ ] Smoke tests pasan

### Después de Deploy

- [ ] Backend responde en `/health`
- [ ] Frontend carga correctamente
- [ ] API endpoints accesibles
- [ ] Database conectada
- [ ] Redis conectado (si se usa)
- [ ] Application Insights enviando telemetría
- [ ] Logs sin errores críticos

---

## 🔧 COMANDOS ÚTILES PARA DEBUGGING

```bash
# Ver logs de App Service
az webapp log tail --name APP_NAME --resource-group RG

# Ver variables de entorno
az webapp config appsettings list --name APP_NAME --resource-group RG

# Verificar estado de PostgreSQL
az postgres flexible-server show --name SERVER_NAME --resource-group RG

# Verificar estado de Redis
az redis show --name NAME --resource-group RG

# Verificar cuotas
az vm list-usage --location westeurope

# Validar Bicep
az bicep build --file infrastructure/azure/main.bicep

# Verificar secrets en Key Vault
az keyvault secret list --vault-name VAULT_NAME
```

---

**Última actualización:** 2025-11-16  
**Total de fallos documentados:** 80+ fallos potenciales

