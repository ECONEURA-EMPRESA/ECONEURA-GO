# 🔥 AUTOCRÍTICA BRUTAL: SOLUCIÓN CRM PREMIUM
## Análisis Técnico Exhaustivo - Todos los Problemas Posibles

**Fecha:** 16 de Noviembre de 2025  
**Analista:** Arquitecto Senior - Análisis Crítico  
**Calificación Real:** 6/10 (antes de correcciones)  
**Calificación Objetivo:** 10/10 (después de correcciones)

---

## ⚠️ PROBLEMAS CRÍTICOS ENCONTRADOS: 25+

---

## 🔴 PROBLEMA 1: CONNECTION POOLING DUPLICADO (CRÍTICO)

### Problema:
- Cada store (`postgresLeadStore`, `postgresDealStore`, etc.) crea su propio `Pool`
- Múltiples pools = múltiples conexiones = agotamiento de conexiones
- PostgreSQL Standard_B1ms solo tiene ~100 conexiones máximas

**Impacto:**
- ❌ Agotamiento de conexiones en minutos
- ❌ Errores "too many connections"
- ❌ Sistema se cae bajo carga

**Solución:**
```typescript
// SINGLETON de Pool compartido
// packages/backend/src/infra/persistence/postgresPool.ts

import { Pool } from 'pg';
import { getValidatedEnv } from '../../config/env';
import { logger } from '../../shared/logger';

let sharedPool: Pool | null = null;

export function getPostgresPool(): Pool {
  if (!sharedPool) {
    const env = getValidatedEnv();
    const databaseUrl = (env as any)['DATABASE_URL'] as string | undefined;
    
    if (!databaseUrl) {
      throw new Error('DATABASE_URL no configurado');
    }
    
    sharedPool = new Pool({
      connectionString: databaseUrl,
      ssl: process.env['NODE_ENV'] === 'production' ? { rejectUnauthorized: false } : false,
      max: 10,  // REDUCIDO: Standard_B1ms solo soporta ~100 conexiones totales
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 5000,
      statement_timeout: 30000,  // Timeout de queries
      query_timeout: 30000
    });
    
    // Event handlers para monitoreo
    sharedPool.on('error', (error) => {
      logger.error('[PostgresPool] Error en pool', { error: error.message });
    });
    
    sharedPool.on('connect', () => {
      logger.debug('[PostgresPool] Nueva conexión establecida');
    });
  }
  
  return sharedPool;
}

// Cerrar pool al cerrar aplicación
export async function closePostgresPool(): Promise<void> {
  if (sharedPool) {
    await sharedPool.end();
    sharedPool = null;
    logger.info('[PostgresPool] Pool cerrado');
  }
}
```

**Todos los stores deben usar:**
```typescript
import { getPostgresPool } from '../../../infra/persistence/postgresPool';

// En lugar de crear nuevo Pool
const client = await getPostgresPool().connect();
```

---

## 🔴 PROBLEMA 2: QUERIES SIN LÍMITES (CRÍTICO)

### Problema:
- `getSalesMetrics` puede traer TODOS los deals sin límite
- Si hay 100,000 deals, la query trae 100,000 filas
- Memory overflow, timeout, sistema lento

**Impacto:**
- ❌ Timeout de queries (30s)
- ❌ Memory overflow en Node.js
- ❌ Frontend se congela con datos grandes
- ❌ PostgreSQL se bloquea

**Solución:**
```typescript
// AGREGACIONES EN SQL, NO EN MEMORIA
export async function getSalesMetrics(...) {
  // Query optimizada con agregaciones en SQL
  const result = await client.query(`
    SELECT 
      COUNT(*) FILTER (WHERE stage = 'closed_won') as deals_closed_won,
      SUM(revenue) FILTER (WHERE stage = 'closed_won') as total_revenue,
      AVG(revenue) FILTER (WHERE stage = 'closed_won') as avg_deal_value,
      COUNT(*) as total_deals
    FROM crm_deals d
    INNER JOIN crm_leads l ON d.lead_id = l.id
    WHERE l.department = $1
      AND d.closed_date >= $2
      AND d.closed_date <= $3
      AND d.stage = 'closed_won'
    LIMIT 10000  -- CRÍTICO: límite máximo
  `, [department, startDate, endDate]);
  
  // Revenue por mes (agregación en SQL)
  const byMonth = await client.query(`
    SELECT 
      DATE_TRUNC('month', d.closed_date) as month,
      SUM(d.revenue) as revenue,
      COUNT(*) as deals
    FROM crm_deals d
    INNER JOIN crm_leads l ON d.lead_id = l.id
    WHERE l.department = $1
      AND d.closed_date >= $2
      AND d.closed_date <= $3
      AND d.stage = 'closed_won'
    GROUP BY DATE_TRUNC('month', d.closed_date)
    ORDER BY month
    LIMIT 24  -- Máximo 24 meses
  `, [department, startDate, endDate]);
}
```

