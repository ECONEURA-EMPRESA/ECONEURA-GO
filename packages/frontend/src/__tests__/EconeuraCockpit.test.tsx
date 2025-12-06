import React from 'react';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import '@testing-library/jest-dom';
import EconeuraCockpit from '../EconeuraCockpit';
import { vi } from 'vitest';

// Mocks
vi.mock('../config/api', () => ({
  API_URL: 'http://localhost:3000/api',
}));

vi.mock('../utils/apiUrl', () => ({
  getApiUrl: () => 'http://localhost:3000/api',
  getAuthToken: () => 'test-token',
  createAuthHeaders: () => ({}),
}));

vi.mock('sonner', () => ({
  Toaster: () => null,
  toast: {
    success: vi.fn(),
    error: vi.fn(),
  },
}));

vi.mock('../hooks/useNeuraChat', () => ({
  useNeuraChat: () => ({
    chatMsgs: [],
    setChatMsgs: vi.fn(),
    chatInput: '',
    setChatInput: vi.fn(),
    isChatLoading: false,
    pendingAttachment: null,
    isUploadingAttachment: false,
    handleAttachmentUpload: vi.fn(),
    removeAttachment: vi.fn(),
    sendChatMessage: vi.fn(),
  }),
}));

// Mockear el componente `CRMPremiumPanel` que parece estar causando problemas
vi.mock('../components/CRMPremiumPanel', () => ({
  CRMPremiumPanel: () => <div>CRM Premium Panel Mock</div>,
}));

describe('EconeuraCockpit', () => {
  const user = {
    id: 'test-user',
    email: 'test@econeura.com',
    name: 'Test User',
  };

  test('debería renderizarse correctamente', async () => {
    render(<EconeuraCockpit user={user} />);
    // El texto "ECONEURA" está estilizado, buscar por partes
    await waitFor(() => {
        expect(screen.getByText(/ECONEURA/i)).toBeInTheDocument();
    }, { timeout: 3000 });
    expect(screen.getByPlaceholderText(/Buscar agentes/i)).toBeInTheDocument();
  });

  test('debería cambiar de departamento al hacer clic', async () => {
    const user = userEvent.setup();
    render(<EconeuraCockpit user={user} />);

    // Abrir el menú lateral en móvil (donde están los botones de departamento)
    const menuButton = screen.getByLabelText(/Toggle menu/i);
    await user.click(menuButton);

    // Cambiar a Marketing
    const marketingButton = screen.getByRole('button', { name: /Marketing/i });
    await user.click(marketingButton);

    await waitFor(() => {
      expect(screen.getByText('Neura CMO')).toBeInTheDocument();
    }, { timeout: 5000 });
  });

  test('debería filtrar agentes al buscar', async () => {
    const user = userEvent.setup();
    render(<EconeuraCockpit user={user} />);

    const searchInput = screen.getByPlaceholderText(/Buscar agentes/i);
    await user.type(searchInput, 'Consejo');

    await waitFor(() => {
      expect(screen.getByText('Agenda Consejo')).toBeInTheDocument();
      expect(screen.queryByText('Análisis de Competencia')).not.toBeInTheDocument();
    }, { timeout: 5000 });
  });

  test('debería abrir el panel de chat', async () => {
    const user = userEvent.setup();
    render(<EconeuraCockpit user={user} />);

    const openChatButton = screen.getByTestId('open-chat-button');
    await user.click(openChatButton);

    await waitFor(() => {
        expect(screen.getByPlaceholderText(/Escribe tu mensaje/i)).toBeInTheDocument();
    });
  });

  test('debería mostrar el modal de configuración de agente', async () => {
    const user = userEvent.setup();
    render(<EconeuraCockpit user={user} />);

    const configureButtons = screen.getAllByLabelText('Configurar agente');
    await user.click(configureButtons[0]);

    await waitFor(() => {
      expect(screen.getByText('Conectar Agente')).toBeInTheDocument();
    });
  });
});
