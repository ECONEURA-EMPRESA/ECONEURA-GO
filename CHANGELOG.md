# Changelog

Todos los cambios notables en este proyecto serán documentados en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/),
y este proyecto adhiere a [Semantic Versioning](https://semver.org/lang/es/).

## [Unreleased]

### Added
- CRM Premium Panel con 10 mejoras premium
- Hooks personalizados `useCRMData` y `useCRMLeads`
- Integración completa con API backend
- Workflows CI/CD mejorados
- Dependabot configuration
- CodeQL security scanning
- Release automation
- Templates de GitHub (PR, Issues)
- Configuraciones de calidad (.editorconfig, .prettierrc)

### Changed
- Reorganización de documentación
- Mejora de workflows CI/CD
- Optimización de estructura del proyecto

### Fixed
- Corrección de endpoints inexistentes
- Fix de tipos en CRMAgentImpact
- Corrección de paginación (page/pageSize -> limit/offset)
- Validación mejorada de datos de API
- Fix de imports (React.useEffect -> useEffect)

## [1.0.0] - 2025-01-17

### Added
- Arquitectura DDD + CQRS + Event Sourcing
- 11 NEURAS (asistentes IA por departamento)
- CRM Premium Panel
- Autenticación Azure AD
- RBAC completo
- Application Insights integration
- Azure deployment con Bicep
- GitHub Actions workflows

---

[Unreleased]: https://github.com/TU-REPO/ECONEURA-FULL/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/TU-REPO/ECONEURA-FULL/releases/tag/v1.0.0
