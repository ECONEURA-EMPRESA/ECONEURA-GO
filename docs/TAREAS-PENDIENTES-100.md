# Lista de Tareas Pendientes - Completar al 100% todas las Fases

Este documento detalla todas las tareas pendientes para completar ECONEURA-FULL al 100%, siguiendo el mismo nivel de rigor y exhaustividad que hemos mantenido.

---

## 🎯 OBJETIVO: 100% COMPLETADO EN TODAS LAS FASES

---

## 📋 FASE 6 - Frontend: Componentes Avanzados Pendientes

### Tarea F6.13: Migrar AnalyticsDashboard
- [ ] **F6.13.1** - Leer `ECONEURA-REMOTE/frontend/src/components/AnalyticsDashboard.tsx` línea por línea
- [ ] **F6.13.2** - Analizar dependencias (hooks, servicios, tipos)
- [ ] **F6.13.3** - Crear `packages/frontend/src/cockpit/components/AnalyticsDashboard.tsx`
- [ ] **F6.13.4** - Migrar 1:1 el diseño (mismas clases Tailwind, misma estructura JSX)
- [ ] **F6.13.5** - Adaptar llamadas a API (reemplazar `API_URL` por `conversationsApi`/`neurasApi`)
- [ ] **F6.13.6** - Conectar a `useCockpitState` si aplica
- [ ] **F6.13.7** - Añadir tipos TypeScript estrictos (sin `any`)
- [ ] **F6.13.8** - Crear tests unitarios (`packages/frontend/src/tests/AnalyticsDashboard.test.tsx`)
- [ ] **F6.13.9** - Verificar `type-check:frontend` ✅
- [ ] **F6.13.10** - Verificar tests pasan ✅

### Tarea F6.14: Migrar ConnectAgentModal
- [ ] **F6.14.1** - Leer `ECONEURA-REMOTE/frontend/src/components/ConnectAgentModal.tsx` línea por línea
- [ ] **F6.14.2** - Analizar lógica de conexión de webhooks (Make/n8n)
- [ ] **F6.14.3** - Crear `packages/frontend/src/cockpit/components/ConnectAgentModal.tsx`
- [ ] **F6.14.4** - Migrar 1:1 el diseño (mismas clases, misma UX)
- [ ] **F6.14.5** - Conectar a `automationAgentsRegistry` del backend (vía API si es necesario)
- [ ] **F6.14.6** - Adaptar guardado de webhooks (localStorage → backend API si aplica)
- [ ] **F6.14.7** - Añadir tipos TypeScript estrictos
- [ ] **F6.14.8** - Crear tests unitarios
- [ ] **F6.14.9** - Verificar `type-check:frontend` ✅
- [ ] **F6.14.10** - Verificar tests pasan ✅

### Tarea F6.15: Migrar LibraryPanel
- [ ] **F6.15.1** - Leer `ECONEURA-REMOTE/frontend/src/components/LibraryPanel.tsx` línea por línea
- [ ] **F6.15.2** - Analizar integración con API de biblioteca
- [ ] **F6.15.3** - Crear `packages/frontend/src/cockpit/components/LibraryPanel.tsx`
- [ ] **F6.15.4** - Migrar 1:1 el diseño
- [ ] **F6.15.5** - Crear `packages/frontend/src/services/libraryApi.ts` si no existe
- [ ] **F6.15.6** - Conectar a backend API de biblioteca (cuando exista en FASE 8)
- [ ] **F6.15.7** - Añadir tipos TypeScript estrictos
- [ ] **F6.15.8** - Crear tests unitarios
- [ ] **F6.15.9** - Verificar `type-check:frontend` ✅
- [ ] **F6.15.10** - Verificar tests pasan ✅

### Tarea F6.16: Migrar HITLApprovalModal
- [ ] **F6.16.1** - Leer `ECONEURA-REMOTE/frontend/src/components/HITLApprovalModal.tsx` línea por línea
- [ ] **F6.16.2** - Analizar flujo de aprobación humana
- [ ] **F6.16.3** - Crear `packages/frontend/src/cockpit/components/HITLApprovalModal.tsx`
- [ ] **F6.16.4** - Migrar 1:1 el diseño
- [ ] **F6.16.5** - Conectar a `useCockpitState.pendingHITL`
- [ ] **F6.16.6** - Añadir tipos TypeScript estrictos
- [ ] **F6.16.7** - Crear tests unitarios
- [ ] **F6.16.8** - Verificar `type-check:frontend` ✅
- [ ] **F6.16.9** - Verificar tests pasan ✅

