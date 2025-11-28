/**
 * ECONEURA - Logger Estructurado - Código Senior 2025
 * Reemplaza console.log con logging enterprise-grade
 */

import winston from 'winston';
import path from 'path';
import fs from 'fs';
import { sanitizeMetadata, sanitizeLogMessage } from './utils/logSanitizer';

// Crear directorio de logs si no existe
const logsDir = path.join(process.cwd(), 'logs');

if (!fs.existsSync(logsDir)) {
  try {
    fs.mkdirSync(logsDir, { recursive: true });
  } catch (err) {
    // En Azure App Service, puede no tener permisos, usar console
    // ✅ AUDITORÍA: console.warn justificado aquí (bootstrap, logger aún no inicializado)

    console.warn('[Logger] No se pudo crear directorio de logs:', (err as Error).message);
  }
}

// NO importar Application Insights aquí para evitar circular dependency
// Se importará de forma lazy cuando sea necesario

/**
 * Formato personalizado para ECONEURA
 * Sanitiza información sensible antes de escribir
 */
const customFormat = winston.format.printf(({ level, message, timestamp, correlationId, ...metadata }) => {
  // Sanitizar mensaje
  const sanitizedMessage = sanitizeLogMessage(String(message));

  // Sanitizar metadata
  const sanitizedMetadata = sanitizeMetadata(metadata as Record<string, unknown>);

  let msg = `${timestamp} [${level.toUpperCase()}]`;

  // En producción, no mostrar correlationId completo (solo últimos 4 caracteres)
  if (correlationId) {
    const isProduction = process.env['NODE_ENV'] === 'production';
    if (isProduction && typeof correlationId === 'string' && correlationId.length > 4) {
      msg += ` [***${correlationId.substring(correlationId.length - 4)}]`;
    } else {
      msg += ` [${correlationId}]`;
    }
  }

  msg += `: ${sanitizedMessage}`;

  if (Object.keys(sanitizedMetadata).length > 0) {
    msg += ` ${JSON.stringify(sanitizedMetadata)}`;
  }

  return msg;
});

/**
 * Configure transports based on environment
 */
const transports: winston.transport[] = [
  new winston.transports.Console({
    format: winston.format.combine(
      winston.format.colorize(),
      customFormat
    )
  })
];

// File transports solo en local o si hay permisos
if (process.env['NODE_ENV'] !== 'production' || fs.existsSync(logsDir)) {
  try {
    transports.push(
      new winston.transports.File({
        filename: path.join(logsDir, 'error.log'),
        level: 'error',
        maxsize: 10 * 1024 * 1024,
        maxFiles: 14,
        format: winston.format.combine(
          winston.format.timestamp(),
          winston.format.json()
        )
      })
    );

    transports.push(
      new winston.transports.File({
        filename: path.join(logsDir, 'combined.log'),
        maxsize: 10 * 1024 * 1024,
        maxFiles: 7,
        format: winston.format.combine(
          winston.format.timestamp(),
          winston.format.json()
        )
      })
    );
  } catch (err) {

    console.warn('[Logger] No se pudieron crear file transports:', (err as Error).message);
  }
}

/**
 * Instancia principal de logger
 */
const winstonLogger = winston.createLogger({
  level: process.env['LOG_LEVEL'] || (process.env['NODE_ENV'] === 'production' ? 'info' : 'debug'),
  format: winston.format.combine(
    winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
    winston.format.errors({ stack: true }),
    winston.format.splat(),
    winston.format.json()
  ),
  defaultMeta: {
    service: 'econeura-backend',
    environment: process.env['NODE_ENV'] || 'development'
  },
  transports
});

/**
 * Helper para Application Insights (integración completa)
 * Importación lazy para evitar circular dependency
 */
