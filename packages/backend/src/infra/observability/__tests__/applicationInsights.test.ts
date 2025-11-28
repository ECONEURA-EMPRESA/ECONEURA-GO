/**
 * Tests unitarios para Application Insights
 */
import { describe, it, expect, beforeEach, jest } from '@jest/globals';
import {
  initializeApplicationInsights,
  getTelemetryClient,
  trackEvent,
  trackMetric,
  trackTrace,
  trackException,
  setCorrelationContext
} from '../applicationInsights';

// Mock de applicationinsights
jest.mock('applicationinsights', () => {
  const mockClient = {
    trackEvent: jest.fn(),
    trackMetric: jest.fn(),
    trackTrace: jest.fn(),
    trackException: jest.fn(),
    trackRequest: jest.fn(),
    context: {
      tags: {},
      keys: {
        cloudRole: 'cloudRole',
        cloudRoleInstance: 'cloudRoleInstance'
      }
    }
  };

  return {
    setup: jest.fn().mockReturnValue({
      setAutoDependencyCorrelation: jest.fn().mockReturnThis(),
      setAutoCollectRequests: jest.fn().mockReturnThis(),
      setAutoCollectPerformance: jest.fn().mockReturnThis(),
      setAutoCollectExceptions: jest.fn().mockReturnThis(),
      setAutoCollectDependencies: jest.fn().mockReturnThis(),
      setAutoCollectConsole: jest.fn().mockReturnThis(),
      setUseDiskRetryCaching: jest.fn().mockReturnThis(),
      setSendLiveMetrics: jest.fn().mockReturnThis(),
      start: jest.fn()
    }),
    defaultClient: mockClient,
    getCorrelationContext: jest.fn().mockReturnValue({
      customProperties: {}
    })
  };
});

describe('Application Insights', () => {
  beforeEach(() => {
    // Reset mocks
    jest.clearAllMocks();
    // Reset module state
    jest.resetModules();
  });

  describe('initializeApplicationInsights', () => {
    it('debería inicializar Application Insights si hay connection string', () => {
      // Mock environment
      process.env['APPLICATIONINSIGHTS_CONNECTION_STRING'] = 'InstrumentationKey=test-key';

      const result = initializeApplicationInsights();
      expect(result).toBe(true);
    });

    it('debería retornar false si no hay connection string', () => {
      delete process.env['APPLICATIONINSIGHTS_CONNECTION_STRING'];

      const result = initializeApplicationInsights();
      expect(result).toBe(false);
    });
  });

  describe('getTelemetryClient', () => {
    it('debería retornar cliente si está inicializado', () => {
      process.env['APPLICATIONINSIGHTS_CONNECTION_STRING'] = 'InstrumentationKey=test-key';
      initializeApplicationInsights();

      const client = getTelemetryClient();
      expect(client).not.toBeNull();
    });

    it('debería retornar null si no está inicializado', () => {
      delete process.env['APPLICATIONINSIGHTS_CONNECTION_STRING'];
      jest.resetModules();

      const client = getTelemetryClient();
      expect(client).toBeNull();
    });
  });

  describe('trackEvent', () => {
    it('debería trackear evento si cliente está disponible', () => {
      process.env['APPLICATIONINSIGHTS_CONNECTION_STRING'] = 'InstrumentationKey=test-key';
      initializeApplicationInsights();

      trackEvent('TestEvent', { key: 'value' });

      const appInsights = require('applicationinsights');
      expect(appInsights.defaultClient.trackEvent).toHaveBeenCalledWith({
        name: 'TestEvent',
        properties: expect.objectContaining({
          key: 'value',
          timestamp: expect.any(String)
        })
      });
    });

    it('no debería fallar si cliente no está disponible', () => {
      delete process.env['APPLICATIONINSIGHTS_CONNECTION_STRING'];
      jest.resetModules();

      expect(() => {
        trackEvent('TestEvent', { key: 'value' });
      }).not.toThrow();
    });
  });

  describe('trackMetric', () => {
    it('debería trackear métrica si cliente está disponible', () => {
      process.env['APPLICATIONINSIGHTS_CONNECTION_STRING'] = 'InstrumentationKey=test-key';
      initializeApplicationInsights();

      trackMetric('TestMetric', 100, { key: 'value' });

      const appInsights = require('applicationinsights');
      expect(appInsights.defaultClient.trackMetric).toHaveBeenCalledWith({
        name: 'TestMetric',
        value: 100,
        properties: { key: 'value' }
      });
    });
  });

  describe('trackTrace', () => {
    it('debería trackear trace si cliente está disponible', () => {
      process.env['APPLICATIONINSIGHTS_CONNECTION_STRING'] = 'InstrumentationKey=test-key';
      initializeApplicationInsights();

      trackTrace('Test message', 'Information', { key: 'value' });

      const appInsights = require('applicationinsights');
      expect(appInsights.defaultClient.trackTrace).toHaveBeenCalledWith({
        message: 'Test message',
        severity: 'Information',
        properties: { key: 'value' }
      });
    });
  });

  describe('trackException', () => {
    it('debería trackear excepción si cliente está disponible', () => {
      process.env['APPLICATIONINSIGHTS_CONNECTION_STRING'] = 'InstrumentationKey=test-key';
      initializeApplicationInsights();

      const error = new Error('Test error');
      trackException(error, { key: 'value' });

      const appInsights = require('applicationinsights');
      expect(appInsights.defaultClient.trackException).toHaveBeenCalledWith({
        exception: error,
        properties: { key: 'value' }
      });
    });
  });

  describe('setCorrelationContext', () => {
    it('debería establecer contexto de correlación', () => {
      process.env['APPLICATIONINSIGHTS_CONNECTION_STRING'] = 'InstrumentationKey=test-key';
      initializeApplicationInsights();

      setCorrelationContext({
        tenantId: 'tenant-123',
        userId: 'user-456',
        correlationId: 'corr-789'
      });

      // Verificar que se llamó getCorrelationContext
      const appInsights = require('applicationinsights');
      expect(appInsights.getCorrelationContext).toHaveBeenCalled();
    });
  });
});

