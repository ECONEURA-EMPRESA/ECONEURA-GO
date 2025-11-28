# 🚀 SCRIPT: APLICAR MEJORAS WORKFLOWS A 10/10
# Autor: Jefe Técnico ECONEURA
# Fecha: 2025-01-18
# Objetivo: Automatizar TODAS las mejoras de workflows a nivel 10/10

param(
    [switch]$DryRun = $false,
    [switch]$SkipBackup = $false,
    [switch]$SkipValidation = $false,
    [switch]$SkipTesting = $false
)

$ErrorActionPreference = "Stop"
$WORKFLOWS_DIR = ".github/workflows"
$BACKUP_DIR = ".github/workflows.backup"
$LOG_FILE = "workflows-improvements.log"

# Colores para output
function Write-Success { param($msg) Write-Host "✅ $msg" -ForegroundColor Green }
function Write-Error { param($msg) Write-Host "❌ $msg" -ForegroundColor Red }
function Write-Warning { param($msg) Write-Host "⚠️  $msg" -ForegroundColor Yellow }
function Write-Info { param($msg) Write-Host "ℹ️  $msg" -ForegroundColor Cyan }

# Logging
function Write-Log {
    param($msg)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $msg" | Out-File -FilePath $LOG_FILE -Append
    Write-Host "[$timestamp] $msg"
}

# Validar prerequisitos
function Test-Prerequisites {
    Write-Log "Validando prerequisitos..."
    
    $errors = @()
    
    # Verificar que estamos en el directorio correcto
    if (-not (Test-Path "package.json")) {
        $errors += "No se encontró package.json. ¿Estás en el directorio raíz del proyecto?"
    }
    
    # Verificar que existe .github/workflows
    if (-not (Test-Path $WORKFLOWS_DIR)) {
        $errors += "No se encontró $WORKFLOWS_DIR"
    }
    
    # Verificar que git está disponible
    try {
        git --version | Out-Null
    } catch {
        $errors += "Git no está disponible"
    }
    
    # Verificar que node está disponible
    try {
        node --version | Out-Null
    } catch {
        $errors += "Node.js no está disponible"
    }
    
    # Verificar que npm está disponible
    try {
        npm --version | Out-Null
    } catch {
        $errors += "npm no está disponible"
    }
    
    if ($errors.Count -gt 0) {
        Write-Error "Prerequisitos no cumplidos:"
        $errors | ForEach-Object { Write-Error "  - $_" }
        exit 1
    }
    
    Write-Success "Todos los prerequisitos cumplidos"
}

# Backup de workflows
function Backup-Workflows {
    if ($SkipBackup) {
        Write-Warning "Saltando backup (--SkipBackup)"
        return
    }
    
    Write-Log "Haciendo backup de workflows..."
    
    if (Test-Path $BACKUP_DIR) {
        Remove-Item $BACKUP_DIR -Recurse -Force
    }
    
    New-Item -ItemType Directory -Path $BACKUP_DIR | Out-Null
    Copy-Item "$WORKFLOWS_DIR/*.yml" -Destination $BACKUP_DIR -Force
    
    Write-Success "Backup completado en $BACKUP_DIR"
}

# Validar sintaxis YAML
function Test-YamlSyntax {
    param($file)
    
    # Verificación básica de YAML
    $content = Get-Content $file -Raw
    
    # Verificar que no hay tabs (debe usar espacios)
    if ($content -match "`t") {
        Write-Error "Archivo $file contiene tabs (debe usar espacios)"
        return $false
    }
    
    # Verificar que tiene estructura básica de workflow
    if ($content -notmatch "name:") {
        Write-Error "Archivo $file no tiene campo 'name:'"
        return $false
    }
    
    if ($content -notmatch "on:") {
        Write-Error "Archivo $file no tiene campo 'on:'"
        return $false
    }
    
    if ($content -notmatch "jobs:") {
        Write-Error "Archivo $file no tiene campo 'jobs:'"
        return $false
    }
    
    return $true
}

