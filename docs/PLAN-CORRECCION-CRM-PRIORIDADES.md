# 🚨 PLAN DE CORRECCIÓN CRM - PRIORIDADES INMEDIATAS

## ⚡ CORRECCIONES CRÍTICAS (HACER PRIMERO)

### 1. Singleton Pool Compartido (30 min) ⚡ CRÍTICO
**Problema:** Múltiples pools = agotamiento de conexiones  
**Impacto:** Sistema se cae bajo carga  
**Archivo:** `packages/backend/src/infra/persistence/postgresPool.ts` (NUEVO)

### 2. Caché Redis para Métricas (30 min) ⚡ CRÍTICO
**Problema:** Auto-refresh cada 30s satura PostgreSQL  
**Impacto:** PostgreSQL sobrecargado  
**Archivo:** `packages/backend/src/crm/infra/salesMetricsCache.ts` (NUEVO)

### 3. Transacciones en Webhooks (1 hora) ⚡ CRÍTICO
**Problema:** Datos inconsistentes si falla actualización  
**Impacto:** Métricas incorrectas  
**Archivo:** `packages/backend/src/crm/api/webhookRoutes.ts` (MODIFICAR)

### 4. Rate Limiting Webhooks (30 min) ⚡ CRÍTICO
**Problema:** DoS attack posible  
**Impacto:** Sistema inestable  
**Archivo:** `packages/backend/src/api/http/middleware/webhookRateLimiter.ts` (NUEVO)

### 5. Validación de Agentes (30 min) ⚡ CRÍTICO
**Problema:** Agentes fantasma en métricas  
**Impacto:** Datos incorrectos  
**Archivo:** `packages/backend/src/crm/application/validateAgent.ts` (NUEVO)

### 6. Queries Optimizadas (1 hora) ⚡ CRÍTICO
**Problema:** Trae todos los registros sin límite  
**Impacto:** Memory overflow, timeouts  
**Archivo:** `packages/backend/src/crm/application/getSalesMetrics.ts` (MODIFICAR)

### 7. Índices Compuestos (15 min) ⚡ CRÍTICO
**Problema:** Queries lentas  
**Impacto:** Timeouts frecuentes  
**Archivo:** `packages/backend/database/migrations/003_crm_indexes.sql` (NUEVO)

---

## 🔧 CORRECCIONES IMPORTANTES (HACER DESPUÉS)

### 8. Retry en Queries (30 min)
**Archivo:** Modificar stores para usar `retryDatabase`

### 9. Manejo de Errores PostgreSQL (1 hora)
**Archivo:** `packages/backend/src/shared/utils/postgresErrorMapper.ts` (NUEVO)

### 10. Validación Payload Size (15 min)
**Archivo:** Modificar webhookRoutes

### 11. Locks en Métricas (30 min)
**Archivo:** Modificar updateAgentMetrics

### 12. Virtualización Tablas (2 horas)
**Archivo:** `packages/frontend/src/cockpit/components/LeadsTable.tsx` (MODIFICAR)

### 13. Debounce Búsqueda (30 min)
**Archivo:** Modificar hooks de CRM

---

## 📋 ORDEN DE EJECUCIÓN

1. ✅ Singleton Pool (30 min)
2. ✅ Índices Compuestos (15 min)
3. ✅ Caché Redis (30 min)
4. ✅ Rate Limiting (30 min)
5. ✅ Validación Agentes (30 min)
6. ✅ Queries Optimizadas (1 hora)
7. ✅ Transacciones (1 hora)
8. ✅ Retry (30 min)
9. ✅ Manejo Errores (1 hora)
10. ✅ Payload Size (15 min)
11. ✅ Locks (30 min)
12. ✅ Virtualización (2 horas)
13. ✅ Debounce (30 min)

**Tiempo Total:** ~9 horas (1 día de trabajo)

---

## 🎯 OBJETIVO

**Antes:** 6/10 (sistema funcional pero con problemas críticos)  
**Después:** 10/10 (sistema robusto, escalable, seguro)

