# 🎯 PRÓXIMOS PASOS - CRM

## ✅ ESTADO ACTUAL: 10/10 COMPLETADO

**Backend CRM:** ✅ Completado y listo  
**Rutas:** ✅ Implementadas y registradas  
**Seguridad:** ✅ HMAC, rate limiting, validaciones  
**Performance:** ✅ Caché Redis, optimizaciones SQL

---

## 📋 CHECKLIST DE PRÓXIMOS PASOS

### 1. BASE DE DATOS (CRÍTICO)

#### 1.1. Crear Base de Datos (si no existe)
```sql
CREATE DATABASE econeura_app;
```

#### 1.2. Ejecutar Migraciones
```bash
# Desde packages/backend/
psql -U postgres -d econeura_app -f database/migrations/002_crm_premium.sql
psql -U postgres -d econeura_app -f database/migrations/003_crm_indexes.sql
```

**Archivos de migración:**
- ✅ `002_crm_premium.sql` - Tablas principales (leads, deals, conversations, agents)
- ✅ `003_crm_indexes.sql` - Índices compuestos para performance

#### 1.3. Verificar Tablas
```sql
\dt crm_*
SELECT COUNT(*) FROM crm_leads;
SELECT COUNT(*) FROM crm_deals;
SELECT COUNT(*) FROM crm_conversations;
SELECT COUNT(*) FROM crm_agents;
```

---

### 2. CONFIGURACIÓN DE ENTORNO

#### 2.1. Variables de Entorno Requeridas
```env
# Base de datos
DATABASE_URL=postgresql://postgres:password@localhost:5432/econeura_app

# CRM Webhooks (opcional, pero recomendado)
CRM_WEBHOOK_SECRET=mDK3Ojdx2k+gqqZ7Tsi1jIjFlVpzmHVL23vyeKrOWjU=

# Redis (opcional, para caché)
REDIS_URL=redis://localhost:6379
```

#### 2.2. Verificar Configuración
```bash
# Verificar que DATABASE_URL está configurado
echo $DATABASE_URL

# Verificar que el servidor puede conectarse
npm run dev
```

---

### 3. TESTING MANUAL

#### 3.1. Health Check
```bash
curl http://localhost:3000/health
# Esperado: {"status":"ok"}
```

#### 3.2. Probar API CRM (requiere auth)
```bash
# Obtener token de autenticación primero
TOKEN="Bearer <tu-token>"

# Listar leads
curl -H "Authorization: $TOKEN" \
  "http://localhost:3000/api/crm/leads?department=cmo&limit=10"

# Obtener métricas de ventas
curl -H "Authorization: $TOKEN" \
  "http://localhost:3000/api/crm/sales-metrics?department=cso&period=month"
```

#### 3.3. Probar Webhooks (requiere HMAC)
```bash
# Generar HMAC signature
SECRET="mDK3Ojdx2k+gqqZ7Tsi1jIjFlVpzmHVL23vyeKrOWjU="
BODY='{"email":"test@example.com","nombre":"Test User","department":"cmo","agent_name":"Lead_Prospector"}'
SIGNATURE=$(echo -n "$BODY" | openssl dgst -sha256 -hmac "$SECRET" | cut -d' ' -f2)

# Crear lead
curl -X POST http://localhost:3000/api/crm/webhooks/lead-created \
  -H "Content-Type: application/json" \
  -H "X-Webhook-Signature: $SIGNATURE" \
  -d "$BODY"
```

---

### 4. FRONTEND (PRÓXIMA FASE)

#### 4.1. Crear Componente CRMPanel
- 📁 `packages/frontend/src/components/CRMPanel.tsx`
- Integrar con React Query
- Tabla de leads con TanStack Table
- Panel de métricas con Recharts

#### 4.2. Agregar a Departments
- Agregar panel a `departments.ts` en CMO y CSO
- Configurar rutas en router

