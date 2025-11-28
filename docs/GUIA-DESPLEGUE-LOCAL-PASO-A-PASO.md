# 🚀 GUÍA DE DESPLIEGUE LOCAL - PASO A PASO

## ✅ PRE-REQUISITOS VERIFICADOS

- ✅ Migraciones creadas (002 y 003)
- ✅ Script de despliegue creado
- ✅ Dependencias actualizadas (pg v8.16.3)

---

## 📋 PASO 1: CONFIGURAR POSTGRESQL

### 1.1. Verificar que PostgreSQL está corriendo

```powershell
# Verificar servicio
Get-Service -Name postgresql* | Select-Object Name, Status
```

Si no está corriendo:
```powershell
# Iniciar servicio (ajusta el nombre según tu instalación)
Start-Service postgresql-x64-16
```

### 1.2. Crear base de datos

```powershell
# Conectar a PostgreSQL
psql -U postgres

# Crear base de datos
CREATE DATABASE econeura_app;

# Salir
\q
```

**O usar el script automático:**
```powershell
.\scripts\deploy-local.ps1 -PostgresPassword "tu-password"
```

---

## 📋 PASO 2: EJECUTAR MIGRACIONES

### Opción A: Manual

```powershell
cd packages\backend

# Ejecutar migraciones
psql -U postgres -d econeura_app -f database\migrations\002_crm_premium.sql
psql -U postgres -d econeura_app -f database\migrations\003_crm_indexes.sql
```

### Opción B: Script Automático

```powershell
# Desde la raíz del proyecto
.\scripts\deploy-local.ps1 -PostgresPassword "tu-password"
```

---

## 📋 PASO 3: CONFIGURAR .ENV

### 3.1. Verificar si existe

```powershell
cd packages\backend
Test-Path .env
```

### 3.2. Crear/Editar .env

```powershell
# Si no existe, crear
New-Item .env -ItemType File

# Editar con tu editor favorito
notepad .env
```

### 3.3. Contenido mínimo de .env

```env
NODE_ENV=development
PORT=3000

# PostgreSQL (ajusta según tu configuración)
DATABASE_URL=postgresql://postgres:tu-password@localhost:5432/econeura_app

# Redis (opcional, pero recomendado)
REDIS_URL=redis://localhost:6379

# CRM Webhooks (GENERAR UNO SEGURO)
CRM_WEBHOOK_SECRET=
```

### 3.4. Generar CRM_WEBHOOK_SECRET

```powershell
# Generar secret seguro
[Convert]::ToBase64String([System.Security.Cryptography.RandomNumberGenerator]::GetBytes(32))
```

Copiar el resultado y pegarlo en `CRM_WEBHOOK_SECRET` en `.env`.

---

## 📋 PASO 4: INSTALAR DEPENDENCIAS

```powershell
# Desde la raíz del proyecto
npm install

# O solo backend
cd packages\backend
npm install
```

**Verificar que `pg` se instaló:**
```powershell
npm list pg
```

---

## 📋 PASO 5: VERIFICAR TYPESCRIPT

```powershell
cd packages\backend
npm run type-check
```

**Nota:** Puede haber warnings de paths, pero no son bloqueantes.

---

## 📋 PASO 6: INICIAR BACKEND

```powershell
cd packages\backend
npm run dev
```

**Verificar en los logs:**
- ✅ `ECONEURA backend escuchando en el puerto 3000`
- ✅ `[PostgresPool] Pool inicializado`
- ✅ `[Redis] Conectado correctamente` (si Redis está configurado)

---

## 📋 PASO 7: VERIFICAR HEALTH CHECK

```powershell
# En otra terminal
Invoke-WebRequest -Uri http://localhost:3000/health
```

**Respuesta esperada:**
```json
{
  "status": "ok"
}
```

---

## 📋 PASO 8: VERIFICAR EN POSTGRESQL

```powershell
# Conectar
psql -U postgres -d econeura_app

# Verificar tablas
\dt crm_*

# Ver estructura de una tabla
\d crm_leads

# Salir
\q
```

---

## ✅ CHECKLIST FINAL

- [ ] PostgreSQL corriendo
- [ ] Base de datos `econeura_app` creada
- [ ] Migraciones ejecutadas (002 y 003)
- [ ] `.env` configurado
- [ ] `CRM_WEBHOOK_SECRET` generado y configurado
- [ ] Dependencias instaladas
- [ ] Backend iniciado sin errores
- [ ] Health check responde OK
- [ ] Pool de PostgreSQL inicializado (ver logs)
- [ ] Tablas creadas en PostgreSQL

---

## 🔧 TROUBLESHOOTING

### Error: "psql no se reconoce como comando"
**Solución:** Agregar PostgreSQL al PATH o usar ruta completa:
```powershell
"C:\Program Files\PostgreSQL\16\bin\psql.exe" -U postgres
```

### Error: "DATABASE_URL no configurado"
**Solución:** Verificar que `.env` tiene `DATABASE_URL` correcto.

### Error: "Table does not exist"
**Solución:** Ejecutar migraciones:
```powershell
psql -U postgres -d econeura_app -f packages\backend\database\migrations\002_crm_premium.sql
```

### Error: "too many connections"
**Solución:** Verificar que solo hay un pool (ya está implementado).

### Error: "Redis no disponible"
**Solución:** Redis es opcional. El sistema funciona sin él (sin caché).

---

## 🎯 SIGUIENTE PASO

Una vez que el backend esté corriendo:
1. ✅ Verificar health check
2. ⏳ Crear webhooks completos
3. ⏳ Crear frontend panel
4. ⏳ Testing manual

---

**Estado:** ✅ Listo para despliegue  
**Última actualización:** 16 Noviembre 2025