---

## 🔴 PROBLEMA 3: SIN CACHÉ PARA MÉTRICAS (CRÍTICO)

### Problema:
- Auto-refresh cada 30s hace query pesada cada 30s
- Si 10 usuarios están viendo el panel = 10 queries cada 30s
- PostgreSQL se satura

**Impacto:**
- ❌ PostgreSQL sobrecargado
- ❌ Queries lentas
- ❌ Timeouts frecuentes
- ❌ Costos altos (más CPU en Azure)

**Solución:**
```typescript
// CACHÉ CON REDIS (ya existe Redis en el sistema)
// packages/backend/src/crm/infra/salesMetricsCache.ts

import { getRedisClient, isRedisAvailable } from '../../../infra/cache/redisClient';
import { logger } from '../../../shared/logger';

const CACHE_TTL = 60;  // 60 segundos (más que auto-refresh de 30s)

export async function getCachedSalesMetrics(
  department: 'cmo' | 'cso',
  period: string,
  fetchFn: () => Promise<SalesMetrics>
): Promise<SalesMetrics> {
  const cacheKey = `crm:sales-metrics:${department}:${period}`;
  
  // Intentar obtener de caché
  if (isRedisAvailable()) {
    const redis = getRedisClient();
    if (redis) {
      try {
        const cached = await redis.get(cacheKey);
        if (cached) {
          logger.debug('[CRM Cache] Métricas obtenidas de caché', { department, period });
          return JSON.parse(cached);
        }
      } catch (error) {
        logger.warn('[CRM Cache] Error obteniendo de caché', {
          error: error instanceof Error ? error.message : String(error)
        });
      }
    }
  }
  
  // Si no hay caché, obtener de DB
  const metrics = await fetchFn();
  
  // Guardar en caché
  if (isRedisAvailable()) {
    const redis = getRedisClient();
    if (redis) {
      try {
        await redis.setex(cacheKey, CACHE_TTL, JSON.stringify(metrics));
        logger.debug('[CRM Cache] Métricas guardadas en caché', { department, period });
      } catch (error) {
        logger.warn('[CRM Cache] Error guardando en caché', {
          error: error instanceof Error ? error.message : String(error)
        });
      }
    }
  }
  
  return metrics;
}

// Usar en getSalesMetrics:
export async function getSalesMetrics(...) {
  return getCachedSalesMetrics(department, period, async () => {
    // Query real aquí
  });
}
```

---

## 🔴 PROBLEMA 4: SIN TRANSACCIONES (CRÍTICO)

### Problema:
- Webhook `deal-stage-change` hace múltiples operaciones:
  1. Buscar deal
  2. Crear/actualizar deal
  3. Actualizar métricas de agente
- Si falla en el paso 3, deal se crea pero métricas no se actualizan
- Datos inconsistentes

**Impacto:**
- ❌ Datos inconsistentes
- ❌ Métricas incorrectas
- ❌ Revenue no coincide con deals

**Solución:**
```typescript
// USAR TRANSACCIONES
export async function updateDealWithMetrics(
  dealId: string,
  updates: Partial<Deal>,
  agentMetrics?: { deals_cerrados?: number; revenue_generado?: number }
): Promise<Result<Deal, Error>> {
  const client = await getPostgresPool().connect();
  
  try {
    await client.query('BEGIN');  // Iniciar transacción
    
    // 1. Actualizar deal
    const dealResult = await updateDealInTransaction(client, dealId, updates);
    if (!dealResult.success) {
      await client.query('ROLLBACK');
      return err(dealResult.error);
    }
    
    // 2. Actualizar métricas de agente (si se proporciona)
    if (agentMetrics && updates.assigned_agent) {
      const metricsResult = await updateAgentMetricsInTransaction(
        client,
        updates.assigned_agent,
        agentMetrics
      );
      if (!metricsResult.success) {
        await client.query('ROLLBACK');
        return err(metricsResult.error);
      }
    }
    
    await client.query('COMMIT');  // Confirmar transacción
    return dealResult;
  } catch (error) {
    await client.query('ROLLBACK');  // Revertir en caso de error
    return err(error instanceof Error ? error : new Error(String(error)));
  } finally {
    client.release();
  }
}
```

---

## 🔴 PROBLEMA 5: RACE CONDITIONS EN MÉTRICAS (CRÍTICO)

### Problema:
- Dos webhooks simultáneos actualizan métricas del mismo agente
- Ambos leen: `revenue_generado = 1000`
- Ambos escriben: `revenue_generado = 1000 + 500 = 1500`
- Debería ser: `1000 + 500 + 500 = 2000`
- Pérdida de datos

