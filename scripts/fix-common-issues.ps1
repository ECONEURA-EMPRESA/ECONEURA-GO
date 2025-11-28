# ECONEURA-FULL - Script de Corrección de Problemas Comunes
# Corrige automáticamente los problemas más comunes

param(
    [string]$ResourceGroup = "rg-econeura-full-staging",
    [string]$Environment = "staging",
    [switch]$FixAll
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Azure CLI no está instalado" -ForegroundColor Red
    exit 1
}

Write-Host "`n🔧 CORRECCIÓN DE PROBLEMAS COMUNES - ECONEURA-FULL`n" -ForegroundColor Cyan

# ============================================================================
# 1. DESPERTAR POSTGRESQL (si está pausado)
# ============================================================================
if ($FixAll -or $true) {
    Write-Host "🐘 1. Verificando PostgreSQL..." -ForegroundColor Yellow
    
    $postgresName = "pg-econeura-full-$Environment"
    
    try {
        $pg = az postgres flexible-server show --name $postgresName --resource-group $ResourceGroup 2>&1
        if ($LASTEXITCODE -eq 0) {
            $pgJson = $pg | ConvertFrom-Json
            $state = $pgJson.state
            
            if ($state -eq "Stopped") {
                Write-Host "PostgreSQL está pausado. Despertando..." -ForegroundColor Yellow
                az postgres flexible-server start --name $postgresName --resource-group $ResourceGroup
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "✅ PostgreSQL despertado" -ForegroundColor Green
                    Write-Host "Esperando 30 segundos para que esté listo..." -ForegroundColor Gray
                    Start-Sleep -Seconds 30
                } else {
                    Write-Host "❌ Error despertando PostgreSQL" -ForegroundColor Red
                }
            } else {
                Write-Host "✅ PostgreSQL está corriendo (estado: $state)" -ForegroundColor Green
            }
        }
    } catch {
        Write-Host "⚠️  No se pudo verificar PostgreSQL: $_" -ForegroundColor Yellow
    }
}

