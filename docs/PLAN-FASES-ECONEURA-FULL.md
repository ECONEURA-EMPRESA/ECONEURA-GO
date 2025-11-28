# Plan de Fases ECONEURA-FULL (Contrato de Trabajo)

## FASE 0 – Fundamentos del monorepo (10 tareas)

1. F0.1 – Consolidar `package.json` raíz para que sólo existan estos scripts globales: `build`, `build:backend`, `build:frontend`, `dev:backend`, `dev:frontend`, `test:backend`, `type-check:backend`, `type-check:frontend`.
2. F0.2 – Ajustar `tsconfig.base.json` a strict máximo (incluyendo `noUncheckedIndexedAccess`, `noImplicitOverride`, `noPropertyAccessFromIndexSignature`).
3. F0.3 – Crear `.gitignore` definitivo (node_modules, dist, logs, coverage, `.env*`, `.vscode`, `.idea`, artefactos de tests).
4. F0.4 – Crear `.editorconfig` para estandarizar formato entre IDEs.
5. F0.5 – Crear `.prettierrc` alineado con el estilo actual de ECONEURA-PRO.
6. F0.6 – Crear `.eslintrc.cjs` con reglas fuertes de TS (plugin `@typescript-eslint`, no `any`, no imports sin usar, etc.).
7. F0.7 – Crear `CODEOWNERS` asignando ownership a: `packages/backend`, `packages/frontend`, `infrastructure/azure`, `docs/`.
8. F0.8 – Rellenar `README.md` con: visión del producto, estructura de carpetas, comandos clave, link a docs.
9. F0.9 – Rellenar `SECURITY.md` con política de secretos (Key Vault), accesos, gestión de credenciales.
10. F0.10 – Iniciar `CHANGELOG.md` con el hito “Creación ECONEURA-FULL + estructura 2025”.

## FASE 1 – Modelo de dominio 11 NEURAS + LLM (12 tareas)

11. F1.1 – Revisar y pulir `llmAgentsRegistry.ts` para las 11 NEURAS: prompts finales, modelos exactos, parámetros óptimos.
12. F1.2 – Alinear `neuraCatalog.ts` con `DOMAIN-NEURAS.md` (departamentos, descripciones, relaciones).
13. F1.3 – Crear tipos de dominio compartidos: `NeuraId`, `NeuraDepartment`, `LLMProvider`, etc. en `shared/types`.
14. F1.4 – Asegurar que `invokeLLMAgent.ts` no depende de infra (solo del puerto `LLMClient`).
15. F1.5 – Crear `LLMClientMock` para tests unitarios de `invokeLLMAgent`.
16. F1.6 – Añadir tests unitarios para `llmAgentsRegistry` (lookup válido/ inválido).
17. F1.7 – Añadir tests unitarios para `neuraCatalog` (lookup válido/ inválido).
18. F1.8 – Añadir tests unitarios para `invokeLLMAgent` (flujo éxito y error de proveedor).
19. F1.9 – Revisar `OpenAIAdapter.ts` para asegurar manejo robusto de errores, timeouts y logs estructurados.
20. F1.10 – Añadir tests unitarios para `OpenAIAdapter` con mocks de cliente OpenAI.
21. F1.11 – Documentar en `DOMAIN-NEURAS.md` cómo se mapean NEURAS → LLM agents (sección “Contratos LLM”).
22. F1.12 – `npm run test:backend` + `type-check:backend` verde tras esta fase.

## FASE 2 – Automation Make + n8n (núcleo completo) (14 tareas)