### Tarea F6.17: Migrar ReferencesBlock
- [ ] **F6.17.1** - Leer `ECONEURA-REMOTE/frontend/src/components/ReferencesBlock.tsx` línea por línea
- [ ] **F6.17.2** - Analizar estructura de referencias (RAG)
- [ ] **F6.17.3** - Crear `packages/frontend/src/cockpit/components/ReferencesBlock.tsx`
- [ ] **F6.17.4** - Migrar 1:1 el diseño
- [ ] **F6.17.5** - Conectar a tipos de mensajes con `references` (ya existe en `ChatMessage`)
- [ ] **F6.17.6** - Añadir tipos TypeScript estrictos
- [ ] **F6.17.7** - Crear tests unitarios
- [ ] **F6.17.8** - Verificar `type-check:frontend` ✅
- [ ] **F6.17.9** - Verificar tests pasan ✅

### Tarea F6.18: Migrar ErrorBoundary
- [ ] **F6.18.1** - Leer `ECONEURA-REMOTE/frontend/src/components/ErrorBoundary.jsx` línea por línea
- [ ] **F6.18.2** - Convertir a TypeScript
- [ ] **F6.18.3** - Crear `packages/frontend/src/shared/components/ErrorBoundary.tsx`
- [ ] **F6.18.4** - Añadir tipos TypeScript estrictos
- [ ] **F6.18.5** - Integrar en `App.tsx`
- [ ] **F6.18.6** - Crear tests unitarios
- [ ] **F6.18.7** - Verificar `type-check:frontend` ✅

### Tarea F6.19: Tests E2E Completos
- [ ] **F6.19.1** - Configurar Playwright en `packages/frontend` (si no está)
- [ ] **F6.19.2** - Crear `packages/frontend/tests-e2e/login.spec.ts`:
  - Login exitoso
  - Login con credenciales inválidas
  - Persistencia de sesión
- [ ] **F6.19.3** - Crear `packages/frontend/tests-e2e/cockpit.spec.ts`:
  - Renderizado del cockpit
  - Navegación entre departamentos
  - Búsqueda de agentes
- [ ] **F6.19.4** - Crear `packages/frontend/tests-e2e/chat.spec.ts`:
  - Enviar mensaje a NEURA
  - Recibir respuesta
  - Historial de conversación
- [ ] **F6.19.5** - Crear `packages/frontend/tests-e2e/agent-execution.spec.ts`:
  - Ejecutar agente automation
  - Ver resultado de ejecución
  - Manejo de errores
- [ ] **F6.19.6** - Crear `packages/frontend/tests-e2e/full-flow.spec.ts`:
  - Flujo completo: login → cockpit → seleccionar NEURA → enviar mensaje → ejecutar agente
- [ ] **F6.19.7** - Configurar CI/CD para ejecutar tests e2e
- [ ] **F6.19.8** - Verificar todos los tests e2e pasan ✅

### Tarea F6.20: Des-skip Test de Validación LoginPage
- [ ] **F6.20.1** - Leer `packages/frontend/src/tests/LoginPage.test.tsx` (test skipped)
- [ ] **F6.20.2** - Analizar estructura DOM real del componente `LoginPage`
- [ ] **F6.20.3** - Ajustar matcher para encontrar mensaje de error
- [ ] **F6.20.4** - Verificar test pasa ✅

---

## 🔧 FASE 8 - Migración Exhaustiva Backend (Lote 1: Middleware y Utilidades)

### Tarea F8.1: Migrar Rate Limiter
- [ ] **F8.1.1** - Leer `ECONEURA-REMOTE/backend/middleware/rateLimiter.js` línea por línea
- [ ] **F8.1.2** - Analizar algoritmo de rate limiting (token bucket, sliding window, etc.)
- [ ] **F8.1.3** - Crear `packages/backend/src/api/http/middleware/rateLimiter.ts`
- [ ] **F8.1.4** - Implementar con TypeScript estricto
- [ ] **F8.1.5** - Añadir configuración vía `envSchema.ts`
- [ ] **F8.1.6** - Crear tests unitarios
- [ ] **F8.1.7** - Integrar en `server.ts`
- [ ] **F8.1.8** - Verificar `type-check:backend` ✅
- [ ] **F8.1.9** - Verificar tests pasan ✅

