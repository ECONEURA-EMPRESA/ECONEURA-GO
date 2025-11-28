# 🚀 Guía de Setup para GitHub Repository

## 📋 Checklist Pre-GitHub

### 1. ✅ Estructura del Proyecto
- [x] Monorepo con workspaces configurado
- [x] `.github/` con workflows y templates
- [x] Configuraciones de calidad (`.editorconfig`, `.prettierrc`)
- [x] Documentación organizada
- [x] Scripts de utilidades

### 2. ✅ Archivos de Configuración
- [x] `.gitignore` configurado
- [x] `README.md` completo
- [x] `CONTRIBUTING.md`
- [x] `CHANGELOG.md`
- [x] `LICENSE`
- [x] `SECURITY.md`

### 3. ✅ GitHub Configuration
- [x] Workflows CI/CD
- [x] Dependabot configurado
- [x] CodeQL analysis
- [x] PR templates
- [x] Issue templates
- [x] CODEOWNERS

---

## 🔧 Pasos para Configurar en GitHub

### Paso 1: Crear Repositorio

1. Ir a GitHub y crear nuevo repositorio
2. **NO inicializar** con README, .gitignore o license (ya los tenemos)
3. Nombre sugerido: `ECONEURA-FULL`

### Paso 2: Inicializar Git Local

```powershell
# Si no está inicializado
git init

# Agregar remote
git remote add origin https://github.com/TU-USERNAME/ECONEURA-FULL.git

# Verificar
git remote -v
```

### Paso 3: Primer Commit

```powershell
# Agregar todos los archivos
git add .

# Commit inicial
git commit -m "feat: initial commit - ECONEURA-FULL monorepo"

# Push a main
git branch -M main
git push -u origin main
```

### Paso 4: Configurar GitHub Secrets

Ir a: `Settings → Secrets and variables → Actions`

**Secrets requeridos:**

```
AZURE_CREDENTIALS
  → Service Principal JSON de Azure
  → Formato: {"clientId":"...","clientSecret":"...","subscriptionId":"...","tenantId":"..."}

AZURE_WEBAPP_NAME_BACKEND
  → Nombre del App Service (ej: app-econeura-full-staging-backend)

AZURE_WEBAPP_PUBLISH_PROFILE_BACKEND
  → Publish Profile del App Service (descargar desde Azure Portal)

AZURE_STATIC_WEB_APPS_API_TOKEN
  → Token de Static Web Apps (obtener desde Azure Portal)

POSTGRES_ADMIN_PASSWORD
  → Password del administrador de PostgreSQL

OPENAI_API_KEY
  → API Key de OpenAI (opcional, para desarrollo)
```

**Secrets opcionales:**

```
SNYK_TOKEN
  → Para security scanning con Snyk

CODECOV_TOKEN
  → Para coverage reports
```

### Paso 5: Configurar Branch Protection

Ir a: `Settings → Branches`

**Para `main`:**
- ✅ Require a pull request before merging
- ✅ Require approvals: 1
- ✅ Require status checks to pass before merging
  - ✅ backend-ci / ci-success
  - ✅ frontend-ci / ci-success
- ✅ Require branches to be up to date before merging
- ✅ Include administrators

**Para `develop`:**
- ✅ Require a pull request before merging
- ✅ Require approvals: 1
- ✅ Require status checks to pass before merging

### Paso 6: Habilitar Features

**Settings → General:**

- ✅ Issues (habilitado)
- ✅ Discussions (habilitado)
- ✅ Projects (opcional)
- ✅ Wiki (deshabilitado - usamos docs/)
- ✅ Allow merge commits
- ✅ Allow squash merging
- ✅ Allow rebase merging

**Settings → Security:**

- ✅ Dependency graph (habilitado)
- ✅ Dependabot alerts (habilitado)
- ✅ Dependabot security updates (habilitado)
- ✅ Code scanning (habilitado - CodeQL)

### Paso 7: Configurar GitHub Pages (Opcional)

Si quieres documentación en GitHub Pages:

1. Ir a `Settings → Pages`
2. Source: `Deploy from a branch`
3. Branch: `main` / `docs/`
4. Save

### Paso 8: Verificar Workflows

1. Ir a `Actions`
2. Verificar que los workflows aparecen
3. Hacer un commit de prueba para activar CI

---

## 🧪 Testing de Workflows

### Test Backend CI

```powershell
# Hacer un cambio pequeño en backend
# Ejemplo: agregar un comentario en packages/backend/src/index.ts

git add .
git commit -m "test: trigger backend CI"
git push
```

Verificar en GitHub Actions que:
- ✅ Backend CI se ejecuta
- ✅ Todos los jobs pasan (lint, type-check, test, build)

### Test Frontend CI

```powershell
# Hacer un cambio pequeño en frontend
# Ejemplo: agregar un comentario en packages/frontend/src/App.tsx

git add .
git commit -m "test: trigger frontend CI"
git push
```

Verificar que:
- ✅ Frontend CI se ejecuta
- ✅ Todos los jobs pasan

### Test Deploy (Staging)

1. Ir a `Actions → App Deploy`
2. Click en `Run workflow`
3. Seleccionar `environment: staging`
4. Ejecutar

Verificar que:
- ✅ Build exitoso
- ✅ Deploy a Azure exitoso
- ✅ Smoke tests pasan

---

## 📊 Monitoreo Post-Setup

### Verificar Dependabot

1. Ir a `Security → Dependabot`
2. Verificar que está activo
3. Esperar primera actualización (lunes 09:00)

### Verificar CodeQL

1. Ir a `Security → Code scanning`
2. Verificar que CodeQL está activo
3. Revisar resultados del análisis

### Verificar Coverage

1. Ir a `Actions` después de un CI run
2. Verificar que coverage se sube a Codecov (si está configurado)

---

## 🚨 Troubleshooting

### Workflows no se ejecutan

**Problema:** Workflows no aparecen en Actions

**Solución:**
- Verificar que están en `.github/workflows/`
- Verificar sintaxis YAML
- Hacer un commit que toque los paths configurados

### Secrets no encontrados

**Problema:** Workflow falla con "secret not found"

**Solución:**
- Verificar que los secrets están en `Settings → Secrets`
- Verificar nombres exactos (case-sensitive)
- Verificar que el workflow tiene acceso a secrets

### Deploy falla

**Problema:** Deploy a Azure falla

**Solución:**
- Verificar `AZURE_CREDENTIALS` (formato JSON correcto)
- Verificar que el Service Principal tiene permisos
- Verificar que los recursos Azure existen
- Revisar logs en Azure Portal

---

## ✅ Checklist Final

Antes de considerar el setup completo:

- [ ] Repositorio creado en GitHub
- [ ] Código pusheado a `main`
- [ ] Secrets configurados
- [ ] Branch protection activado
- [ ] Workflows ejecutándose correctamente
- [ ] Dependabot activo
- [ ] CodeQL activo
- [ ] Deploy a staging funciona
- [ ] Documentación accesible

---

## 🎯 Próximos Pasos

1. **Primer Release:**
   ```powershell
   git tag v1.0.0
   git push origin v1.0.0
   ```
   Esto activará el workflow de release

2. **Configurar Environments:**
   - Crear environments en GitHub (dev, staging, prod)
   - Configurar protection rules
   - Agregar secrets específicos por environment

3. **Configurar Notifications:**
   - Slack/Discord webhooks para deployments
   - Email notifications para security alerts

4. **Documentar Proceso:**
   - Actualizar `docs/deployment/` con URLs reales
   - Documentar proceso de release

---

**¡Setup completo! 🎉**

