# 🎯 ORDEN TÉCNICA: WORKFLOWS A 10/10

**De:** Jefe Técnico ECONEURA  
**Para:** Equipo de Desarrollo  
**Fecha:** 2025-01-18  
**Prioridad:** 🔴 **CRÍTICA - EJECUTAR INMEDIATAMENTE**  
**Objetivo:** Llevar todos los workflows GitHub Actions a nivel 10/10

---

## 📋 RESUMEN EJECUTIVO

**Estado Actual:** 7.9/10  
**Objetivo:** 10/10  
**Workflows Afectados:** 7 workflows  
**Tiempo Estimado:** 4-6 horas  
**Riesgo:** Bajo (mejoras incrementales)

---

## 🚨 ORDEN DIRECTA

**Como Jefe Técnico, ordeno que se implementen TODAS las mejoras siguientes para llevar los workflows a 10/10. NO HAY NEGOCIACIÓN. TODO DEBE ESTAR EN VERDE.**

---

## 1️⃣ BACKEND CI - MEJORAS CRÍTICAS

### ✅ **TAREA 1.1: Hacer Lint Requerido**

**Archivo:** `.github/workflows/backend-ci.yml`

**Cambio:**
```yaml
# ANTES (línea 40-42):
- name: Run ESLint
  run: npm run lint:backend || echo "⚠️ Linting no configurado aún"
  continue-on-error: true

# DESPUÉS:
- name: Run ESLint
  run: npm run lint:backend
  continue-on-error: false
```

**Justificación:** Lint debe ser requerido, no opcional. Si hay errores de lint, el workflow debe fallar.

---

### ✅ **TAREA 1.2: Hacer Coverage Requerido**

**Archivo:** `.github/workflows/backend-ci.yml`

**Cambio:**
```yaml
# ANTES (línea 86-88):
- name: Generate coverage
  run: npm run test:backend -- --coverage || echo "⚠️ Coverage no configurado"
  continue-on-error: true

# DESPUÉS:
- name: Generate coverage
  run: npm run test:backend -- --coverage
  continue-on-error: false
```

**Justificación:** Coverage es crítico para calidad de código. Debe ser requerido.

---

### ✅ **TAREA 1.3: Hacer Snyk Requerido si Token Existe**

**Archivo:** `.github/workflows/backend-ci.yml`

**Cambio:**
```yaml
# ANTES (línea 143-149):
- name: Run Snyk security scan
  uses: snyk/actions/node@master
  env:
    SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
  continue-on-error: true
  with:
    args: --severity-threshold=high

# DESPUÉS:
- name: Run Snyk security scan
  if: ${{ secrets.SNYK_TOKEN != '' }}
  uses: snyk/actions/node@master
  env:
    SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
  continue-on-error: false
  with:
    args: --severity-threshold=high
```

**Justificación:** Si Snyk está configurado, debe ser requerido y fallar si encuentra vulnerabilidades críticas.

---

### ✅ **TAREA 1.4: Agregar Upload de Artifacts**

**Archivo:** `.github/workflows/backend-ci.yml`

**Agregar después de línea 126:**
```yaml
- name: Upload build artifacts
  uses: actions/upload-artifact@v4
  if: success()
  with:
    name: backend-build-${{ github.sha }}
    path: packages/backend/dist
    retention-days: 7
```

**Justificación:** Artifacts necesarios para deploy y debugging.

---

## 2️⃣ FRONTEND CI - MEJORAS CRÍTICAS

### ✅ **TAREA 2.1: Hacer Lint Requerido**

**Archivo:** `.github/workflows/frontend-ci.yml`

**Cambio:**
```yaml
# ANTES (línea 40-42):
- name: Run ESLint
  run: npm run lint --workspace=@econeura/web || echo "⚠️ Linting no configurado aún"
  continue-on-error: true

# DESPUÉS:
- name: Run ESLint
  run: npm run lint --workspace=@econeura/web
  continue-on-error: false
```

---

### ✅ **TAREA 2.2: Hacer Tests Requeridos**

**Archivo:** `.github/workflows/frontend-ci.yml`

**Cambio:**
```yaml
# ANTES (línea 122-124):
- name: Run unit tests
  run: npm run test --workspace=@econeura/web || echo "⚠️ Tests no configurados aún"
  continue-on-error: true

# DESPUÉS:
- name: Run unit tests
  run: npm run test --workspace=@econeura/web
  continue-on-error: false
```

---

