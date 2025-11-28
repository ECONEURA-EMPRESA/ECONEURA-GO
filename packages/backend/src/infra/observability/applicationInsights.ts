/**
 * ECONEURA - Application Insights Integration
 * Integración completa con Azure Application Insights para observabilidad enterprise
 */
import * as appInsights from 'applicationinsights';
import { getValidatedEnv } from '../../config/env';
import { logger } from '../../shared/logger';

let isInitialized = false;
let telemetryClient: appInsights.TelemetryClient | null = null;

/**
 * Inicializar Application Insights
 * Se llama automáticamente al importar este módulo si APPLICATIONINSIGHTS_CONNECTION_STRING está configurado
 */
export function initializeApplicationInsights(): boolean {
  if (isInitialized) {
    return telemetryClient !== null;
  }

  try {
    const env = getValidatedEnv();
    const connectionString = env.APPLICATIONINSIGHTS_CONNECTION_STRING;

    if (!connectionString || typeof connectionString !== 'string') {
      // ✅ AUDITORÍA: console.warn justificado aquí (bootstrap, logger puede causar circular dependency)

      console.warn('[ApplicationInsights] Connection string no configurado, telemetría deshabilitada');
      isInitialized = true;
      return false;
    }

    // Configurar Application Insights
    appInsights
      .setup(connectionString)
      .setAutoDependencyCorrelation(true)
      .setAutoCollectRequests(true)
      .setAutoCollectPerformance(true, true)
      .setAutoCollectExceptions(true)
      .setAutoCollectDependencies(true)
      .setAutoCollectConsole(true, true)
      .setUseDiskRetryCaching(true)
      .setSendLiveMetrics(true)
      .start();

    telemetryClient = appInsights.defaultClient;

    // Configurar contexto por defecto
    telemetryClient.context.tags[telemetryClient.context.keys.cloudRole] = 'econeura-backend';
    telemetryClient.context.tags[telemetryClient.context.keys.cloudRoleInstance] =
      process.env['WEBSITE_INSTANCE_ID'] || 'local';

    // Usar logger para evitar circular dependency durante inicialización
    // logger.info('[ApplicationInsights] Inicializado correctamente');
    isInitialized = true;
    return true;
  } catch (error) {
    // Usar console.error si logger no está disponible aún (evita circular dependency)
    try {
      logger.error('[ApplicationInsights] Error inicializando', {
        error: error instanceof Error ? error.message : String(error)
      });
    } catch {
      console.error('[ApplicationInsights] Error inicializando', error);
    }
    isInitialized = true;
    return false;
  }
}

/**
 * Obtener cliente de telemetría
 */
export function getTelemetryClient(): appInsights.TelemetryClient | null {
  if (!isInitialized) {
    initializeApplicationInsights();
  }
  return telemetryClient;
}

/**
 * Track custom event
 */
export function trackEvent(name: string, properties?: Record<string, string | number | boolean>): void {
  const client = getTelemetryClient();
  if (client) {
    client.trackEvent({
      name,
      properties: {
        ...properties,
        timestamp: new Date().toISOString()
      }
    });
  }
}

/**
 * Track custom metric
 */
export function trackMetric(name: string, value: number, properties?: Record<string, string>): void {
  const client = getTelemetryClient();
  if (client) {
    client.trackMetric({
      name,
      value,
      ...(properties ? { properties } : {})
    });
  }
}

/**
 * Track trace
 */
export function trackTrace(
  message: string,
  severity: 'Verbose' | 'Information' | 'Warning' | 'Error' | 'Critical',
  properties?: Record<string, string>
): void {
  const client = getTelemetryClient();
  if (client) {
    // Application Insights usa SeverityLevel que es string
    // Los valores válidos son: 'Verbose', 'Information', 'Warning', 'Error', 'Critical'
    client.trackTrace({
      message,
      severity: severity, // SeverityLevel es string, nuestros valores son válidos
      ...(properties ? { properties } : {})
    });
  }
}

/**
 * Track exception
 */
export function trackException(error: Error, properties?: Record<string, string>): void {
  const client = getTelemetryClient();
  if (client) {
    client.trackException({
      exception: error,
      ...(properties ? { properties } : {})
    });
  }
}

/**
 * Start operation (para distributed tracing)
 * Retorna el operation context para poder finalizarlo después
 */
export function startOperation(name: string): { name: string } | null {
  const client = getTelemetryClient();
  if (client) {
    // Application Insights maneja las operaciones automáticamente
    // Solo retornamos un identificador para tracking
    return { name };
  }
  return null;
}

/**
 * Set correlation context (tenantId, userId, etc.)
 */
export function setCorrelationContext(context: {
  tenantId?: string;
  userId?: string;
  correlationId?: string;
}): void {
  const client = getTelemetryClient();
  if (client && appInsights.getCorrelationContext()) {
    const correlationContext = appInsights.getCorrelationContext();
    if (correlationContext) {
      correlationContext.customProperties = {
        ...correlationContext.customProperties,
        ...(context.tenantId ? { tenantId: context.tenantId } : {}),
        ...(context.userId ? { userId: context.userId } : {}),
        ...(context.correlationId ? { correlationId: context.correlationId } : {})
      };
    }
  }
}

// NO inicializar automáticamente aquí para evitar loops infinitos
// Se inicializa explícitamente en registrations.ts cuando se registra el servicio
// Marcar como inicializado si no hay connection string para evitar intentos repetidos
if (typeof process !== 'undefined' && !isInitialized) {
  const env = process.env;
  const connectionString = env['APPLICATIONINSIGHTS_CONNECTION_STRING'];
  if (!connectionString) {
    // Marcar como inicializado sin connection string para evitar loops
    isInitialized = true;
    telemetryClient = null;
  }
}

// Exportar cliente por compatibilidad con código existente
export const defaultClient = telemetryClient;