**Impacto:**
- ❌ Métricas incorrectas
- ❌ Revenue perdido
- ❌ Datos inconsistentes

**Solución:**
```typescript
// USAR UPDATE ATOMIC (PostgreSQL)
export async function updateAgentMetricsAtomic(
  agentName: string,
  metrics: { deals_cerrados?: number; revenue_generado?: number }
): Promise<Result<void, Error>> {
  const client = await getPostgresPool().connect();
  
  try {
    // UPDATE atómico (PostgreSQL lo hace atómicamente)
    if (metrics.revenue_generado) {
      await client.query(`
        UPDATE crm_agents
        SET metrics = jsonb_set(
          metrics,
          '{revenue_generado}',
          to_jsonb((metrics->>'revenue_generado')::numeric + $1)
        ),
        updated_at = NOW()
        WHERE nombre = $2
      `, [metrics.revenue_generado, agentName]);
    }
    
    if (metrics.deals_cerrados) {
      await client.query(`
        UPDATE crm_agents
        SET metrics = jsonb_set(
          metrics,
          '{deals_cerrados}',
          to_jsonb((metrics->>'deals_cerrados')::numeric + $1)
        ),
        updated_at = NOW()
        WHERE nombre = $2
      `, [metrics.deals_cerrados, agentName]);
    }
    
    return ok(undefined);
  } catch (error) {
    return err(error instanceof Error ? error : new Error(String(error)));
  } finally {
    client.release();
  }
}
```

---

## 🔴 PROBLEMA 6: SIN RETRY EN QUERIES (CRÍTICO)

### Problema:
- Si PostgreSQL está temporalmente ocupado, query falla
- Sin retry, webhook falla
- Lead/deal se pierde

**Impacto:**
- ❌ Pérdida de datos
- ❌ Webhooks fallan sin recuperación
- ❌ Datos inconsistentes

**Solución:**
```typescript
// USAR retryDatabase (ya existe en el sistema)
import { retryDatabase } from '../../../shared/utils/retry';

export async function createLead(lead: Lead): Promise<Result<Lead, Error>> {
  return retryDatabase(async () => {
    const client = await getPostgresPool().connect();
    
    try {
      const result = await client.query(/* ... */);
      return ok(result.rows[0] as Lead);
    } finally {
      client.release();
    }
  }, {
    maxRetries: 3,
    operationName: 'createLead'
  });
}
```

---

## 🔴 PROBLEMA 7: SIN VALIDACIÓN DE AGENTE (CRÍTICO)

### Problema:
- Webhook puede recibir `agent_name: "AgenteInventado"`
- No se valida que el agente existe en `automationAgentsRegistry` o `crm_agents`
- Métricas se crean para agentes que no existen

**Impacto:**
- ❌ Métricas incorrectas
- ❌ Agentes fantasma
- ❌ Datos inconsistentes

**Solución:**
```typescript
// VALIDAR AGENTE ANTES DE CREAR/ACTUALIZAR
import { automationAgents } from '../../../automation/automationAgentsRegistry';

export async function validateAgent(agentName: string, department: 'cmo' | 'cso'): Promise<boolean> {
  // 1. Verificar en automationAgentsRegistry
  const agent = automationAgents.find(
    a => a.name === agentName && 
    (a.neuraKey === department || a.neuraKey === 'cmo' || a.neuraKey === 'cso')
  );
  
  if (agent) {
    return true;
  }
  
  // 2. Verificar en crm_agents (puede ser agente nuevo)
  const client = await getPostgresPool().connect();
  try {
    const result = await client.query(
      'SELECT 1 FROM crm_agents WHERE nombre = $1 AND department = $2 LIMIT 1',
      [agentName, department]
    );
    return result.rows.length > 0;
  } finally {
    client.release();
  }
}

// En webhook:
const isValidAgent = await validateAgent(parsed.assigned_agent, department);
if (!isValidAgent) {
  return res.status(400).json({
    success: false,
    error: `Agente "${parsed.assigned_agent}" no existe o no pertenece a ${department}`,
    code: 'INVALID_AGENT'
  });
}
```

---

## 🔴 PROBLEMA 8: SIN RATE LIMITING EN WEBHOOKS (CRÍTICO)

### Problema:
- Webhooks son públicos (solo HMAC)
- Si N8N tiene bug y envía 1000 webhooks/segundo
- PostgreSQL se satura
- Sistema se cae

**Impacto:**
- ❌ DoS attack posible
- ❌ PostgreSQL sobrecargado
- ❌ Sistema inestable