### ✅ **TAREA 2.3: Hacer E2E Tests Requeridos**

**Archivo:** `.github/workflows/frontend-ci.yml`

**Cambio:**
```yaml
# ANTES (línea 157-159):
- name: Run E2E tests
  run: npm run test:e2e --workspace=@econeura/web || echo "⚠️ E2E tests no configurados aún"
  continue-on-error: true

# DESPUÉS:
- name: Run E2E tests
  run: npm run test:e2e --workspace=@econeura/web
  continue-on-error: false
```

---

### ✅ **TAREA 2.4: Agregar Bundle Size Limits**

**Archivo:** `.github/workflows/frontend-ci.yml`

**Agregar después de línea 102:**
```yaml
- name: Validate bundle size
  run: |
    MAX_BUNDLE_SIZE_MB=5
    BUNDLE_SIZE=$(du -sm packages/frontend/dist | cut -f1)
    
    if [ "$BUNDLE_SIZE" -gt "$MAX_BUNDLE_SIZE_MB" ]; then
      echo "❌ Bundle size ($BUNDLE_SIZE MB) exceeds maximum ($MAX_BUNDLE_SIZE_MB MB)"
      echo "📦 Top 10 largest files:"
      find packages/frontend/dist -type f -exec du -h {} \; | sort -rh | head -10
      exit 1
    fi
    
    echo "✅ Bundle size ($BUNDLE_SIZE MB) is within limits"
```

**Justificación:** Control de bundle size es crítico para performance.

---

### ✅ **TAREA 2.5: Agregar Upload de Artifacts**

**Archivo:** `.github/workflows/frontend-ci.yml`

**Agregar después de línea 102:**
```yaml
- name: Upload build artifacts
  uses: actions/upload-artifact@v4
  if: success()
  with:
    name: frontend-build-${{ github.sha }}
    path: packages/frontend/dist
    retention-days: 7
```

---

## 3️⃣ APP DEPLOY - MEJORAS CRÍTICAS

### ✅ **TAREA 3.1: Agregar GitHub Environments**

**Archivo:** `.github/workflows/app-deploy.yml`

**Cambio:**
```yaml
# ANTES (línea 12-14):
jobs:
  app-deploy:
    runs-on: ubuntu-latest
    timeout-minutes: 30

# DESPUÉS:
jobs:
  app-deploy:
    runs-on: ubuntu-latest
    timeout-minutes: 30
    environment: ${{ github.event.inputs.environment }}
```

**Acción Adicional:** Configurar Environments en GitHub:
1. Settings → Environments
2. Crear: `dev`, `staging`, `prod`
3. Para `prod`: Agregar protection rules (required reviewers)

---

### ✅ **TAREA 3.2: Actualizar Static Web Apps Deploy**

**Archivo:** `.github/workflows/app-deploy.yml`

**Cambio:**
```yaml
# ANTES (línea 112-121):
- name: Deploy frontend to Azure Static Web App
  uses: Azure/static-web-apps-deploy@v1
  with:
    azure_static_web_apps_api_token: ${{ secrets.AZURE_STATIC_WEB_APPS_API_TOKEN }}
    repo_token: ${{ secrets.GITHUB_TOKEN }}
    action: "upload"
    app_location: "packages/frontend"
    output_location: "dist"
    skip_app_build: true

# DESPUÉS:
- name: Deploy frontend to Azure Static Web App
  uses: Azure/static-web-apps-deploy@v1
  with:
    azure_static_web_apps_api_token: ${{ secrets.AZURE_STATIC_WEB_APPS_API_TOKEN }}
    repo_token: ${{ secrets.GITHUB_TOKEN }}
    action: "upload"
    app_location: "packages/frontend"
    output_location: "dist"
    skip_app_build: true
    deployment_environment: ${{ github.event.inputs.environment }}
```

**Nota:** Verificar si existe versión más reciente de la action.

---

### ✅ **TAREA 3.3: Agregar Rollback Strategy**

**Archivo:** `.github/workflows/app-deploy.yml`

