# 🤝 Guía de Contribución - ECONEURA-FULL

¡Gracias por tu interés en contribuir a ECONEURA-FULL!

## 📋 Tabla de Contenidos

- [Código de Conducta](#código-de-conducta)
- [Cómo Contribuir](#cómo-contribuir)
- [Proceso de Desarrollo](#proceso-de-desarrollo)
- [Estándares de Código](#estándares-de-código)
- [Commits](#commits)
- [Pull Requests](#pull-requests)

## 📜 Código de Conducta

Este proyecto sigue el [Código de Conducta de Contributor Covenant](https://www.contributor-covenant.org/).

## 🚀 Cómo Contribuir

### Reportar Bugs

1. Verifica que el bug no haya sido reportado ya
2. Crea una issue usando el template de [Bug Report](.github/ISSUE_TEMPLATE/bug_report.md)
3. Incluye pasos para reproducir, comportamiento esperado vs actual, y entorno

### Sugerir Features

1. Verifica que la feature no haya sido sugerida ya
2. Crea una issue usando el template de [Feature Request](.github/ISSUE_TEMPLATE/feature_request.md)
3. Describe claramente la feature, su motivación y casos de uso

### Contribuir Código

1. Fork el repositorio
2. Crea una rama desde `develop`: `git checkout -b feature/mi-feature`
3. Realiza tus cambios
4. Asegúrate de que los tests pasen
5. Commit siguiendo [Conventional Commits](#commits)
6. Push y crea un Pull Request

## 🔄 Proceso de Desarrollo

### Branches

- `main` - Producción (solo releases)
- `develop` - Desarrollo activo
- `feature/*` - Nuevas features
- `fix/*` - Bug fixes
- `hotfix/*` - Hotfixes urgentes

### Workflow

1. **Crear branch** desde `develop`
2. **Desarrollar** con tests
3. **Commit** con mensajes descriptivos
4. **Push** y crear PR
5. **Review** y aprobación
6. **Merge** a `develop`
7. **Deploy** a staging
8. **Release** a producción

## 📐 Estándares de Código

### TypeScript

- TypeScript estricto (`strict: true`)
- Sin `any` (usar `unknown` si es necesario)
- Interfaces para objetos
- Types para uniones/primitivos

### Estilo

- Usar `.editorconfig` y `.prettierrc.json`
- 2 espacios de indentación
- Comillas simples en JS/TS
- Semicolons al final

### Naming

- `camelCase` para variables/funciones
- `PascalCase` para clases/interfaces
- `UPPER_SNAKE_CASE` para constantes
- `kebab-case` para archivos

## 💬 Commits

Usamos [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- `feat` - Nueva funcionalidad
- `fix` - Bug fix
- `docs` - Documentación
- `style` - Formato (no afecta código)
- `refactor` - Refactorización
- `perf` - Mejora de performance
- `test` - Tests
- `chore` - Tareas de mantenimiento
- `ci` - Cambios en CI/CD
- `build` - Cambios en build

### Scope

- `backend` - Backend
- `frontend` - Frontend
- `crm` - CRM
- `infra` - Infraestructura
- `docs` - Documentación
- `deps` - Dependencias
- `config` - Configuración

### Ejemplos

```bash
feat(crm): add lead export to CSV
fix(backend): resolve authentication token expiration
docs(deployment): update Azure deployment guide
refactor(frontend): optimize component rendering
```

## 🔍 Pull Requests

### Checklist

- [ ] Código sigue los estándares del proyecto
- [ ] Tests añadidos/actualizados
- [ ] Tests pasan localmente
- [ ] Documentación actualizada
- [ ] Commits siguen Conventional Commits
- [ ] Sin warnings de TypeScript
- [ ] Sin errores de linting

### Template

Usa el [PR Template](.github/PULL_REQUEST_TEMPLATE.md) al crear un PR.

### Review Process

1. Al menos 1 aprobación requerida
2. Todos los checks de CI deben pasar
3. Sin conflictos con `develop`
4. Code review positivo

## 🧪 Testing

### Backend

```bash
npm run test:backend
npm run test:backend -- --coverage
```

### Frontend

```bash
npm run test:frontend
npm run test:e2e
```

### Coverage

- Backend: >80% coverage
- Frontend: >70% coverage

## 📚 Documentación

- Actualiza documentación si añades features
- Añade ejemplos de uso
- Documenta breaking changes

## ❓ Preguntas?

- Abre una [Discussion](https://github.com/TU-REPO/ECONEURA-FULL/discussions)
- Revisa la [documentación](docs/)
- Contacta al equipo

---

**¡Gracias por contribuir! 🎉**

