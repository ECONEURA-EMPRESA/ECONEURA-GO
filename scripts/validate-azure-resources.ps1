# ECONEURA-FULL - Validación de Recursos Azure
# Valida que todos los recursos Azure existen y están configurados correctamente

param(
    [string]$ResourceGroup = "rg-econeura-full-staging",
    [string]$Environment = "staging"
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Azure CLI no está instalado" -ForegroundColor Red
    Write-Host "Instalar: https://aka.ms/InstallAzureCLIWindows" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n🔍 VALIDACIÓN DE RECURSOS AZURE`n" -ForegroundColor Cyan
Write-Host "Resource Group: $ResourceGroup" -ForegroundColor Cyan
Write-Host "Environment: $Environment`n" -ForegroundColor Cyan

$global:Errors = @()
$global:Warnings = @()

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "❌ ERROR: $Message" -ForegroundColor Red
    $global:Errors += $Message
}

function Write-Warning-Custom {
    param([string]$Message)
    Write-Host "⚠️  WARNING: $Message" -ForegroundColor Yellow
    $global:Warnings += $Message
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

# ============================================================================
# 1. VALIDAR RESOURCE GROUP
# ============================================================================
Write-Host "📦 1. Validando Resource Group..." -ForegroundColor Yellow

try {
    $rg = az group show --name $ResourceGroup 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Resource Group existe: $ResourceGroup"
    } else {
        Write-Error-Custom "Resource Group NO existe: $ResourceGroup"
        Write-Host "Crear con: az group create --name $ResourceGroup --location westeurope" -ForegroundColor Yellow
    }
} catch {
    Write-Error-Custom "Error verificando Resource Group: $_"
}

# ============================================================================
# 2. VALIDAR APP SERVICE PLAN
# ============================================================================
Write-Host "`n🖥️  2. Validando App Service Plan..." -ForegroundColor Yellow

$appServicePlanName = "plan-econeura-full-$Environment"

try {
    $plan = az appservice plan show --name $appServicePlanName --resource-group $ResourceGroup 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "App Service Plan existe: $appServicePlanName"
        
        # Verificar SKU
        $sku = ($plan | ConvertFrom-Json).sku.name
        if ($sku -eq "B1") {
            Write-Success "SKU correcto: B1"
        } else {
            Write-Warning-Custom "SKU: $sku (esperado: B1)"
        }
    } else {
        Write-Error-Custom "App Service Plan NO existe: $appServicePlanName"
    }
} catch {
    Write-Error-Custom "Error verificando App Service Plan: $_"
}

# ============================================================================
# 3. VALIDAR APP SERVICE (BACKEND)
# ============================================================================
Write-Host "`n🚀 3. Validando App Service (Backend)..." -ForegroundColor Yellow

$appServiceName = "app-econeura-full-$Environment-backend"

try {
    $app = az webapp show --name $appServiceName --resource-group $ResourceGroup 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "App Service existe: $appServiceName"
        
        # Verificar configuración
        $appJson = $app | ConvertFrom-Json
        
        # Verificar HTTPS Only
        if ($appJson.httpsOnly) {
            Write-Success "HTTPS Only: Habilitado"
        } else {
            Write-Warning-Custom "HTTPS Only: Deshabilitado (recomendado habilitar)"
        }
        
        # Verificar Managed Identity
        $identity = az webapp identity show --name $appServiceName --resource-group $ResourceGroup 2>&1
        if ($LASTEXITCODE -eq 0) {
            $identityJson = $identity | ConvertFrom-Json
            if ($identityJson.type -eq "SystemAssigned" -and $identityJson.principalId) {
                Write-Success "Managed Identity: Habilitada"
            } else {
                Write-Warning-Custom "Managed Identity: No habilitada (requerida para Key Vault)"
            }
        }
        
        # Verificar Application Settings críticas
        $settings = az webapp config appsettings list --name $appServiceName --resource-group $ResourceGroup 2>&1
        if ($LASTEXITCODE -eq 0) {
            $settingsJson = $settings | ConvertFrom-Json
            
            $criticalSettings = @(
                "NODE_ENV",
                "PORT",
                "OPENAI_API_KEY",
                "DATABASE_URL",
                "APPLICATIONINSIGHTS_CONNECTION_STRING"
            )
            
            foreach ($setting in $criticalSettings) {
                $found = $settingsJson | Where-Object { $_.name -eq $setting }
                if ($found) {
                    Write-Success "Setting configurada: $setting"
                } else {
                    Write-Error-Custom "Setting faltante: $setting"
                }
            }
        }
        
    } else {
        Write-Error-Custom "App Service NO existe: $appServiceName"
    }
} catch {
    Write-Error-Custom "Error verificando App Service: $_"
}