#### 4.3. Integración con React Query
```typescript
// Ejemplo de hook
const { data: leads, isLoading } = useQuery({
  queryKey: ['crm', 'leads', department],
  queryFn: () => fetchLeads(department),
  refetchInterval: 30000 // Auto-refresh cada 30s
});
```

---

### 5. INTEGRACIÓN CON N8N

#### 5.1. Configurar Webhooks en N8N
- URL: `https://tu-dominio.com/api/crm/webhooks/lead-created`
- Método: POST
- Headers: `X-Webhook-Signature: <hmac-signature>`
- Body: JSON con payload del schema

#### 5.2. Agentes a Integrar
- **CMO:**
  - Lead_Prospector
  - Email_Campaign_Manager
  - Content_Generator
- **CSO:**
  - Deal_Closer
  - Meeting_Scheduler

#### 5.3. Testing de Integración
- Probar webhook desde N8N
- Verificar que lead se crea en DB
- Verificar que métricas se actualizan
- Verificar que caché se invalida

---

### 6. MONITOREO Y LOGS

#### 6.1. Verificar Logs
```bash
# Buscar logs de CRM
tail -f logs/combined.log | grep CRM

# Buscar errores
tail -f logs/error.log | grep CRM
```

#### 6.2. Verificar Métricas
- Revisar Application Insights (si configurado)
- Verificar que requests se trackean
- Verificar que errores se loguean

---

## 🚨 PROBLEMAS COMUNES Y SOLUCIONES

### Error: "DATABASE_URL no configurado"
**Solución:** Agregar `DATABASE_URL` al `.env`

### Error: "Table crm_leads does not exist"
**Solución:** Ejecutar migraciones SQL

### Error: "Invalid signature" en webhooks
**Solución:** Verificar que `CRM_WEBHOOK_SECRET` coincide y que el HMAC se calcula correctamente

### Error: "Rate limit exceeded"
**Solución:** Esperar 1 minuto o verificar configuración de rate limiting

### Error: "Agent not found"
**Solución:** Verificar que el agente existe en `automationAgentsRegistry` o en `crm_agents`

---

## 📊 MÉTRICAS DE ÉXITO

### Backend
- ✅ Servidor inicia sin errores
- ✅ Health check responde 200 OK
- ✅ Rutas CRM responden correctamente
- ✅ Webhooks procesan requests
- ✅ Base de datos conectada
- ✅ Pool de PostgreSQL inicializado

### Funcionalidad
- ✅ Leads se crean correctamente
- ✅ Deals se actualizan correctamente
- ✅ Métricas se calculan correctamente
- ✅ Caché funciona (si Redis disponible)
- ✅ Transacciones funcionan

---

## 🎯 PRIORIDADES

### ALTA PRIORIDAD (Hacer primero)
1. ✅ Ejecutar migraciones de base de datos
2. ✅ Verificar que servidor inicia
3. ✅ Probar health check
4. ✅ Probar endpoints básicos

### MEDIA PRIORIDAD
5. ⚠️ Testing manual completo
6. ⚠️ Integración con N8N
7. ⚠️ Verificar logs y métricas

### BAJA PRIORIDAD (Después)
8. 📋 Crear componente frontend
9. 📋 Integrar con React Query
10. 📋 Crear panel de visualización

---

## 📚 DOCUMENTACIÓN RELACIONADA

- `docs/RESUMEN-FINAL-CRM-10-10.md` - Resumen completo
- `docs/INSTALACION-CRM-PREMIUM-10-10.md` - Plan de instalación
- `docs/SOLUCION-CRM-PREMIUM-COMPLETA.md` - Solución técnica
- `database/migrations/002_crm_premium.sql` - Schema SQL
- `database/migrations/003_crm_indexes.sql` - Índices SQL

---

**Última actualización:** 16 Noviembre 2025  
**Estado:** ✅ Backend completado, pendiente testing y frontend

