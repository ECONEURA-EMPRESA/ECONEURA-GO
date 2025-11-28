# FASE 22: Crear Architecture Decision Records (ADRs)
$ErrorActionPreference = "Stop"

Write-Host "📝 Creando Architecture Decision Records..." -ForegroundColor Cyan

# Crear directorio
New-Item -ItemType Directory -Path "docs/architecture/decisions" -Force | Out-Null

# ADR 001: Feature-Sliced Design
$adr001 = @"
# ADR 001: Feature-Sliced Design para Frontend

**Status**: Approved  
**Fecha**: 2025-11-25  
**Decisión por**: Equipo Arquitectura

---

## Context

El frontend de ECONEURA tiene múltiples funcionalidades complejas (Login, Cockpit, Chat, CRM) que necesitan ser organizadas de manera escalable y mantenible.

## Decision

Adoptar **Feature-Sliced Design (FSD)** como arquitectura frontend.

### Estructura:

\`\`\`
src/
├── app/          # Setup, providers, routing
├── pages/        # Pages/routes
├── widgets/      # Complex ui blocks
├── features/     # User scenarios
│   ├── auth/     # Login, logout
│   ├── chat/     # Chat con NEURAS
│   ├── cockpit/  # Dashboard principal
│   └── crm/      # CRM module
├── entities/     # Business entities
├── shared/       # Shared code
└── widgets/      # Composite blocks
\`\`\`

## Consequences

### Positivo ✅

- **Modularidad**: Cada feature independiente
- **Escalabilidad**: Fácil agregar nuevas features
- **Mantenibilidad**: Código organizado por dominio
- **Reutilización**: Shared entities y widgets
- **Testabilidad**: Features aisladas testables

### Negativo ⚠️

- Curva de aprendizaje inicial
- Más estructura = más archivos

## Alternatives Considered

1. **Single component folder**: Rechazado por no escalar
2. **Atomic Design**: Rechazado por ser muy granular
3. **Domain-driven folders**: Parcialmente usado en entities

---

**Decisión final**: FSD es óptimo para ECONEURA.
"@

Set-Content "docs/architecture/decisions/001-feature-sliced-design.md" $adr001
Write-Host "  ✅ ADR 001: Feature-Sliced Design" -ForegroundColor Green

# ADR 002: Managed Identities
$adr002 = @"
# ADR 002: Managed Identities en Azure

**Status**: Approved  
**Fecha**: 2025-11-25  
**Decisión por**: Equipo DevOps + Seguridad

---

## Context

Conectar aplicaciones a servicios Azure (PostgreSQL, Redis, Key Vault, Storage) requiere credenciales. Manejar connection strings es un riesgo de seguridad.

## Decision

**CERO connection strings en código**.  
TODO via **Azure Managed Identities**.

### Implementación:

1. User-Assigned Managed Identity creada en Bicep
2. Roles asignados: Storage Blob Data Contributor, Key Vault Secrets User
3. App Service usa Managed Identity para acceder a todos los recursos
4. Connection strings almacenados en Key Vault
5. App accede a Key Vault usando Managed Identity

## Consequences

### Positivo ✅

- **Seguridad máxima**: CERO secrets en código
- **Compliance**: ISO 27001, SOC 2 ready
- **Rotación automática**: Azure maneja credenciales
- **Audit trail**: Todos los accesos loggeados
- **Zero trust**: Access control granular

### Negativo ⚠️

- Setup inicial más complejo
- Debugging local requiere emulación

## Alternatives Considered

1. **Connection strings en variables de entorno**: Rechazado (inseguro)
2. **Service Principals**: Rechazado (requiere manejo manual de secrets)
3. **System-assigned MI**: Rechazado (User-assigned es más flexible)

---

**Decisión final**: Managed Identities son obligatorias.
"@

Set-Content "docs/architecture/decisions/002-managed-identities.md" $adr002
Write-Host "  ✅ ADR 002: Managed Identities" -ForegroundColor Green

# ADR 003: DDD + CQRS
$adr003 = @"
# ADR 003: Domain-Driven Design + CQRS Backend

**Status**: Approved  
**Fecha**: 2025-11-25  
**Decisión por**: Equipo Backend

---

## Context

Backend de ECONEURA tiene lógica de negocio compleja (11 NEURAS, CRM, automatizaciones). Necesitamos arquitectura que separe claramente responsabilidades.

## Decision

Adoptar **Domain-Driven Design (DDD)** + **CQRS (Command Query Responsibility Segregation)**.

### Estructura:

\`\`\`
src/
├── domain/              # Domain models
│   ├── entities/        # User, Lead, Conversation
│   ├── value-objects/   # Email, PhoneNumber
│   └── aggregates/      # Complex business objects
├── application/
│   ├── commands/        # Write operations
│   │   ├── CreateLead/
│   │   └── SendMessage/
│   └── queries/         # Read operations
│       ├── GetLeads/
│       └── GetConversations/
├── infrastructure/      # External concerns
│   ├── database/
│   ├── cache/
│   └── ai/             # Gemini integration
└── presentation/        # API routes
\`\`\`

## Consequences

### Positivo ✅

- **Separation of Concerns**: Domain puro, sin dependencias externas
- **Testabilidad**: Domain logic testable sin DB
- **Escalabilidad**: Commands y Queries pueden escalar independientemente
- **Performance**: Queries optimizadas sin afectar writes
- **Claridad**: Intenciones explícitas (CreateX vs GetX)

### Negativo ⚠️

- Más código boilerplate
- Curva de aprendizaje DDD

## Alternatives Considered

1. **MVC simple**: Rechazado (no es escalable para complejidad de 11 NEURAS)
2. **Microservicios**: Rechazado (overkill para MVP)
3. **Event Sourcing + CQRS**: Considerado para V2

---

**Decisión final**: DDD+CQRS perfecto para ECONEURA.
"@

Set-Content "docs/architecture/decisions/003-ddd-cqrs.md" $adr003
Write-Host "  ✅ ADR 003: DDD + CQRS" -ForegroundColor Green

Write-Host "`n✅ FASE 22 COMPLETADA: 3 ADRs creados" -ForegroundColor Green
