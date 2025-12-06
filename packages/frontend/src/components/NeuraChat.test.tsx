import React from 'react';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import '@testing-library/jest-dom';
import { NeuraChat } from './NeuraChat';
import { vi } from 'vitest';

describe('NeuraChat', () => {
  const mockDept = {
    id: 'test-dept',
    name: 'Test Department',
    neura: { title: 'Test Neura', subtitle: '', tags: [] },
  };

  const defaultProps = {
    isOpen: true,
    onClose: vi.fn(),
    dept: mockDept as any,
    messages: [],
    input: '',
    setInput: vi.fn(),
    onSend: vi.fn(),
    isLoading: false,
    pendingAttachment: null,
    onRemoveAttachment: vi.fn(),
    darkMode: false,
  };

  test('no debería renderizarse si isOpen es false', () => {
    render(<NeuraChat {...defaultProps} isOpen={false} />);
    expect(screen.queryByText(/Hola, ¿en qué deberíamos profundizar hoy?/i)).not.toBeInTheDocument();
  });

  test('debería mostrar el mensaje de bienvenida si no hay mensajes', () => {
    render(<NeuraChat {...defaultProps} />);
    expect(screen.getByText(/Hola, ¿en qué deberíamos profundizar hoy?/i)).toBeInTheDocument();
  });

  test('debería llamar a onSend al hacer clic en enviar con un mensaje', async () => {
    const user = userEvent.setup();
    render(<NeuraChat {...defaultProps} input="Hola Neura" />);

    const sendButton = screen.getByRole('button', { name: /Enviar/i });
    await user.click(sendButton);

    expect(defaultProps.onSend).toHaveBeenCalled();
  });

  test('el botón de enviar debería estar deshabilitado si no hay input ni adjunto', () => {
    render(<NeuraChat {...defaultProps} />);
    const sendButton = screen.getByRole('button', { name: /Enviar/i });
    expect(sendButton).toBeDisabled();
  });

  test('debería mostrar los mensajes del usuario y del asistente', () => {
    const messages = [
      { id: '1', role: 'user' as const, text: 'Mensaje de usuario' },
      { id: '2', role: 'assistant' as const, text: 'Respuesta de Neura' },
    ];
    render(<NeuraChat {...defaultProps} messages={messages} />);

    expect(screen.getByText('Mensaje de usuario')).toBeInTheDocument();
    expect(screen.getByText('Respuesta de Neura')).toBeInTheDocument();
  });

  test('debería mostrar el indicador de carga', () => {
    render(<NeuraChat {...defaultProps} isLoading={true} />);
    expect(screen.getByTestId('loading-indicator')).toBeInTheDocument();
  });

  test('debería mostrar la vista previa del adjunto y llamar a onRemoveAttachment', async () => {
    const user = userEvent.setup();
    const attachment = {
      fileId: '123',
      originalName: 'test.png',
      mimeType: 'image/png',
      size: 1024,
      url: 'http://test.com/test.png',
      type: 'image' as const,
    };
    render(<NeuraChat {...defaultProps} pendingAttachment={attachment} />);

    expect(screen.getByAltText('Preview')).toBeInTheDocument();

    const removeButton = screen.getByRole('button', { name: /×/i });
    await user.click(removeButton);

    expect(defaultProps.onRemoveAttachment).toHaveBeenCalled();
  });
});