23. F2.1 – Revisar `neura-agents-map.json` en `ECONEURA-PRO` línea a línea (entender TODOS los agentes).
24. F2.2 – Diseñar `Zod` schema para el mapa completo de agentes en `automationAgentsRegistry.ts`.
25. F2.3 – Migrar TODOS los agentes de `neura-agents-map.json` a `AutomationAgent[]` (sin perder ninguno).
26. F2.4 – Normalizar `platform` → `provider: 'make' | 'n8n' | 'llm'` y `trigger: 'manual' | 'auto' | 'scheduled'`.
27. F2.5 – Diseñar estrategia de `webhookUrl`: URLs reales configurables vía env/Key Vault; código solo guarda IDs/paths.
28. F2.6 – Ajustar `automationService.ts` para usar el nuevo schema y devolver siempre `Result`.
29. F2.7 – Revisar `MakeAdapter.ts` y `N8NAdapter.ts` para usar Zod en request/response y logs claros.
30. F2.8 – Añadir tests unitarios para `automationAgentsRegistry` (por `neuraKey`, por `id`, activos/inactivos).
31. F2.9 – Añadir tests unitarios para `automationService` con adaptadores mock (Make/n8n).
32. F2.10 – Revisar `neuraAgentExecutor.ts` (detección robusta de intención, modo mock/real, formato para cockpit).
33. F2.11 – Añadir tests unitarios para `neuraAgentExecutor`.
34. F2.12 – Documentar en `DOMAIN-NEURAS.md` sección “Agentes Automation por NEURA”.
35. F2.13 – Documentar en `API-REFERENCE.md` el endpoint `/api/chat/:neuraKey/execute-agent`.
36. F2.14 – `npm run test:backend` + `type-check:backend` verde.

## FASE 3 – Conversación NEURA + Chat (10 tareas)

37. F3.1 – Revisar `Conversation` y `Message` para incluir `tenantId`, `neuraId`, `userId`, `correlationId`.
38. F3.2 – Diseñar interfaz `ConversationStore` pensando en Event Sourcing.
39. F3.3 – Limpiar `inMemoryConversationStore` como implementación correcta de `ConversationStore`.
40. F3.4 – Revisar `sendNeuraMessage.ts` (nueva/existente, persistencia mensajes, uso correcto de `invokeLLMAgent`).
41. F3.5 – Añadir tests unitarios para `startConversation`, `appendMessage`, `getConversationHistory`, `sendNeuraMessage`.
42. F3.6 – Validar entradas de `conversationRoutes.ts` con Zod.
43. F3.7 – Validar entradas de `neuraChatRoutes.ts` con Zod.
44. F3.8 – Añadir tests de integración HTTP para `/api/conversations` y `/api/neuras/:neuraId/chat`.
45. F3.9 – Documentar en `API-REFERENCE.md` los contratos JSON de conversación.
46. F3.10 – `npm run test:backend` + `type-check:backend` verde.

## FASE 4 – Identity + RBAC + Audit (12 tareas)

47. F4.1 – Diseñar `User`, `Organization`, `Tenant`, `Role`, `Permission` en `identity/domain`.
48. F4.2 – Crear `AuthContext` (`userId`, `tenantId`, `roles`) en `shared/types`.
49. F4.3 – Definir puertos `AuthService` y `TokenService` en `identity/application`.
50. F4.4 – Implementar casos de uso básicos (`validateSession`, `getUserPermissions`).
51. F4.5 – Diseñar middleware de Express para auth + RBAC.
52. F4.6 – Alinear `RBAC-MODEL.md` con enums/tipos reales.
53. F4.7 – Crear `audit/domain` con `AuditEvent`.
54. F4.8 – Crear `audit/infra` para enviar `AuditEvent` a App Insights/Logs.
55. F4.9 – Añadir hooks de audit en agentes Automation, NEURAS LLM, cambios de roles/usuarios.
56. F4.10 – Añadir tests unitarios de `identity` y `audit`.
57. F4.11 – Proteger rutas críticas con auth + RBAC.
58. F4.12 – `npm run test:backend` + `type-check:backend` verde.

## FASE 5 – Persistencia y Event Sourcing mínimo (10 tareas)

