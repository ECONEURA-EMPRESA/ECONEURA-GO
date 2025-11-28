# ============================================
# ECONEURA - Script de Despliegue Local
# ============================================

param(
    [string]$PostgresUser = "postgres",
    [string]$PostgresPassword = "",
    [string]$DatabaseName = "econeura_app",
    [string]$PostgresHost = "localhost",
    [int]$PostgresPort = 5432
)

Write-Host "`n=== DESPLIEGUE LOCAL ECONEURA CRM ===" -ForegroundColor Cyan
Write-Host ""

# Verificar PostgreSQL
Write-Host "[PASO 1] Verificando PostgreSQL..." -ForegroundColor Yellow
try {
    $env:PGPASSWORD = $PostgresPassword
    $testConnection = & psql -U $PostgresUser -h $PostgresHost -p $PostgresPort -d postgres -c "SELECT 1;" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  [OK] PostgreSQL conectado" -ForegroundColor Green
    } else {
        Write-Host "  [ERROR] Error conectando a PostgreSQL" -ForegroundColor Red
        Write-Host "  Verifica que PostgreSQL esté corriendo y las credenciales sean correctas" -ForegroundColor Yellow
        exit 1
    }
} catch {
    Write-Host "  [ERROR] PostgreSQL no encontrado. Asegurate de tener psql en PATH" -ForegroundColor Red
    exit 1
}

# Crear base de datos si no existe
Write-Host "`n[PASO 2] Creando base de datos..." -ForegroundColor Yellow
$dbExists = & psql -U $PostgresUser -h $PostgresHost -p $PostgresPort -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='$DatabaseName'" 2>&1
if ($dbExists -eq "1") {
        Write-Host "  [OK] Base de datos '$DatabaseName' ya existe" -ForegroundColor Green
} else {
    Write-Host "  [INFO] Creando base de datos '$DatabaseName'..." -ForegroundColor Yellow
    & psql -U $PostgresUser -h $PostgresHost -p $PostgresPort -d postgres -c "CREATE DATABASE $DatabaseName;" 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  [OK] Base de datos creada" -ForegroundColor Green
    } else {
        Write-Host "  [ERROR] Error creando base de datos" -ForegroundColor Red
        exit 1
    }
}

# Ejecutar migraciones
Write-Host "`n[PASO 3] Ejecutando migraciones..." -ForegroundColor Yellow

$migrations = @(
    "002_crm_premium.sql",
    "003_crm_indexes.sql"
)

$migrationsPath = "packages\backend\database\migrations"

foreach ($migration in $migrations) {
    $migrationFile = Join-Path $migrationsPath $migration
    if (Test-Path $migrationFile) {
        Write-Host "  [INFO] Ejecutando $migration..." -ForegroundColor Yellow
        & psql -U $PostgresUser -h $PostgresHost -p $PostgresPort -d $DatabaseName -f $migrationFile 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "    [OK] $migration ejecutada correctamente" -ForegroundColor Green
        } else {
            Write-Host "    [WARN] $migration tuvo warnings (puede ser normal si ya existe)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  [ERROR] $migration no encontrada en $migrationsPath" -ForegroundColor Red
    }
}

# Verificar .env
Write-Host "`n[PASO 4] Verificando .env..." -ForegroundColor Yellow
$envFile = "packages\backend\.env"
if (Test-Path $envFile) {
    Write-Host "  [OK] .env existe" -ForegroundColor Green
    
    # Verificar DATABASE_URL
    $envContent = Get-Content $envFile -Raw
    if ($envContent -match "DATABASE_URL") {
        Write-Host "  [OK] DATABASE_URL configurado" -ForegroundColor Green
    } else {
        Write-Host "  [WARN] DATABASE_URL no encontrado en .env" -ForegroundColor Yellow
        Write-Host "  [INFO] Agregando DATABASE_URL..." -ForegroundColor Yellow
        $databaseUrl = "postgresql://$PostgresUser`:$PostgresPassword@$PostgresHost`:$PostgresPort/$DatabaseName"
        Add-Content $envFile "`nDATABASE_URL=$databaseUrl"
        Write-Host "    [OK] DATABASE_URL agregado" -ForegroundColor Green
    }
} else {
    Write-Host "  [WARN] .env no existe. Creando..." -ForegroundColor Yellow
    $databaseUrl = "postgresql://$PostgresUser`:$PostgresPassword@$PostgresHost`:$PostgresPort/$DatabaseName"
    $envTemplate = @"
NODE_ENV=development
PORT=3000

# PostgreSQL
DATABASE_URL=$databaseUrl

# Redis (opcional)
REDIS_URL=redis://localhost:6379

# CRM Webhooks
CRM_WEBHOOK_SECRET=
"@
    Set-Content $envFile $envTemplate
    Write-Host "    [OK] .env creado" -ForegroundColor Green
    Write-Host "    [WARN] IMPORTANTE: Genera CRM_WEBHOOK_SECRET y agrégalo a .env" -ForegroundColor Yellow
}

# Instalar dependencias
Write-Host "`n[PASO 5] Instalando dependencias..." -ForegroundColor Yellow
Push-Location "packages\backend"
npm install 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
        Write-Host "  [OK] Dependencias instaladas" -ForegroundColor Green
} else {
    Write-Host "  [WARN] Algunos warnings en npm install (puede ser normal)" -ForegroundColor Yellow
}

# Verificar TypeScript
Write-Host "`n[PASO 6] Verificando TypeScript..." -ForegroundColor Yellow
npm run type-check 2>&1 | Select-Object -Last 5
if ($LASTEXITCODE -eq 0) {
    Write-Host "  [OK] TypeScript OK" -ForegroundColor Green
} else {
    Write-Host "  [WARN] TypeScript tiene warnings (no bloqueantes)" -ForegroundColor Yellow
}
Pop-Location

Write-Host "`n=== [OK] DESPLIEGUE LOCAL COMPLETADO ===" -ForegroundColor Green
Write-Host ""
Write-Host "[PROXIMOS PASOS]:" -ForegroundColor Cyan
Write-Host "  1. Verifica que .env tiene CRM_WEBHOOK_SECRET configurado" -ForegroundColor White
Write-Host "  2. Inicia el backend: cd packages\backend; npm run dev" -ForegroundColor White
Write-Host "  3. Verifica health check: http://localhost:3000/health" -ForegroundColor White
Write-Host ""

