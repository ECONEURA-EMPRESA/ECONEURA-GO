## Dominio 11 NEURAS

ECONEURA-FULL modela 11 NEURAS, cada una representando un “director virtual” de un área clave de la empresa.
Cada NEURA se compone de:

- Un **agente LLM** principal (registro en `llmAgentsRegistry.ts`).
- Un conjunto de **agentes de automatización** (Make/n8n) registrados en `automationAgentsRegistry.ts`.

Las IDs de NEURA (`NeuraId`) son:

- `neura-ceo`
- `neura-cto`
- `neura-cfo`
- `neura-cmo`
- `neura-ventas`
- `neura-atencion-cliente`
- `neura-rrhh`
- `neura-operaciones`
- `neura-legal`
- `neura-datos`
- `neura-innovacion`

### Contratos LLM (Neura → LLMAgent)

Los contratos LLM entre NEURAS y agentes LLM se definen en `src/llm/llmAgentsRegistry.ts` y `src/neura/neuraCatalog.ts`.
Cada NEURA apunta a un `llmAgentId` que describe:

- `provider`: proveedor de LLM (`openai`, `azure-openai`, etc.).
- `model`: modelo concreto (por ejemplo `gpt-4.1`, `gpt-4.1-mini`).
- `systemPrompt`: prompt de sistema especializado para la NEURA.
- `temperature`, `maxTokens`: parámetros de generación.

Mapa actual (1:1 con código):

- `neura-ceo` → agente LLM `neura-ceo`
  - `provider`: `openai`
  - `model`: `gpt-4.1`
  - Rol: CEO estratégico, priorización, agenda de consejo, coordinación con agentes Automation del CEO.
- `neura-cto` → agente LLM `neura-cto`
  - `provider`: `openai`
  - `model`: `gpt-4.1`
  - Rol: CTO/arquitectura 2025, DDD, CQRS, Event Sourcing, Azure.
- `neura-cfo` → agente LLM `neura-cfo`
  - `provider`: `openai`
  - `model`: `gpt-4.1-mini`
  - Rol: finanzas, cashflow, control de costes, análisis de riesgo.
- `neura-cmo` → agente LLM `neura-cmo`
  - `provider`: `openai`
  - `model`: `gpt-4.1-mini`
  - Rol: marketing/growth, narrativa de marca, campañas.
- `neura-ventas` → agente LLM `neura-ventas`
  - `provider`: `openai`
  - `model`: `gpt-4.1-mini`
  - Rol: soporte a ventas, argumentarios, objeciones y cierre.
- `neura-atencion-cliente` → agente LLM `neura-atencion-cliente`
  - `provider`: `openai`
  - `model`: `gpt-4.1-mini`
  - Rol: soporte y éxito de cliente, multicanal.
- `neura-rrhh` → agente LLM `neura-rrhh`
  - `provider`: `openai`
  - `model`: `gpt-4.1-mini`
  - Rol: talento, cultura, organización y bienestar.
- `neura-operaciones` → agente LLM `neura-operaciones`
  - `provider`: `openai`
  - `model`: `gpt-4.1-mini`
  - Rol: procesos, SLAs, eficiencia operativa.
- `neura-legal` → agente LLM `neura-legal`
  - `provider`: `openai`
  - `model`: `gpt-4.1-mini`
  - Rol: revisión de riesgos legales y cumplimiento (sin sustituir asesoría legal).
- `neura-datos` → agente LLM `neura-datos`
  - `provider`: `openai`
  - `model`: `gpt-4.1-mini`
  - Rol: análisis de datos, KPIs y reporting.
- `neura-innovacion` → agente LLM `neura-innovacion`
  - `provider`: `openai`
  - `model`: `gpt-4.1`
  - Rol: innovación, nuevos modelos de negocio y productos, experimentos.

### Agentes de Automation por NEURA

Los agentes de automatización (Make/n8n/llm) se definen en `src/automation/automationAgentsRegistry.ts` con tipo `AutomationAgent`.
Cada agente tiene:

- `id`: identificador único del agente.
- `neuraKey`: clave corta de la NEURA (por ejemplo `ceo`, `cfo`, `cto`).
- `neuraId`: identificador completo de NEURA (por ejemplo `a-ceo-01`).
- `provider`: `'make' | 'n8n' | 'llm'`.
- `trigger`: `'manual' | 'auto' | 'scheduled'`.
- `webhookUrl`: URL de ejecución (normalizada/sanitizada en código).

Ejemplos (no exhaustivo):

- NEURA CEO (`neuraKey: "ceo"`):
  - `ceo-agenda-consejo` (Make, manual).
  - `ceo-anuncio-semanal` (n8n, manual).
  - `ceo-resumen-ejecutivo` (Make, auto).
  - `ceo-seguimiento-okr` (n8n, manual).

- NEURA CFO (`neuraKey: "cfo"`):
  - `cfo-tesoreria` (Make, auto).
  - `cfo-variance` (n8n, auto).
  - `cfo-facturacion` (Make, auto).
  - `cfo-compras` (n8n, manual).

La lista completa se corresponde 1:1 con el contenido de `config/neura-agents-map.json` de ECONEURA-PRO, migrado y validado con Zod.


