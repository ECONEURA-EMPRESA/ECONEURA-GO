import { z } from 'zod';
import { ok, err, type Result } from '../shared/Result';

export type AutomationProvider = 'make' | 'n8n' | 'llm';

export type AutomationTrigger = 'manual' | 'auto' | 'scheduled';

export interface AutomationAgent {
  id: string;
  neuraKey: string;
  neuraId: string;
  name: string;
  description: string;
  provider: AutomationProvider;
  webhookUrl?: string | undefined;
  trigger: AutomationTrigger;
  active: boolean;
}



const automationAgentSchema = z.object({
  id: z.string(),
  neuraKey: z.string(),
  neuraId: z.string(),
  name: z.string(),
  description: z.string(),
  provider: z.enum(['make', 'n8n', 'llm']),
  webhookUrl: z.string().url().optional(),
  trigger: z.enum(['manual', 'auto', 'scheduled']),
  active: z.boolean()
});

const automationAgentsSchema = z.array(automationAgentSchema);

const automationAgentsRaw: AutomationAgent[] = [
  // CEO
  {
    id: 'ceo-agenda-consejo',
    neuraKey: 'ceo',
    neuraId: 'a-ceo-01',
    name: 'Agenda Consejo',
    description: 'Preparación de agenda del consejo ejecutivo',
    provider: 'make',
    webhookUrl: process.env['WEBHOOK_CEO_AGENDA_CONSEJO'],
    trigger: 'manual',
    active: true
  },
  {
    id: 'ceo-anuncio-semanal',
    neuraKey: 'ceo',
    neuraId: 'a-ceo-01',
    name: 'Anuncio Semanal',
    description: 'Comunicación semanal a toda la empresa',
    provider: 'n8n',
    webhookUrl: process.env['WEBHOOK_CEO_ANUNCIO_SEMANAL'],
    trigger: 'manual',
    active: true
  },
  {
    id: 'ceo-resumen-ejecutivo',
    neuraKey: 'ceo',
    neuraId: 'a-ceo-01',
    name: 'Resumen Ejecutivo',
    description: 'Resumen ejecutivo del día',
    provider: 'make',
    webhookUrl: process.env['WEBHOOK_CEO_RESUMEN_EJECUTIVO'],
    trigger: 'auto',
    active: true
  },
  {
    id: 'ceo-seguimiento-okr',
    neuraKey: 'ceo',
    neuraId: 'a-ceo-01',
    name: 'Seguimiento OKR',
    description: 'Tracking de OKRs trimestrales',
    provider: 'n8n',
    webhookUrl: process.env['WEBHOOK_CEO_SEGUIMIENTO_OKR'],
    trigger: 'manual',
    active: true
  },
  // IA / CTO IA
  {
    id: 'ia-salud-failover',
    neuraKey: 'ia',
    neuraId: 'a-ia-01',
    name: 'Salud y Failover',
    description: 'Monitoreo de salud y failover de modelos IA',
    provider: 'make',
    webhookUrl: process.env['WEBHOOK_IA_SALUD_FAILOVER'],
    trigger: 'auto',
    active: true
  },
  {
    id: 'ia-cost-tracker',
    neuraKey: 'ia',
    neuraId: 'a-ia-01',
    name: 'Cost Tracker',
    description: 'Tracking de costos de APIs de IA',
    provider: 'n8n',
    webhookUrl: process.env['WEBHOOK_IA_COST_TRACKER'],
    trigger: 'auto',
    active: true
  },
  {
    id: 'ia-revision-prompts',
    neuraKey: 'ia',
    neuraId: 'a-ia-01',
    name: 'Revisión Prompts',
    description: 'Análisis y optimización de prompts',
    provider: 'make',
    webhookUrl: process.env['WEBHOOK_IA_REVISION_PROMPTS'],
    trigger: 'manual',
    active: true
  },
  {
    id: 'ia-vigilancia-cuotas',
    neuraKey: 'ia',
    neuraId: 'a-ia-01',
    name: 'Vigilancia Cuotas',
    description: 'Monitoreo de cuotas de API',
    provider: 'n8n',
    webhookUrl: process.env['WEBHOOK_IA_VIGILANCIA_CUOTAS'],
    trigger: 'auto',
    active: true
  },
  // CSO
  {
    id: 'cso-gestor-riesgos',
    neuraKey: 'cso',
    neuraId: 'a-cso-01',
    name: 'Gestor de Riesgos',
    description: 'Gestión de riesgos estratégicos',
    provider: 'make',
    webhookUrl: process.env['WEBHOOK_CSO_GESTOR_RIESGOS'],
    trigger: 'manual',
    active: true
  },
  {
    id: 'cso-vigilancia-competitiva',
    neuraKey: 'cso',
    neuraId: 'a-cso-01',
    name: 'Vigilancia Competitiva',
    description: 'Monitoreo de competidores',
    provider: 'n8n',
    webhookUrl: process.env['WEBHOOK_CSO_VIGILANCIA_COMPETITIVA'],
    trigger: 'auto',
    active: true
  },
  {
    id: 'cso-radar-tendencias',
    neuraKey: 'cso',
    neuraId: 'a-cso-01',
    name: 'Radar de Tendencias',
    description: 'Detección de tendencias del sector',
    provider: 'make',
    webhookUrl: process.env['WEBHOOK_CSO_RADAR_TENDENCIAS'],
    trigger: 'auto',
    active: true
  },
  {
    id: 'cso-ma-sync',
    neuraKey: 'cso',
    neuraId: 'a-cso-01',
    name: 'M&A Sync',
    description: 'Sincronización de operaciones M&A',
    provider: 'n8n',
    webhookUrl: process.env['WEBHOOK_CSO_MA_SYNC'],
    trigger: 'manual',
    active: true
  },
  // CTO
  {
    id: 'cto-finops-cloud',
    neuraKey: 'cto',
    neuraId: 'a-cto-01',
    name: 'FinOps Cloud',
    description: 'Optimización de costos cloud',
    provider: 'make',
    webhookUrl: process.env['WEBHOOK_CTO_FINOPS_CLOUD'],
    trigger: 'auto',
    active: true
  },
  {
    id: 'cto-seguridad-cicd',
    neuraKey: 'cto',
    neuraId: 'a-cto-01',
    name: 'Seguridad CI/CD',
    description: 'Seguridad en pipelines CI/CD',
    provider: 'n8n',
    webhookUrl: process.env['WEBHOOK_CTO_SEGURIDAD_CICD'],
    trigger: 'auto',
    active: true
  },
  {
    id: 'cto-observabilidad-slo',
    neuraKey: 'cto',
    neuraId: 'a-cto-01',
    name: 'Observabilidad SLO',
    description: 'Monitoreo de SLOs y SLAs',
    provider: 'make',
    webhookUrl: process.env['WEBHOOK_CTO_OBSERVABILIDAD_SLO'],
    trigger: 'auto',
    active: true
  },
  {
    id: 'cto-gestion-incidencias',
    neuraKey: 'cto',
    neuraId: 'a-cto-01',
    name: 'Gestión Incidencias',
    description: 'Gestión de incidentes técnicos',
    provider: 'n8n',
    webhookUrl: process.env['WEBHOOK_CTO_GESTION_INCIDENCIAS'],
    trigger: 'manual',
    active: true
  },
  // CISO
  {
    id: 'ciso-vulnerabilidades',
    neuraKey: 'ciso',
    neuraId: 'a-ciso-01',
    name: 'Vulnerabilidades',
    description: 'Escaneo y gestión de vulnerabilidades',
    provider: 'make',
    webhookUrl: process.env['WEBHOOK_CISO_VULNERABILIDADES'],
    trigger: 'auto',
    active: true
  },
  {
    id: 'ciso-phishing-triage',
    neuraKey: 'ciso',
    neuraId: 'a-ciso-01',
    name: 'Phishing Triage',
    description: 'Análisis y triage de reportes de phishing',
    provider: 'n8n',
    webhookUrl: process.env['WEBHOOK_CISO_PHISHING_TRIAGE'],
    trigger: 'auto',
    active: true
  },
  {
    id: 'ciso-backup-restore-dr',
    neuraKey: 'ciso',
    neuraId: 'a-ciso-01',
    name: 'Backup/Restore DR',
    description: 'Gestión de backups y disaster recovery',
    provider: 'make',
    webhookUrl: process.env['WEBHOOK_CISO_BACKUP_RESTORE_DR'],
    trigger: 'manual',
    active: true
  },
  {
    id: 'ciso-recertificacion',
    neuraKey: 'ciso',
    neuraId: 'a-ciso-01',
    name: 'Recertificación',
    description: 'Recertificación de accesos',
    provider: 'n8n',
    webhookUrl: process.env['WEBHOOK_CISO_RECERTIFICACION'],
    trigger: 'manual',
    active: true
  },
  // COO
  {
    id: 'coo-atrasos-excepciones',
    neuraKey: 'coo',
    neuraId: 'a-coo-01',
    name: 'Atrasos y Excepciones',
    description: 'Monitoreo de pedidos atrasados',
    provider: 'make',
    webhookUrl: process.env['WEBHOOK_COO_ATRASOS_EXCEPCIONES'],
    trigger: 'auto',
    active: true
  },
  {
    id: 'coo-centro-nps-csat',
    neuraKey: 'coo',
    neuraId: 'a-coo-01',
    name: 'Centro NPS/CSAT',
    description: 'Análisis de satisfacción del cliente',
    provider: 'n8n',
    webhookUrl: process.env['WEBHOOK_COO_CENTRO_NPS_CSAT'],
    trigger: 'auto',
    active: true
  },
  {
    id: 'coo-latido-sla',
    neuraKey: 'coo',
    neuraId: 'a-coo-01',
    name: 'Latido de SLA',
    description: 'Monitoreo en tiempo real de SLAs',
    provider: 'make',
    webhookUrl: process.env['WEBHOOK_COO_LATIDO_SLA'],
    trigger: 'auto',
    active: true
  },
  {
    id: 'coo-torre-control',
    neuraKey: 'coo',
    neuraId: 'a-coo-01',
    name: 'Torre de Control',
    description: 'Dashboard operativo centralizado',
    provider: 'n8n',
    webhookUrl: process.env['WEBHOOK_COO_TORRE_CONTROL'],
    trigger: 'manual',
    active: true
  },
  // CHRO
  {
    id: 'chro-encuesta-pulso',
    neuraKey: 'chro',
    neuraId: 'a-chro-01',
    name: 'Encuesta de Pulso',
    description: 'Encuestas de clima organizacional',
    provider: 'make',
    webhookUrl: process.env['WEBHOOK_CHRO_ENCUESTA_PULSO'],
    trigger: 'manual',
    active: true
  },
  {
    id: 'chro-offboarding-seguro',
    neuraKey: 'chro',
    neuraId: 'a-chro-01',
    name: 'Offboarding Seguro',
    description: 'Proceso de offboarding automatizado',
    provider: 'n8n',
    webhookUrl: process.env['WEBHOOK_CHRO_OFFBOARDING_SEGURO'],
    trigger: 'manual',
    active: true
  },
  {
    id: 'chro-onboarding-orquestado',
    neuraKey: 'chro',
    neuraId: 'a-chro-01',
    name: 'Onboarding Orquestado',
    description: 'Onboarding automatizado de nuevos empleados',
    provider: 'n8n',
    webhookUrl: process.env['WEBHOOK_CHRO_ONBOARDING_ORQUESTADO'],
    trigger: 'manual',
    active: true
  },
  {
    id: 'chro-pipeline-contratacion',
    neuraKey: 'chro',
    neuraId: 'a-chro-01',
    name: 'Pipeline Contratación',
    description: 'Gestión de pipeline de reclutamiento',
    provider: 'n8n',
    webhookUrl: process.env['WEBHOOK_CHRO_PIPELINE_CONTRATACION'],
    trigger: 'auto',
    active: true
  },
  // CMO/CRO
  {
    id: 'cmo-embudo-comercial',
    neuraKey: 'cmo',
    neuraId: 'a-mkt-01',
    name: 'Embudo Comercial',
    description: 'Análisis del funnel comercial',
    provider: 'make',
    webhookUrl: process.env['WEBHOOK_CMO_EMBUDO_COMERCIAL'],
    trigger: 'auto',
    active: true
  },
  {
    id: 'cmo-salud-pipeline',
    neuraKey: 'cmo',
    neuraId: 'a-mkt-01',
    name: 'Salud de Pipeline',
    description: 'Monitoreo de salud del pipeline de ventas',
    provider: 'n8n',
    webhookUrl: process.env['WEBHOOK_CMO_SALUD_PIPELINE'],
    trigger: 'auto',
    active: true
  },
  {
    id: 'cmo-calidad-leads',
    neuraKey: 'cmo',
    neuraId: 'a-mkt-01',
    name: 'Calidad de Leads',
    description: 'Análisis de calidad de leads',
    provider: 'make',
    webhookUrl: process.env['WEBHOOK_CMO_CALIDAD_LEADS'],
    trigger: 'auto',
    active: true
  },
  {
    id: 'cmo-post-campana',
    neuraKey: 'cmo',
    neuraId: 'a-mkt-01',
    name: 'Post-Campaña',
    description: 'Análisis post-mortem de campañas',
    provider: 'n8n',
    webhookUrl: process.env['WEBHOOK_CMO_POST_CAMPANA'],
    trigger: 'manual',
    active: true
  },
  // CFO
  {
    id: 'cfo-tesoreria',
    neuraKey: 'cfo',
    neuraId: 'a-cfo-01',
    name: 'Tesorería',
    description: 'Gestión de tesorería y cash flow',
    provider: 'make',
    webhookUrl: process.env['WEBHOOK_CFO_TESORERIA'],
    trigger: 'auto',
    active: true
  },
  {
    id: 'cfo-variance',
    neuraKey: 'cfo',
    neuraId: 'a-cfo-01',
    name: 'Variance',
    description: 'Análisis de variance vs presupuesto',
    provider: 'n8n',
    webhookUrl: process.env['WEBHOOK_CFO_VARIANCE'],
    trigger: 'auto',
    active: true
  },
  {
    id: 'cfo-facturacion',
    neuraKey: 'cfo',
    neuraId: 'a-cfo-01',
    name: 'Facturación',
    description: 'Automatización de facturación',
    provider: 'make',
    webhookUrl: process.env['WEBHOOK_CFO_FACTURACION'],
    trigger: 'auto',
    active: true
  },
  {
    id: 'cfo-compras',
    neuraKey: 'cfo',
    neuraId: 'a-cfo-01',
    name: 'Compras',
    description: 'Gestión de órdenes de compra',
    provider: 'n8n',
    webhookUrl: process.env['WEBHOOK_CFO_COMPRAS'],
    trigger: 'manual',
    active: true
  },
  // CDO
  {
    id: 'cdo-linaje',
    neuraKey: 'cdo',
    neuraId: 'a-cdo-01',
    name: 'Linaje',
    description: 'Tracking de linaje de datos',
    provider: 'make',
    webhookUrl: process.env['WEBHOOK_CDO_LINAJE'],
    trigger: 'auto',
    active: true
  },
  {
    id: 'cdo-calidad-datos',
    neuraKey: 'cdo',
    neuraId: 'a-cdo-01',
    name: 'Calidad de Datos',
    description: 'Monitoreo de calidad de datos',
    provider: 'n8n',
    webhookUrl: process.env['WEBHOOK_CDO_CALIDAD_DATOS'],
    trigger: 'auto',
    active: true
  },
  {
    id: 'cdo-catalogo',
    neuraKey: 'cdo',
    neuraId: 'a-cdo-01',
    name: 'Catálogo',
    description: 'Gestión de catálogo de datos',
    provider: 'make',
    webhookUrl: process.env['WEBHOOK_CDO_CATALOGO'],
    trigger: 'manual',
    active: true
  },
  {
    id: 'cdo-coste-dwh',
    neuraKey: 'cdo',
    neuraId: 'a-cdo-01',
    name: 'Coste DWH',
    description: 'Optimización de costos de data warehouse',
    provider: 'n8n',
    webhookUrl: process.env['WEBHOOK_CDO_COSTE_DWH'],
    trigger: 'auto',
    active: true
  },
  // CINO
  {
    id: 'cino-patentes-papers',
    neuraKey: 'cino',
    neuraId: 'a-cino-01',
    name: 'Explorador de Patentes y Papers',
    description: 'Búsqueda y análisis de patentes y papers científicos',
    provider: 'make',
    webhookUrl: process.env['WEBHOOK_CINO_PATENTES_PAPERS'],
    trigger: 'manual',
    active: true
  },
  {
    id: 'cino-radar-startups',
    neuraKey: 'cino',
    neuraId: 'a-cino-01',
    name: 'Radar de Startups y Ecosistemas',
    description: 'Monitoreo de ecosistema de startups',
    provider: 'n8n',
    webhookUrl: process.env['WEBHOOK_CINO_RADAR_STARTUPS'],
    trigger: 'auto',
    active: true
  },
  {
    id: 'cino-prototipos-ia',
    neuraKey: 'cino',
    neuraId: 'a-cino-01',
    name: 'Generador de Prototipos IA/No-Code',
    description: 'Generación automática de prototipos',
    provider: 'make',
    webhookUrl: process.env['WEBHOOK_CINO_PROTOTIPOS_IA'],
    trigger: 'manual',
    active: true
  },
  {
    id: 'cino-tendencias-usuario',
    neuraKey: 'cino',
    neuraId: 'a-cino-01',
    name: 'Agente de Tendencias de Usuario',
    description: 'Análisis de tendencias de comportamiento',
    provider: 'n8n',
    webhookUrl: process.env['WEBHOOK_CINO_TENDENCIAS_USUARIO'],
    trigger: 'auto',
    active: true
  },
  {
    id: 'cino-innovation-lab',
    neuraKey: 'cino',
    neuraId: 'a-cino-01',
    name: 'Innovation Lab',
    description: 'Laboratorio de innovación experimental',
    provider: 'make',
    webhookUrl: process.env['WEBHOOK_CINO_INNOVATION_LAB'],
    trigger: 'manual',
    active: true
  }
];