# Aplicar mejoras a backend-ci.yml
function Update-BackendCI {
    $file = "$WORKFLOWS_DIR/backend-ci.yml"
    
    if (-not (Test-Path $file)) {
        Write-Warning "No se encontró $file, saltando..."
        return
    }
    
    Write-Log "Aplicando mejoras a backend-ci.yml..."
    
    $content = Get-Content $file -Raw
    
    # 1.1: Hacer lint requerido
    $content = $content -replace 'run: npm run lint:backend \|\| echo "⚠️ Linting no configurado aún"\s+continue-on-error: true', 'run: npm run lint:backend`n        continue-on-error: false'
    
    # 1.2: Hacer coverage requerido
    $content = $content -replace 'run: npm run test:backend -- --coverage \|\| echo "⚠️ Coverage no configurado"\s+continue-on-error: true', 'run: npm run test:backend -- --coverage`n        continue-on-error: false'
    
    # 1.3: Hacer Snyk requerido si token existe
    $content = $content -replace 'continue-on-error: true\s+with:\s+args: --severity-threshold=high', 'continue-on-error: false`n        with:`n          args: --severity-threshold=high'
    $content = $content -replace 'name: Run Snyk security scan', "name: Run Snyk security scan`n      if: `${{ secrets.SNYK_TOKEN != '' }}"
    
    # 1.4: Agregar upload artifacts (después de Verify build)
    $artifactStep = @"

      - name: Upload build artifacts
        uses: actions/upload-artifact@v4
        if: success()
        with:
          name: backend-build-`${{ github.sha }}
          path: packages/backend/dist
          retention-days: 7
"@
    
    if ($content -notmatch "Upload build artifacts") {
        $content = $content -replace '(echo "✅ Build successful")', "`$1$artifactStep"
    }
    
    Set-Content -Path $file -Value $content -NoNewline
    Write-Success "Mejoras aplicadas a backend-ci.yml"
}

# Aplicar mejoras a frontend-ci.yml
function Update-FrontendCI {
    $file = "$WORKFLOWS_DIR/frontend-ci.yml"
    
    if (-not (Test-Path $file)) {
        Write-Warning "No se encontró $file, saltando..."
        return
    }
    
    Write-Log "Aplicando mejoras a frontend-ci.yml..."
    
    $content = Get-Content $file -Raw
    
    # 2.1: Hacer lint requerido
    $content = $content -replace 'run: npm run lint --workspace=@econeura/web \|\| echo "⚠️ Linting no configurado aún"\s+continue-on-error: true', 'run: npm run lint --workspace=@econeura/web`n        continue-on-error: false'
    
    # 2.2: Hacer tests requeridos
    $content = $content -replace 'run: npm run test --workspace=@econeura/web \|\| echo "⚠️ Tests no configurados aún"\s+continue-on-error: true', 'run: npm run test --workspace=@econeura/web`n        continue-on-error: false'
    
    # 2.3: Hacer E2E tests requeridos
    $content = $content -replace 'run: npm run test:e2e --workspace=@econeura/web \|\| echo "⚠️ E2E tests no configurados aún"\s+continue-on-error: true', 'run: npm run test:e2e --workspace=@econeura/web`n        continue-on-error: false'
    
    # 2.4: Agregar bundle size limits (después de Analyze bundle size)
    $bundleSizeStep = @"

      - name: Validate bundle size
        run: |
          MAX_BUNDLE_SIZE_MB=5
          BUNDLE_SIZE=`$(du -sm packages/frontend/dist | cut -f1)
          
          if [ "`$BUNDLE_SIZE" -gt "`$MAX_BUNDLE_SIZE_MB" ]; then
            echo "❌ Bundle size (`$BUNDLE_SIZE MB) exceeds maximum (`$MAX_BUNDLE_SIZE_MB MB)"
            echo "📦 Top 10 largest files:"
            find packages/frontend/dist -type f -exec du -h {} \; | sort -rh | head -10
            exit 1
          fi
          
          echo "✅ Bundle size (`$BUNDLE_SIZE MB) is within limits"
"@
    
    if ($content -notmatch "Validate bundle size") {
        $content = $content -replace '(find packages/frontend/dist -type f -name "\.css" -exec du -h {} \; \| sort -rh \| head -5)', "`$1$bundleSizeStep"
    }
    
    # 2.5: Agregar upload artifacts
    $artifactStep = @"

      - name: Upload build artifacts
        uses: actions/upload-artifact@v4
        if: success()
        with:
          name: frontend-build-`${{ github.sha }}
          path: packages/frontend/dist
          retention-days: 7
"@
    
    if ($content -notmatch "Upload build artifacts") {
        $content = $content -replace '(echo "✅ Bundle size)', "`$1$artifactStep"
    }
    
    Set-Content -Path $file -Value $content -NoNewline
    Write-Success "Mejoras aplicadas a frontend-ci.yml"
}