**Agregar después de línea 177:**
```yaml
- name: Rollback on failure
  if: failure()
  run: |
    echo "❌ Deployment failed, initiating rollback..."
    BACKEND_NAME="${{ secrets.AZURE_WEBAPP_NAME_BACKEND }}"
    
    # Obtener último deployment exitoso
    LAST_DEPLOYMENT=$(az webapp deployment list \
      --name "$BACKEND_NAME" \
      --resource-group "rg-econeura-full-${{ github.event.inputs.environment }}" \
      --query "[?state=='Succeeded'] | [0].id" \
      -o tsv)
    
    if [ -n "$LAST_DEPLOYMENT" ]; then
      echo "🔄 Rolling back to: $LAST_DEPLOYMENT"
      az webapp deployment slot swap \
        --name "$BACKEND_NAME" \
        --resource-group "rg-econeura-full-${{ github.event.inputs.environment }}" \
        --slot staging \
        --target-slot production || echo "⚠️ Rollback not available"
    else
      echo "⚠️ No previous deployment found for rollback"
    fi
```

---

### ✅ **TAREA 3.4: Agregar Notificaciones**

**Archivo:** `.github/workflows/app-deploy.yml`

**Agregar al final del job:**
```yaml
- name: Send deployment notification
  if: always()
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    text: |
      Deployment to ${{ github.event.inputs.environment }} ${{ job.status }}
      Commit: ${{ github.sha }}
      Author: ${{ github.actor }}
    webhook_url: ${{ secrets.SLACK_WEBHOOK_URL }}
  env:
    SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
  continue-on-error: true
```

**Nota:** Requiere configurar `SLACK_WEBHOOK_URL` secret (opcional).

---

## 4️⃣ INFRA DEPLOY - MEJORAS CRÍTICAS

### ✅ **TAREA 4.1: Agregar GitHub Environments**

**Archivo:** `.github/workflows/infra-deploy.yml`

**Cambio:**
```yaml
# ANTES (línea 15-17):
jobs:
  infra-deploy:
    runs-on: ubuntu-latest
    timeout-minutes: 45

# DESPUÉS:
jobs:
  infra-deploy:
    runs-on: ubuntu-latest
    timeout-minutes: 45
    environment: ${{ github.event.inputs.environment }}
```

---

### ✅ **TAREA 4.2: Agregar What-If Analysis**

**Archivo:** `.github/workflows/infra-deploy.yml`

**Agregar antes de línea 70:**
```yaml
- name: Bicep What-If Analysis
  uses: azure/CLI@v2
  with:
    inlineScript: |
      echo "🔍 Running What-If analysis..."
      az deployment group what-if \
        --resource-group "${{ github.event.inputs.resourceGroupName }}" \
        --template-file infrastructure/azure/main.bicep \
        --parameters environment=${{ github.event.inputs.environment }} \
                     location=westeurope \
                     baseName=econeura-full \
                     postgresAdminPassword='${{ secrets.POSTGRES_ADMIN_PASSWORD }}' \
                     openAiApiKey='${{ secrets.OPENAI_API_KEY }}' \
                     databaseUrlPlaceholder='postgresql://placeholder:placeholder@placeholder:5432/placeholder?sslmode=require'
      
      echo "✅ What-If analysis completed"
```

---

### ✅ **TAREA 4.3: Agregar Validación de Bicep**

**Archivo:** `.github/workflows/infra-deploy.yml`

**Agregar antes de línea 70:**
```yaml
- name: Validate Bicep templates
  uses: azure/CLI@v2
  with:
    inlineScript: |
      echo "✅ Validating Bicep templates..."
      az deployment group validate \
        --resource-group "${{ github.event.inputs.resourceGroupName }}" \
        --template-file infrastructure/azure/main.bicep \
        --parameters environment=${{ github.event.inputs.environment }} \
                     location=westeurope \
                     baseName=econeura-full \
                     postgresAdminPassword='${{ secrets.POSTGRES_ADMIN_PASSWORD }}' \
                     openAiApiKey='${{ secrets.OPENAI_API_KEY }}' \
                     databaseUrlPlaceholder='postgresql://placeholder:placeholder@placeholder:5432/placeholder?sslmode=require'
      
      if [ $? -ne 0 ]; then
        echo "❌ Bicep validation failed"
        exit 1
      fi
      
      echo "✅ Bicep validation passed"
```

---

### ✅ **TAREA 4.4: Mejorar Validación de Secrets**

**Archivo:** `.github/workflows/infra-deploy.yml`