### Tarea F8.2: Migrar Request ID
- [ ] **F8.2.1** - Leer `ECONEURA-REMOTE/backend/middleware/requestId.js` línea por línea
- [ ] **F8.2.2** - Crear `packages/backend/src/api/http/middleware/requestId.ts`
- [ ] **F8.2.3** - Implementar generación de correlation ID
- [ ] **F8.2.4** - Integrar con logger estructurado
- [ ] **F8.2.5** - Crear tests unitarios
- [ ] **F8.2.6** - Integrar en `server.ts`
- [ ] **F8.2.7** - Verificar `type-check:backend` ✅

### Tarea F8.3: Migrar Cache Headers
- [ ] **F8.3.1** - Leer `ECONEURA-REMOTE/backend/middleware/cacheHeaders.js` línea por línea
- [ ] **F8.3.2** - Crear `packages/backend/src/api/http/middleware/cacheHeaders.ts`
- [ ] **F8.3.3** - Implementar headers de cache (ETag, Cache-Control, etc.)
- [ ] **F8.3.4** - Crear tests unitarios
- [ ] **F8.3.5** - Integrar en `server.ts`
- [ ] **F8.3.6** - Verificar `type-check:backend` ✅

### Tarea F8.4: Migrar Retry Utility
- [ ] **F8.4.1** - Leer `ECONEURA-REMOTE/backend/utils/retry.js` línea por línea
- [ ] **F8.4.2** - Crear `packages/backend/src/shared/utils/retry.ts`
- [ ] **F8.4.3** - Implementar con TypeScript estricto (exponential backoff, max retries, etc.)
- [ ] **F8.4.4** - Crear tests unitarios
- [ ] **F8.4.5** - Usar en adaptadores (OpenAI, Make, n8n) si aplica
- [ ] **F8.4.6** - Verificar `type-check:backend` ✅

### Tarea F8.5: Migrar Error Handler
- [ ] **F8.5.1** - Leer `ECONEURA-REMOTE/backend/utils/errorHandler.js` línea por línea
- [ ] **F8.5.2** - Crear `packages/backend/src/shared/utils/errorHandler.ts`
- [ ] **F8.5.3** - Implementar manejo centralizado de errores
- [ ] **F8.5.4** - Integrar con logger estructurado
- [ ] **F8.5.5** - Crear tests unitarios
- [ ] **F8.5.6** - Integrar en `server.ts` (error handler middleware)
- [ ] **F8.5.7** - Verificar `type-check:backend` ✅

---

## 🔧 FASE 8 - Migración Exhaustiva Backend (Lote 2: Servicios de Infraestructura)

### Tarea F8.6: Migrar Resilient AI Gateway
- [ ] **F8.6.1** - Leer `ECONEURA-REMOTE/backend/services/resilientAIGateway.js` línea por línea
- [ ] **F8.6.2** - Analizar estrategia de resiliencia (circuit breaker, fallback, etc.)
- [ ] **F8.6.3** - Crear `packages/backend/src/infra/llm/ResilientAIGateway.ts`
- [ ] **F8.6.4** - Implementar como wrapper de `LLMClient`
- [ ] **F8.6.5** - Integrar con `retry.ts` y `errorHandler.ts`
- [ ] **F8.6.6** - Crear tests unitarios (mocks de fallos)
- [ ] **F8.6.7** - Integrar en `invokeLLMAgent.ts`
- [ ] **F8.6.8** - Verificar `type-check:backend` ✅
- [ ] **F8.6.9** - Verificar tests pasan ✅

### Tarea F8.7: Migrar Key Vault Service
- [ ] **F8.7.1** - Leer `ECONEURA-REMOTE/backend/services/keyVaultService.js` línea por línea
- [ ] **F8.7.2** - Analizar integración con Azure Key Vault
- [ ] **F8.7.3** - Crear `packages/backend/src/infra/keyvault/KeyVaultService.ts`
- [ ] **F8.7.4** - Implementar puerto `SecretsService`
- [ ] **F8.7.5** - Crear adaptador Azure Key Vault
- [ ] **F8.7.6** - Crear adaptador in-memory para tests
- [ ] **F8.7.7** - Integrar en `envSchema.ts` (leer secrets desde Key Vault)
- [ ] **F8.7.8** - Crear tests unitarios
- [ ] **F8.7.9** - Verificar `type-check:backend` ✅

