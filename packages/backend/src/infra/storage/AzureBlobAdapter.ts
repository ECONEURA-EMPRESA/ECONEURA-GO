/**
 * ECONEURA - Azure Blob Storage Adapter
 * Servicio de Azure Blob Storage con fallback a local
 * Migrado desde ECONEURA-REMOTE/backend/services/azureBlob.js
 */
import path from 'path';
import fs from 'fs';
import { BlobServiceClient } from '@azure/storage-blob';
import { logger } from '../../shared/logger';
import { getValidatedEnv } from '../../config/env';
import type { StorageService } from './StorageService';

const containerName = process.env['AZURE_BLOB_CONTAINER'] || 'econeura-library';
const localDir = path.join(process.cwd(), 'uploads');

function ensureLocalDir(): void {
  try {
    fs.mkdirSync(localDir, { recursive: true });
  } catch {
    // Error creating dir - ignore
  }
}

export class AzureBlobAdapter implements StorageService {
  private readonly connectionString: string | null;
  private readonly blobServiceClient: BlobServiceClient | null;

  constructor() {
    const env = getValidatedEnv();
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const connString = (env as any)['AZURE_STORAGE_CONNECTION_STRING'] as string | undefined;

    if (connString && typeof connString === 'string') {
      this.connectionString = connString;
      try {
        this.blobServiceClient = BlobServiceClient.fromConnectionString(connString);
        logger.info('[AzureBlobAdapter] Cliente Azure Blob Storage inicializado');
      } catch (error) {
        logger.error('[AzureBlobAdapter] Error inicializando cliente', {
          error: error instanceof Error ? error.message : String(error)
        });
        this.blobServiceClient = null;
      }
    } else {
      this.connectionString = null;
      this.blobServiceClient = null;
      logger.warn('[AzureBlobAdapter] AZURE_STORAGE_CONNECTION_STRING no configurado, usando almacenamiento local');
    }
  }

  isConfigured(): boolean {
    return this.blobServiceClient !== null && this.connectionString !== null;
  }

  async uploadBuffer(
    buffer: Buffer,
    storedName: string,
    mimeType: string
  ): Promise<{ provider: string; path: string }> {
    if (this.isConfigured() && this.blobServiceClient) {
      try {
        const containerClient = this.blobServiceClient.getContainerClient(containerName);
        await containerClient.createIfNotExists();
        const blockBlobClient = containerClient.getBlockBlobClient(storedName);
        await blockBlobClient.uploadData(buffer, {
          blobHTTPHeaders: { blobContentType: mimeType }
        });
        return { provider: 'azure', path: `${containerName}/${storedName}` };
      } catch (error) {
        logger.error('[AzureBlobAdapter] Error subiendo a Azure, usando fallback local', {
          error: error instanceof Error ? error.message : String(error)
        });
        // Fallback a local
        return this.uploadToLocal(buffer, storedName);
      }
    }

    // Fallback a local
    return this.uploadToLocal(buffer, storedName);
  }

  private uploadToLocal(buffer: Buffer, storedName: string): { provider: string; path: string } {
    ensureLocalDir();
    const target = path.join(localDir, storedName);
    fs.writeFileSync(target, buffer);
    return { provider: 'local', path: target };
  }

  async downloadToBuffer(provider: string, storagePath: string): Promise<Buffer> {
    if (provider === 'azure' && this.isConfigured() && this.blobServiceClient) {
      try {
        const parts = storagePath.split('/');
        if (parts.length < 2) {
          throw new Error(`Invalid storage path format: ${storagePath}`);
        }
        const container = parts[0];
        if (!container) {
          throw new Error(`Container name is empty in path: ${storagePath}`);
        }
        const blobName = parts.slice(1).join('/');
        const containerClient = this.blobServiceClient.getContainerClient(container);
        const blobClient = containerClient.getBlobClient(blobName);
        const download = await blobClient.download();
        const chunks: Buffer[] = [];

        if (download.readableStreamBody) {
          for await (const chunk of download.readableStreamBody) {
            chunks.push(Buffer.from(chunk));
          }
        }

        return Buffer.concat(chunks);
      } catch (error) {
        logger.error('[AzureBlobAdapter] Error descargando de Azure', {
          error: error instanceof Error ? error.message : String(error)
        });
        throw error;
      }
    }

    // Local
    if (!fs.existsSync(storagePath)) {
      throw new Error(`Archivo local no encontrado: ${storagePath}`);
    }
    return fs.readFileSync(storagePath);
  }
}

export const azureBlobAdapter = new AzureBlobAdapter();

