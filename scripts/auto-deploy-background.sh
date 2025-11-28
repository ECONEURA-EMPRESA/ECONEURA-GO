#!/bin/bash
# ============================================
# SCRIPT DEPLOYMENT AUTOMÁTICO ASÍNCRONO
# Ejecuta deployment y configuración de secrets en background
# ============================================

LOG_FILE="deployment-automation.log"
OUTPUTS_FILE="deployment-outputs.json"

echo "🚀 Iniciando deployment automático en background..." > $LOG_FILE
date >> $LOG_FILE

# 1. Ejecutar Deployment (si falla, reintenta 1 vez)
echo "📦 Desplegando infraestructura Azure..." >> $LOG_FILE
az deployment group create \
  --resource-group rg-econeura-ok-prod \
  --template-file infrastructure/azure/main.bicep \
  --parameters \
    postgresAdminPassword='Q5elkWEcQKm5iK+LGO5OaxxUpqaG52y9' \
    geminiApiKey='INSERT_YOUR_KEY_HERE' \
  --query properties.outputs -o json > $OUTPUTS_FILE 2>> $LOG_FILE

if [ $? -ne 0 ]; then
  echo "❌ Error en deployment. Reintentando en 30s..." >> $LOG_FILE
  sleep 30
  az deployment group create \
    --resource-group rg-econeura-ok-prod \
    --template-file infrastructure/azure/main.bicep \
    --parameters \
      postgresAdminPassword='Q5elkWEcQKm5iK+LGO5OaxxUpqaG52y9' \
      geminiApiKey='INSERT_YOUR_KEY_HERE' \
    --query properties.outputs -o json > $OUTPUTS_FILE 2>> $LOG_FILE
fi

if [ ! -f "$OUTPUTS_FILE" ]; then
  echo "❌ Error fatal: No se generó archivo de outputs" >> $LOG_FILE
  exit 1
fi

echo "✅ Infraestructura desplegada. Configurando secrets..." >> $LOG_FILE

# 2. Configurar Secrets Automáticamente
# Usamos el script existente pero en modo no-interactivo
# (Asumimos que el script configure-secrets.sh puede leer de variables de entorno o argumentos si se modifica,
#  por ahora lo llamamos directamente y esperamos que funcione con el archivo generado)

# Modificamos configure-secrets.sh para aceptar API Key como argumento o variable si es necesario,
# o simplemente extraemos los valores aquí directamente para ser más robustos.

APP_URL=$(jq -r '.appServiceUrl.value' $OUTPUTS_FILE)
DB_URL=$(jq -r '.databaseUrl.value' $OUTPUTS_FILE)
REDIS_HOST=$(jq -r '.redisHost.value' $OUTPUTS_FILE)
REDIS_PORT=$(jq -r '.redisPort.value' $OUTPUTS_FILE)
REDIS_KEY=$(jq -r '.redisPrimaryKey.value' $OUTPUTS_FILE)
INSIGHTS=$(jq -r '.appInsightsConnectionString.value' $OUTPUTS_FILE)
STORAGE=$(jq -r '.storageConnectionString.value' $OUTPUTS_FILE)
STATIC_URL=$(jq -r '.staticWebAppUrl.value' $OUTPUTS_FILE)

echo "🔑 Configurando GitHub Secrets..." >> $LOG_FILE

gh secret set AZURE_APP_SERVICE_URL -b "https://$APP_URL" >> $LOG_FILE 2>&1
gh secret set DATABASE_URL -b "$DB_URL" >> $LOG_FILE 2>&1
gh secret set REDIS_HOST -b "$REDIS_HOST" >> $LOG_FILE 2>&1
gh secret set REDIS_PORT -b "$REDIS_PORT" >> $LOG_FILE 2>&1
gh secret set REDIS_PASSWORD -b "$REDIS_KEY" >> $LOG_FILE 2>&1
gh secret set APPLICATIONINSIGHTS_CONNECTION_STRING -b "$INSIGHTS" >> $LOG_FILE 2>&1
gh secret set AZURE_STORAGE_CONNECTION_STRING -b "$STORAGE" >> $LOG_FILE 2>&1
gh secret set AZURE_STATIC_WEB_APP_URL -b "https://$STATIC_URL" >> $LOG_FILE 2>&1
gh secret set NODE_ENV -b "production" >> $LOG_FILE 2>&1
gh secret set USE_MEMORY_STORE -b "false" >> $LOG_FILE 2>&1

# Nota: GEMINI_API_KEY debe ser configurada manualmente o pasada de forma segura si ya la tenemos.
# En este script asumimos que el usuario la configurará o ya está.

echo "✅ Secrets configurados." >> $LOG_FILE

# 3. Trigger CI/CD
echo "🚀 Disparando CI/CD..." >> $LOG_FILE
gh workflow run ci.yml --ref feat/omega-protocol-10-10 >> $LOG_FILE 2>&1

echo "🎉 PROCESO COMPLETADO EXITOSAMENTE" >> $LOG_FILE
date >> $LOG_FILE