### Tarea F8.8: Migrar Azure Blob Storage
- [ ] **F8.8.1** - Leer `ECONEURA-REMOTE/backend/services/azureBlob.js` línea por línea
- [ ] **F8.8.2** - Analizar operaciones (upload, download, delete, list)
- [ ] **F8.8.3** - Crear `packages/backend/src/infra/storage/StorageService.ts` (puerto)
- [ ] **F8.8.4** - Crear `packages/backend/src/infra/storage/AzureBlobAdapter.ts`
- [ ] **F8.8.5** - Crear adaptador in-memory para tests
- [ ] **F8.8.6** - Crear tests unitarios
- [ ] **F8.8.7** - Verificar `type-check:backend` ✅

### Tarea F8.9: Migrar PDF Ingest
- [ ] **F8.9.1** - Leer `ECONEURA-REMOTE/backend/services/pdfIngest.js` línea por línea
- [ ] **F8.9.2** - Analizar procesamiento de PDFs (extracción de texto, OCR, etc.)
- [ ] **F8.9.3** - Crear `packages/backend/src/knowledge/application/pdfIngest.ts` (caso de uso)
- [ ] **F8.9.4** - Crear `packages/backend/src/knowledge/infra/PdfProcessor.ts` (adaptador)
- [ ] **F8.9.5** - Integrar con `StorageService` para leer PDFs
- [ ] **F8.9.6** - Crear tests unitarios
- [ ] **F8.9.7** - Verificar `type-check:backend` ✅

---

## 🔧 FASE 8 - Migración Exhaustiva Backend (Lote 3: APIs y Funciones)

### Tarea F8.10: Migrar API de Agentes
- [ ] **F8.10.1** - Leer `ECONEURA-REMOTE/backend/api/agents.js` línea por línea
- [ ] **F8.10.2** - Analizar endpoints (listar, obtener, crear, actualizar agentes)
- [ ] **F8.10.3** - Crear `packages/backend/src/api/http/routes/agentsRoutes.ts`
- [ ] **F8.10.4** - Crear casos de uso en `packages/backend/src/automation/application/`
- [ ] **F8.10.5** - Crear schemas Zod para validación
- [ ] **F8.10.6** - Crear tests de integración
- [ ] **F8.10.7** - Integrar en `server.ts`
- [ ] **F8.10.8** - Verificar `type-check:backend` ✅

### Tarea F8.11: Migrar API de Biblioteca
- [ ] **F8.11.1** - Leer `ECONEURA-REMOTE/backend/api/library.js` línea por línea
- [ ] **F8.11.2** - Analizar endpoints (listar documentos, buscar, subir, eliminar)
- [ ] **F8.11.3** - Crear `packages/backend/src/knowledge/domain/` (Document, Library aggregates)
- [ ] **F8.11.4** - Crear `packages/backend/src/knowledge/application/` (casos de uso)
- [ ] **F8.11.5** - Crear `packages/backend/src/api/http/routes/libraryRoutes.ts`
- [ ] **F8.11.6** - Integrar con `StorageService` y `PdfProcessor`
- [ ] **F8.11.7** - Crear tests de integración
- [ ] **F8.11.8** - Verificar `type-check:backend` ✅

### Tarea F8.12: Migrar API de Métricas
- [ ] **F8.12.1** - Leer `ECONEURA-REMOTE/backend/api/metrics.js` línea por línea
- [ ] **F8.12.2** - Analizar métricas (uso de tokens, costos, ejecuciones, etc.)
- [ ] **F8.12.3** - Crear `packages/backend/src/metrics/domain/` (Metric, MetricAggregate)
- [ ] **F8.12.4** - Crear `packages/backend/src/metrics/application/` (casos de uso)
- [ ] **F8.12.5** - Crear `packages/backend/src/api/http/routes/metricsRoutes.ts`
- [ ] **F8.12.6** - Integrar con Event Store para calcular métricas desde eventos
- [ ] **F8.12.7** - Crear tests de integración
- [ ] **F8.12.8** - Verificar `type-check:backend` ✅

