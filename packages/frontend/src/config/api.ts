/**
 * ECONEURA - API Configuration
 * Centralized API URL and correlation ID generation
 */

const getApiUrl = () => {
  // Preferir variable de entorno, fallback a localhost:3000
  if (import.meta.env.VITE_API_URL) {
    return import.meta.env.VITE_API_URL;
  }
  return 'http://localhost:3000/api';
};

export const API_URL = getApiUrl();

export function generateCorrelationId(prefix = 'web'): string {
  return `${prefix}-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
}

