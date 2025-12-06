import { automationService } from '../../src/automation/automationService';
import { makeAdapter } from '../../src/infra/automation/MakeAdapter';
import { n8nAdapter } from '../../src/infra/automation/N8NAdapter';
import { recordAuditEvent } from '../../src/audit/infra/loggerAuditSink';
import * as agentRegistry from '../../src/automation/automationAgentsRegistry';

// Mock de los módulos
jest.mock('../../src/infra/automation/MakeAdapter');
jest.mock('../../src/infra/automation/N8NAdapter');
jest.mock('../../src/audit/infra/loggerAuditSink');

describe('automationService', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  const mockAuthContext = {
    userId: 'test-user',
    tenantId: 'test-tenant',
    roles: ['user'],
    sessionId: 'test-session',
  };

  const mockAgent = {
    id: 'test-agent',
    neuraKey: 'test',
    neuraId: 'test',
    provider: 'make',
    webhookUrl: 'http://test.com',
    active: true,
  };

  test('debe ejecutar en modo mock cuando no hay webhook', async () => {
    const agentWithoutWebhook = { ...mockAgent, webhookUrl: undefined };
    jest.spyOn(agentRegistry, 'getAutomationAgentById').mockReturnValue({ success: true, data: agentWithoutWebhook as any });

    const result = await automationService.executeByAgentId(agentWithoutWebhook.id, {
      input: { test: true },
      authContext: mockAuthContext,
    });

    expect(result.success).toBe(true);
    if (result.success) {
      expect(result.data.mode).toBe('mock');
      expect(result.data.status).toBe('completed');
    }
    expect(recordAuditEvent).toHaveBeenCalledWith(expect.objectContaining({
        action: 'automation.execute',
        metadata: expect.objectContaining({ mode: 'mock' })
    }));
  });

  test('debe manejar error si el agente no existe', async () => {
    jest.spyOn(agentRegistry, 'getAutomationAgentById').mockReturnValue({ success: false, error: new Error('Agent not found') });
    const result = await automationService.executeByAgentId('agente-inexistente', { input: {} });
    expect(result.success).toBe(false);
    if (!result.success) {
      expect(result.error.message).toContain('Agent not found');
    }
  });

  test('debe ejecutar un agente de Make.com exitosamente', async () => {
    jest.spyOn(agentRegistry, 'getAutomationAgentById').mockReturnValue({ success: true, data: mockAgent as any });
    (makeAdapter.executeWebhook as jest.Mock).mockResolvedValue({ success: true, data: { data: { success: true } } });

    const result = await automationService.executeByAgentId(mockAgent.id, { input: {}, authContext: mockAuthContext });

    expect(result.success).toBe(true);
    if (result.success) {
      expect(result.data.mode).toBe('real');
      expect(result.data.provider).toBe('make');
    }
  });

  test('debe manejar un fallo en el adaptador de Make.com', async () => {
    const error = new Error('Fallo en Make.com');
    jest.spyOn(agentRegistry, 'getAutomationAgentById').mockReturnValue({ success: true, data: mockAgent as any });
    (makeAdapter.executeWebhook as jest.Mock).mockResolvedValue({ success: false, error });

    const result = await automationService.executeByAgentId(mockAgent.id, { input: {}, authContext: mockAuthContext });

    expect(result.success).toBe(false);
    if (!result.success) {
      expect(result.error).toBe(error);
    }
  });

  test('debe ejecutar un agente de n8n exitosamente', async () => {
    const n8nAgent = { ...mockAgent, provider: 'n8n' as any };
    jest.spyOn(agentRegistry, 'getAutomationAgentById').mockReturnValue({ success: true, data: n8nAgent as any });
    (n8nAdapter.executeWebhook as jest.Mock).mockResolvedValue({ success: true, data: { data: { success: true } } });

    const result = await automationService.executeByAgentId(n8nAgent.id, { input: {}, authContext: mockAuthContext });

    expect(result.success).toBe(true);
    if (result.success) {
      expect(result.data.mode).toBe('real');
      expect(result.data.provider).toBe('n8n');
    }
  });

  test('debe manejar un fallo en el adaptador de n8n', async () => {
    const n8nAgent = { ...mockAgent, provider: 'n8n' as any };
    const error = new Error('Fallo en n8n');
    jest.spyOn(agentRegistry, 'getAutomationAgentById').mockReturnValue({ success: true, data: n8nAgent as any });
    (n8nAdapter.executeWebhook as jest.Mock).mockResolvedValue({ success: false, error });

    const result = await automationService.executeByAgentId(n8nAgent.id, { input: {}, authContext: mockAuthContext });

    expect(result.success).toBe(false);
    if (!result.success) {
      expect(result.error).toBe(error);
    }
  });

  test('debe devolver error para un provider no soportado', async () => {
    const unsupportedAgent = { ...mockAgent, provider: 'desconocido' as any };
    jest.spyOn(agentRegistry, 'getAutomationAgentById').mockReturnValue({ success: true, data: unsupportedAgent as any });

    const result = await automationService.executeByAgentId(unsupportedAgent.id, { input: {} });

    expect(result.success).toBe(false);
    if (!result.success) {
      expect(result.error.message).toContain('Provider not supported: desconocido');
    }
  });
});
