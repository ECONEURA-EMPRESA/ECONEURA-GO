/**
 * ECONEURA - CRM API Routes
 * 
 * Rutas principales del CRM para Marketing y Ventas.
 * Todas requieren autenticación.
 */

import { Router, type Request, type Response } from 'express';
import { z } from 'zod';
import { listLeads } from '../infra/postgresLeadStore';
import { getSalesMetrics } from '../application/getSalesMetrics';
import { logger } from '../../shared/logger';
import type { RequestWithId } from '../../api/http/middleware/requestId';
import { sendResult } from '../../api/http/httpResult';

const router = Router();

// Schema de validación para query params de leads
const listLeadsQuerySchema = z.object({
  department: z.enum(['cmo', 'cso']),
  status: z.string().optional(),
  limit: z.string().regex(/^\d+$/).transform(Number).optional(),
  offset: z.string().regex(/^\d+$/).transform(Number).optional(),
  search: z.string().optional()
});

/**
 * GET /api/crm/leads
 * Listar leads con filtros
 */
router.get('/leads', async (req: Request, res: Response) => {
  try {
    const reqWithId = req as RequestWithId;
    
    // ✅ CORRECCIÓN: Logging para debugging
    logger.debug('[CRM Routes] Leads request', {
      query: req.query,
      department: req.query['department'],
      limit: req.query['limit'],
      offset: req.query['offset']
    });
    
    // Validar query params con Zod
    const parsed = listLeadsQuerySchema.parse(req.query);

    const filters: {
      department: 'cmo' | 'cso';
      status?: string;
      limit?: number;
      offset?: number;
      search?: string;
    } = {
      department: parsed.department
    };

    if (parsed.status) {
      filters.status = parsed.status;
    }
    if (parsed.limit) {
      filters.limit = parsed.limit;
    }
    if (parsed.offset) {
      filters.offset = parsed.offset;
    }
    if (parsed.search) {
      filters.search = parsed.search;
    }

    const result = await listLeads(filters);

    if (result.success) {
      logger.info('[CRM Routes] Leads obtenidos', {
        department: parsed.department,
        count: result.data.leads.length,
        total: result.data.total,
        requestId: reqWithId.id
      });
    }

    sendResult(res, result);
    return;
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({
        success: false,
        error: 'Parámetros de consulta inválidos',
        details: error.errors,
        code: 'INVALID_QUERY_PARAMS'
      });
    }

    logger.error('[CRM Routes] Error obteniendo leads', {
      error: error instanceof Error ? error.message : String(error),
      requestId: (req as RequestWithId).id
    });
    res.status(500).json({ success: false, error: 'Error interno del servidor' });
    return;
  }
});

/**
 * GET /api/crm/sales-metrics
 * Obtener métricas de ventas (optimizado con caché)
 */
// Schema de validación para query params de sales-metrics
const salesMetricsQuerySchema = z.object({
  department: z.enum(['cmo', 'cso']),
  period: z.enum(['day', 'week', 'month', 'year', 'all']).optional().default('month'),
  startDate: z.string().datetime().optional(),
  endDate: z.string().datetime().optional()
});

router.get('/sales-metrics', async (req: Request, res: Response) => {
  try {
    const reqWithId = req as RequestWithId;
    
    // ✅ CORRECCIÓN: Logging para debugging
    logger.debug('[CRM Routes] Sales metrics request', {
      query: req.query,
      department: req.query['department'],
      period: req.query['period']
    });
    
    // Validar query params con Zod
    const parsed = salesMetricsQuerySchema.parse(req.query);

    const result = await getSalesMetrics(
      parsed.department,
      parsed.period,
      parsed.startDate,
      parsed.endDate
    );

    if (result.success) {
      logger.info('[CRM Routes] Sales metrics obtenidas', {
        department: parsed.department,
        period: parsed.period,
        total_revenue: result.data.total_revenue,
        requestId: reqWithId.id
      });
    }

    sendResult(res, result);
    return;
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({
        success: false,
        error: 'Parámetros de consulta inválidos',
        details: error.errors,
        code: 'INVALID_QUERY_PARAMS'
      });
    }

    logger.error('[CRM Routes] Error obteniendo sales metrics', {
      error: error instanceof Error ? error.message : String(error),
      requestId: (req as RequestWithId).id
    });
    res.status(500).json({ success: false, error: 'Error interno del servidor' });
    return;
  }
});

export { router as crmRoutes };