# Aplicar mejoras a app-deploy.yml
function Update-AppDeploy {
    $file = "$WORKFLOWS_DIR/app-deploy.yml"
    
    if (-not (Test-Path $file)) {
        Write-Warning "No se encontró $file, saltando..."
        return
    }
    
    Write-Log "Aplicando mejoras a app-deploy.yml..."
    
    $content = Get-Content $file -Raw
    
    # 3.1: Agregar GitHub Environments
    if ($content -notmatch "environment:") {
        $content = $content -replace '(timeout-minutes: 30)', "`$1`n    environment: `${{ github.event.inputs.environment }}"
    }
    
    # 3.2: Actualizar Static Web Apps deploy (ya está en v1, verificar si hay v2)
    # Nota: Mantener v1 por ahora, actualizar manualmente si existe v2
    
    # 3.3: Agregar rollback strategy (al final del job)
    $rollbackStep = @"

      - name: Rollback on failure
        if: failure()
        run: |
          echo "❌ Deployment failed, initiating rollback..."
          BACKEND_NAME="`${{ secrets.AZURE_WEBAPP_NAME_BACKEND }}"
          
          # Obtener último deployment exitoso
          LAST_DEPLOYMENT=`$(az webapp deployment list \
            --name "`$BACKEND_NAME" \
            --resource-group "rg-econeura-full-`${{ github.event.inputs.environment }}" \
            --query "[?state=='Succeeded'] | [0].id" \
            -o tsv)
          
          if [ -n "`$LAST_DEPLOYMENT" ]; then
            echo "🔄 Rolling back to: `$LAST_DEPLOYMENT"
            az webapp deployment slot swap \
              --name "`$BACKEND_NAME" \
              --resource-group "rg-econeura-full-`${{ github.event.inputs.environment }}" \
              --slot staging \
              --target-slot production || echo "⚠️ Rollback not available"
          else
            echo "⚠️ No previous deployment found for rollback"
          fi
"@
    
    if ($content -notmatch "Rollback on failure") {
        $content = $content -replace '(echo "⚠️ API endpoint returned HTTP)', "`$1$rollbackStep"
    }
    
    Set-Content -Path $file -Value $content -NoNewline
    Write-Success "Mejoras aplicadas a app-deploy.yml"
}

# Aplicar mejoras a infra-deploy.yml
function Update-InfraDeploy {
    $file = "$WORKFLOWS_DIR/infra-deploy.yml"
    
    if (-not (Test-Path $file)) {
        Write-Warning "No se encontró $file, saltando..."
        return
    }
    
    Write-Log "Aplicando mejoras a infra-deploy.yml..."
    
    $content = Get-Content $file -Raw
    
    # 4.1: Agregar GitHub Environments
    if ($content -notmatch "environment:") {
        $content = $content -replace '(timeout-minutes: 45)', "`$1`n    environment: `${{ github.event.inputs.environment }}"
    }
    
    # 4.2: Agregar What-If analysis (antes de Deploy Bicep)
    $whatIfStep = @"

      - name: Bicep What-If Analysis
        uses: azure/CLI@v2
        with:
          inlineScript: |
            echo "🔍 Running What-If analysis..."
            az deployment group what-if \
              --resource-group "`${{ github.event.inputs.resourceGroupName }}" \
              --template-file infrastructure/azure/main.bicep \
              --parameters environment=`${{ github.event.inputs.environment }} \
                           location=westeurope \
                           baseName=econeura-full \
                           postgresAdminPassword='`${{ secrets.POSTGRES_ADMIN_PASSWORD }}' \
                           openAiApiKey='`${{ secrets.OPENAI_API_KEY }}' \
                           databaseUrlPlaceholder='postgresql://placeholder:placeholder@placeholder:5432/placeholder?sslmode=require'
            
            echo "✅ What-If analysis completed"
"@
    
    if ($content -notmatch "Bicep What-If Analysis") {
        $content = $content -replace '(name: Deploy Bicep main)', "$whatIfStep`n`n      - `$1"
    }
    
    # 4.3: Agregar validación Bicep (antes de What-If)
    $validateStep = @"

      - name: Validate Bicep templates
        uses: azure/CLI@v2
        with:
          inlineScript: |
            echo "✅ Validating Bicep templates..."
            az deployment group validate \
              --resource-group "`${{ github.event.inputs.resourceGroupName }}" \
              --template-file infrastructure/azure/main.bicep \
              --parameters environment=`${{ github.event.inputs.environment }} \
                           location=westeurope \
                           baseName=econeura-full \
                           postgresAdminPassword='`${{ secrets.POSTGRES_ADMIN_PASSWORD }}' \
                           openAiApiKey='`${{ secrets.OPENAI_API_KEY }}' \
                           databaseUrlPlaceholder='postgresql://placeholder:placeholder@placeholder:5432/placeholder?sslmode=require'
            
            if [ `$? -ne 0 ]; then
              echo "❌ Bicep validation failed"
              exit 1
            fi
            
            echo "✅ Bicep validation passed"
