# 🎯 INSTALACIÓN TÉCNICA CRM PREMIUM 10/10
## Plan Completo: Backend + Frontend + Power BI + Agentes N8N

**Fecha:** 16 de Noviembre de 2025  
**Objetivo:** CRM completo para CMO y CSO con integración a agentes automatizados y Power BI  
**Tiempo Estimado:** 9 días  
**Calificación Objetivo:** 10/10

---

## 📋 ÍNDICE

1. [Dependencias y Configuración Inicial](#1-dependencias-y-configuración-inicial)
2. [Schema PostgreSQL](#2-schema-postgresql)
3. [Backend: Bounded Context CRM](#3-backend-bounded-context-crm)
4. [Backend: API Endpoints](#4-backend-api-endpoints)
5. [Backend: Webhooks Seguros](#5-backend-webhooks-seguros)
6. [Integración con Agentes Existentes](#6-integración-con-agentes-existentes)
7. [Frontend: React Query Setup](#7-frontend-react-query-setup)
8. [Frontend: Componente CRMPanel](#8-frontend-componente-crmpanel)
9. [Power BI: Configuración y Conexión](#9-power-bi-configuración-y-conexión)
10. [Documentación Webhooks N8N](#10-documentación-webhooks-n8n)

---

## 1. DEPENDENCIAS Y CONFIGURACIÓN INICIAL

### 1.1. Backend: Instalar PostgreSQL Client

```bash
cd packages/backend
npm install pg
npm install --save-dev @types/pg
```

**Verificar instalación:**
```bash
npm list pg @types/pg
```

### 1.2. Frontend: Instalar React Query y Tablas

```bash
cd packages/frontend
npm install @tanstack/react-query @tanstack/react-table
npm install recharts  # Para gráficos si no hay Power BI
```

**Verificar instalación:**
```bash
npm list @tanstack/react-query @tanstack/react-table recharts
```

### 1.3. Backend: Agregar Variables de Entorno

**Archivo:** `packages/backend/src/config/envSchema.ts`

```typescript
export const envSchema = z.object({
  // ... campos existentes ...
  
  // CRM Webhooks
  CRM_WEBHOOK_SECRET: z.string().optional(),  // Secret para validar HMAC de N8N
  
  // Power BI
  POWERBI_TENANT_ID: z.string().optional(),
  POWERBI_CLIENT_ID: z.string().optional(),
  POWERBI_CLIENT_SECRET: z.string().optional(),
  POWERBI_WORKSPACE_ID_CMO: z.string().optional(),
  POWERBI_WORKSPACE_ID_CSO: z.string().optional(),
  POWERBI_REPORT_ID_CMO: z.string().optional(),
  POWERBI_REPORT_ID_CSO: z.string().optional(),
  POWERBI_EMBED_URL_CMO: z.string().url().optional(),
  POWERBI_EMBED_URL_CSO: z.string().url().optional()
});
```

---

## 2. SCHEMA POSTGRESQL

### 2.1. Crear Archivo de Migración

**Archivo:** `packages/backend/database/migrations/001_create_crm_tables.sql`

```sql
-- ============================================
-- CRM TABLES - Marketing y Ventas
-- ============================================

-- Tabla: Leads (IA y Tradicional)
CREATE TABLE IF NOT EXISTS crm_leads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) NOT NULL UNIQUE,
  nombre VARCHAR(255) NOT NULL,
  empresa VARCHAR(255),
  telefono VARCHAR(50),
  cargo VARCHAR(100),
  score INTEGER CHECK (score >= 1 AND score <= 10),
  status VARCHAR(50) DEFAULT 'new' CHECK (status IN ('new', 'qualified', 'contacted', 'lost')),
  department VARCHAR(50) NOT NULL CHECK (department IN ('cmo', 'cso')),
  source VARCHAR(50) NOT NULL CHECK (source IN ('ia', 'traditional')),  -- CRÍTICO para comparación
  assigned_agent VARCHAR(255),  -- NULL si es tradicional
  enrichment_data JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Tabla: Deals (solo CSO)
CREATE TABLE IF NOT EXISTS crm_deals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lead_id UUID NOT NULL REFERENCES crm_leads(id) ON DELETE CASCADE,
  valor_estimado DECIMAL(10, 2) NOT NULL,
  stage VARCHAR(50) DEFAULT 'meeting_scheduled' CHECK (stage IN ('meeting_scheduled', 'proposal_sent', 'negotiation', 'closed_won', 'closed_lost')),
  source VARCHAR(50) NOT NULL CHECK (source IN ('ia', 'traditional')),  -- CRÍTICO para comparación
  assigned_agent VARCHAR(255),
  meeting_date TIMESTAMP,
  proposal_sent_at TIMESTAMP,
  closed_date TIMESTAMP,
  lost_reason TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Tabla: Conversaciones (solo IA)
CREATE TABLE IF NOT EXISTS crm_conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lead_id UUID NOT NULL REFERENCES crm_leads(id) ON DELETE CASCADE,
  mensaje TEXT NOT NULL,
  agent_name VARCHAR(255) NOT NULL,
  direction VARCHAR(50) NOT NULL CHECK (direction IN ('inbound', 'outbound')),
  intent VARCHAR(50) CHECK (intent IN ('positivo', 'neutro', 'negativo')),
  timestamp TIMESTAMP DEFAULT NOW()
);

-- Tabla: Agentes IA (métricas)
CREATE TABLE IF NOT EXISTS crm_agents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre VARCHAR(255) NOT NULL UNIQUE,
  department VARCHAR(50) NOT NULL CHECK (department IN ('cmo', 'cso')),
  role VARCHAR(50) CHECK (role IN ('prospector', 'qualifier', 'closer', 'nurture', 'retention')),
  status VARCHAR(50) DEFAULT 'active' CHECK (status IN ('active', 'paused')),
  metrics JSONB DEFAULT '{
    "leads_procesados": 0,
    "meetings_agendados": 0,
    "deals_cerrados": 0,
    "revenue_generado": 0
  }'::jsonb,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- ============================================
-- ÍNDICES CRÍTICOS
-- ============================================

-- Leads
CREATE INDEX IF NOT EXISTS idx_crm_leads_department ON crm_leads(department);
CREATE INDEX IF NOT EXISTS idx_crm_leads_source ON crm_leads(source);  -- CRÍTICO para comparación
CREATE INDEX IF NOT EXISTS idx_crm_leads_status ON crm_leads(status);
CREATE INDEX IF NOT EXISTS idx_crm_leads_created_at ON crm_leads(created_at);
CREATE INDEX IF NOT EXISTS idx_crm_leads_assigned_agent ON crm_leads(assigned_agent);

-- Deals
CREATE INDEX IF NOT EXISTS idx_crm_deals_lead_id ON crm_deals(lead_id);
CREATE INDEX IF NOT EXISTS idx_crm_deals_source ON crm_deals(source);  -- CRÍTICO para comparación
CREATE INDEX IF NOT EXISTS idx_crm_deals_stage ON crm_deals(stage);
CREATE INDEX IF NOT EXISTS idx_crm_deals_department ON crm_deals((SELECT department FROM crm_leads WHERE id = crm_deals.lead_id));

-- Conversaciones
CREATE INDEX IF NOT EXISTS idx_crm_conversations_lead_id ON crm_conversations(lead_id);
CREATE INDEX IF NOT EXISTS idx_crm_conversations_agent_name ON crm_conversations(agent_name);
CREATE INDEX IF NOT EXISTS idx_crm_conversations_timestamp ON crm_conversations(timestamp);

-- Agentes
CREATE INDEX IF NOT EXISTS idx_crm_agents_department ON crm_agents(department);
CREATE INDEX IF NOT EXISTS idx_crm_agents_status ON crm_agents(status);

-- ============================================
-- TRIGGERS
-- ============================================

-- Actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_crm_leads_updated_at
  BEFORE UPDATE ON crm_leads
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_crm_deals_updated_at
  BEFORE UPDATE ON crm_deals
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_crm_agents_updated_at
  BEFORE UPDATE ON crm_agents
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

### 2.2. Ejecutar Migración

```bash
# Conectar a PostgreSQL y ejecutar
psql -h YOUR_POSTGRES_HOST -U econeuraadmin -d econeura_app -f packages/backend/database/migrations/001_create_crm_tables.sql
```

**O desde Azure:**
```bash
az postgres flexible-server db execute \
  --resource-group rg-econeura-full-staging \
  --server-name pg-econeura-full-staging \
  --database-name econeura_app \
  --file-path packages/backend/database/migrations/001_create_crm_tables.sql
```

---

## 3. BACKEND: BOUNDED CONTEXT CRM

### 3.1. Estructura de Carpetas

```
packages/backend/src/crm/
├── domain/
│   ├── Lead.ts
│   ├── Deal.ts
│   ├── Conversation.ts
│   ├── Agent.ts
│   └── events.ts
├── application/
│   ├── createLead.ts
│   ├── qualifyLead.ts
│   ├── createDeal.ts
│   ├── updateDealStage.ts
│   ├── compareIATraditional.ts  ← CRÍTICO
│   └── getAgentMetrics.ts
├── infra/
│   ├── postgresLeadStore.ts
│   ├── postgresDealStore.ts
│   ├── postgresConversationStore.ts
│   ├── postgresAgentStore.ts
│   └── powerBiAdapter.ts
└── api/
    ├── crmRoutes.ts
    └── webhookRoutes.ts
```

### 3.2. Domain Models

**Archivo:** `packages/backend/src/crm/domain/Lead.ts`

```typescript
export type LeadStatus = 'new' | 'qualified' | 'contacted' | 'lost';
export type LeadSource = 'ia' | 'traditional';
export type Department = 'cmo' | 'cso';

export interface Lead {
  id: string;
  email: string;
  nombre: string;
  empresa?: string;
  telefono?: string;
  cargo?: string;
  score: number;  // 1-10
  status: LeadStatus;
  department: Department;
  source: LeadSource;  // CRÍTICO
  assigned_agent?: string;
  enrichment_data?: Record<string, unknown>;
  created_at: Date;
  updated_at: Date;
}

export function createLead(data: {
  email: string;
  nombre: string;
  empresa?: string;
  telefono?: string;
  cargo?: string;
  score?: number;
  department: Department;
  source: LeadSource;
  assigned_agent?: string;
  enrichment_data?: Record<string, unknown>;
}): Lead {
  return {
    id: crypto.randomUUID(),
    email: data.email,
    nombre: data.nombre,
    empresa: data.empresa,
    telefono: data.telefono,
    cargo: data.cargo,
    score: data.score ?? 5,
    status: 'new',
    department: data.department,
    source: data.source,
    assigned_agent: data.assigned_agent,
    enrichment_data: data.enrichment_data ?? {},
    created_at: new Date(),
    updated_at: new Date()
  };
}
```

**Archivo:** `packages/backend/src/crm/domain/Deal.ts`

```typescript
export type DealStage = 'meeting_scheduled' | 'proposal_sent' | 'negotiation' | 'closed_won' | 'closed_lost';
export type DealSource = 'ia' | 'traditional';

export interface Deal {
  id: string;
  lead_id: string;
  valor_estimado: number;
  stage: DealStage;
  source: DealSource;  // CRÍTICO
  assigned_agent?: string;
  meeting_date?: Date;
  proposal_sent_at?: Date;
  closed_date?: Date;
  lost_reason?: string;
  created_at: Date;
  updated_at: Date;
}
```

**Archivo:** `packages/backend/src/crm/domain/Agent.ts`

```typescript
export type AgentRole = 'prospector' | 'qualifier' | 'closer' | 'nurture' | 'retention';
export type AgentStatus = 'active' | 'paused';

export interface Agent {
  id: string;
  nombre: string;
  department: 'cmo' | 'cso';
  role?: AgentRole;
  status: AgentStatus;
  metrics: {
    leads_procesados: number;
    meetings_agendados: number;
    deals_cerrados: number;
    revenue_generado: number;
  };
  created_at: Date;
  updated_at: Date;
}
```

### 3.3. PostgreSQL Adapters

**Archivo:** `packages/backend/src/crm/infra/postgresLeadStore.ts`

```typescript
import { Pool } from 'pg';
import { getValidatedEnv } from '../../config/env';
import { logger } from '../../shared/logger';
import type { Lead } from '../domain/Lead';
import { ok, err, type Result } from '../../shared/Result';

let pool: Pool | null = null;

function getPool(): Pool {
  if (!pool) {
    const env = getValidatedEnv();
    const databaseUrl = (env as any)['DATABASE_URL'] as string | undefined;
    
    if (!databaseUrl) {
      throw new Error('DATABASE_URL no configurado');
    }
    
    pool = new Pool({
      connectionString: databaseUrl,
      ssl: process.env['NODE_ENV'] === 'production' ? { rejectUnauthorized: false } : false
    });
  }
  
  return pool;
}

export async function createLead(lead: Lead): Promise<Result<Lead, Error>> {
  try {
    const client = await getPool().connect();
    
    try {
      const result = await client.query(
        `INSERT INTO crm_leads (
          id, email, nombre, empresa, telefono, cargo, score, status,
          department, source, assigned_agent, enrichment_data, created_at, updated_at
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
        RETURNING *`,
        [
          lead.id, lead.email, lead.nombre, lead.empresa, lead.telefono, lead.cargo,
          lead.score, lead.status, lead.department, lead.source, lead.assigned_agent,
          JSON.stringify(lead.enrichment_data), lead.created_at, lead.updated_at
        ]
      );
      
      return ok(result.rows[0] as Lead);
    } finally {
      client.release();
    }
  } catch (error) {
    logger.error('[CRM] Error creando lead', { error: error instanceof Error ? error.message : String(error) });
    return err(error instanceof Error ? error : new Error(String(error)));
  }
}

export async function getLeads(filters: {
  department?: 'cmo' | 'cso';
  source?: 'ia' | 'traditional';
  status?: string;
  assigned_agent?: string;
  limit?: number;
  offset?: number;
}): Promise<Result<Lead[], Error>> {
  try {
    const client = await getPool().connect();
    
    try {
      const conditions: string[] = [];
      const params: unknown[] = [];
      let paramIndex = 1;
      
      if (filters.department) {
        conditions.push(`department = $${paramIndex++}`);
        params.push(filters.department);
      }
      
      if (filters.source) {
        conditions.push(`source = $${paramIndex++}`);
        params.push(filters.source);
      }
      
      if (filters.status) {
        conditions.push(`status = $${paramIndex++}`);
        params.push(filters.status);
      }
      
      if (filters.assigned_agent) {
        conditions.push(`assigned_agent = $${paramIndex++}`);
        params.push(filters.assigned_agent);
      }
      
      const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';
      const limit = filters.limit ?? 100;
      const offset = filters.offset ?? 0;
      
      params.push(limit, offset);
      
      const result = await client.query(
        `SELECT * FROM crm_leads ${whereClause} ORDER BY created_at DESC LIMIT $${paramIndex++} OFFSET $${paramIndex++}`,
        params
      );
      
      return ok(result.rows as Lead[]);
    } finally {
      client.release();
    }
  } catch (error) {
    logger.error('[CRM] Error obteniendo leads', { error: error instanceof Error ? error.message : String(error) });
    return err(error instanceof Error ? error : new Error(String(error)));
  }
}
```

**Archivo:** `packages/backend/src/crm/infra/postgresDealStore.ts` (similar estructura)

**Archivo:** `packages/backend/src/crm/infra/postgresConversationStore.ts` (similar estructura)

**Archivo:** `packages/backend/src/crm/infra/postgresAgentStore.ts` (similar estructura)

### 3.4. Use Cases

**Archivo:** `packages/backend/src/crm/application/compareIATraditional.ts` (CRÍTICO)

```typescript
import { getLeads } from '../infra/postgresLeadStore';
import { getDeals } from '../infra/postgresDealStore';
import { ok, err, type Result } from '../../shared/Result';

export interface ComparisonData {
  ia: {
    leads: number;
    deals: number;
    revenue: number;
  };
  traditional: {
    leads: number;
    deals: number;
    revenue: number;
  };
  improvement: {
    leads: number;  // porcentaje
    deals: number;
    revenue: number;
  };
}

export async function compareIATraditional(
  department: 'cmo' | 'cso',
  period: 'day' | 'week' | 'month' = 'month'
): Promise<Result<ComparisonData, Error>> {
  try {
    // Calcular fecha de inicio según periodo
    const now = new Date();
    const startDate = new Date();
    
    switch (period) {
      case 'day':
        startDate.setDate(now.getDate() - 1);
        break;
      case 'week':
        startDate.setDate(now.getDate() - 7);
        break;
      case 'month':
        startDate.setMonth(now.getMonth() - 1);
        break;
    }
    
    // Obtener leads IA
    const leadsIA = await getLeads({
      department,
      source: 'ia',
      limit: 10000
    });
    
    if (!leadsIA.success) {
      return err(leadsIA.error);
    }
    
    // Obtener leads Tradicional
    const leadsTraditional = await getLeads({
      department,
      source: 'traditional',
      limit: 10000
    });
    
    if (!leadsTraditional.success) {
      return err(leadsTraditional.error);
    }
    
    // Obtener deals IA
    const dealsIA = await getDeals({
      department,
      source: 'ia',
      limit: 10000
    });
    
    if (!dealsIA.success) {
      return err(dealsIA.error);
    }
    
    // Obtener deals Tradicional
    const dealsTraditional = await getDeals({
      department,
      source: 'traditional',
      limit: 10000
    });
    
    if (!dealsTraditional.success) {
      return err(dealsTraditional.error);
    }
    
    // Calcular revenue
    const revenueIA = dealsIA.data
      .filter(d => d.stage === 'closed_won')
      .reduce((sum, d) => sum + Number(d.valor_estimado), 0);
    
    const revenueTraditional = dealsTraditional.data
      .filter(d => d.stage === 'closed_won')
      .reduce((sum, d) => sum + Number(d.valor_estimado), 0);
    
    // Calcular mejoras
    const improvement = {
      leads: leadsTraditional.data.length > 0
        ? ((leadsIA.data.length - leadsTraditional.data.length) / leadsTraditional.data.length) * 100
        : 0,
      deals: dealsTraditional.data.length > 0
        ? ((dealsIA.data.length - dealsTraditional.data.length) / dealsTraditional.data.length) * 100
        : 0,
      revenue: revenueTraditional > 0
        ? ((revenueIA - revenueTraditional) / revenueTraditional) * 100
        : 0
    };
    
    return ok({
      ia: {
        leads: leadsIA.data.length,
        deals: dealsIA.data.length,
        revenue: revenueIA
      },
      traditional: {
        leads: leadsTraditional.data.length,
        deals: dealsTraditional.data.length,
        revenue: revenueTraditional
      },
      improvement
    });
  } catch (error) {
    return err(error instanceof Error ? error : new Error(String(error)));
  }
}
```

---

## 4. BACKEND: API ENDPOINTS

### 4.1. CRM Routes

**Archivo:** `packages/backend/src/crm/api/crmRoutes.ts`

```typescript
import { Router, type Request, type Response } from 'express';
import { z } from 'zod';
import { getLeads, createLead } from '../infra/postgresLeadStore';
import { getDeals, createDeal } from '../infra/postgresDealStore';
import { getAgents } from '../infra/postgresAgentStore';
import { compareIATraditional } from '../application/compareIATraditional';
import { sendResult } from '../../api/http/httpResult';
import { logger } from '../../shared/logger';
import type { RequestWithId } from '../../api/http/middleware/requestId';

const router = Router();

// GET /api/crm/leads
router.get('/leads', async (req: Request, res: Response) => {
  try {
    const reqWithId = req as RequestWithId;
    const { department, source, status, assigned_agent, limit, offset } = req.query;
    
    const result = await getLeads({
      department: department as 'cmo' | 'cso' | undefined,
      source: source as 'ia' | 'traditional' | undefined,
      status: status as string | undefined,
      assigned_agent: assigned_agent as string | undefined,
      limit: limit ? Number.parseInt(limit as string, 10) : undefined,
      offset: offset ? Number.parseInt(offset as string, 10) : undefined
    });
    
    sendResult(res, result);
  } catch (error) {
    logger.error('[CRM Routes] Error obteniendo leads', {
      error: error instanceof Error ? error.message : String(error)
    });
    res.status(500).json({ success: false, error: 'Error interno del servidor' });
  }
});

// GET /api/crm/deals
router.get('/deals', async (req: Request, res: Response) => {
  // Similar a leads
});

// GET /api/crm/agents
router.get('/agents', async (req: Request, res: Response) => {
  // Similar a leads
});

// GET /api/crm/comparison (CRÍTICO)
router.get('/comparison', async (req: Request, res: Response) => {
  try {
    const { department, period } = req.query;
    
    if (!department || (department !== 'cmo' && department !== 'cso')) {
      return res.status(400).json({
        success: false,
        error: 'department debe ser "cmo" o "cso"'
      });
    }
    
    const result = await compareIATraditional(
      department as 'cmo' | 'cso',
      (period as 'day' | 'week' | 'month') ?? 'month'
    );
    
    sendResult(res, result);
  } catch (error) {
    logger.error('[CRM Routes] Error obteniendo comparación', {
      error: error instanceof Error ? error.message : String(error)
    });
    res.status(500).json({ success: false, error: 'Error interno del servidor' });
  }
});

export { router as crmRoutes };
```

### 4.2. Registrar Rutas en Server

**Archivo:** `packages/backend/src/api/http/server.ts`

```typescript
import { crmRoutes } from '../../../crm/api/crmRoutes';
import { webhookRoutes } from '../../../crm/api/webhookRoutes';

// ... código existente ...

app.use('/api/crm', crmRoutes);
app.use('/api/crm/webhooks', webhookRoutes);  // Sin auth (webhooks públicos)
```

---

## 5. BACKEND: WEBHOOKS SEGUROS

### 5.1. Validación HMAC

**Archivo:** `packages/backend/src/crm/api/webhookRoutes.ts`

```typescript
import { Router, type Request, type Response } from 'express';
import { z } from 'zod';
import crypto from 'crypto';
import { getValidatedEnv } from '../../config/env';
import { createLead } from '../infra/postgresLeadStore';
import { createConversation } from '../infra/postgresConversationStore';
import { logger } from '../../shared/logger';
import type { RequestWithId } from '../../api/http/middleware/requestId';

const router = Router();

// Validar HMAC
function validateHMAC(body: string, signature: string, secret: string): boolean {
  const hmac = crypto.createHmac('sha256', secret);
  hmac.update(body);
  const expectedSignature = hmac.digest('hex');
  return crypto.timingSafeEqual(
    Buffer.from(signature),
    Buffer.from(expectedSignature)
  );
}

// Middleware de validación HMAC
function webhookAuthMiddleware(req: Request, res: Response, next: () => void): void {
  const env = getValidatedEnv();
  const secret = (env as any)['CRM_WEBHOOK_SECRET'] as string | undefined;
  
  if (!secret) {
    logger.warn('[CRM Webhooks] CRM_WEBHOOK_SECRET no configurado, validación deshabilitada');
    next();
    return;
  }
  
  const signature = req.headers['x-webhook-signature'] as string | undefined;
  const body = JSON.stringify(req.body);
  
  if (!signature || !validateHMAC(body, signature, secret)) {
    logger.warn('[CRM Webhooks] Firma HMAC inválida', {
      path: req.path,
      ip: req.ip
    });
    res.status(401).json({ success: false, error: 'Invalid signature' });
    return;
  }
  
  next();
}

// POST /api/crm/webhooks/lead-created
const leadCreatedSchema = z.object({
  email: z.string().email(),
  nombre: z.string().min(1),
  empresa: z.string().optional(),
  telefono: z.string().optional(),
  cargo: z.string().optional(),
  score: z.number().min(1).max(10).optional(),
  department: z.enum(['cmo', 'cso']),
  agent_name: z.string().min(1),
  enrichment_data: z.record(z.unknown()).optional()
});

router.post('/lead-created', webhookAuthMiddleware, async (req: Request, res: Response) => {
  try {
    const reqWithId = req as RequestWithId;
    const parsed = leadCreatedSchema.parse(req.body);
    
    const lead = createLead({
      email: parsed.email,
      nombre: parsed.nombre,
      empresa: parsed.empresa,
      telefono: parsed.telefono,
      cargo: parsed.cargo,
      score: parsed.score,
      department: parsed.department,
      source: 'ia',  // Siempre IA desde webhook
      assigned_agent: parsed.agent_name,
      enrichment_data: parsed.enrichment_data
    });
    
    const result = await createLead(lead);
    
    if (result.success) {
      logger.info('[CRM Webhooks] Lead creado', {
        leadId: result.data.id,
        agent: parsed.agent_name,
        requestId: reqWithId.id
      });
      res.status(201).json({ success: true, lead: result.data });
    } else {
      logger.error('[CRM Webhooks] Error creando lead', {
        error: result.error.message,
        requestId: reqWithId.id
      });
      res.status(500).json({ success: false, error: result.error.message });
    }
  } catch (error) {
    if (error instanceof z.ZodError) {
      res.status(400).json({ success: false, error: 'Datos inválidos', details: error.issues });
      return;
    }
    
    logger.error('[CRM Webhooks] Error procesando lead-created', {
      error: error instanceof Error ? error.message : String(error)
    });
    res.status(500).json({ success: false, error: 'Error interno del servidor' });
  }
});

// POST /api/crm/webhooks/conversation
const conversationSchema = z.object({
  lead_id: z.string().uuid(),
  mensaje: z.string().min(1),
  agent_name: z.string().min(1),
  direction: z.enum(['inbound', 'outbound']),
  intent: z.enum(['positivo', 'neutro', 'negativo']).optional()
});

router.post('/conversation', webhookAuthMiddleware, async (req: Request, res: Response) => {
  // Similar a lead-created
});

// POST /api/crm/webhooks/deal-stage-change
const dealStageChangeSchema = z.object({
  deal_id: z.string().uuid(),
  new_stage: z.enum(['meeting_scheduled', 'proposal_sent', 'negotiation', 'closed_won', 'closed_lost']),
  agent_name: z.string().min(1),
  metadata: z.record(z.unknown()).optional()
});

router.post('/deal-stage-change', webhookAuthMiddleware, async (req: Request, res: Response) => {
  // Similar a lead-created
});

export { router as webhookRoutes };
```

---

## 6. INTEGRACIÓN CON AGENTES EXISTENTES

### 6.1. Agregar Agentes CRM a automationAgentsRegistry

**Archivo:** `packages/backend/src/automation/automationAgentsRegistry.ts`

```typescript
// Agregar al final del array automationAgentsRaw:

// MARKETING (CMO) - Agentes CRM
{
  id: 'cmo-lead-prospector',
  neuraKey: 'cmo',
  neuraId: 'a-cmo-01',
  name: 'Lead_Prospector',
  description: 'Busca leads en LinkedIn/Apollo y los envía a CRM',
  provider: 'n8n',
  webhookUrl: sanitizeWebhookUrl(process.env['N8N_WEBHOOK_LEAD_PROSPECTOR']),
  trigger: 'auto',
  active: true
},
{
  id: 'cmo-email-campaign',
  neuraKey: 'cmo',
  neuraId: 'a-cmo-01',
  name: 'Email_Campaign_Manager',
  description: 'Envía emails automatizados y registra respuestas en CRM',
  provider: 'n8n',
  webhookUrl: sanitizeWebhookUrl(process.env['N8N_WEBHOOK_EMAIL_CAMPAIGN']),
  trigger: 'auto',
  active: true
},
{
  id: 'cmo-content-generator',
  neuraKey: 'cmo',
  neuraId: 'a-cmo-01',
  name: 'Content_Generator',
  description: 'Genera contenido y registra engagement en CRM',
  provider: 'n8n',
  webhookUrl: sanitizeWebhookUrl(process.env['N8N_WEBHOOK_CONTENT_GENERATOR']),
  trigger: 'auto',
  active: true
},
{
  id: 'cmo-social-scheduler',
  neuraKey: 'cmo',
  neuraId: 'a-cmo-01',
  name: 'Social_Media_Scheduler',
  description: 'Publica en redes y registra interacciones en CRM',
  provider: 'n8n',
  webhookUrl: sanitizeWebhookUrl(process.env['N8N_WEBHOOK_SOCIAL_SCHEDULER']),
  trigger: 'auto',
  active: true
},
{
  id: 'cmo-ad-analyzer',
  neuraKey: 'cmo',
  neuraId: 'a-cmo-01',
  name: 'Ad_Performance_Analyzer',
  description: 'Analiza ROI de ads y registra leads generados en CRM',
  provider: 'n8n',
  webhookUrl: sanitizeWebhookUrl(process.env['N8N_WEBHOOK_AD_ANALYZER']),
  trigger: 'auto',
  active: true
},

// VENTAS (CSO) - Agentes CRM
{
  id: 'cso-lead-qualifier',
  neuraKey: 'cso',
  neuraId: 'a-cso-01',
  name: 'Lead_Qualifier',
  description: 'Califica leads (score 1-10) y actualiza CRM',
  provider: 'n8n',
  webhookUrl: sanitizeWebhookUrl(process.env['N8N_WEBHOOK_LEAD_QUALIFIER']),
  trigger: 'auto',
  active: true
},
{
  id: 'cso-meeting-scheduler',
  neuraKey: 'cso',
  neuraId: 'a-cso-01',
  name: 'Meeting_Scheduler',
  description: 'Agenda reuniones con leads calificados y actualiza CRM',
  provider: 'n8n',
  webhookUrl: sanitizeWebhookUrl(process.env['N8N_WEBHOOK_MEETING_SCHEDULER']),
  trigger: 'auto',
  active: true
},
{
  id: 'cso-proposal-generator',
  neuraKey: 'cso',
  neuraId: 'a-cso-01',
  name: 'Proposal_Generator',
  description: 'Genera propuestas y las envía, actualiza CRM',
  provider: 'n8n',
  webhookUrl: sanitizeWebhookUrl(process.env['N8N_WEBHOOK_PROPOSAL_GENERATOR']),
  trigger: 'auto',
  active: true
},
{
  id: 'cso-deal-closer',
  neuraKey: 'cso',
  neuraId: 'a-cso-01',
  name: 'Deal_Closer',
  description: 'Gestiona negociaciones y cierra ventas, actualiza CRM',
  provider: 'n8n',
  webhookUrl: sanitizeWebhookUrl(process.env['N8N_WEBHOOK_DEAL_CLOSER']),
  trigger: 'auto',
  active: true
},
{
  id: 'cso-objection-handler',
  neuraKey: 'cso',
  neuraId: 'a-cso-01',
  name: 'Objection_Handler',
  description: 'Responde objeciones automáticamente y registra en CRM',
  provider: 'n8n',
  webhookUrl: sanitizeWebhookUrl(process.env['N8N_WEBHOOK_OBJECTION_HANDLER']),
  trigger: 'auto',
  active: true
}
```

---

## 7. FRONTEND: REACT QUERY SETUP

### 7.1. Configurar React Query Provider

**Archivo:** `packages/frontend/src/main.tsx`

```typescript
import React from 'react';
import ReactDOM from 'react-dom/client';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { App } from './App';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      refetchOnWindowFocus: false,
      retry: 1,
      staleTime: 30000  // 30 segundos
    }
  }
});

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <QueryClientProvider client={queryClient}>
      <App />
    </QueryClientProvider>
  </React.StrictMode>
);
```

### 7.2. Crear Hooks para CRM

**Archivo:** `packages/frontend/src/hooks/useCRM.ts`

```typescript
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { apiClient } from '../services/apiClient';

export function useCRMLeads(department: 'cmo' | 'cso', filters?: {
  source?: 'ia' | 'traditional';
  status?: string;
  assigned_agent?: string;
}) {
  return useQuery({
    queryKey: ['crm-leads', department, filters],
    queryFn: async () => {
      const params = new URLSearchParams({ department });
      if (filters?.source) params.set('source', filters.source);
      if (filters?.status) params.set('status', filters.status);
      if (filters?.assigned_agent) params.set('assigned_agent', filters.assigned_agent);
      
      const response = await apiClient.get<{ success: true; data: any[] }>(
        `/api/crm/leads?${params.toString()}`,
        localStorage.getItem('econeura_token') ?? undefined
      );
      
      if (response.success) {
        return response.data;
      }
      throw new Error('Error obteniendo leads');
    },
    refetchInterval: 30000  // Auto-refresh cada 30s
  });
}

export function useCRMComparison(department: 'cmo' | 'cso', period: 'day' | 'week' | 'month' = 'month') {
  return useQuery({
    queryKey: ['crm-comparison', department, period],
    queryFn: async () => {
      const response = await apiClient.get<{ success: true; data: any }>(
        `/api/crm/comparison?department=${department}&period=${period}`,
        localStorage.getItem('econeura_token') ?? undefined
      );
      
      if (response.success) {
        return response.data;
      }
      throw new Error('Error obteniendo comparación');
    },
    refetchInterval: 30000
  });
}
```

---

## 8. FRONTEND: COMPONENTE CRMPANEL

### 8.1. Componente Principal

**Archivo:** `packages/frontend/src/cockpit/components/CRMPanel.tsx`

```typescript
import React, { useState } from 'react';
import { useCRMLeads, useCRMComparison } from '../../../hooks/useCRM';
import { LeadsTable } from './LeadsTable';
import { ComparisonDashboard } from './ComparisonDashboard';
import { PowerBIPanel } from './PowerBIPanel';
import { AgentsPerformance } from './AgentsPerformance';

interface CRMPanelProps {
  department: 'cmo' | 'cso';
  darkMode: boolean;
}

export function CRMPanel({ department, darkMode }: CRMPanelProps) {
  const [activeTab, setActiveTab] = useState<'leads' | 'deals' | 'agents' | 'comparison' | 'powerbi'>('leads');
  
  return (
    <div className={`${darkMode ? 'bg-slate-950 text-slate-50' : 'bg-slate-50 text-slate-900'} p-6`}>
      <div className="flex items-center justify-between mb-6">
        <h2 className="text-2xl font-bold text-emerald-400">CRM - {department.toUpperCase()}</h2>
        <div className="flex gap-2">
          {['leads', 'deals', 'agents', 'comparison', 'powerbi'].map((tab) => (
            <button
              key={tab}
              onClick={() => setActiveTab(tab as any)}
              className={`px-4 py-2 rounded-lg ${
                activeTab === tab
                  ? 'bg-emerald-500/80 text-white'
                  : darkMode
                  ? 'bg-slate-800 text-slate-300 hover:bg-slate-700'
                  : 'bg-white text-slate-700 hover:bg-slate-100'
              }`}
            >
              {tab.charAt(0).toUpperCase() + tab.slice(1)}
            </button>
          ))}
        </div>
      </div>
      
      {activeTab === 'leads' && <LeadsTable department={department} darkMode={darkMode} />}
      {activeTab === 'comparison' && <ComparisonDashboard department={department} darkMode={darkMode} />}
      {activeTab === 'powerbi' && <PowerBIPanel department={department} darkMode={darkMode} />}
      {activeTab === 'agents' && <AgentsPerformance department={department} darkMode={darkMode} />}
    </div>
  );
}
```

### 8.2. Agregar Panel a Departments

**Archivo:** `packages/frontend/src/cockpit/EconeuraCockpit.tsx`

```typescript
import { CRMPanel } from './components/CRMPanel';

// En el render, agregar:
{state.dept.id === 'CMO' || state.dept.id === 'CSO' ? (
  <CRMPanel department={state.dept.id.toLowerCase() as 'cmo' | 'cso'} darkMode={state.darkMode} />
) : (
  // ... resto del contenido
)}
```

---

## 9. POWER BI: CONFIGURACIÓN Y CONEXIÓN

### 9.1. Backend: Power BI Adapter

**Archivo:** `packages/backend/src/crm/infra/powerBiAdapter.ts`

```typescript
import { getValidatedEnv } from '../../config/env';
import { getLeads } from './postgresLeadStore';
import { getDeals } from './postgresDealStore';
import { compareIATraditional } from '../application/compareIATraditional';
import { ok, err, type Result } from '../../shared/Result';

export interface PowerBIResponse {
  data: unknown[];
  metadata: {
    total: number;
    date_range: string;
    department: string;
    generated_at: string;
  };
}

export async function getPowerBILeads(
  department: 'cmo' | 'cso',
  filters?: { source?: 'ia' | 'traditional'; status?: string }
): Promise<Result<PowerBIResponse, Error>> {
  try {
    const result = await getLeads({
      department,
      source: filters?.source,
      status: filters?.status,
      limit: 10000
    });
    
    if (!result.success) {
      return err(result.error);
    }
    
    return ok({
      data: result.data.map(lead => ({
        id: lead.id,
        email: lead.email,
        nombre: lead.nombre,
        empresa: lead.empresa,
        score: lead.score,
        status: lead.status,
        source: lead.source,
        assigned_agent: lead.assigned_agent,
        created_at: lead.created_at.toISOString()
      })),
      metadata: {
        total: result.data.length,
        date_range: 'last_30_days',
        department,
        generated_at: new Date().toISOString()
      }
    });
  } catch (error) {
    return err(error instanceof Error ? error : new Error(String(error)));
  }
}

export async function getPowerBIComparison(
  department: 'cmo' | 'cso',
  period: 'day' | 'week' | 'month' = 'month'
): Promise<Result<PowerBIResponse, Error>> {
  try {
    const result = await compareIATraditional(department, period);
    
    if (!result.success) {
      return err(result.error);
    }
    
    return ok({
      data: [
        {
          source: 'ia',
          leads: result.data.ia.leads,
          deals: result.data.ia.deals,
          revenue: result.data.ia.revenue
        },
        {
          source: 'traditional',
          leads: result.data.traditional.leads,
          deals: result.data.traditional.deals,
          revenue: result.data.traditional.revenue
        }
      ],
      metadata: {
        total: 2,
        date_range: period,
        department,
        generated_at: new Date().toISOString()
      }
    });
  } catch (error) {
    return err(error instanceof Error ? error : new Error(String(error)));
  }
}
```

### 9.2. Endpoint Power BI

**Archivo:** `packages/backend/src/crm/api/crmRoutes.ts` (agregar)

```typescript
import { getPowerBILeads, getPowerBIComparison } from '../infra/powerBiAdapter';

// GET /api/crm/powerbi/leads
router.get('/powerbi/leads', async (req: Request, res: Response) => {
  try {
    const { department, source, status } = req.query;
    
    if (!department || (department !== 'cmo' && department !== 'cso')) {
      return res.status(400).json({
        success: false,
        error: 'department debe ser "cmo" o "cso"'
      });
    }
    
    const result = await getPowerBILeads(
      department as 'cmo' | 'cso',
      {
        source: source as 'ia' | 'traditional' | undefined,
        status: status as string | undefined
      }
    );
    
    sendResult(res, result);
  } catch (error) {
    logger.error('[CRM Routes] Error obteniendo Power BI leads', {
      error: error instanceof Error ? error.message : String(error)
    });
    res.status(500).json({ success: false, error: 'Error interno del servidor' });
  }
});

// GET /api/crm/powerbi/comparison
router.get('/powerbi/comparison', async (req: Request, res: Response) => {
  // Similar a leads
});
```

### 9.3. Frontend: Power BI Panel

**Archivo:** `packages/frontend/src/cockpit/components/PowerBIPanel.tsx`

```typescript
import React from 'react';
import { getValidatedEnv } from '../../../config/env';

interface PowerBIPanelProps {
  department: 'cmo' | 'cso';
  darkMode: boolean;
}

export function PowerBIPanel({ department, darkMode }: PowerBIPanelProps) {
  const embedUrl = department === 'cmo'
    ? process.env['VITE_POWERBI_EMBED_URL_CMO']
    : process.env['VITE_POWERBI_EMBED_URL_CSO'];
  
  if (!embedUrl) {
    // Fallback a gráficos Recharts
    return <RechartsFallback department={department} darkMode={darkMode} />;
  }
  
  return (
    <div className={`${darkMode ? 'bg-slate-900' : 'bg-white'} rounded-lg p-4`}>
      <iframe
        src={embedUrl}
        width="100%"
        height="800"
        frameBorder="0"
        allowFullScreen
        className="rounded-lg"
      />
    </div>
  );
}
```

---

## 10. DOCUMENTACIÓN WEBHOOKS N8N

### 10.1. Crear Documentación

**Archivo:** `docs/WEBHOOKS-N8N-CRM.md`

```markdown
# Webhooks N8N para CRM

## Configuración

1. Obtener `CRM_WEBHOOK_SECRET` del backend
2. Configurar en N8N como variable de entorno
3. Usar en HTTP Request node con header `X-Webhook-Signature`

## Endpoints Disponibles

### POST /api/crm/webhooks/lead-created

**Body:**
```json
{
  "email": "lead@example.com",
  "nombre": "Juan Pérez",
  "empresa": "Empresa S.A.",
  "telefono": "+34 600 000 000",
  "cargo": "CEO",
  "score": 8,
  "department": "cmo",
  "agent_name": "Lead_Prospector",
  "enrichment_data": {
    "linkedin": "https://linkedin.com/in/juanperez",
    "company_size": "50-100"
  }
}
```

**Headers:**
- `Content-Type: application/json`
- `X-Webhook-Signature: <HMAC_SHA256>`

### POST /api/crm/webhooks/conversation

**Body:**
```json
{
  "lead_id": "uuid-del-lead",
  "mensaje": "Hola, estoy interesado en su producto",
  "agent_name": "Email_Campaign_Manager",
  "direction": "inbound",
  "intent": "positivo"
}
```

### POST /api/crm/webhooks/deal-stage-change

**Body:**
```json
{
  "deal_id": "uuid-del-deal",
  "new_stage": "closed_won",
  "agent_name": "Deal_Closer",
  "metadata": {
    "valor_final": 10000
  }
}
```

## Ejemplo N8N Workflow

1. **Trigger:** Webhook (recibe datos de LinkedIn)
2. **Function:** Calcular score y enriquecer datos
3. **HTTP Request:** POST a `/api/crm/webhooks/lead-created`
   - Headers: `X-Webhook-Signature` con HMAC
   - Body: JSON con datos del lead
```

---

## ✅ CHECKLIST FINAL

- [ ] Dependencias instaladas (pg, @tanstack/react-query, etc.)
- [ ] Schema PostgreSQL creado y migrado
- [ ] Bounded context CRM implementado
- [ ] Endpoints API funcionando
- [ ] Webhooks con validación HMAC
- [ ] Agentes agregados a automationAgentsRegistry
- [ ] Frontend con React Query
- [ ] CRMPanel integrado en cockpit
- [ ] Power BI configurado (o fallback Recharts)
- [ ] Documentación webhooks creada
- [ ] Tests básicos pasando
- [ ] Type-check sin errores

---

**Tiempo Total:** 9 días  
**Resultado:** CRM Premium 10/10 completamente funcional