**Cambio:**
```yaml
# ANTES (línea 20-27):
- name: Validate required secrets
  run: |
    echo "Validating required secrets..."
    if [ -z "${{ secrets.AZURE_CREDENTIALS }}" ]; then
      echo "❌ AZURE_CREDENTIALS is missing"
      exit 1
    fi
    echo "✅ AZURE_CREDENTIALS is present"

# DESPUÉS:
- name: Validate required secrets
  run: |
    echo "Validating required secrets..."
    MISSING_SECRETS=0
    
    if [ -z "${{ secrets.AZURE_CREDENTIALS }}" ]; then
      echo "❌ AZURE_CREDENTIALS is missing"
      MISSING_SECRETS=$((MISSING_SECRETS + 1))
    fi
    
    if [ -z "${{ secrets.POSTGRES_ADMIN_PASSWORD }}" ]; then
      echo "❌ POSTGRES_ADMIN_PASSWORD is missing"
      MISSING_SECRETS=$((MISSING_SECRETS + 1))
    fi
    
    if [ -z "${{ secrets.OPENAI_API_KEY }}" ]; then
      echo "❌ OPENAI_API_KEY is missing"
      MISSING_SECRETS=$((MISSING_SECRETS + 1))
    fi
    
    if [ $MISSING_SECRETS -gt 0 ]; then
      echo ""
      echo "❌ FALTAN $MISSING_SECRETS SECRETS CRÍTICOS"
      echo "Configurar en: https://github.com/${{ github.repository }}/settings/secrets/actions"
      exit 1
    fi
    
    echo "✅ All required secrets are present"
```

---

### ✅ **TAREA 4.5: Capturar Outputs del Deployment**

**Archivo:** `.github/workflows/infra-deploy.yml`

**Agregar después de línea 83:**
```yaml
- name: Capture deployment outputs
  uses: azure/CLI@v2
  id: deployment-outputs
  with:
    inlineScript: |
      DEPLOYMENT_NAME="econeura-full-${{ github.event.inputs.environment }}-$(date +%Y%m%d-%H%M%S)"
      RG="${{ github.event.inputs.resourceGroupName }}"
      
      OUTPUTS=$(az deployment group show \
        --resource-group "$RG" \
        --name "$DEPLOYMENT_NAME" \
        --query "properties.outputs" \
        -o json)
      
      echo "outputs<<EOF" >> $GITHUB_OUTPUT
      echo "$OUTPUTS" >> $GITHUB_OUTPUT
      echo "EOF" >> $GITHUB_OUTPUT
      
      echo "📊 Deployment outputs captured"
```

---

## 5️⃣ BACKEND DEPLOY - MEJORAS CRÍTICAS

### ✅ **TAREA 5.1: ELIMINAR O MEJORAR COMPLETAMENTE**

**DECISIÓN:** Este workflow está duplicado con `app-deploy.yml`. 

**OPCIÓN A - ELIMINAR:**
```bash
# Eliminar archivo
rm .github/workflows/backend-deploy.yml
```

**OPCIÓN B - MEJORAR COMPLETAMENTE:**

**Archivo:** `.github/workflows/backend-deploy.yml`

**REEMPLAZAR TODO EL CONTENIDO:**
```yaml
name: Deploy Backend to Azure

on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment (dev/staging/prod)'
        required: true
        default: 'dev'

env:
  NODE_VERSION: '20'

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    timeout-minutes: 20
    environment: ${{ github.event.inputs.environment }}

    steps:
      - name: Validate required secrets
        run: |
          MISSING_SECRETS=0
          if [ -z "${{ secrets.AZURE_CREDENTIALS }}" ]; then
            echo "❌ AZURE_CREDENTIALS is missing"
            MISSING_SECRETS=$((MISSING_SECRETS + 1))
          fi
          if [ -z "${{ secrets.AZURE_WEBAPP_NAME_BACKEND }}" ]; then
            echo "❌ AZURE_WEBAPP_NAME_BACKEND is missing"
            MISSING_SECRETS=$((MISSING_SECRETS + 1))
          fi
          if [ $MISSING_SECRETS -gt 0 ]; then
            echo "❌ FALTAN $MISSING_SECRETS SECRETS CRÍTICOS"
            exit 1
          fi
          echo "✅ All required secrets are present"

      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Type-check backend
        run: npm run type-check:backend

      - name: Build backend
        run: npm run build:backend

      - name: Verify build
        run: |
          if [ ! -d "packages/backend/dist" ]; then
            echo "❌ Build failed: dist folder not found"
            exit 1
          fi
          echo "✅ Build verified"

      - name: Prune dev dependencies
        run: npm prune --production
        working-directory: packages/backend

      - name: Login to Azure
        uses: azure/login@v2
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}

      - name: Deploy to Azure Web App
        uses: azure/webapps-deploy@v3
        with:
          app-name: ${{ secrets.AZURE_WEBAPP_NAME_BACKEND }}
          package: ./packages/backend

      - name: Wait for backend to be ready
        run: |
          BACKEND_NAME="${{ secrets.AZURE_WEBAPP_NAME_BACKEND }}"
          BACKEND_URL="https://${BACKEND_NAME}.azurewebsites.net"
          MAX_ATTEMPTS=30
          ATTEMPT=1
          
          while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
            HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "${BACKEND_URL}/health" 2>/dev/null || echo "000")
            if [ "$HTTP_CODE" = "200" ]; then
              echo "✅ Backend está listo (HTTP $HTTP_CODE)"
              exit 0
            fi
            echo "Intento $ATTEMPT/$MAX_ATTEMPTS: Esperando..."
            sleep 10
            ATTEMPT=$((ATTEMPT + 1))
          done
          
          echo "❌ Backend no respondió después de 5 minutos"
          exit 1

      - name: Smoke test
        run: |
          BACKEND_NAME="${{ secrets.AZURE_WEBAPP_NAME_BACKEND }}"
          BACKEND_URL="https://${BACKEND_NAME}.azurewebsites.net"
          HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "${BACKEND_URL}/health")
          if [ "$HTTP_CODE" -ne 200 ]; then
            echo "❌ Smoke test failed (HTTP $HTTP_CODE)"
            exit 1
          fi
          echo "✅ Smoke test passed"
```

