# 🔄 Referencia de Workflows - GitHub Actions

## 📋 Workflows Disponibles

### 1. Backend CI (`backend-ci.yml`)

**Trigger:**
- Push a `main` o `develop` (cambios en `packages/backend/**`)
- Pull requests a `main` o `develop`

**Jobs:**
- `lint` - ESLint
- `type-check` - TypeScript type checking
- `test` - Tests unitarios + coverage
- `build` - Build del backend
- `security-scan` - npm audit + Snyk
- `ci-success` - Job de éxito

**Duración:** ~10-15 minutos

**Status Badge:**
```markdown
![Backend CI](https://github.com/TU-REPO/ECONEURA-FULL/workflows/Backend%20CI/badge.svg)
```

---

### 2. Frontend CI (`frontend-ci.yml`)

**Trigger:**
- Push a `main` o `develop` (cambios en `packages/frontend/**`)
- Pull requests a `main` o `develop`

**Jobs:**
- `lint` - ESLint
- `type-check` - TypeScript type checking
- `build` - Build del frontend + bundle analysis
- `test` - Tests unitarios + coverage
- `test-e2e` - Tests E2E con Playwright
- `security-scan` - npm audit + Snyk
- `ci-success` - Job de éxito

**Duración:** ~15-20 minutos

**Status Badge:**
```markdown
![Frontend CI](https://github.com/TU-REPO/ECONEURA-FULL/workflows/Frontend%20CI/badge.svg)
```

---

### 3. App Deploy (`app-deploy.yml`)

**Trigger:**
- `workflow_dispatch` (manual)
- Input: `environment` (dev/staging/prod)

**Jobs:**
- `app-deploy` - Deploy completo
  - Validación de secrets
  - Build backend + frontend
  - Deploy a Azure App Service (backend)
  - Deploy a Azure Static Web Apps (frontend)
  - Smoke tests

**Duración:** ~20-30 minutos

**Secrets Requeridos:**
- `AZURE_CREDENTIALS`
- `AZURE_WEBAPP_NAME_BACKEND`
- `AZURE_WEBAPP_PUBLISH_PROFILE_BACKEND`
- `AZURE_STATIC_WEB_APPS_API_TOKEN`

---

### 4. Infra Deploy (`infra-deploy.yml`)

**Trigger:**
- `workflow_dispatch` (manual)
- Inputs: `environment`, `resourceGroupName`

**Jobs:**
- `infra-deploy` - Despliegue de infraestructura con Bicep

**Duración:** ~15-20 minutos

---

### 5. Release (`release.yml`) ⭐ NUEVO

**Trigger:**
- Push de tag `v*.*.*` (ej: `v1.2.3`)
- `workflow_dispatch` con inputs

**Jobs:**
- `release` - Creación automática de release
  - Generación de changelog
  - Creación de release en GitHub
  - Actualización de CHANGELOG.md
  - Tags automáticos

**Uso:**
```bash
# Opción 1: Crear tag manualmente
git tag v1.2.3
git push origin v1.2.3

# Opción 2: Usar workflow_dispatch desde GitHub UI
# Ir a Actions → Release → Run workflow
```

---

### 6. CodeQL Analysis (`codeql-analysis.yml`) ⭐ NUEVO

**Trigger:**
- Push a `main` o `develop`
- Pull requests
- Schedule: Lunes 00:00 (semanal)

**Jobs:**
- `analyze` - Análisis de seguridad con CodeQL
  - JavaScript
  - TypeScript

**Duración:** ~10-15 minutos

---

## 🔍 Monitoreo de Workflows

### Ver Estado

1. Ir a `Actions` en GitHub
2. Ver lista de workflows ejecutados
3. Click en un run para ver detalles

### Logs

- Cada job tiene logs detallados
- Descargar logs completos si es necesario
- Re-ejecutar jobs fallidos

### Notificaciones

Configurar en `Settings → Notifications`:
- ✅ Email para workflow failures
- ✅ Email para workflow approvals requeridas

---

## 🛠️ Troubleshooting Workflows

### Workflow no se ejecuta

**Causas comunes:**
- Paths no coinciden con cambios
- Branch no es `main` o `develop`
- Sintaxis YAML incorrecta

**Solución:**
```yaml
# Verificar paths en workflow
on:
  push:
    paths:
      - 'packages/backend/**'  # Debe coincidir con archivos cambiados
```

### Job falla

**Verificar:**
1. Logs del job
2. Secrets configurados
3. Permisos del workflow
4. Dependencias disponibles

### Timeout

**Solución:**
```yaml
timeout-minutes: 30  # Aumentar si es necesario
```

---

## 📊 Métricas

### Tiempos Promedio

- Backend CI: ~10 min
- Frontend CI: ~15 min
- App Deploy: ~25 min
- Release: ~5 min
- CodeQL: ~12 min

### Costos

GitHub Actions: **2000 minutos/mes gratis**
- Backend CI: ~10 min/run
- Frontend CI: ~15 min/run
- **Total estimado:** ~500-800 min/mes (dentro del límite)

---

## 🎯 Mejores Prácticas

1. **No ejecutar workflows en cada commit**
   - Usar paths para filtrar
   - Agrupar cambios relacionados

2. **Caché de dependencias**
   - Ya configurado con `cache: 'npm'`
   - Reduce tiempo de ejecución

3. **Jobs paralelos**
   - Backend CI: jobs en paralelo
   - Frontend CI: jobs en paralelo
   - Reduce tiempo total

4. **Continue-on-error**
   - Usado para steps opcionales
   - No falla el workflow completo

5. **Timeouts**
   - Configurados para evitar jobs infinitos
   - Ajustar según necesidad

---

## 🔗 Links Útiles

- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [Workflow Syntax](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)
- [Secrets Management](https://docs.github.com/en/actions/security-guides/encrypted-secrets)