### Tarea F8.13: Migrar API de Propuestas
- [ ] **F8.13.1** - Leer `ECONEURA-REMOTE/backend/api/proposals.js` línea por línea
- [ ] **F8.13.2** - Analizar endpoints (crear, listar, aprobar, rechazar propuestas)
- [ ] **F8.13.3** - Crear `packages/backend/src/proposals/domain/` (Proposal aggregate)
- [ ] **F8.13.4** - Crear `packages/backend/src/proposals/application/` (casos de uso)
- [ ] **F8.13.5** - Crear `packages/backend/src/api/http/routes/proposalsRoutes.ts`
- [ ] **F8.13.6** - Integrar con HITL si aplica
- [ ] **F8.13.7** - Crear tests de integración
- [ ] **F8.13.8** - Verificar `type-check:backend` ✅

### Tarea F8.14: Migrar API de Webhooks
- [ ] **F8.14.1** - Leer `ECONEURA-REMOTE/backend/api/webhooks.js` línea por línea
- [ ] **F8.14.2** - Analizar endpoints (recibir webhooks, validar, procesar)
- [ ] **F8.14.3** - Crear `packages/backend/src/webhooks/domain/` (Webhook aggregate)
- [ ] **F8.14.4** - Crear `packages/backend/src/webhooks/application/` (casos de uso)
- [ ] **F8.14.5** - Crear `packages/backend/src/api/http/routes/webhooksRoutes.ts`
- [ ] **F8.14.6** - Integrar con `automationService`
- [ ] **F8.14.7** - Crear tests de integración
- [ ] **F8.14.8** - Verificar `type-check:backend` ✅

### Tarea F8.15: Migrar Funciones (Functions)
- [ ] **F8.15.1** - Leer todos los archivos en `ECONEURA-REMOTE/backend/functions/*.js`
- [ ] **F8.15.2** - Analizar cada función y mapear a bounded context apropiado:
  - `listarAgentesDisponibles.js` → `packages/backend/src/automation/application/listAgents.ts`
  - `generarReporte.js` → `packages/backend/src/reports/application/generateReport.ts`
  - `enviarAlerta.js` → `packages/backend/src/notifications/application/sendAlert.ts`
  - `ejecutarWebhook.js` → ya migrado en `automationService`
  - `consultarDatos.js` → `packages/backend/src/knowledge/application/queryData.ts`
  - `agendarReunion.js` → `packages/backend/src/calendar/application/scheduleMeeting.ts`
- [ ] **F8.15.3** - Crear casos de uso para cada función
- [ ] **F8.15.4** - Crear tests unitarios
- [ ] **F8.15.5** - Verificar `type-check:backend` ✅

---

## 🔧 FASE 8 - Migración Exhaustiva Backend (Lote 4: Configuración y Prompts)

### Tarea F8.16: Migrar Configuración Redis
- [ ] **F8.16.1** - Leer `ECONEURA-REMOTE/backend/config/redis.js` línea por línea
- [ ] **F8.16.2** - Analizar uso de Redis (cache, rate limiting, etc.)
- [ ] **F8.16.3** - Crear `packages/backend/src/infra/cache/CacheService.ts` (puerto)
- [ ] **F8.16.4** - Crear `packages/backend/src/infra/cache/RedisAdapter.ts`
- [ ] **F8.16.5** - Crear adaptador in-memory para tests
- [ ] **F8.16.6** - Integrar en `rateLimiter.ts` si aplica
- [ ] **F8.16.7** - Crear tests unitarios
- [ ] **F8.16.8** - Verificar `type-check:backend` ✅

### Tarea F8.17: Revisar y Consolidar Prompts
- [ ] **F8.17.1** - Leer todos los archivos en `ECONEURA-REMOTE/backend/prompts/*.js`
- [ ] **F8.17.2** - Comparar con `packages/backend/src/llm/llmAgentsRegistry.ts`
- [ ] **F8.17.3** - Verificar que todos los prompts están migrados
- [ ] **F8.17.4** - Actualizar `systemPrompt` en `llmAgentsRegistry.ts` si hay mejoras
- [ ] **F8.17.5** - Documentar cambios en `docs/DOMAIN-NEURAS.md`
- [ ] **F8.17.6** - Verificar `type-check:backend` ✅

---

## 🧪 FASE 8 - Tests y Verificación Final

### Tarea F8.18: Tests de Integración Backend Completos
- [ ] **F8.18.1** - Crear `packages/backend/tests/integration/conversation-flow.test.ts`:
  - Iniciar conversación
  - Enviar mensaje
  - Obtener historial
  - Ejecutar agente
