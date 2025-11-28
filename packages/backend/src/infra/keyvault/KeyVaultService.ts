/**
 * ECONEURA - Azure Key Vault Service
 * Gestión segura de secrets usando Managed Identity
 * Migrado desde ECONEURA-REMOTE/backend/services/keyVaultService.js
 */
import { DefaultAzureCredential } from '@azure/identity';
import { SecretClient } from '@azure/keyvault-secrets';
import { logger } from '../../shared/logger';
import { getValidatedEnv } from '../../config/env';

export interface SecretsService {
  getSecret(secretName: string): Promise<string>;
  getJWTSecret(): Promise<string>;
  getSessionSecret(): Promise<string>;
  getOpenAIKey(): Promise<string>;
  healthCheck(): Promise<{
    status: string;
    message?: string;
    cached_secrets?: number;
    vault_url?: string;
  }>;
}

class KeyVaultService implements SecretsService {
  private client: SecretClient | null = null;
  private readonly cache = new Map<string, string>();
  private readonly cacheExpiry = 5 * 60 * 1000; // 5 minutos
  private readonly lastCacheTime = new Map<string, number>();

  constructor() {
    // Auto-inicializar si KEY_VAULT_URL está disponible
    const env = getValidatedEnv();
    if (env.KEY_VAULT_URL) {
      this.initialize();
    }
  }

  /**
   * Inicializar cliente de Key Vault
   */
  initialize(): boolean {
    try {
      const env = getValidatedEnv();
      const keyVaultUrl = env.KEY_VAULT_URL;

      if (!keyVaultUrl) {
        logger.warn('KEY_VAULT_URL no configurado, usando variables de entorno locales');
        return false;
      }

      // Usar Managed Identity (automático en Azure App Service)
      const credential = new DefaultAzureCredential();
      this.client = new SecretClient(keyVaultUrl, credential);

      logger.info('Cliente Key Vault inicializado correctamente', { keyVaultUrl });

      return true;
    } catch (error) {
      logger.error('Error inicializando Key Vault', {
        error: error instanceof Error ? error.message : String(error),
        stack: error instanceof Error ? error.stack : undefined
      });
      return false;
    }
  }

  /**
   * Obtener secret de Key Vault (con caché)
   */
  async getSecret(secretName: string): Promise<string> {
    // Si no hay cliente, usar variable de entorno
    if (!this.client) {
      const env = getValidatedEnv();
      const envKey = secretName.replace(/-/g, '_').toUpperCase();
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const envValue = (env as any)[envKey];
      if (envValue && typeof envValue === 'string') {
        return envValue;
      }
      throw new Error(`Secret ${secretName} no encontrado en env variables`);
    }

    // Verificar caché
    const now = Date.now();
    const lastCache = this.lastCacheTime.get(secretName);

    if (this.cache.has(secretName) && lastCache !== undefined && now - lastCache < this.cacheExpiry) {
      const cached = this.cache.get(secretName);
      if (cached) {
        return cached;
      }
    }

    // Obtener de Key Vault
    try {
      const secret = await this.client.getSecret(secretName);

      // Guardar en caché
      if (secret.value) {
        this.cache.set(secretName, secret.value);
        this.lastCacheTime.set(secretName, now);
        return secret.value;
      }

      throw new Error(`Secret ${secretName} no tiene valor`);
    } catch (error) {
      logger.error('Error obteniendo secret de Key Vault', {
        secretName,
        error: error instanceof Error ? error.message : String(error)
      });

      // Fallback a variable de entorno
      const env = getValidatedEnv();
      const envKey = secretName.replace(/-/g, '_').toUpperCase();
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const envValue = (env as any)[envKey];
      if (envValue && typeof envValue === 'string') {
        logger.info('Usando fallback de env variable para secret', { secretName });
        return envValue;
      }

      throw error;
    }
  }

  /**
   * Obtener JWT Secret
   */
  async getJWTSecret(): Promise<string> {
    return this.getSecret('JWT-SECRET');
  }

  /**
   * Obtener Session Secret
   */
  async getSessionSecret(): Promise<string> {
    return this.getSecret('SESSION-SECRET');
  }

  /**
   * Obtener OpenAI API Key
   */
  async getOpenAIKey(): Promise<string> {
    return this.getSecret('OPENAI-API-KEY');
  }

  /**
   * Limpiar caché (útil para testing o rotación de secrets)
   */
  clearCache(): void {
    this.cache.clear();
    this.lastCacheTime.clear();
  }

  /**
   * Verificar salud de conexión con Key Vault
   */
  async healthCheck(): Promise<{
    status: string;
    message?: string;
    cached_secrets?: number;
    vault_url?: string;
  }> {
    if (!this.client) {
      return {
        status: 'not_configured',
        message: 'Key Vault no configurado, usando env variables'
      };
    }

    try {
      // Intentar obtener un secret para verificar conectividad
      await this.getSecret('JWT-SECRET');

      const env = getValidatedEnv();
      const healthResult: {
        status: string;
        cached_secrets: number;
        vault_url?: string;
      } = {
        status: 'ok',
        cached_secrets: this.cache.size
      };
      if (env.KEY_VAULT_URL) {
        healthResult.vault_url = env.KEY_VAULT_URL;
      }
      return healthResult;
    } catch (error) {
      return {
        status: 'error',
        message: error instanceof Error ? error.message : String(error)
      };
    }
  }
}

// Singleton
export const keyVaultService = new KeyVaultService();

