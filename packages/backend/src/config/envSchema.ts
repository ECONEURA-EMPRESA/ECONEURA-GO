import { z } from 'zod';

/**
 * Esquema de variables de entorno para ECONEURA
 * Sólo fijamos aquí lo mínimo imprescindible para arrancar el backend.
 * El resto de secretos de Azure/OpenAI se añaden de forma incremental.
 */

export const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.string().optional(),
  PAYLOAD_LIMIT: z.string().optional(),
  CORS_ALLOWED_ORIGINS: z.string().optional(),

  // Claves de OpenAI / LLM (se pueden ampliar con otros providers)
  OPENAI_API_KEY: z.string().min(1).optional(),
  MISTRAL_API_KEY: z.string().min(1).optional(),
  // Endpoint personalizado para LLM (ej: Mammouth.ai, LiteLLM proxy)
  OPENAI_BASE_URL: z.string().url().optional(),
  LLM_BASE_URL: z.string().url().optional(),
  PUBLIC_UPLOAD_BASE_URL: z.string().url().optional(),

  // Placeholders para Azure / base de datos (se rellenarán cuando migremos infra)
  AZURE_TENANT_ID: z.string().optional(),
  AZURE_SUBSCRIPTION_ID: z.string().optional(),
  AZURE_CLIENT_ID: z.string().optional(),
  AZURE_CLIENT_SECRET: z.string().optional(),

  // Azure Key Vault
  KEY_VAULT_URL: z.string().url().optional(),

  // Azure Blob Storage
  AZURE_STORAGE_CONNECTION_STRING: z.string().optional(),
  AZURE_BLOB_CONTAINER: z.string().optional(),

  // Application Insights
  APPLICATIONINSIGHTS_CONNECTION_STRING: z.string().optional(),

  // Redis Cache
  REDIS_URL: z.string().optional(),

  // Base de datos transaccional principal (PostgreSQL en ECONEURA actual)
  DATABASE_URL: z.string().optional(),

  // CRM Webhooks
  CRM_WEBHOOK_SECRET: z.string().optional(),

  // Event Store / Read Models (futuro Cosmos DB u otro almacenamiento)
  EVENTSTORE_COSMOS_ENDPOINT: z.string().optional(),
  EVENTSTORE_COSMOS_KEY: z.string().optional(),
  EVENTSTORE_COSMOS_DATABASE_ID: z.string().optional(),
  EVENTSTORE_COSMOS_CONTAINER_ID: z.string().optional(),
  READMODELS_COSMOS_ENDPOINT: z.string().optional(),
  READMODELS_COSMOS_KEY: z.string().optional(),
  READMODELS_COSMOS_DATABASE_ID: z.string().optional(),
  READMODELS_COSMOS_CONTAINER_ID: z.string().optional()
});

export type Env = z.infer<typeof envSchema>;