59. F5.1 – Definir puertos `EventStore` y `ReadModelStore` en `infra/persistence`.
60. F5.2 – Diseñar eventos de conversación (`ConversationStarted`, `MessageAppended`).
61. F5.3 – Implementar `CosmosEventStoreAdapter.ts` (interfaces).
62. F5.4 – Implementar `CosmosReadModelAdapter.ts`.
63. F5.5 – Escribir proyección simple para conversaciones.
64. F5.6 – Añadir connection strings en `envSchema.ts`.
65. F5.7 – Tests unitarios con EventStore en memoria para probar proyecciones.
66. F5.8 – Plan en `AZURE-INFRA.md` para mapear EventStore/ReadModels a Cosmos/DB.
67. F5.9 – Ajustar casos de conversación para poder cambiar de store in-memory a EventStore.
68. F5.10 – `npm run test:backend` + `type-check:backend` verde.

## FASE 6 – Frontend: estructura + adaptación a backend nuevo (12 tareas)

69. F6.1 – Crear carpetas `src/auth/`, `src/cockpit/`, `src/shared/`, `src/services/`, `src/types/`, `src/tests/` y `tests-e2e/`.
70. F6.2 – Copiar `LoginPage` desde PRO respetando diseño 1:1.
71. F6.3 – Copiar `EconeuraCockpit.tsx` y componentes dependientes respetando diseño 1:1.
72. F6.4 – Crear `src/services/apiClient.ts` con baseURL y manejo tipado de errores.
73. F6.5 – Crear `src/services/neurasApi.ts` (NEURAS + LLM).
74. F6.6 – Crear `src/services/conversationsApi.ts` (conversación + chat).
75. F6.7 – Crear `src/types/api.ts` con DTOs de backend.
76. F6.8 – Refactorizar `LoginPage` para usar `apiClient` y tipos.
77. F6.9 – Refactorizar `EconeuraCockpit` para usar nuevas APIs manteniendo UI exacta.
78. F6.10 – Añadir tests unitarios para `LoginPage` y `EconeuraCockpit`.
79. F6.11 – Crear test e2e: login → cockpit → mensaje NEURA → ejecutar agente.
80. F6.12 – `npm run type-check:frontend` + tests frontend/e2e verde.

## FASE 7 – Infra Azure y CI/CD operativos (10 tareas)

81. F7.1 – Implementar `main.bicep` orquestando `core`, `app-backend`, `app-frontend`, `database`, `redis`, `keyvault`, `monitoring`.
82. F7.2 – Configurar `main.parameters.dev.json` con valores dev reales.
83. F7.3 – Probar despliegue dev de infra con `infra-deploy.yml` o CLI local.
84. F7.4 – Ajustar `backend-ci.yml` para correr en PR a `main/develop`.
85. F7.5 – Ajustar `frontend-ci.yml` en la misma línea.
86. F7.6 – Configurar `infra-deploy.yml` como workflow manual/merge a `main`.
87. F7.7 – Configurar `app-deploy.yml` para deploy backend + frontend a Azure.
88. F7.8 – Documentar en `CI-CD.md` flujo PR → CI → deploy dev → promoción prod.
89. F7.9 – Ejecutar pipeline completo en dev y verificar backend + frontend levantados.
90. F7.10 – Añadir smoke tests post-deploy (health, conversación, NEURA).

## FASE 8 – Endgame: limpieza, migración exhaustiva PRO y verificación final (10 tareas)

91. F8.1 – Definir lista completa de archivos JS en PRO pendientes de migrar.
92. F8.2 – Crear estrategia de migración por lotes (bounded contexts).
93. F8.3 – Aplicar DIRECTRICES de migración exhaustiva archivo a archivo.
94. F8.4 – Actualizar `MIGRATION_LOG.md` para cada lote migrado.
95. F8.5 – Eliminar dependencias JS/legacy de `ECONEURA-FULL`.
96. F8.6 – Ejecutar `npm run test` (backend) y `npm run type-check` como verificación final.
97. F8.7 – Ejecutar CI completo en GitHub y verificar.
98. F8.8 – Ejecutar tests e2e en dev (login + cockpit + NEURA + agente).
99. F8.9 – Revisar código con checklist “sin atajos”: sin `any` injustificados, sin TODO críticos, sin código muerto.
100. F8.10 – Cerrar `MIGRATION_LOG.md` FASE 1 con resumen de estado.