**Solución:**
```typescript
// RATE LIMITING ESPECÍFICO PARA WEBHOOKS
// packages/backend/src/api/http/middleware/webhookRateLimiter.ts

import rateLimit from 'express-rate-limit';
import RedisStore from 'rate-limit-redis';
import { getRedisClient, isRedisAvailable } from '../../../infra/cache/redisClient';

let webhookRedisStore: RedisStore | undefined = undefined;

if (isRedisAvailable()) {
  const redis = getRedisClient();
  if (redis) {
    webhookRedisStore = new RedisStore({
      prefix: 'rl:webhook:',
      sendCommand: (...args: string[]) => {
        const result = redis.call(...(args as [string, ...any[]]));
        return result as Promise<any>;
      }
    });
  }
}

export const webhookRateLimiter = rateLimit({
  store: webhookRedisStore,
  windowMs: 60 * 1000,  // 1 minuto
  max: 100,  // Máximo 100 webhooks por minuto por IP
  message: 'Too many webhook requests, please try again later',
  standardHeaders: true,
  legacyHeaders: false
});

// En webhookRoutes.ts:
router.post('/deal-stage-change', webhookRateLimiter, webhookAuthMiddleware, async (req, res) => {
  // ...
});
```

---

## 🔴 PROBLEMA 9: SIN VALIDACIÓN DE PAYLOAD SIZE (CRÍTICO)

### Problema:
- Webhook puede recibir `enrichment_data` con 10MB de datos
- Sin validación, se intenta insertar en PostgreSQL
- Error, pero ya se consumió memoria

**Impacto:**
- ❌ Memory overflow
- ❌ Errores de PostgreSQL
- ❌ DoS attack posible

**Solución:**
```typescript
// VALIDAR TAMAÑO DE PAYLOAD
const MAX_PAYLOAD_SIZE = 100 * 1024;  // 100KB

router.post('/deal-stage-change', webhookAuthMiddleware, async (req, res) => {
  const payloadSize = JSON.stringify(req.body).length;
  
  if (payloadSize > MAX_PAYLOAD_SIZE) {
    return res.status(413).json({
      success: false,
      error: 'Payload too large',
      code: 'PAYLOAD_TOO_LARGE',
      maxSize: MAX_PAYLOAD_SIZE
    });
  }
  
  // ... resto del código
});
```

---

## 🔴 PROBLEMA 10: AUTO-REFRESH SIN DEBOUNCE (CRÍTICO)

### Problema:
- Frontend hace auto-refresh cada 30s
- Si usuario cambia periodo, hace 2 requests simultáneos
- Backend procesa ambos (desperdicio)

**Impacto:**
- ❌ Requests duplicados
- ❌ Carga innecesaria en backend
- ❌ UX pobre (loading múltiples veces)

**Solución:**
```typescript
// DEBOUNCE EN FRONTEND
import { useDebouncedValue } from '@mantine/hooks';  // O implementar propio

export function useCRMSalesMetrics(...) {
  const [debouncedPeriod] = useDebouncedValue(period, 500);  // Esperar 500ms
  
  return useQuery({
    queryKey: ['crm-sales-metrics', department, debouncedPeriod],
    queryFn: async () => {
      // ...
    },
    refetchInterval: 30000,
    // CRÍTICO: Cancelar request anterior si cambia periodo
    refetchOnMount: false,
    refetchOnWindowFocus: false
  });
}
```

---

## 🔴 PROBLEMA 11: SIN VIRTUALIZACIÓN EN TABLAS (CRÍTICO)

### Problema:
- Si hay 10,000 leads, tabla renderiza 10,000 filas
- Browser se congela
- UX terrible

**Impacto:**
- ❌ Browser se congela
- ❌ UX terrible
- ❌ Sistema inutilizable con muchos datos

**Solución:**
```typescript
// USAR VIRTUALIZACIÓN (react-window o @tanstack/react-virtual)
import { useVirtualizer } from '@tanstack/react-virtual';

export function LeadsTable({ leads, darkMode }: LeadsTableProps) {
  const parentRef = React.useRef<HTMLDivElement>(null);
  
  const virtualizer = useVirtualizer({
    count: leads.length,
    getScrollElement: () => parentRef.current,
    estimateSize: () => 50,  // Altura estimada de cada fila
    overscan: 5  // Renderizar 5 filas extra fuera de vista
  });
  
  return (
    <div ref={parentRef} className="h-96 overflow-auto">
      <div style={{ height: `${virtualizer.getTotalSize()}px`, position: 'relative' }}>
        {virtualizer.getVirtualItems().map(virtualRow => (
          <div
            key={virtualRow.key}
            style={{
              position: 'absolute',
              top: 0,
              left: 0,
              width: '100%',
              height: `${virtualRow.size}px`,
              transform: `translateY(${virtualRow.start}px)`
            }}
          >
            {/* Renderizar fila */}
          </div>
        ))}
      </div>
    </div>
  );
}
```

---

