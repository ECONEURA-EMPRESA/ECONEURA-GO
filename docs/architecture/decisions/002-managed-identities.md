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