**RECOMENDACIÓN:** OPCIÓN A (eliminar) - `app-deploy.yml` ya cubre esto.

---

## 6️⃣ RELEASE - MEJORAS CRÍTICAS

### ✅ **TAREA 6.1: Actualizar Create Release Action**

**Archivo:** `.github/workflows/release.yml`

**Cambio:**
```yaml
# ANTES (línea 81-106):
- name: Create Release
  uses: actions/create-release@v1
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
  with:
    tag_name: v${{ steps.version.outputs.version }}
    release_name: Release v${{ steps.version.outputs.version }}
    body: |
      ## 🚀 Release v${{ steps.version.outputs.version }}
      ### 📋 Cambios
      ${{ steps.changelog.outputs.changelog }}
    draft: false
    prerelease: false

# DESPUÉS:
- name: Create Release
  uses: softprops/action-gh-release@v1
  with:
    tag_name: v${{ steps.version.outputs.version }}
    name: Release v${{ steps.version.outputs.version }}
    body: |
      ## 🚀 Release v${{ steps.version.outputs.version }}
      
      ### 📋 Cambios
      
      ${{ steps.changelog.outputs.changelog }}
      
      ### 📦 Instalación
      
      ```bash
      npm install
      ```
      
      ### 🔗 Links
      
      - [Documentación](https://github.com/${{ github.repository }}/tree/main/docs)
      - [Changelog completo](https://github.com/${{ github.repository }}/blob/main/CHANGELOG.md)
    draft: false
    prerelease: false
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

---

### ✅ **TAREA 6.2: Agregar Validación de Versión**

**Archivo:** `.github/workflows/release.yml`

**Agregar después de línea 58:**
```yaml
- name: Validate version format
  run: |
    VERSION="${{ steps.version.outputs.version }}"
    
    # Validar formato semver
    if ! echo "$VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9-]+(\.[0-9]+)?)?$'; then
      echo "❌ Invalid version format: $VERSION"
      echo "Expected format: X.Y.Z or X.Y.Z-prerelease"
      exit 1
    fi
    
    echo "✅ Version format valid: $VERSION"
```

---

### ✅ **TAREA 6.3: Agregar Pre-release Checks**

**Archivo:** `.github/workflows/release.yml`

**Agregar después de línea 46:**
```yaml
- name: Check CI status
  uses: Sibz/github-status-action@v1
  with:
    authToken: ${{ secrets.GITHUB_TOKEN }}
    context: 'backend-ci / ci-success'
    state: 'success'
    continue-on-error: false

- name: Check CI status (frontend)
  uses: Sibz/github-status-action@v1
  with:
    authToken: ${{ secrets.GITHUB_TOKEN }}
    context: 'frontend-ci / ci-success'
    state: 'success'
    continue-on-error: false