function logToAppInsights(level: string, message: string, metadata?: Record<string, unknown>): void {
  try {
    // Importación lazy para evitar circular dependency

    const appInsights = require('../infra/observability/applicationInsights');
    const client = appInsights.getTelemetryClient();
    if (!client) {
      return; // Application Insights no disponible
    }

    // Convertir metadata a formato string (Application Insights requiere strings)
    const properties: Record<string, string> = {};
    if (metadata) {
      for (const [key, value] of Object.entries(metadata)) {
        properties[key] = typeof value === 'string' ? value : JSON.stringify(value);
      }
    }

    switch (level) {
      case 'error':
        appInsights.trackException(new Error(message), properties);
        break;
      case 'warn':
        appInsights.trackTrace(message, 'Warning', properties);
        break;
      case 'info':
        appInsights.trackTrace(message, 'Information', properties);
        break;
      case 'debug':
        appInsights.trackTrace(message, 'Verbose', properties);
        break;
      default:
        appInsights.trackTrace(message, 'Verbose', properties);
    }
  } catch {
    // No fallar si Application Insights tiene problemas o no está disponible
    // Silenciar errores para evitar loops
  }
}

/**
 * Contexto de correlación global (para logging)
 */
let correlationContext: {
  correlationId?: string;
  tenantId?: string;
  userId?: string;
} = {};

/**
 * Establecer contexto de correlación para logging
 */
export function setCorrelationContext(context: {
  correlationId?: string;
  tenantId?: string;
  userId?: string;
}): void {
  correlationContext = { ...correlationContext, ...context };
}

/**
 * Obtener contexto de correlación actual
 */
export function getCorrelationContext(): {
  correlationId?: string;
  tenantId?: string;
  userId?: string;
} {
  return { ...correlationContext };
}

/**
 * Enriquecer metadata con contexto de correlación
 */
function enrichMetadata(metadata?: Record<string, unknown>): Record<string, unknown> {
  return {
    ...metadata,
    ...(correlationContext.correlationId ? { correlationId: correlationContext.correlationId } : {}),
    ...(correlationContext.tenantId ? { tenantId: correlationContext.tenantId } : {}),
    ...(correlationContext.userId ? { userId: correlationContext.userId } : {})
  };
}

/**
 * API pública de logger
 * Todas las funciones sanitizan automáticamente mensajes y metadata
 */
export const logger = {
  error: (message: string, metadata?: Record<string, unknown>): void => {
    const enriched = enrichMetadata(metadata);
    const sanitizedMsg = sanitizeLogMessage(message);
    const sanitizedMeta = sanitizeMetadata(enriched);
    winstonLogger.error(sanitizedMsg, sanitizedMeta);
    logToAppInsights('error', sanitizedMsg, sanitizedMeta);
  },

  warn: (message: string, metadata?: Record<string, unknown>): void => {
    const enriched = enrichMetadata(metadata);
    const sanitizedMsg = sanitizeLogMessage(message);
    const sanitizedMeta = sanitizeMetadata(enriched);
    winstonLogger.warn(sanitizedMsg, sanitizedMeta);
    logToAppInsights('warn', sanitizedMsg, sanitizedMeta);
  },

  info: (message: string, metadata?: Record<string, unknown>): void => {
    const enriched = enrichMetadata(metadata);
    const sanitizedMsg = sanitizeLogMessage(message);
    const sanitizedMeta = sanitizeMetadata(enriched);
    winstonLogger.info(sanitizedMsg, sanitizedMeta);
    logToAppInsights('info', sanitizedMsg, sanitizedMeta);
  },

  debug: (message: string, metadata?: Record<string, unknown>): void => {
    const enriched = enrichMetadata(metadata);
    const sanitizedMsg = sanitizeLogMessage(message);
    const sanitizedMeta = sanitizeMetadata(enriched);
    winstonLogger.debug(sanitizedMsg, sanitizedMeta);
    logToAppInsights('debug', sanitizedMsg, sanitizedMeta);
  },

  verbose: (message: string, metadata?: Record<string, unknown>): void => {
    const enriched = enrichMetadata(metadata);
    const sanitizedMsg = sanitizeLogMessage(message);
    const sanitizedMeta = sanitizeMetadata(enriched);
    winstonLogger.verbose(sanitizedMsg, sanitizedMeta);
    logToAppInsights('verbose', sanitizedMsg, sanitizedMeta);
  }
};

export default logger;