# ============================================================================
# 4. VALIDAR STATIC WEB APP (FRONTEND)
# ============================================================================
Write-Host "`n🌐 4. Validando Static Web App (Frontend)..." -ForegroundColor Yellow

$staticWebAppName = "swa-econeura-full-$Environment"

try {
    $swa = az staticwebapp show --name $staticWebAppName --resource-group $ResourceGroup 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Static Web App existe: $staticWebAppName"
    } else {
        Write-Warning-Custom "Static Web App NO existe: $staticWebAppName (puede crearse automáticamente)"
    }
} catch {
    Write-Warning-Custom "Error verificando Static Web App: $_"
}

# ============================================================================
# 5. VALIDAR POSTGRESQL
# ============================================================================
Write-Host "`n🐘 5. Validando PostgreSQL..." -ForegroundColor Yellow

$postgresName = "pg-econeura-full-$Environment"

try {
    $pg = az postgres flexible-server show --name $postgresName --resource-group $ResourceGroup 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "PostgreSQL existe: $postgresName"
        
        $pgJson = $pg | ConvertFrom-Json
        
        # Verificar estado
        $state = $pgJson.state
        if ($state -eq "Ready") {
            Write-Success "Estado: Ready"
        } elseif ($state -eq "Stopped") {
            Write-Warning-Custom "Estado: Stopped (pausado - despertar con: az postgres flexible-server start)"
        } else {
            Write-Warning-Custom "Estado: $state"
        }
        
        # Verificar firewall rules
        $firewallRules = az postgres flexible-server firewall-rule list --name $postgresName --resource-group $ResourceGroup 2>&1
        if ($LASTEXITCODE -eq 0) {
            $rules = $firewallRules | ConvertFrom-Json
            $allowAzure = $rules | Where-Object { $_.name -like "*AllowAzure*" -or $_.startIpAddress -eq "0.0.0.0" }
            if ($allowAzure) {
                Write-Success "Firewall: Regla para Azure services existe"
            } else {
                Write-Warning-Custom "Firewall: Regla para Azure services NO existe"
            }
        }
        
    } else {
        Write-Error-Custom "PostgreSQL NO existe: $postgresName"
    }
} catch {
    Write-Error-Custom "Error verificando PostgreSQL: $_"
}

# ============================================================================
# 6. VALIDAR REDIS
# ============================================================================
Write-Host "`n🔴 6. Validando Redis Cache..." -ForegroundColor Yellow

$redisName = "redis-econeura-full-$Environment"

try {
    $redis = az redis show --name $redisName --resource-group $ResourceGroup 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Redis existe: $redisName"
        
        $redisJson = $redis | ConvertFrom-Json
        
        # Verificar estado
        $provisioningState = $redisJson.provisioningState
        if ($provisioningState -eq "Succeeded") {
            Write-Success "Estado: Succeeded"
        } else {
            Write-Warning-Custom "Estado: $provisioningState"
        }
        
        # Verificar firewall
        $firewallRules = az redis firewall-rule list --name $redisName --resource-group $ResourceGroup 2>&1
        if ($LASTEXITCODE -eq 0) {
            $rules = $firewallRules | ConvertFrom-Json
            if ($rules.Count -gt 0) {
                Write-Success "Firewall: Reglas configuradas"
            } else {
                Write-Warning-Custom "Firewall: Sin reglas (puede estar bloqueado)"
            }
        }
        
    } else {
        Write-Warning-Custom "Redis NO existe: $redisName (opcional, pero recomendado)"
    }
} catch {
    Write-Warning-Custom "Error verificando Redis: $_"
}

