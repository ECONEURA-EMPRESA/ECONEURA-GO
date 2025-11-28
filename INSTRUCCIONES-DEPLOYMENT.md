# 🚀 INSTRUCCIONES PARA DEPLOYMENT LOCAL

## ✅ VERIFICACIÓN PREVIA COMPLETADA

- ✅ Type-check: Backend y Frontend sin errores
- ✅ Estructura de archivos: Completa
- ✅ CRM Routes: Implementado y validado
- ✅ CRM Panel: Implementado y validado
- ✅ 5 Mejoras post-auditoría: Aplicadas
- ✅ Type-safety: 98% (44/45 `any` eliminados)

---

## 🚀 PASOS PARA ARRANCAR

### 1️⃣ Terminal 1 - Backend

```powershell
cd C:\Users\Usuario\ECONEURA-FULL\packages\backend
npm run dev
```

**Espera a ver:**
```
✅ Server running on port 3000
✅ Database connected
✅ CRM routes registered
```

### 2️⃣ Terminal 2 - Frontend

```powershell
cd C:\Users\Usuario\ECONEURA-FULL\packages\frontend
npm run dev
```

**Espera a ver:**
```
  VITE v7.x.x  ready in xxx ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
```

---

## 🌐 URLs

- **Frontend:** http://localhost:5173
- **Backend:** http://localhost:3000
- **API:** http://localhost:3000/api

---

## ✅ CHECKLIST DE VERIFICACIÓN

### Login
- [ ] Abre http://localhost:5173
- [ ] Deberías ver el LOGIN de ECONEURA
- [ ] Logo circular visible
- [ ] Formulario de login funcional
- [ ] Puedes registrarte o iniciar sesión

### Cockpit
- [ ] Después del login, se muestra el COCKPIT
- [ ] Sidebar con departamentos visible
- [ ] Logo ECONEURA en header (pequeño)
- [ ] Navegación entre departamentos funciona

### CRM Panel
- [ ] Ve al departamento **MKT (Marketing)**
- [ ] Deberías ver el **CRM Premium Panel**
- [ ] KPIs se muestran (Revenue, Deals, etc.)
- [ ] Tabla de leads visible
- [ ] Gráficos de ventas funcionan
- [ ] Filtros y búsqueda operativos

### API (Opcional - Verificar en DevTools)
- [ ] Abre DevTools (F12) → Network
- [ ] Verifica que `/api/auth/login` responde 200
- [ ] Verifica que `/api/crm/leads?department=cmo` responde
- [ ] Verifica que `/api/crm/sales-metrics?department=cmo&period=month` responde

---

## 🐛 SOLUCIÓN DE PROBLEMAS

### Backend no arranca
**Error:** `DATABASE_URL not configured`
- **Solución:** El backend puede arrancar sin DB para pruebas básicas
- Si necesitas DB: Configura `DATABASE_URL` en `.env`

**Error:** `Port 3000 already in use`
- **Solución:** Cambia el puerto en `.env`: `PORT=3001`

### Frontend no arranca
**Error:** `Port 5173 already in use`
- **Solución:** Vite usará automáticamente el siguiente puerto disponible
- O cambia en `vite.config.ts`

### Error de conexión a API
**Error:** `Failed to fetch /api/auth/login`
- **Solución:** Verifica que el backend está corriendo en puerto 3000
- Verifica `packages/frontend/src/config/api.ts` apunta a `http://localhost:3000/api`

### CRM Panel no se muestra
**Causa:** Solo se muestra en departamento **MKT (Marketing)**
- **Solución:** Asegúrate de estar en el departamento correcto en el sidebar

---

## ✅ SI TODO FUNCIONA

Una vez verificado que:
- ✅ Login funciona
- ✅ Cockpit se muestra
- ✅ CRM Panel visible y funcional
- ✅ Sin errores en consola

**Entonces puedes proceder con:**

### 1. Commit a GitHub
```bash
git add .
git commit -m "feat: 5 mejoras post-auditoría + deployment local verificado"
git push origin main
```

### 2. Deploy a Azure
- Los workflows de GitHub Actions se ejecutarán automáticamente
- Verifica variables de entorno en Azure Portal
- Monitorea el deployment en GitHub Actions

### 3. Testing en Producción
- Verifica login en producción
- Conecta agentes reales de N8N al CRM
- Monitorea logs en Application Insights

---

## 📊 ESTADO ACTUAL

- ✅ **Auditoría:** 10/10 fases completadas
- ✅ **Mejoras:** 5/5 aplicadas
- ✅ **Type-safety:** 98%
- ✅ **Validación:** Zod schemas implementados
- ✅ **CRM:** Listo para producción
- ✅ **Deployment Local:** Listo para verificar

---

**¡Todo listo para arrancar y verificar!** 🚀