"@
    
    if ($content -notmatch "Validate Bicep templates") {
        $content = $content -replace '(name: Bicep What-If Analysis|name: Deploy Bicep main)', "$validateStep`n`n      - `$1"
    }
    
    # 4.4: Mejorar validación secrets (ya está, solo mejorar)
    # Nota: Ya tiene validación básica, mejorar si es necesario
    
    # 4.5: Capturar outputs (después de Deploy Bicep)
    $outputsStep = @"

      - name: Capture deployment outputs
        uses: azure/CLI@v2
        id: deployment-outputs
        with:
          inlineScript: |
            DEPLOYMENT_NAME="econeura-full-`${{ github.event.inputs.environment }}-`$(date +%Y%m%d-%H%M%S)"
            RG="`${{ github.event.inputs.resourceGroupName }}"
            
            OUTPUTS=`$(az deployment group show \
              --resource-group "`$RG" \
              --name "`$DEPLOYMENT_NAME" \
              --query "properties.outputs" \
              -o json)
            
            echo "outputs<<EOF" >> `$GITHUB_OUTPUT
            echo "`$OUTPUTS" >> `$GITHUB_OUTPUT
            echo "EOF" >> `$GITHUB_OUTPUT
            
            echo "📊 Deployment outputs captured"
"@
    
    if ($content -notmatch "Capture deployment outputs") {
        $content = $content -replace '(name: Deployment summary)', "$outputsStep`n`n      - `$1"
    }
    
    Set-Content -Path $file -Value $content -NoNewline
    Write-Success "Mejoras aplicadas a infra-deploy.yml"
}

# Aplicar mejoras a release.yml
function Update-Release {
    $file = "$WORKFLOWS_DIR/release.yml"
    
    if (-not (Test-Path $file)) {
        Write-Warning "No se encontró $file, saltando..."
        return
    }
    
    Write-Log "Aplicando mejoras a release.yml..."
    
    $content = Get-Content $file -Raw
    
    # 6.1: Actualizar create release action
    $content = $content -replace 'uses: actions/create-release@v1', 'uses: softprops/action-gh-release@v1'
    
    # 6.2: Agregar validación de versión (después de Determine version)
    $validateVersionStep = @"

      - name: Validate version format
        run: |
          VERSION="`${{ steps.version.outputs.version }}"
          
          # Validar formato semver
          if ! echo "`$VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9-]+(\.[0-9]+)?)?`$'; then
            echo "❌ Invalid version format: `$VERSION"
            echo "Expected format: X.Y.Z or X.Y.Z-prerelease"
            exit 1
          fi
          
          echo "✅ Version format valid: `$VERSION"
"@
    
    if ($content -notmatch "Validate version format") {
        $content = $content -replace '(echo "📦 Version:)', "`$1`n$validateVersionStep"
    }
    
    Set-Content -Path $file -Value $content -NoNewline
    Write-Success "Mejoras aplicadas a release.yml"
}

# Validar todos los workflows
function Test-AllWorkflows {
    Write-Log "Validando todos los workflows..."
    
    $errors = @()
    $workflows = Get-ChildItem "$WORKFLOWS_DIR/*.yml"
    
    foreach ($workflow in $workflows) {
        if (-not (Test-YamlSyntax $workflow.FullName)) {
            $errors += $workflow.Name
        }
    }
    
    if ($errors.Count -gt 0) {
        Write-Error "Workflows con errores:"
        $errors | ForEach-Object { Write-Error "  - $_" }
        return $false
    }
    
    Write-Success "Todos los workflows son válidos"
    return $true
}

# Función principal
function Main {
    Write-Host "🚀 APLICANDO MEJORAS WORKFLOWS A 10/10" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    if ($DryRun) {
        Write-Warning "MODO DRY-RUN: No se harán cambios reales"
        Write-Host ""
    }
    
    try {
        # Validar prerequisitos
        if (-not $SkipValidation) {
            Test-Prerequisites
        }
        
        # Backup
        if (-not $DryRun) {
            Backup-Workflows
        }
        
        # Aplicar mejoras
        if (-not $DryRun) {
            Update-BackendCI
            Update-FrontendCI
            Update-AppDeploy
            Update-InfraDeploy
            Update-Release
        } else {
            Write-Info "DRY-RUN: Simulando cambios..."
        }
        
        # Validar workflows
        if (-not $SkipTesting) {
            if (-not (Test-AllWorkflows)) {
                Write-Error "Validación falló. Revisar workflows."
                exit 1
            }
        }
        
        Write-Host ""
        Write-Success "✅ TODAS LAS MEJORAS APLICADAS EXITOSAMENTE"
        Write-Host ""
        Write-Info "Próximos pasos:"
        Write-Info "1. Revisar cambios: git diff $WORKFLOWS_DIR"
        Write-Info "2. Commit cambios: git add $WORKFLOWS_DIR && git commit -m 'feat: improve workflows to 10/10'"
        Write-Info "3. Push cambios: git push"
        Write-Info "4. Verificar workflows en GitHub Actions"
        
    } catch {
        Write-Error "Error: $_"
        Write-Error "Stack trace: $($_.ScriptStackTrace)"
        exit 1
    }
}

# Ejecutar
Main