# ============================================================================
# 7. VALIDAR KEY VAULT
# ============================================================================
Write-Host "`n🔐 7. Validando Key Vault..." -ForegroundColor Yellow

$keyVaultName = "kv-econeura-full-$Environment"

try {
    $kv = az keyvault show --name $keyVaultName --resource-group $ResourceGroup 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Key Vault existe: $keyVaultName"
        
        # Verificar secrets críticos
        $criticalSecrets = @(
            "OPENAI-API-KEY",
            "JWT-SECRET",
            "DATABASE-URL"
        )
        
        foreach ($secret in $criticalSecrets) {
            $secretCheck = az keyvault secret show --vault-name $keyVaultName --name $secret 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Success "Secret existe: $secret"
            } else {
                Write-Warning-Custom "Secret faltante: $secret"
            }
        }
        
    } else {
        Write-Error-Custom "Key Vault NO existe: $keyVaultName"
    }
} catch {
    Write-Error-Custom "Error verificando Key Vault: $_"
}

# ============================================================================
# 8. VALIDAR STORAGE ACCOUNT
# ============================================================================
Write-Host "`n💾 8. Validando Storage Account..." -ForegroundColor Yellow

$storageName = "st${Environment}econeurafull"

try {
    $storage = az storage account show --name $storageName --resource-group $ResourceGroup 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Storage Account existe: $storageName"
        
        # Verificar containers
        $containers = az storage container list --account-name $storageName --auth-mode login 2>&1
        if ($LASTEXITCODE -eq 0) {
            $containersJson = $containers | ConvertFrom-Json
            $documentsContainer = $containersJson | Where-Object { $_.name -eq "documents" }
            if ($documentsContainer) {
                Write-Success "Container existe: documents"
            } else {
                Write-Warning-Custom "Container faltante: documents"
            }
        }
        
    } else {
        Write-Warning-Custom "Storage Account NO existe: $storageName (opcional, pero recomendado)"
    }
} catch {
    Write-Warning-Custom "Error verificando Storage Account: $_"
}

# ============================================================================
# 9. VALIDAR APPLICATION INSIGHTS
# ============================================================================
Write-Host "`n📊 9. Validando Application Insights..." -ForegroundColor Yellow

$appInsightsName = "appi-econeura-full-$Environment"

try {
    $ai = az monitor app-insights component show --app $appInsightsName --resource-group $ResourceGroup 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Application Insights existe: $appInsightsName"
        
        # Obtener connection string
        $connectionString = az monitor app-insights component show --app $appInsightsName --resource-group $ResourceGroup --query "connectionString" -o tsv 2>&1
        if ($connectionString) {
            Write-Success "Connection String: Disponible"
        } else {
            Write-Warning-Custom "Connection String: No disponible"
        }
        
    } else {
        Write-Error-Custom "Application Insights NO existe: $appInsightsName"
    }
} catch {
    Write-Error-Custom "Error verificando Application Insights: $_"
}

# ============================================================================
# RESUMEN FINAL
# ============================================================================
Write-Host "`n" -NoNewline
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "📊 RESUMEN DE VALIDACIÓN AZURE" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan

$errorCount = $global:Errors.Count
$warningCount = $global:Warnings.Count

if ($errorCount -eq 0 -and $warningCount -eq 0) {
    Write-Host "`n✅ TODOS LOS RECURSOS VALIDADOS CORRECTAMENTE`n" -ForegroundColor Green
    exit 0
} elseif ($errorCount -eq 0) {
    Write-Host "`n⚠️  VALIDACIÓN CON ADVERTENCIAS" -ForegroundColor Yellow
    Write-Host "Errores: 0" -ForegroundColor Green
    Write-Host "Advertencias: $warningCount`n" -ForegroundColor Yellow
    exit 0
} else {
    Write-Host "`n❌ VALIDACIÓN FALLIDA" -ForegroundColor Red
    Write-Host "Errores: $errorCount" -ForegroundColor Red
    Write-Host "Advertencias: $warningCount`n" -ForegroundColor Yellow
    
    Write-Host "ERRORES ENCONTRADOS:" -ForegroundColor Red
    foreach ($error in $global:Errors) {
        Write-Host "  ❌ $error" -ForegroundColor Red
    }
    
    exit 1
}

