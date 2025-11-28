import { logger } from '../utils/logger';

interface ValidatedEnv {
  DATABASE_URL: string;
  REDIS_HOST: string;
  REDIS_PASSWORD: string;
  REDIS_PORT: string;
  GEMINI_API_KEY: string;
  NODE_ENV?: string;
  PORT?: string;
  [key: string]: string | undefined;
}

export const validateEnv = () => {
  const requiredEnv = [
    'DATABASE_URL',
    'REDIS_HOST',
    'REDIS_PASSWORD',
    'REDIS_PORT',
    'GEMINI_API_KEY'
  ];

  const missing = requiredEnv.filter(env => !process.env[env]);

  if (missing.length > 0) {
    logger.error('❌ Missing required environment variables:', { missing });
    if (process.env.NODE_ENV === 'production') {
      process.exit(1);
    }
  } else {
    logger.info('✅ Environment variables validated');
  }
};

export const getValidatedEnv = (): ValidatedEnv => {
  validateEnv();
  return process.env as ValidatedEnv;
};

export const clearEnvCache = () => {
  // Placeholder for cache clearing if needed
};
