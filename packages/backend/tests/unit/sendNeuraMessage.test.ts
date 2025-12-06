import { sendNeuraMessage } from '../../src/conversation/sendNeuraMessage';
import * as appendMessage from '../../src/conversation/appendMessage';
import * as startConversation from '../../src/conversation/startConversation';
import { inMemoryConversationStore } from '../../src/conversation/store/inMemoryConversationStore';
import * as invokeLLMAgent from '../../src/llm/invokeLLMAgent';
import * as neuraCatalog from '../../src/neura/neuraCatalog';
import * as llmAgentsRegistry from '../../src/llm/llmAgentsRegistry';

jest.mock('../../src/conversation/appendMessage');
jest.mock('../../src/conversation/startConversation');
jest.mock('../../src/conversation/store/inMemoryConversationStore');
jest.mock('../../src/llm/invokeLLMAgent');
jest.mock('../../src/neura/neuraCatalog');
jest.mock('../../src/llm/llmAgentsRegistry');

describe('sendNeuraMessage', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    // Asegurar que getMessages siempre devuelva un array
    (inMemoryConversationStore.getMessages as jest.Mock).mockResolvedValue([]);
  });

  const mockInput = {
    neuraId: 'neura-ceo' as any,
    message: 'Hola',
    userId: 'test-user',
    tenantId: 'test-tenant',
  };

  test('debería devolver error si neuraId no se proporciona', async () => {
    const result = await sendNeuraMessage({ ...mockInput, neuraId: undefined as any });
    expect(result.success).toBe(false);
    if (!result.success) {
      expect(result.error.message).toBe('neuraId is required');
    }
  });

  test('debería crear una nueva conversación si no se proporciona conversationId', async () => {
    (startConversation.startConversation as jest.Mock).mockResolvedValue({ success: true, data: { id: 'new-convo' } });
    (neuraCatalog.getNeuraById as jest.Mock).mockReturnValue({ success: true, data: {} });
    (appendMessage.appendMessage as jest.Mock).mockResolvedValue({ success: true, data: {} });
    (invokeLLMAgent.invokeLLMAgent as jest.Mock).mockResolvedValue({ success: true, data: { outputText: 'Respuesta' } });

    await sendNeuraMessage(mockInput);
    expect(startConversation.startConversation).toHaveBeenCalled();
  });

  test('debería manejar error si la creación de la conversación falla', async () => {
    (neuraCatalog.getNeuraById as jest.Mock).mockReturnValue({ success: true, data: {} });
    (startConversation.startConversation as jest.Mock).mockResolvedValue({ success: false, error: new Error('Fallo al crear') });

    const result = await sendNeuraMessage(mockInput);
    expect(result.success).toBe(false);
    if (!result.success) {
      expect(result.error.message).toBe('Fallo al crear');
    }
  });

  test('debería manejar error si appendMessage falla', async () => {
    (startConversation.startConversation as jest.Mock).mockResolvedValue({ success: true, data: { id: 'new-convo' } });
    (neuraCatalog.getNeuraById as jest.Mock).mockReturnValue({ success: true, data: {} });
    (appendMessage.appendMessage as jest.Mock).mockResolvedValue({ success: false, error: new Error('Fallo al añadir mensaje') });

    const result = await sendNeuraMessage(mockInput);
    expect(result.success).toBe(false);
    if (!result.success) {
      expect(result.error.message).toBe('Fallo al añadir mensaje');
    }
  });

  test('debería manejar error si invokeLLMAgent falla', async () => {
    (startConversation.startConversation as jest.Mock).mockResolvedValue({ success: true, data: { id: 'new-convo' } });
    (neuraCatalog.getNeuraById as jest.Mock).mockReturnValue({ success: true, data: { llmAgentId: 'test-agent' } });
    (llmAgentsRegistry.getLLMAgent as jest.Mock).mockReturnValue({ success: true, data: { provider: 'test' } });
    (appendMessage.appendMessage as jest.Mock).mockResolvedValue({ success: true, data: {} });
    (invokeLLMAgent.invokeLLMAgent as jest.Mock).mockResolvedValue({ success: false, error: new Error('Fallo en LLM') });

    const result = await sendNeuraMessage(mockInput);
    expect(result.success).toBe(false);
    if (!result.success) {
      expect(result.error.message).toBe('Fallo en LLM');
    }
  });

  test('debería pasar el historial de mensajes al LLM', async () => {
    (startConversation.startConversation as jest.Mock).mockResolvedValue({ success: true, data: { id: 'new-convo' } });
    (neuraCatalog.getNeuraById as jest.Mock).mockReturnValue({ success: true, data: { llmAgentId: 'test-agent' } });
    (llmAgentsRegistry.getLLMAgent as jest.Mock).mockReturnValue({ success: true, data: { provider: 'test' } });
    (appendMessage.appendMessage as jest.Mock).mockResolvedValue({ success: true, data: {} });
    (invokeLLMAgent.invokeLLMAgent as jest.Mock).mockResolvedValue({ success: true, data: { outputText: 'Respuesta' } });
    (inMemoryConversationStore.getMessages as jest.Mock).mockResolvedValue([
      { role: 'user', content: 'Mensaje anterior' },
      { role: 'assistant', content: 'Respuesta anterior' },
      { role: 'user', content: 'Hola' },
    ]);

    await sendNeuraMessage(mockInput);

    expect(invokeLLMAgent.invokeLLMAgent).toHaveBeenCalledWith(
      expect.objectContaining({
        conversationHistory: [
          { role: 'user', content: 'Mensaje anterior' },
          { role: 'assistant', content: 'Respuesta anterior' },
        ],
      }),
      expect.any(Object)
    );
  });
});
