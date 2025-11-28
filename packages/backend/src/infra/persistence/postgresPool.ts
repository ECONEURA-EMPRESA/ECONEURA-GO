/**
 * ECONEURA - PostgreSQL Pool Singleton
 * 
 * Pool compartido para todas las operaciones de base de datos.
 * Evita agotamiento de conexiones (Standard_B1ms solo tiene ~100 conexiones máximas).
 * 
 * CRÍTICO: Todos los stores deben usar este pool, NO crear pools propios.
 */

import { Pool, type PoolConfig } from 'pg';
import { getValidatedEnv } from '../../config/env';
import { logger } from '../../shared/logger';

let sharedPool: Pool | null = null;
let healthCheckInterval: NodeJS.Timeout | null = null;

/**
 * Obtener el pool compartido de PostgreSQL
 * 
 * Singleton pattern: solo se crea una vez.
 * Si el pool se cae, se recrea automáticamente en la próxima llamada.
 */
export function getPostgresPool(): Pool {
  if (!sharedPool) {
    const env = getValidatedEnv();
    const databaseUrl = env.DATABASE_URL;

    if (!databaseUrl || typeof databaseUrl !== 'string') {
      throw new Error('DATABASE_URL no configurado');
    }

    const poolConfig: PoolConfig = {
      connectionString: databaseUrl,
      ssl: process.env['NODE_ENV'] === 'production' ? { rejectUnauthorized: false } : false,
      max: 10, // REDUCIDO: Standard_B1ms solo soporta ~100 conexiones totales
      idleTimeoutMillis: 30000, // Cerrar conexiones idle después de 30s
      connectionTimeoutMillis: 5000, // Timeout al conectar
      // Timeouts de queries (PostgreSQL)
      statement_timeout: 30000, // 30 segundos
      query_timeout: 30000
    };

    sharedPool = new Pool(poolConfig);

    // Event handlers para monitoreo
    sharedPool.on('error', (error) => {
      const pgError = error as Error & { code?: string };
      logger.error('[PostgresPool] Error en pool', {
        error: error.message,
        code: pgError.code,
        stack: error.stack
      });

      // Si el pool se cae, resetear para que se recree en próxima llamada
      if (pgError.code === 'ECONNREFUSED' || pgError.code === 'ETIMEDOUT') {
        logger.warn('[PostgresPool] Pool caído, se recreará en próxima llamada');
        sharedPool = null;
        if (healthCheckInterval) {
          clearInterval(healthCheckInterval);
          healthCheckInterval = null;
        }
      }
    });

    sharedPool.on('connect', () => {
      logger.debug('[PostgresPool] Nueva conexión establecida');
    });

    sharedPool.on('acquire', () => {
      logger.debug('[PostgresPool] Conexión adquirida del pool');
    });

    sharedPool.on('remove', () => {
      logger.debug('[PostgresPool] Conexión removida del pool');
    });

    // Health check periódico (cada minuto)
    healthCheckInterval = setInterval(async () => {
      if (!sharedPool) {
        return;
      }

      try {
        const client = await sharedPool.connect();
        try {
          await client.query('SELECT 1');
          logger.debug('[PostgresPool] Health check OK');
        } finally {
          client.release();
        }
      } catch (error) {
        logger.error('[PostgresPool] Health check falló, reiniciando pool', {
          error: error instanceof Error ? error.message : String(error)
        });

        // Cerrar pool y resetear
        try {
          await sharedPool.end();
        } catch {
          // Ignorar errores al cerrar
        }
        sharedPool = null;

        if (healthCheckInterval) {
          clearInterval(healthCheckInterval);
          healthCheckInterval = null;
        }
      }
    }, 60000); // Cada minuto

    logger.info('[PostgresPool] Pool inicializado', {
      max: poolConfig.max,
      environment: process.env['NODE_ENV']
    });
  }

  return sharedPool;
}

/**
 * Cerrar el pool compartido
 * 
 * Llamar al cerrar la aplicación (graceful shutdown).
 */
export async function closePostgresPool(): Promise<void> {
  if (healthCheckInterval) {
    clearInterval(healthCheckInterval);
    healthCheckInterval = null;
  }

  if (sharedPool) {
    try {
      await sharedPool.end();
      logger.info('[PostgresPool] Pool cerrado correctamente');
    } catch (error) {
      logger.error('[PostgresPool] Error cerrando pool', {
        error: error instanceof Error ? error.message : String(error)
      });
    } finally {
      sharedPool = null;
    }
  }
}

/**
 * Verificar si el pool está disponible
 */
export function isPostgresPoolAvailable(): boolean {
  return sharedPool !== null && sharedPool.totalCount > 0;
}

/**
 * Obtener estadísticas del pool (para monitoreo)
 */
export function getPoolStats(): {
  total: number;
  idle: number;
  waiting: number;
} | null {
  if (!sharedPool) {
    return null;
  }

  return {
    total: sharedPool.totalCount,
    idle: sharedPool.idleCount,
    waiting: sharedPool.waitingCount
  };
}

