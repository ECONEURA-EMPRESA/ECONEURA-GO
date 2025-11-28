// Detector de agentes (versión simplificada)
export interface AgentIntent {
  detected: boolean;
  agentId: string | null;
  action: string;
  confidence: number;
}

export function detectAgentIntent(message: string, deptId: string): AgentIntent {
  return {
    detected: false,
    agentId: null,
    action: 'execute',
    confidence: 0
  };
}

export function getAgentInfo(agentId: string): { name: string; icon: string } | null {
  return {
    name: agentId,
    icon: '🤖'
  };
}

export function generateConfirmationMessage(agentId: string): string {
  return `Ejecutar agente ${agentId}?`;
}
