/**
 * ECONEURA - Knowledge Domain: Service Factory
 * Factory para crear instancias de los servicios del dominio knowledge
 */
import { InMemoryDocumentStore } from './inMemoryDocumentStore';
import { InMemoryDocumentChunkStore } from './inMemoryDocumentChunkStore';
import { StubDocumentProcessor } from './stubDocumentProcessor';
import { azureBlobAdapter } from '../../infra/storage/AzureBlobAdapter';

// Instancias singleton para toda la aplicación
export const documentStore = new InMemoryDocumentStore();
export const documentChunkStore = new InMemoryDocumentChunkStore();
export const documentProcessor = new StubDocumentProcessor();

// Storage service (ya existe como singleton)
export const storageService = azureBlobAdapter;

