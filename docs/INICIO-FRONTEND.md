# 🚀 INICIO DEL FRONTEND

## ✅ COMANDOS EJECUTADOS

```powershell
cd C:\Users\Usuario\ECONEURA-FULL\packages\frontend
npm run dev
```

---

## 🌐 URLs

- **Frontend:** http://localhost:5173
- **Backend:** http://localhost:3000

---

## 📋 PASOS PARA PROBAR

1. **Abrir navegador**
   - Ir a: http://localhost:5173

2. **Iniciar sesión**
   - Usar credenciales de desarrollo

3. **Seleccionar departamento**
   - CMO (Chief Marketing Officer)
   - CSO (Chief Sales Officer)

4. **Ver panel CRM**
   - Tab "Analytics": Dashboard con métricas y gráficos
   - Tab "Leads": Tabla de leads con búsqueda y filtros

---

## ⚠️ REQUISITOS

- ✅ Backend corriendo en puerto 3000
- ✅ Base de datos PostgreSQL configurada
- ✅ Tablas CRM creadas (migrations)

---

## 🔍 VERIFICACIÓN

### En el navegador:
1. Abre DevTools (F12)
2. Ve a la pestaña "Network"
3. Selecciona CMO o CSO
4. Deberías ver requests a:
   - `GET /api/crm/leads?department=cmo`
   - `GET /api/crm/sales-metrics?department=cmo&period=month`

### Si hay errores:
- Revisa la consola del navegador
- Verifica que el backend esté corriendo
- Verifica que las tablas CRM existan en PostgreSQL

---

## 🎯 CARACTERÍSTICAS DISPONIBLES

### Analytics Tab:
- ✅ KPI Cards (Revenue, Deals, Valor Promedio)
- ✅ Gráfico de línea: Revenue por mes
- ✅ Gráfico de barras: Top agentes
- ✅ Selector de período (day, week, month, year, all)

### Leads Tab:
- ✅ Tabla virtualizada (rendimiento óptimo)
- ✅ Búsqueda con debounce (300ms)
- ✅ Filtro por status
- ✅ Paginación
- ✅ Auto-refresh cada 30s

---

**Última actualización:** 17 Noviembre 2025

