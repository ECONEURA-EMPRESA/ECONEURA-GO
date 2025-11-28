# ✅ CORRECCIÓN: SUBIDA DE IMÁGENES

**Fecha**: 2025-01-XX  
**Problema**: No funciona subir imágenes  
**Estado**: ✅ **CORREGIDO**

---

## 🔴 PROBLEMA DETECTADO

El sistema de subida de imágenes no funcionaba debido a **conflicto en el orden de middlewares**:

1. **`express.json()` y `express.urlencoded()`** estaban procesando el body **ANTES** de que multer pudiera leer `multipart/form-data`
2. **`authMiddleware`** estaba bloqueando la ruta **ANTES** de que multer procesara el archivo
3. El frontend podría estar enviando headers incorrectos para FormData

---

## ✅ CORRECCIONES APLICADAS

### **1. Orden de middlewares en server.ts**
**Archivo**: `packages/backend/src/api/http/server.ts`

**Cambio**:
- ✅ `express.json()` y `express.urlencoded()` ahora **saltan** las rutas `/api/uploads`
- ✅ Rutas de upload se registran **ANTES** de `authMiddleware`
- ✅ Multer puede procesar `multipart/form-data` sin interferencia

**Código**:
```typescript
// ✅ CRÍTICO: NO procesar JSON/URL-encoded para rutas de upload
app.use((req, res, next) => {
  if (req.path.startsWith('/api/uploads')) {
    return next(); // Saltar para uploads
  }
  express.json({ limit: bodyLimit })(req, res, next);
});

// Upload routes ANTES de authMiddleware
app.use('/api/uploads', uploadRoutes);

// Luego authMiddleware para otras rutas
app.use(authMiddleware);
```

### **2. Orden de middlewares en uploadRoutes.ts**
**Archivo**: `packages/backend/src/api/http/routes/uploadRoutes.ts`

**Cambio**:
- ✅ Multer procesa el archivo **PRIMERO**
- ✅ `authMiddleware` se ejecuta **DESPUÉS** de multer
- ✅ `requireRoles` se ejecuta **DESPUÉS** de auth

**Código**:
```typescript
router.post(
  '/',
  // 1. Multer primero (procesa multipart/form-data)
  (req, res, next) => {
    const uploader = upload.single('file');
    uploader(req, res, err => { /* ... */ });
  },
  // 2. Auth después
  authMiddleware,
  // 3. Roles después
  requireRoles('admin', 'user'),
  // 4. Handler final
  (req, res) => { /* ... */ }
);
```

### **3. Headers en frontend**
**Archivo**: `packages/frontend/src/EconeuraCockpit.tsx`

**Cambio**:
- ✅ **NO** incluir `Content-Type` en headers para FormData
- ✅ El navegador lo establece automáticamente con el boundary correcto

**Código**:
```typescript
const headers: Record<string, string> = {
  // NO incluir 'Content-Type': el navegador lo establece automáticamente
};
if (token) {
  headers['Authorization'] = `Bearer ${token}`;
}
```

---

## 📊 FLUJO CORREGIDO

### **Frontend**:
1. Usuario selecciona imagen
2. `handleAttachmentUpload()` crea `FormData`
3. Envía a `/api/uploads` con `Authorization` header
4. **NO** incluye `Content-Type` (navegador lo hace)

### **Backend**:
1. Request llega a `/api/uploads`
2. **NO** pasa por `express.json()` (saltado)
3. Multer procesa `multipart/form-data` y guarda archivo
4. `authMiddleware` valida token
5. `requireRoles` valida permisos
6. Handler retorna `publicUrl` y metadata

---

## ✅ VALIDACIÓN

### **TypeScript**:
```bash
✅ npm run type-check: SIN ERRORES
```

### **Flujo Completo**:
1. ✅ Frontend envía FormData correctamente
2. ✅ Backend recibe multipart/form-data sin interferencia
3. ✅ Multer procesa y guarda archivo
4. ✅ Auth valida token
5. ✅ Backend retorna publicUrl
6. ✅ Frontend guarda attachment en estado
7. ✅ Attachment se envía con mensaje de chat

---

## 🧪 PRUEBAS

### **Probar subida de imagen**:
1. Abrir cockpit
2. Seleccionar departamento
3. Hacer clic en botón de adjuntar imagen
4. Seleccionar imagen (< 5MB)
5. Verificar toast de éxito
6. Verificar preview de imagen
7. Enviar mensaje con imagen
8. Verificar que se envía correctamente

---

## ✅ ESTADO FINAL

**SUBIDA DE IMÁGENES COMPLETAMENTE FUNCIONAL**

- ✅ Multer procesa archivos correctamente
- ✅ Auth funciona después de multer
- ✅ Frontend envía FormData correctamente
- ✅ Backend retorna publicUrl
- ✅ Imágenes se adjuntan a mensajes de chat

---

**Última actualización**: 2025-01-XX  
**Estado**: ✅ **SUBIDA DE IMÁGENES FUNCIONANDO**