- [ ] **F8.18.2** - Crear `packages/backend/tests/integration/automation-flow.test.ts`:
  - Ejecutar agente Make
  - Ejecutar agente n8n
  - Manejo de errores
- [ ] **F8.18.3** - Crear `packages/backend/tests/integration/auth-rbac.test.ts`:
  - Autenticación
  - RBAC por roles
  - Audit logging
- [ ] **F8.18.4** - Verificar todos los tests de integración pasan ✅

### Tarea F8.19: Verificación Final Sin Atajos
- [ ] **F8.19.1** - Buscar todos los `any` sin justificar:
  ```bash
  grep -r "any" packages/backend/src --include="*.ts" | grep -v "// eslint-disable"
  ```
- [ ] **F8.19.2** - Buscar TODOs críticos:
  ```bash
  grep -r "TODO" packages/backend/src packages/frontend/src
  ```
- [ ] **F8.19.3** - Buscar código muerto (imports sin usar, funciones sin usar)
- [ ] **F8.19.4** - Ejecutar `npm run type-check:backend` y verificar 0 errores ✅
- [ ] **F8.19.5** - Ejecutar `npm run type-check:frontend` y verificar 0 errores ✅
- [ ] **F8.19.6** - Ejecutar `npm run test:backend` y verificar 100% pasan ✅
- [ ] **F8.19.7** - Ejecutar `npm run test:frontend` y verificar 100% pasan ✅
- [ ] **F8.19.8** - Ejecutar tests e2e y verificar 100% pasan ✅

### Tarea F8.20: Actualizar MIGRATION_LOG.md
- [ ] **F8.20.1** - Marcar todas las tareas completadas en `MIGRATION_LOG.md`
- [ ] **F8.20.2** - Actualizar estadísticas finales:
  - Archivos migrados: ~150+ archivos TypeScript
  - Archivos pendientes: 0
  - Tests: ~50+ tests unitarios + integración + e2e
- [ ] **F8.20.3** - Documentar mejoras y decisiones arquitectónicas
- [ ] **F8.20.4** - Marcar FASE 8 como ✅ COMPLETADA

---

## 📊 RESUMEN DE TAREAS POR FASE

### FASE 6 (Frontend Avanzado):
- **F6.13** - AnalyticsDashboard (10 subtareas)
- **F6.14** - ConnectAgentModal (10 subtareas)
- **F6.15** - LibraryPanel (10 subtareas)
- **F6.16** - HITLApprovalModal (9 subtareas)
- **F6.17** - ReferencesBlock (9 subtareas)
- **F6.18** - ErrorBoundary (7 subtareas)
- **F6.19** - Tests E2E Completos (8 subtareas)
- **F6.20** - Des-skip Test LoginPage (4 subtareas)

**Total FASE 6:** 8 tareas principales, 67 subtareas

### FASE 8 (Migración Exhaustiva):
- **Lote 1 (Middleware y Utilidades):** 5 tareas principales, 45 subtareas
- **Lote 2 (Servicios de Infraestructura):** 4 tareas principales, 36 subtareas
- **Lote 3 (APIs y Funciones):** 6 tareas principales, 48 subtareas
- **Lote 4 (Configuración y Prompts):** 2 tareas principales, 12 subtareas
- **Tests y Verificación Final:** 3 tareas principales, 20 subtareas

**Total FASE 8:** 20 tareas principales, 161 subtareas

### TOTAL GENERAL:
- **28 tareas principales**
- **228 subtareas**
- **Estado objetivo:** 100% completado en todas las fases

---

## ✅ CRITERIOS DE COMPLETACIÓN AL 100%

Para considerar una tarea "completada al 100%", debe cumplir:

1. ✅ Código migrado 1:1 desde ECONEURA-REMOTE (respetando diseño/funcionalidad)
2. ✅ TypeScript estricto (0 errores de `type-check`, sin `any` sin justificar)
3. ✅ Tests unitarios creados y pasando
4. ✅ Tests de integración (si aplica) creados y pasando
5. ✅ Documentación actualizada (si aplica)
6. ✅ Integrado en el sistema (imports, exports, rutas, etc.)
7. ✅ Verificado manualmente (si aplica)

---

**Última actualización:** 2025-11-16  
**Estado:** 📋 Plan completo creado, listo para ejecutar

