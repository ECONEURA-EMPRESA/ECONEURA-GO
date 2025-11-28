/**
 * ECONEURA Backend - Entry Point
 * Inicializa servicios de infraestructura antes de arrancar el servidor
 */
// Cargar variables de entorno desde .env PRIMERO
import { config } from 'dotenv';
import { resolve } from 'path';

// Cargar .env desde el directorio del backend (usando __dirname de CommonJS)
const envPath = resolve(__dirname, '../.env');
config({ path: envPath }); // Carga .env desde el directorio del backend

import { createServer } from './api/http/server';
import { getValidatedEnv, clearEnvCache, validateEnv } from './config/env'; // Added validateEnv
import { logger } from './shared/logger';

// Limpiar cache de entorno para forzar recarga después de cargar .env
clearEnvCache();

// Validar variables de entorno PRIMERO (falla rápido si faltan)
let env: ReturnType<typeof getValidatedEnv>;
try {
  // Call validateEnv as per instruction
  validateEnv();
  env = getValidatedEnv();
  logger.info('[Startup] Variables de entorno validadas correctamente');
} catch (error) {

  console.error('❌ ERROR: Validación de variables de entorno falló:', error instanceof Error ? error.message : String(error));

  console.error('Por favor, revisa tu archivo .env o variables de entorno');
  process.exit(1);
}

// Inicializar DI Container (debe ser lo primero)
import { initializeServices } from './infra/di';

// Inicializar Application Insights (debe ser lo primero)
import './infra/observability/applicationInsights';

// Inicializar Redis (para rate limiting distribuido)
import './infra/cache/redisClient';

// Inicializar Base de Datos (Tablas)
import { initDatabase } from './infra/persistence/initDb';

// Inicializar servicios en DI Container
try {
  initializeServices();
  logger.info('[Startup] Servicios inicializados correctamente');
} catch (error) {
  logger.error('[Startup] Error inicializando servicios', {
    error: error instanceof Error ? error.message : String(error)
  });
  if (env.NODE_ENV === 'production') {
    process.exit(1);
  }
}

// Función async para inicializar el servidor
async function startServer() {
  // Inicializar tablas de BD solo si NO estamos en modo memoria
  if (process.env['USE_MEMORY_STORE'] !== 'true') {
    await initDatabase();
  } else {
    logger.warn('[Startup] Skipping database initialization (USE_MEMORY_STORE=true)');
  }

  const app = await createServer();

  const port = Number(env.PORT ?? 3001); // Backend en puerto 3001, frontend en 3000

  app.listen(port, () => {
    logger.info(`✅ ECONEURA backend escuchando en el puerto ${port}`, {
      environment: env.NODE_ENV,
      port,
      healthCheck: `http://localhost:${port}/api/health`
    });
  });
}

// Iniciar servidor
startServer().catch((error) => {
  console.error('FATAL STARTUP ERROR:', error);
  logger.error('[Startup] Error fatal iniciando servidor', {
    error: error instanceof Error ? error.message : String(error),
    stack: error instanceof Error ? error.stack : undefined
  });
  process.exit(1);
});


