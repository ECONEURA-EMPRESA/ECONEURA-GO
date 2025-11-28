# 🔧 SOLUCIÓN ERRORES TYPESCRIPT

## ⚠️ ERROR ENCONTRADO

```
error TS2322: Type '{ propertyName: string; ... }[]' is not assignable to type 'McpToolProperty[]'
```

**Ubicación:** `node_modules/@azure/functions/src/utils/toolProperties.ts:226`

**Causa:** Error en dependencia externa (`@azure/functions`), no en nuestro código.

---

## ✅ SOLUCIÓN APLICADA

### 1. Agregar `skipLibCheck: true` en tsconfig.json

Esto hace que TypeScript ignore errores en archivos de `node_modules`.

**Archivo:** `packages/backend/tsconfig.json`

```json
{
  "compilerOptions": {
    "skipLibCheck": true  // ← Agregado
  }
}
```

---

## 🚀 COMANDOS CORREGIDOS

### Compilar (ignora errores de node_modules)
```powershell
cd C:\Users\Usuario\ECONEURA-FULL\packages\backend
npm run build
```

### Iniciar servidor
```powershell
npm run dev
```

---

## 📋 ALTERNATIVAS PARA MIGRACIONES SQL

### Si psql NO está en PATH:

#### Opción 1: Usar ruta completa
```powershell
# Buscar psql en tu sistema
Get-Command psql -ErrorAction SilentlyContinue

# O usar ruta completa (ajusta según tu instalación)
"C:\Program Files\PostgreSQL\15\bin\psql.exe" -U postgres -d econeura_app -f database\migrations\002_crm_premium.sql
```

#### Opción 2: Usar pgAdmin o DBeaver
- Abrir pgAdmin
- Conectar a la base de datos `econeura_app`
- Ejecutar el contenido de `002_crm_premium.sql`
- Ejecutar el contenido de `003_crm_indexes.sql`

#### Opción 3: Agregar PostgreSQL al PATH
```powershell
# Agregar temporalmente al PATH
$env:Path += ";C:\Program Files\PostgreSQL\15\bin"

# Verificar
psql --version
```

---

## ✅ VERIFICACIÓN

Después de aplicar `skipLibCheck: true`:

```powershell
npm run type-check
# Debería compilar sin errores (solo warnings de node_modules)

npm run build
# Debería compilar exitosamente
```

---

**Última actualización:** 16 Noviembre 2025

