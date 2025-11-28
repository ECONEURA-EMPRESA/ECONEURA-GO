/**
 * ECONEURA - Telemetry Middleware
 * Middleware para instrumentación automática de requests con Application Insights
 */
import type { Request, Response, NextFunction } from 'express';
import {
  getTelemetryClient,
  trackMetric,
  trackTrace,
  setCorrelationContext
} from './applicationInsights';
import type { RequestWithId } from '../../api/http/middleware/requestId';
import type { AuthContext } from '../../shared/types/auth';

/**
 * Middleware de telemetría que instrumenta automáticamente todas las requests
 */
export function telemetryMiddleware(req: Request, res: Response, next: NextFunction): void {
  const reqWithId = req as RequestWithId;
  const correlationId = reqWithId.id || 'unknown';

  const startTime = Date.now();

  // Establecer contexto de correlación
  const authContext = (req as Request & { authContext?: AuthContext }).authContext;
  setCorrelationContext({
    correlationId
  });

  const client = getTelemetryClient();
  if (client) {
    client.trackRequest({
      name: `${req.method} ${req.path}`,
      url: req.url,
      duration: 0, // Se actualizará al final
      resultCode: '200', // Se actualizará al final (debe ser string)
      success: true, // Se actualizará al final
      properties: {
        method: req.method,
        path: req.path,
        correlationId,
        tenantId: authContext?.tenantId || 'unknown',
        userId: authContext?.userId || 'unknown'
      }
    });
  }

  // Interceptar respuesta para medir duración
  res.on('finish', () => {
    const duration = Date.now() - startTime;

    // Track métrica de duración
    trackMetric('http_request_duration_ms', duration, {
      method: req.method,
      path: req.path,
      status: res.statusCode.toString()
    });

    // Track métrica de status code
    trackMetric('http_request_status', res.statusCode, {
      method: req.method,
      path: req.path
    });

    // Track error si es 5xx
    if (res.statusCode >= 500) {
      trackTrace(
        `Server error: ${req.method} ${req.path} - Status ${res.statusCode}`,
        'Error',
        {
          method: req.method,
          path: req.path,
          status: res.statusCode.toString(),
          correlationId
        }
      );
    } else if (res.statusCode >= 400) {
      trackTrace(
        `Client error: ${req.method} ${req.path} - Status ${res.statusCode}`,
        'Warning',
        {
          method: req.method,
          path: req.path,
          status: res.statusCode.toString(),
          correlationId
        }
      );
    }

    // Application Insights maneja las operaciones automáticamente
    // No necesitamos finalizar manualmente
  });

  next();
}