## 🔴 PROBLEMA 12: SIN MANEJO DE CONEXIONES PERDIDAS (CRÍTICO)

### Problema:
- Si PostgreSQL se cae, pool mantiene conexiones muertas
- Queries fallan sin recuperación
- Sistema no se recupera automáticamente

**Impacto:**
- ❌ Sistema inutilizable si PostgreSQL se cae
- ❌ Sin recuperación automática
- ❌ Errores en cascada

**Solución:**
```typescript
// HEALTH CHECK Y RECONEXIÓN
export function getPostgresPool(): Pool {
  if (!sharedPool) {
    // ... crear pool ...
    
    // Health check periódico
    setInterval(async () => {
      try {
        const client = await sharedPool!.connect();
        await client.query('SELECT 1');
        client.release();
      } catch (error) {
        logger.error('[PostgresPool] Health check falló, reiniciando pool', {
          error: error instanceof Error ? error.message : String(error)
        });
        // Cerrar pool y recrear
        await sharedPool!.end();
        sharedPool = null;
        // Pool se recreará en próxima llamada
      }
    }, 60000);  // Cada minuto
  }
  
  return sharedPool;
}
```

---

## 🔴 PROBLEMA 13: SIN VALIDACIÓN DE DUPLICADOS (CRÍTICO)

### Problema:
- Webhook puede recibir mismo lead dos veces (retry de N8N)
- `email UNIQUE` falla, pero no se maneja
- Lead se pierde

**Impacto:**
- ❌ Leads perdidos
- ❌ Errores no manejados
- ❌ Datos inconsistentes

**Solución:**
```typescript
// MANEJAR DUPLICADOS ELEGANTEMENTE
export async function createLead(lead: Lead): Promise<Result<Lead, Error>> {
  try {
    const result = await client.query(/* INSERT ... */);
    return ok(result.rows[0] as Lead);
  } catch (error: any) {
    // Si es error de duplicado, obtener lead existente
    if (error.code === '23505' && error.constraint === 'crm_leads_email_key') {
      logger.info('[CRM] Lead duplicado, obteniendo existente', { email: lead.email });
      const existing = await getLeadByEmail(lead.email);
      if (existing.success && existing.data) {
        return ok(existing.data);
      }
    }
    return err(error instanceof Error ? error : new Error(String(error)));
  }
}
```

---

## 🔴 PROBLEMA 14: SIN ÍNDICES COMPUESTOS (CRÍTICO)

### Problema:
- Query `WHERE department = 'cso' AND stage = 'closed_won' AND closed_date >= ...`
- Índices individuales no son suficientes
- Query lenta con muchos datos

**Impacto:**
- ❌ Queries lentas (segundos)
- ❌ Timeouts frecuentes
- ❌ PostgreSQL sobrecargado

**Solución:**
```sql
-- ÍNDICES COMPUESTOS PARA QUERIES COMUNES
CREATE INDEX IF NOT EXISTS idx_crm_deals_department_stage_date 
  ON crm_deals(department, stage, closed_date) 
  WHERE closed_date IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_crm_deals_agent_stage_revenue 
  ON crm_deals(assigned_agent, stage, revenue) 
  WHERE revenue IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_crm_leads_department_status_created 
  ON crm_leads(department, status, created_at);
```

---

## 🔴 PROBLEMA 15: SIN PREPARED STATEMENTS (CRÍTICO)

### Problema:
- Queries se construyen con string concatenation
- Vulnerable a SQL injection (aunque usamos parámetros, mejor prevenir)
- Sin reutilización de planes de ejecución

**Impacto:**
- ❌ Riesgo de SQL injection
- ❌ Performance subóptima
- ❌ Sin optimización de queries

**Solución:**
```typescript
// USAR PARÁMETROS SIEMPRE (ya lo hacemos, pero verificar)
// NUNCA hacer:
// `SELECT * FROM crm_deals WHERE department = '${department}'`  ❌

// SIEMPRE hacer:
await client.query(
  'SELECT * FROM crm_deals WHERE department = $1',
  [department]  // ✅
);
```

---

## 🔴 PROBLEMA 16: SIN MONITOREO DE QUERIES LENTAS (CRÍTICO)

### Problema:
- Si query tarda 10 segundos, no se detecta
- No hay alertas
- Problema se descubre cuando es demasiado tarde

**Impacto:**
- ❌ Problemas no detectados
- ❌ Performance degradada sin saberlo
- ❌ Sin métricas de queries

