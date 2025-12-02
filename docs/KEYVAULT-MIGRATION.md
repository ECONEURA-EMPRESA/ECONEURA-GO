# Azure Key Vault Migration Guide

## Overview

This guide documents the migration from GitHub Secrets to Azure Key Vault for ECONEURA-GO production deployments.

## Why Migrate?

**Security Issues with GitHub Secrets**:
1. Less secure than Azure Key Vault (managed HSM)
2. No audit trail for secret access
3. No automatic rotation
4. Violates principle of least privilege (anyone with repo access can view workflow runs)

**Benefits of Azure Key Vault**:
1. Hardware-backed secret storage
2. Audit logging for all access
3. Azure-native integration
4. Managed identities support
5. Network-level access control

---

## Migration Steps

### 1. Prerequisites

- Azure CLI installed and logged in
- Access to Azure subscription with Key Vault
- GitHub repository admin access

### 2. Create Secrets in Azure Key Vault

Run the migration script:

```bash
chmod +x scripts/migrate-secrets-to-keyvault.sh
./scripts/migrate-secrets-to-keyvault.sh
```

This script will prompt you for each secret and securely store it in Azure Key Vault.

**Required Secrets**:
- `POSTGRES-ADMIN-PASSWORD`: PostgreSQL admin password
- `GEMINI-API-KEY`: Gemini API key
- `DATABASE-URL`: Full database connection string
- `REDIS-PASSWORD`: Redis password
- `JWT-SECRET`: JWT signing secret (minimum 32 characters)

### 3. Verify Secrets in Key Vault

```bash
# List all secrets
az keyvault secret list --vault-name econeura-kv-production --query "[].name" -o table

# Verify a specific secret (shows value)
az keyvault secret show --vault-name econeura-kv-production --name POSTGRES-ADMIN-PASSWORD --query "value" -o tsv
```

### 4. Workflows Updated

The following workflows have been updated to use Key Vault:

#### ✅ main_econeura-backend-production.yml

**Changes**:
- Added `Azure/get-keyvault-secrets@v1` action after Azure login
- Retrieves all secrets from Key Vault
- Sets environment variables for deployment

**Before** (GitHub Secrets):
```yaml
environment:
  DATABASE_URL: ${{ secrets.DATABASE_URL }}
```

**After** (Key Vault):
```yaml
- name: Get secrets from Key Vault
  uses: Azure/get-keyvault-secrets@v1
  with:
    keyvault: "econeura-kv-production"
    secrets: 'DATABASE-URL, GEMINI-API-KEY'
  id: keyvault-secrets

- name: Set environment variables
  run: |
    echo "DATABASE_URL=${{ steps.keyvault-secrets.outputs.DATABASE-URL }}" >> $GITHUB_ENV
```

### 5. Test the Workflows

**IMPORTANT**: Do NOT delete GitHub Secrets until workflows are verified working!

1. Trigger a deployment:
   ```bash
   git commit --allow-empty -m "test: verify Key Vault integration"
   git push origin main
   ```

2. Monitor GitHub Actions:
   - https://github.com/ECONEURA-EMPRESA/ECONEURA-GO/actions
   - Check "Get secrets from Key Vault" step succeeds
   - Verify deployment completes successfully

3. Verify application health:
   ```bash
   curl https://econeura-backend-production.azurewebsites.net/api/health
   ```

### 6. Cleanup (AFTER Verification)

Once you've verified workflows work with Key Vault:

1. Delete GitHub Secrets:
   - Go to: https://github.com/ECONEURA-EMPRESA/ECONEURA-GO/settings/secrets/actions
   - Delete the following (keep only Azure login credentials):
     - ~~DATABASE_URL~~
     - ~~GEMINI_API_KEY~~
     - ~~POSTGRES_ADMIN_PASSWORD~~
     - ~~REDIS_PASSWORD~~
   
2. Keep these GitHub Secrets (needed for Azure login):
   - ✅ AZUREAPPSERVICE_CLIENTID_*
   - ✅ AZUREAPPSERVICE_TENANTID_*
   - ✅ AZUREAPPSERVICE_SUBSCRIPTIONID_*
   - ✅ AZURE_STATIC_WEB_APPS_API_TOKEN

---

## Rollback Plan

If something goes wrong, rollback is simple:

1. Re-add secrets to GitHub Secrets
2. Revert workflow changes:
   ```bash
   git revert HEAD
   git push origin main
   ```

---

## Security Audit Trail

### Key Vault Access Logs

Monitor who accesses secrets:

```bash
# View Key Vault audit logs
az monitor activity-log list \
  --resource-group rg-econeura-ok-prod \
  --resource-id $(az keyvault show --name econeura-kv-production --query id -o tsv) \
  --start-time 2024-01-01 \
  --query "[?contains(operationName.value, 'Microsoft.KeyVault')]" \
  -o table
```

### GitHub Actions Logs

All secret retrievals are logged in GitHub Actions workflow runs.

---

## Troubleshooting

### Error: "Failed to get secrets from Key Vault"

**Cause**: Service Principal doesn't have Key Vault Secrets User role

**Fix**:
```bash
SP_APP_ID="YOUR_SP_APP_ID"
KEYVAULT_ID=$(az keyvault show --name econeura-kv-production --query id -o tsv)

az role assignment create \
  --assignee $SP_APP_ID \
  --role "Key Vault Secrets User" \
  --scope $KEYVAULT_ID
```

### Error: "Secret not found"

**Cause**: Secret name doesn't match exactly (case-sensitive)

**Fix**: Verify secret name:
```bash
az keyvault secret list --vault-name econeura-kv-production --query "[].name" -o table
```

---

## Status

- [x] Migration script created
- [x] Backend deployment workflow updated
- [ ] Frontend deployment workflow updated (if needed)
- [ ] Tested in production
- [ ] GitHub Secrets deleted

**Next Steps**: Test deployment and verify before cleanup.
