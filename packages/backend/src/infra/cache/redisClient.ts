/**
 * ECONEURA - Redis Client
 * Cliente Redis para rate limiting distribuido y caching
 */
import Redis from 'ioredis';
import { getValidatedEnv } from '../../config/env';
import { logger } from '../../shared/logger';

let redisClient: Redis | null = null;
let isInitialized = false;

/**
 * Inicializar cliente Redis
 */
export function initializeRedis(): boolean {
  if (isInitialized) {
    return redisClient !== null;
  }

  try {
    const env = getValidatedEnv();
    const redisUrl = env.REDIS_URL;

    if (!redisUrl || typeof redisUrl !== 'string') {
      logger.warn('[Redis] REDIS_URL no configurado, Redis deshabilitado');
      isInitialized = true;
      return false;
    }

    // Crear cliente Redis
    redisClient = new Redis(redisUrl, {
      retryStrategy: (times) => {
        if (times > 10) {
          logger.error('[Redis] Máximo de reintentos alcanzado');
          return null; // Detener reintentos
        }
        const delay = Math.min(times * 50, 2000);
        return delay;
      },
      maxRetriesPerRequest: 3,
      enableReadyCheck: true,
      connectTimeout: 10000,
      commandTimeout: 5000,
      keepAlive: 30000,
      lazyConnect: true,
      enableOfflineQueue: false
    });

    // Event handlers
    redisClient.on('connect', () => {
      logger.info('[Redis] Conectado correctamente');
    });

    redisClient.on('ready', () => {
      logger.info('[Redis] Cliente listo');
    });

    redisClient.on('error', (error) => {
      logger.error('[Redis] Error de conexión', { error: error.message });
    });

    redisClient.on('close', () => {
      logger.warn('[Redis] Conexión cerrada');
    });

    // Conectar
    redisClient.connect().catch((error) => {
      logger.error('[Redis] Error conectando', { error: error.message });
      redisClient = null;
    });

    isInitialized = true;
    return true;
  } catch (error) {
    logger.error('[Redis] Error inicializando cliente', {
      error: error instanceof Error ? error.message : String(error)
    });
    isInitialized = true;
    return false;
  }
}

/**
 * Obtener cliente Redis
 */
export function getRedisClient(): Redis | null {
  if (!isInitialized) {
    initializeRedis();
  }
  return redisClient;
}

/**
 * Verificar si Redis está disponible
 */
export function isRedisAvailable(): boolean {
  const client = getRedisClient();
  return client !== null && client.status === 'ready';
}

/**
 * Cerrar conexión Redis
 */
export async function closeRedis(): Promise<void> {
  if (redisClient) {
    await redisClient.quit();
    redisClient = null;
    logger.info('[Redis] Conexión cerrada');
  }
}

// Inicializar automáticamente al importar
initializeRedis();

