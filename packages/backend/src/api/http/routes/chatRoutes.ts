import { Router } from 'express';
import { executeNeuraAgentFromChat } from '../../../automation/neuraAgentExecutor';
import { requireRoles } from '../middleware/rbacMiddleware';

const router = Router();

router.post('/api/chat/:neuraKey/execute-agent', requireRoles('admin', 'user'), async (req, res) => {
  const { neuraKey } = req.params;
  const { message, neuraId, userId, correlationId } = req.body as {
    message?: string;
    neuraId?: string;
    userId?: string;
    correlationId?: string;
  };

  if (!message) {
    return res.status(400).json({
      success: false,
      error: 'message is required'
    });
  }

  try {
    const result = await executeNeuraAgentFromChat(message, {
      neuraKey: neuraKey ?? '',
      neuraId: neuraId ?? '',
      userId: userId ?? null,
      correlationId: correlationId ?? undefined
    });

    if (!result.success) {
      return res.status(500).json({
        success: false,
        error: result.error.message
      });
    }

    return res.status(200).json({
      success: result.data.success,
      message: result.data.message
    });
  } catch (e) {
    const error = e instanceof Error ? e : new Error('Unknown error');
    return res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

export const chatRoutes = router;