**Solución:**
```typescript
// WRAPPER PARA MONITOREAR QUERIES
export async function executeQueryWithMonitoring<T>(
  query: string,
  params: unknown[],
  operationName: string
): Promise<Result<T, Error>> {
  const startTime = Date.now();
  
  try {
    const client = await getPostgresPool().connect();
    try {
      const result = await client.query(query, params);
      const duration = Date.now() - startTime;
      
      // Log si es lenta (>1s)
      if (duration > 1000) {
        logger.warn('[CRM] Query lenta detectada', {
          operation: operationName,
          duration,
          query: query.substring(0, 100)  // Primeros 100 caracteres
        });
      }
      
      // Track en Application Insights
      trackMetric('crm_query_duration_ms', duration, {
        operation: operationName
      });
      
      return ok(result.rows as T);
    } finally {
      client.release();
    }
  } catch (error) {
    const duration = Date.now() - startTime;
    logger.error('[CRM] Query falló', {
      operation: operationName,
      duration,
      error: error instanceof Error ? error.message : String(error)
    });
    return err(error instanceof Error ? error : new Error(String(error)));
  }
}
```

---

## 🔴 PROBLEMA 17: SIN VALIDACIÓN DE DATOS DE N8N (CRÍTICO)

### Problema:
- N8N puede enviar datos malformados:
  - `email: "no-es-email"`
  - `revenue: "no-es-numero"`
  - `score: 999` (fuera de rango)
- Zod valida, pero errores no son claros

**Impacto:**
- ❌ Datos inválidos en base de datos
- ❌ Errores confusos
- ❌ Debugging difícil

**Solución:**
```typescript
// VALIDACIÓN EXHAUSTIVA CON MENSAJES CLAROS
const dealStageChangeSchema = z.object({
  lead_id: z.string().uuid({ message: 'lead_id debe ser un UUID válido' }),
  stage: z.enum(['meeting_scheduled', 'proposal_sent', 'negotiation', 'closed_won', 'closed_lost'], {
    errorMap: () => ({ message: 'stage debe ser uno de: meeting_scheduled, proposal_sent, negotiation, closed_won, closed_lost' })
  }),
  revenue: z.number()
    .positive({ message: 'revenue debe ser un número positivo' })
    .max(10000000, { message: 'revenue no puede exceder 10,000,000' })
    .optional(),
  // ... más validaciones
}).refine(
  (data) => {
    // Validación cruzada: revenue requerido si closed_won
    if (data.stage === 'closed_won' && !data.revenue) {
      return false;
    }
    return true;
  },
  { message: 'revenue es requerido cuando stage = closed_won' }
);
```

---

## 🔴 PROBLEMA 18: SIN MANEJO DE ERRORES DE POSTGRESQL (CRÍTICO)

### Problema:
- Errores de PostgreSQL no se categorizan
- `23505` (unique violation) vs `23503` (foreign key violation) se tratan igual
- Sin mensajes claros para el usuario

**Impacto:**
- ❌ Errores confusos
- ❌ Debugging difícil
- ❌ UX pobre

**Solución:**
```typescript
// MAPEAR ERRORES DE POSTGRESQL
export function mapPostgresError(error: any): { code: string; message: string; statusCode: number } {
  const pgCode = error.code;
  
  switch (pgCode) {
    case '23505':  // Unique violation
      return {
        code: 'DUPLICATE_ENTRY',
        message: 'Ya existe un registro con estos datos',
        statusCode: 409
      };
    case '23503':  // Foreign key violation
      return {
        code: 'FOREIGN_KEY_VIOLATION',
        message: 'Referencia a registro inexistente',
        statusCode: 400
      };
    case '23502':  // Not null violation
      return {
        code: 'NOT_NULL_VIOLATION',
        message: 'Campo requerido faltante',
        statusCode: 400
      };
    case '23514':  // Check violation
      return {
        code: 'CHECK_VIOLATION',
        message: 'Datos no cumplen restricciones',
        statusCode: 400
      };
    case '40P01':  // Deadlock
      return {
        code: 'DEADLOCK',
        message: 'Conflicto de transacciones, reintentar',
        statusCode: 409
      };
    default:
      return {
        code: 'DATABASE_ERROR',
        message: 'Error de base de datos',
        statusCode: 500
      };
  }
}

// Usar en stores:
catch (error: any) {
  if (error.code && error.code.startsWith('23') || error.code.startsWith('40')) {
    const mapped = mapPostgresError(error);
    return err(new AppError(mapped.message, mapped.statusCode, mapped.code));
  }
  return err(error instanceof Error ? error : new Error(String(error)));
}
```

---

## 🔴 PROBLEMA 19: SIN PAGINACIÓN REAL (CRÍTICO)

### Problema:
- `getLeads` tiene `limit` y `offset`, pero frontend no los usa correctamente
- Si hay 10,000 leads, frontend intenta traerlos todos
- Backend devuelve solo 50, pero frontend no sabe que hay más

**Impacto:**
- ❌ Datos incompletos
- ❌ UX confusa
- ❌ Sin paginación real