```

---

## 7️⃣ CODEQL - MEJORAS MENORES

### ✅ **TAREA 7.1: Agregar Notificaciones (Opcional)**

**Archivo:** `.github/workflows/codeql-analysis.yml`

**Agregar al final:**
```yaml
- name: Notify on critical findings
  if: failure()
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    text: |
      CodeQL found critical security issues!
      Repository: ${{ github.repository }}
      Commit: ${{ github.sha }}
    webhook_url: ${{ secrets.SLACK_WEBHOOK_URL }}
  continue-on-error: true
```

---

## 📋 CHECKLIST DE EJECUCIÓN

### **FASE 1: CRÍTICAS (Hacer primero)**

- [ ] **1.1** Hacer lint requerido en backend-ci.yml
- [ ] **1.2** Hacer coverage requerido en backend-ci.yml
- [ ] **1.3** Hacer Snyk requerido si token existe en backend-ci.yml
- [ ] **1.4** Agregar upload artifacts en backend-ci.yml
- [ ] **2.1** Hacer lint requerido en frontend-ci.yml
- [ ] **2.2** Hacer tests requeridos en frontend-ci.yml
- [ ] **2.3** Hacer E2E tests requeridos en frontend-ci.yml
- [ ] **2.4** Agregar bundle size limits en frontend-ci.yml
- [ ] **2.5** Agregar upload artifacts en frontend-ci.yml
- [ ] **3.1** Agregar GitHub Environments en app-deploy.yml
- [ ] **3.2** Actualizar Static Web Apps deploy en app-deploy.yml
- [ ] **3.3** Agregar rollback strategy en app-deploy.yml
- [ ] **4.1** Agregar GitHub Environments en infra-deploy.yml
- [ ] **4.2** Agregar What-If analysis en infra-deploy.yml
- [ ] **4.3** Agregar validación Bicep en infra-deploy.yml
- [ ] **4.4** Mejorar validación secrets en infra-deploy.yml
- [ ] **5.1** Eliminar o mejorar backend-deploy.yml
- [ ] **6.1** Actualizar create release action en release.yml
- [ ] **6.2** Agregar validación versión en release.yml
- [ ] **6.3** Agregar pre-release checks en release.yml

### **FASE 2: CONFIGURACIÓN GITHUB**

- [ ] Configurar Environments (dev, staging, prod)
- [ ] Agregar protection rules para prod
- [ ] Configurar SLACK_WEBHOOK_URL (opcional)

### **FASE 3: TESTING**

- [ ] Ejecutar todos los workflows manualmente
- [ ] Verificar que todos pasan
- [ ] Verificar que artifacts se suben
- [ ] Verificar que notifications funcionan

---

## 🎯 CRITERIOS DE ÉXITO

**Para considerar 10/10, TODOS estos criterios deben cumplirse:**

1. ✅ **Todos los workflows pasan sin errores**
2. ✅ **Lint es requerido y falla si hay errores**
3. ✅ **Tests son requeridos y fallan si hay errores**
4. ✅ **Coverage es requerido y se sube a Codecov**
5. ✅ **Artifacts se suben correctamente**
6. ✅ **GitHub Environments configurados**
7. ✅ **Rollback strategy implementada**
8. ✅ **What-If analysis funciona**
9. ✅ **Validación de Bicep funciona**
10. ✅ **Release workflow actualizado**

---

## ⚠️ ADVERTENCIAS

1. **NO COMMITEAR SIN PROBAR:** Cada cambio debe probarse localmente primero
2. **NO ROMPER WORKFLOWS EXISTENTES:** Hacer cambios incrementales
3. **VERIFICAR SECRETS:** Asegurar que todos los secrets están configurados
4. **BACKUP:** Hacer backup de workflows antes de cambiar

---

## 📞 SOPORTE

Si hay problemas durante la implementación:

1. Revisar logs de GitHub Actions
2. Verificar secrets en Settings → Secrets
3. Consultar documentación: `docs/TROUBLESHOOTING-GUIA-COMPLETA.md`
4. Contactar Jefe Técnico

---

## ✅ FIRMA

**Jefe Técnico ECONEURA**  
**Fecha:** 2025-01-18  
**Prioridad:** 🔴 **CRÍTICA**  
**Estado:** ⏳ **PENDIENTE DE EJECUCIÓN**

---

**ESTA ORDEN DEBE SER EJECUTADA COMPLETAMENTE. NO HAY NEGOCIACIÓN. TODO DEBE ESTAR EN VERDE.**

---

**Total:** ~2000 palabras  
**Última actualización:** 2025-01-18

