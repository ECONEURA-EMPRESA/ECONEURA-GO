import '@testing-library/jest-dom';

// Mock de scrollIntoView para evitar errores en JSDOM
window.HTMLElement.prototype.scrollIntoView = vi.fn();
