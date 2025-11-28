/**
 * ECONEURA - Key Vault Provider
 * Provider para obtener secretos de Azure Key Vault
 */
import { DefaultAzureCredential } from '@azure/identity';
import { SecretClient } from '@azure/keyvault-secrets';
import { logger } from '../../shared/logger';
import { getValidatedEnv } from '../../config/env';

export class KeyVaultProvider {
  private client: SecretClient | null = null;
  private vaultUrl: string | null = null;
  private isInitialized = false;

  /**
   * Inicializar cliente de Key Vault
   */
  initialize(): boolean {
    if (this.isInitialized) {
      return this.client !== null;
    }

    try {
      const env = getValidatedEnv();
      const keyVaultUrl = env.KEY_VAULT_URL;

      if (!keyVaultUrl || typeof keyVaultUrl !== 'string') {
        logger.debug('[KeyVaultProvider] KEY_VAULT_URL no configurado');
        this.isInitialized = true;
        return false;
      }

      // Usar Managed Identity (automático en Azure App Service)
      const credential = new DefaultAzureCredential();
      this.client = new SecretClient(keyVaultUrl, credential);
      this.vaultUrl = keyVaultUrl;

      logger.info('[KeyVaultProvider] Cliente inicializado correctamente', { keyVaultUrl });
      this.isInitialized = true;
      return true;
    } catch (error) {
      logger.error('[KeyVaultProvider] Error inicializando', {
        error: error instanceof Error ? error.message : String(error),
        stack: error instanceof Error ? error.stack : undefined
      });
      this.isInitialized = true;
      return false;
    }
  }

  /**
   * Verificar si Key Vault está disponible
   */
  isAvailable(): boolean {
    return this.client !== null && this.isInitialized;
  }

  /**
   * Obtener secret de Key Vault
   */
  async getSecret(secretName: string): Promise<string> {
    if (!this.client) {
      throw new Error('Key Vault client no inicializado');
    }

    try {
      const secret = await this.client.getSecret(secretName);

      if (!secret.value) {
        throw new Error(`Secret ${secretName} no tiene valor`);
      }

      return secret.value;
    } catch (error) {
      logger.error('[KeyVaultProvider] Error obteniendo secret', {
        secretName,
        error: error instanceof Error ? error.message : String(error)
      });
      throw error;
    }
  }

  /**
   * Obtener URL del vault
   */
  getVaultUrl(): string | null {
    return this.vaultUrl;
  }
}

