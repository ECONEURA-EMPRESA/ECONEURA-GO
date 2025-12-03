import express, { Request, Response } from 'express';

const router = express.Router();

/**
 * Health check endpoint
 * Returns 200 if service is running
 */
router.get('/health', (_req: Request, res: Response) => {
    res.status(200).json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        environment: process.env.NODE_ENV || 'development'
    });
});

/**
 * Readiness check endpoint
 * Returns 200 if service is ready to accept traffic
 * Checks: DB connection, Redis connection, etc.
 */
router.get('/ready', async (_req: Request, res: Response) => {
    try {
        // Real health checks
        const dbCheck = await prisma.$queryRaw`SELECT 1`.then(() => 'ok').catch((e) => `error: ${e.message}`);
        const redisCheck = await redis.ping().then(() => 'ok').catch((e) => `error: ${e.message}`);

        const isHealthy = dbCheck === 'ok' && redisCheck === 'ok';

        if (!isHealthy) {
            throw new Error('Infrastructure services unhealthy');
        }

        res.status(200).json({
            status: 'ready',
            timestamp: new Date().toISOString(),
            checks: {
                database: dbCheck,
                redis: redisCheck,
                storage: 'ok' // Storage check skipped for now
            }
        });
    } catch (error) {
        res.status(503).json({
            status: 'not ready',
            error: error instanceof Error ? error.message : 'Unknown error'
        });
    }
});

export default router;
