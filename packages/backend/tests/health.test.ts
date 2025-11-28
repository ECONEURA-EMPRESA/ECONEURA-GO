import request from 'supertest';
import { createServer } from '../src/api/http/server';

describe('GET /health', () => {
  it('debe devolver 200 y status ok', async () => {
    const app = await createServer();

    const response = await request(app).get('/health');

    expect(response.status).toBe(200);
    expect(response.body).toMatchObject({ status: 'ok' });
  });
});