**Solución:**
```typescript
// PAGINACIÓN CON TOTAL COUNT
export async function getLeadsPaginated(filters: {
  department?: 'cmo' | 'cso';
  limit?: number;
  offset?: number;
}): Promise<Result<{ leads: Lead[]; total: number; hasMore: boolean }, Error>> {
  const client = await getPostgresPool().connect();
  
  try {
    // Query 1: Obtener leads
    const leadsResult = await client.query(/* SELECT con LIMIT/OFFSET */);
    
    // Query 2: Obtener total (optimizado)
    const countResult = await client.query(/* SELECT COUNT(*) */);
    
    const total = Number.parseInt(countResult.rows[0].count, 10);
    const limit = filters.limit ?? 50;
    const offset = filters.offset ?? 0;
    const hasMore = offset + limit < total;
    
    return ok({
      leads: leadsResult.rows as Lead[],
      total,
      hasMore
    });
  } finally {
    client.release();
  }
}
```

---

## 🔴 PROBLEMA 20: SIN VALIDACIÓN DE FECHAS (CRÍTICO)

### Problema:
- Webhook puede recibir `closed_date: "2020-01-01"` (fecha pasada muy antigua)
- O `closed_date: "2050-01-01"` (fecha futura)
- Sin validación, se inserta en DB
- Datos incorrectos

**Impacto:**
- ❌ Datos incorrectos
- ❌ Gráficos incorrectos
- ❌ Métricas incorrectas

**Solución:**
```typescript
// VALIDAR FECHAS
const dealStageChangeSchema = z.object({
  // ...
  closed_date: z.string().datetime().refine(
    (date) => {
      const d = new Date(date);
      const now = new Date();
      const oneYearAgo = new Date();
      oneYearAgo.setFullYear(now.getFullYear() - 1);
      
      // Fecha debe estar entre 1 año atrás y ahora
      return d >= oneYearAgo && d <= now;
    },
    { message: 'closed_date debe estar entre 1 año atrás y ahora' }
  ).optional()
});
```

---

## 🔴 PROBLEMA 21: SIN LOCK EN ACTUALIZACIÓN DE MÉTRICAS (CRÍTICO)

### Problema:
- Múltiples webhooks actualizan métricas del mismo agente simultáneamente
- Race condition
- Métricas incorrectas

**Solución:**
```typescript
// USAR SELECT FOR UPDATE (LOCK)
export async function updateAgentMetricsWithLock(
  agentName: string,
  metrics: { deals_cerrados?: number; revenue_generado?: number }
): Promise<Result<void, Error>> {
  const client = await getPostgresPool().connect();
  
  try {
    await client.query('BEGIN');
    
    // LOCK el registro
    await client.query(
      'SELECT * FROM crm_agents WHERE nombre = $1 FOR UPDATE',
      [agentName]
    );
    
    // Actualizar (ahora está lockeado, no hay race condition)
    await client.query(/* UPDATE ... */);
    
    await client.query('COMMIT');
    return ok(undefined);
  } catch (error) {
    await client.query('ROLLBACK');
    return err(error instanceof Error ? error : new Error(String(error)));
  } finally {
    client.release();
  }
}
```

---

## 🔴 PROBLEMA 22: SIN CACHÉ DE REACTS QUERY (CRÍTICO)

### Problema:
- React Query hace refetch cada 30s
- Si usuario cambia de tab y vuelve, hace nuevo request
- Sin caché inteligente

**Solución:**
```typescript
// CONFIGURAR REACT QUERY CORRECTAMENTE
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      refetchOnWindowFocus: false,
      retry: 1,
      staleTime: 60000,  // 60 segundos (más que auto-refresh)
      gcTime: 5 * 60 * 1000,  // 5 minutos
      refetchInterval: 30000  // Auto-refresh cada 30s
    }
  }
});
```

---

## 🔴 PROBLEMA 23: SIN DEBOUNCE EN BÚSQUEDA (CRÍTICO)

### Problema:
- Usuario escribe "Juan" en búsqueda
- Frontend hace request por cada letra: "J", "Ju", "Jua", "Juan"
- 4 requests innecesarios

**Solución:**
```typescript
// DEBOUNCE EN BÚSQUEDA
const [searchQuery, setSearchQuery] = useState('');
const [debouncedSearch, setDebouncedSearch] = useState('');

useEffect(() => {
  const timer = setTimeout(() => {
    setDebouncedSearch(searchQuery);
  }, 500);  // Esperar 500ms
  
  return () => clearTimeout(timer);
}, [searchQuery]);

// Usar debouncedSearch en query
const { data } = useCRMLeads(department, { search: debouncedSearch });
```

---

## 🔴 PROBLEMA 24: SIN VALIDACIÓN DE DEPARTAMENTO EN WEBHOOK (CRÍTICO)

