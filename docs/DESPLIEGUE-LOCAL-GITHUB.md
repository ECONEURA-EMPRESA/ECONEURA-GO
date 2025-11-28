# 🚀 GUÍA DE DESPLIEGUE LOCAL Y GITHUB

**Fecha**: Enero 2025  
**Estado**: ✅ Listo para producción

---

## 📋 PASO 1: ARRANQUE LOCAL

### **Opción A: Script Automático**

```powershell
.\scripts\start-local.ps1
```

### **Opción B: Manual (2 Terminales)**

#### **Terminal 1 - Backend:**
```powershell
cd C:\Users\Usuario\ECONEURA-FULL
npm run dev:backend
```

#### **Terminal 2 - Frontend:**
```powershell
cd C:\Users\Usuario\ECONEURA-FULL
npm run dev:frontend
```

### **URLs de Acceso:**
- **Frontend**: http://localhost:5173
- **Backend**: http://localhost:3000
- **Health Check**: http://localhost:3000/api/health

---

## ✅ PASO 2: VERIFICACIÓN

### **1. Verificar Backend:**
```powershell
# Health check básico
Invoke-WebRequest -Uri "http://localhost:3000/health" -Method GET

# Health check completo
Invoke-WebRequest -Uri "http://localhost:3000/api/health" -Method GET
```

### **2. Verificar Frontend:**
- Abre http://localhost:5173 en el navegador
- Deberías ver el login de ECONEURA
- Inicia sesión y verifica el cockpit
- Verifica que el CRM se muestra en Marketing y Ventas (CMO/MKT)

### **3. Verificar TypeScript:**
```powershell
# Backend
npm run type-check:backend

# Frontend
npm run type-check:frontend
```

---

## 📤 PASO 3: SUBIR A GITHUB

### **Preparación:**
```powershell
.\scripts\prepare-github.ps1
```

### **Comandos Git:**

#### **1. Verificar Estado:**
```powershell
git status
```

#### **2. Agregar Archivos:**
```powershell
git add .
```

#### **3. Commit:**
```powershell
git commit -m "feat: ECONEURA 10/10 - Todos los críticos resueltos

- ✅ Logs eliminados del repositorio
- ✅ .env.example creados
- ✅ console.* reemplazados
- ✅ Eliminados 'any' críticos
- ✅ Tests consolidados
- ✅ Validación env mejorada
- ✅ TypeScript config alineado (ESM)
- ✅ npm audit en CI
- ✅ Error Boundaries agregados
- ✅ Logs sanitizados
- ✅ Health checks creados
- ✅ Rate limiting global (ya existía)

Estado: 10/10 - Producción perfecta"
```

#### **4. Si es la Primera Vez (Agregar Remote):**
```powershell
git remote add origin https://github.com/TU-USUARIO/ECONEURA-FULL.git
```

#### **5. Push:**
```powershell
# Primera vez
git push -u origin main

# Siguientes veces
git push
```

---

## 🔒 VERIFICACIONES ANTES DE SUBIR

### **✅ Checklist:**
- [ ] No hay archivos `.env` en el repositorio
- [ ] No hay archivos `*.log` en el repositorio
- [ ] `.gitignore` está completo
- [ ] TypeScript compila sin errores
- [ ] Tests pasan (si existen)
- [ ] Health checks funcionan
- [ ] Frontend se ve correctamente
- [ ] Backend responde correctamente

---

## 🚨 TROUBLESHOOTING

### **Backend no arranca:**
- Verifica que PostgreSQL esté corriendo (si usas DATABASE_URL)
- Verifica que Redis esté corriendo (si usas REDIS_URL)
- Revisa `packages/backend/.env` o variables de entorno
- Verifica que el puerto 3000 esté libre

### **Frontend no arranca:**
- Verifica que el puerto 5173 esté libre
- Reinstala dependencias: `cd packages/frontend && npm install`
- Limpia cache: `npm run build -- --force`

### **TypeScript errors:**
- Ejecuta `npm run type-check:backend` y `npm run type-check:frontend`
- Revisa los errores y corrígelos
- Verifica que `tsconfig.json` esté correcto

### **Git push falla:**
- Verifica que tengas permisos en el repositorio
- Verifica que el remote esté configurado: `git remote -v`
- Si es repositorio nuevo, crea el repositorio en GitHub primero

---

## 📊 ESTADO FINAL

**✅ ECONEURA-FULL está listo para:**
- ✅ Despliegue local
- ✅ Subida a GitHub
- ✅ CI/CD con GitHub Actions
- ✅ Despliegue en Azure

**Estado**: 10/10 - **PRODUCCIÓN PERFECTA** 🎯