# ============================================================================
# 2. CONFIGURAR FIREWALL DE POSTGRESQL (permitir Azure services)
# ============================================================================
if ($FixAll -or $true) {
    Write-Host "`n🔥 2. Configurando firewall de PostgreSQL..." -ForegroundColor Yellow
    
    $postgresName = "pg-econeura-full-$Environment"
    
    try {
        # Verificar si ya existe regla para Azure
        $firewallRules = az postgres flexible-server firewall-rule list --name $postgresName --resource-group $ResourceGroup 2>&1
        if ($LASTEXITCODE -eq 0) {
            $rules = $firewallRules | ConvertFrom-Json
            $allowAzure = $rules | Where-Object { $_.startIpAddress -eq "0.0.0.0" -and $_.endIpAddress -eq "0.0.0.0" }
            
            if (-not $allowAzure) {
                Write-Host "Agregando regla de firewall para Azure services..." -ForegroundColor Yellow
                az postgres flexible-server firewall-rule create `
                    --name $postgresName `
                    --resource-group $ResourceGroup `
                    --rule-name "AllowAzureServices" `
                    --start-ip-address "0.0.0.0" `
                    --end-ip-address "0.0.0.0"
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "✅ Regla de firewall agregada" -ForegroundColor Green
                } else {
                    Write-Host "❌ Error agregando regla de firewall" -ForegroundColor Red
                }
            } else {
                Write-Host "✅ Regla de firewall ya existe" -ForegroundColor Green
            }
        }
    } catch {
        Write-Host "⚠️  No se pudo configurar firewall: $_" -ForegroundColor Yellow
    }
}

# ============================================================================
# 3. HABILITAR MANAGED IDENTITY EN APP SERVICE
# ============================================================================
if ($FixAll -or $true) {
    Write-Host "`n🔐 3. Habilitando Managed Identity en App Service..." -ForegroundColor Yellow
    
    $appServiceName = "app-econeura-full-$Environment-backend"
    
    try {
        $identity = az webapp identity show --name $appServiceName --resource-group $ResourceGroup 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Habilitando Managed Identity..." -ForegroundColor Yellow
            az webapp identity assign --name $appServiceName --resource-group $ResourceGroup
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Managed Identity habilitada" -ForegroundColor Green
                
                # Obtener principal ID
                $identityJson = az webapp identity show --name $appServiceName --resource-group $ResourceGroup | ConvertFrom-Json
                $principalId = $identityJson.principalId
                
                Write-Host "Principal ID: $principalId" -ForegroundColor Gray
                Write-Host "⚠️  IMPORTANTE: Agregar este Principal ID a Key Vault Access Policies" -ForegroundColor Yellow
            } else {
                Write-Host "❌ Error habilitando Managed Identity" -ForegroundColor Red
            }
        } else {
            Write-Host "✅ Managed Identity ya está habilitada" -ForegroundColor Green
        }
    } catch {
        Write-Host "⚠️  No se pudo verificar Managed Identity: $_" -ForegroundColor Yellow
    }
}

# ============================================================================
# 4. CONFIGURAR PERMISOS DE KEY VAULT PARA MANAGED IDENTITY
# ============================================================================
if ($FixAll -or $true) {
    Write-Host "`n🔑 4. Configurando permisos de Key Vault..." -ForegroundColor Yellow
    
    $keyVaultName = "kv-econeura-full-$Environment"
    $appServiceName = "app-econeura-full-$Environment-backend"
    
    try {
        # Obtener principal ID de Managed Identity
        $identity = az webapp identity show --name $appServiceName --resource-group $ResourceGroup 2>&1
        if ($LASTEXITCODE -eq 0) {
            $identityJson = $identity | ConvertFrom-Json
            $principalId = $identityJson.principalId
            
            if ($principalId) {
                Write-Host "Agregando permisos a Key Vault para Principal ID: $principalId" -ForegroundColor Yellow
                
                # Agregar política de acceso
                az keyvault set-policy `
                    --name $keyVaultName `
                    --object-id $principalId `
                    --secret-permissions get list
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "✅ Permisos de Key Vault configurados" -ForegroundColor Green
                } else {
                    Write-Host "❌ Error configurando permisos de Key Vault" -ForegroundColor Red
                }
            }
        }
    } catch {
        Write-Host "⚠️  No se pudo configurar Key Vault: $_" -ForegroundColor Yellow
    }
}

# ============================================================================
# 5. VERIFICAR Y CREAR SECRETS CRÍTICOS EN KEY VAULT
# ============================================================================
if ($FixAll) {
    Write-Host "`n📝 5. Verificando secrets en Key Vault..." -ForegroundColor Yellow
    
    $keyVaultName = "kv-econeura-full-$Environment"
    
    $criticalSecrets = @(
        @{ Name = "OPENAI-API-KEY"; Prompt = "OpenAI API Key" },
        @{ Name = "JWT-SECRET"; Prompt = "JWT Secret (64 caracteres mínimo)" },
        @{ Name = "SESSION-SECRET"; Prompt = "Session Secret (32 caracteres mínimo)" }
    )
    
    foreach ($secret in $criticalSecrets) {
        try {
            $secretCheck = az keyvault secret show --vault-name $keyVaultName --name $secret.Name 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Host "Secret faltante: $($secret.Name)" -ForegroundColor Yellow
                $value = Read-Host "Ingrese valor para $($secret.Prompt) (o presione Enter para omitir)"
                
                if ($value) {
                    az keyvault secret set --vault-name $keyVaultName --name $secret.Name --value $value
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "✅ Secret creado: $($secret.Name)" -ForegroundColor Green
                    }
                }
            } else {
                Write-Host "✅ Secret existe: $($secret.Name)" -ForegroundColor Green
            }
        } catch {
            Write-Host "⚠️  Error verificando secret $($secret.Name): $_" -ForegroundColor Yellow
        }
    }
}

# ============================================================================
# 6. REINICIAR APP SERVICE (para aplicar cambios)
# ============================================================================
if ($FixAll -or $true) {
    Write-Host "`n🔄 6. Reiniciando App Service..." -ForegroundColor Yellow
    
    $appServiceName = "app-econeura-full-$Environment-backend"
    
    try {
        Write-Host "Reiniciando App Service..." -ForegroundColor Yellow
        az webapp restart --name $appServiceName --resource-group $ResourceGroup
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ App Service reiniciado" -ForegroundColor Green
            Write-Host "Esperando 30 segundos para que esté listo..." -ForegroundColor Gray
            Start-Sleep -Seconds 30
        } else {
            Write-Host "❌ Error reiniciando App Service" -ForegroundColor Red
        }
    } catch {
        Write-Host "⚠️  No se pudo reiniciar App Service: $_" -ForegroundColor Yellow
    }
}

Write-Host "`n✅ CORRECCIÓN COMPLETADA`n" -ForegroundColor Green