### Problema:
- Webhook puede recibir `department: "invalid"`
- O `department: "cmo"` pero agente es de `cso`
- Sin validación, se inserta incorrectamente

**Solución:**
```typescript
// VALIDAR CONSISTENCIA
const isValid = await validateAgentDepartment(
  parsed.assigned_agent,
  parsed.department
);

if (!isValid) {
  return res.status(400).json({
    success: false,
    error: `Agente "${parsed.assigned_agent}" no pertenece a ${parsed.department}`,
    code: 'AGENT_DEPARTMENT_MISMATCH'
  });
}
```

---

## 🔴 PROBLEMA 25: SIN MONITOREO DE PERFORMANCE (CRÍTICO)

### Problema:
- No se trackea tiempo de queries
- No se trackea número de queries
- No se detectan problemas de performance

**Solución:**
```typescript
// TRACKEAR EN APPLICATION INSIGHTS
trackMetric('crm_query_count', 1, { operation: 'getSalesMetrics' });
trackMetric('crm_query_duration_ms', duration, { operation: 'getSalesMetrics' });

// Alertas en Azure:
// - Si query_duration > 5s → Alerta
// - Si query_count > 100/min → Alerta
```

---

## ✅ SOLUCIÓN COMPLETA CORREGIDA

### Archivos a Crear/Modificar:

1. **`packages/backend/src/infra/persistence/postgresPool.ts`** (NUEVO)
   - Singleton de Pool compartido
   - Health check automático
   - Manejo de errores

2. **`packages/backend/src/crm/infra/salesMetricsCache.ts`** (NUEVO)
   - Caché con Redis
   - TTL de 60 segundos

3. **`packages/backend/src/crm/infra/postgresDealStore.ts`** (MODIFICAR)
   - Usar `getPostgresPool()` compartido
   - Agregar transacciones
   - Agregar retry
   - Agregar monitoreo

4. **`packages/backend/src/crm/api/webhookRoutes.ts`** (MODIFICAR)
   - Agregar rate limiting
   - Agregar validación de payload size
   - Agregar validación de agente
   - Agregar transacciones

5. **`packages/backend/src/crm/application/getSalesMetrics.ts`** (MODIFICAR)
   - Agregar caché
   - Optimizar queries (agregaciones en SQL)
   - Agregar límites

6. **`packages/frontend/src/hooks/useCRM.ts`** (MODIFICAR)
   - Agregar debounce
   - Mejorar configuración de React Query

7. **`packages/frontend/src/cockpit/components/LeadsTable.tsx`** (MODIFICAR)
   - Agregar virtualización
   - Agregar debounce en búsqueda

8. **`packages/backend/database/migrations/002_crm_premium.sql`** (MODIFICAR)
   - Agregar índices compuestos
   - Agregar constraints adicionales

---

## 📊 RESUMEN DE PROBLEMAS

| Categoría | Problemas | Severidad |
|-----------|-----------|-----------|
| **Performance** | 8 | 🔴 Crítico |
| **Seguridad** | 4 | 🔴 Crítico |
| **Datos** | 6 | 🔴 Crítico |
| **UX** | 4 | 🟡 Medio |
| **Mantenibilidad** | 3 | 🟡 Medio |

**Total:** 25 problemas críticos encontrados

---

## 🎯 PLAN DE CORRECCIÓN

### Fase 1: Performance (2 días)
1. Singleton de Pool compartido
2. Caché con Redis
3. Queries optimizadas (agregaciones en SQL)
4. Índices compuestos

### Fase 2: Seguridad y Datos (2 días)
5. Transacciones
6. Rate limiting webhooks
7. Validación exhaustiva
8. Manejo de errores PostgreSQL

### Fase 3: UX y Frontend (1 día)
9. Virtualización tablas
10. Debounce búsqueda
11. Mejor configuración React Query

**Total:** 5 días de correcciones

---

## ✅ CHECKLIST DE CORRECCIONES

- [ ] Singleton Pool compartido
- [ ] Caché Redis para métricas
- [ ] Transacciones en webhooks
- [ ] Rate limiting webhooks
- [ ] Validación de agentes
- [ ] Retry en queries
- [ ] Índices compuestos
- [ ] Monitoreo de queries
- [ ] Virtualización tablas
- [ ] Debounce búsqueda
- [ ] Manejo de errores PostgreSQL
- [ ] Validación de payload size
- [ ] Locks en métricas
- [ ] Paginación real
- [ ] Health check Pool

---

**Calificación Actual:** 6/10  
**Calificación Después de Correcciones:** 10/10  
**Tiempo de Corrección:** 5 días

---

*"La perfección no es alcanzable, pero si perseguimos la perfección podemos alcanzar la excelencia."*