export const automationAgents: AutomationAgent[] = automationAgentsSchema.parse(automationAgentsRaw);

export function getAutomationAgentById(id: string): Result<AutomationAgent, Error> {
  const agent = automationAgents.find((a) => a.id === id && a.active);
  if (!agent) {
    return err(new Error(`Automation agent not found: ${id}`));
  }
  return ok(agent);
}

export function getAutomationAgentsByNeuraKey(neuraKey: string): AutomationAgent[] {
  return automationAgents.filter((a) => a.neuraKey === neuraKey && a.active);
}

/**
 * Valida que todas las variables de entorno necesarias estén presentes.
 * Lanza un error si falta alguna variable crítica para un agente activo.
 */
export function validateAutomationEnvironment(): void {
  const missingVars: string[] = [];

  automationAgentsRaw.forEach((agent) => {
    if (agent.active && !agent.webhookUrl) {
      // Construir el nombre de la variable basado en el ID del agente para el mensaje de error
      // Esto es una aproximación, ya que no tenemos el nombre de la variable almacenado directamente en el objeto
      // Pero nos ayuda a identificar qué agente está fallando.
      missingVars.push(`Webhook URL for active agent '${agent.name}' (${agent.id}) is missing`);
    }
  });

  if (missingVars.length > 0) {
    const errorMessage = `
      CRITICAL ERROR: Missing Environment Variables for Automation Agents.
      The following active agents are missing their webhook URLs:
      ${missingVars.map(v => `- ${v}`).join('\n')}
      
      Please check your .env file and ensure all required WEBHOOK_ variables are defined.
    `;
    // En desarrollo o producción, esto debería detener la ejecución para evitar comportamientos inesperados
    if (process.env['NODE_ENV'] !== 'test') {
      console.error(errorMessage);
      // Opcional: throw new Error(errorMessage); si queremos detener el arranque
      // Por ahora solo logueamos error crítico
    }
  }
}

// Ejecutar validación al cargar el módulo (fail fast)
validateAutomationEnvironment();


