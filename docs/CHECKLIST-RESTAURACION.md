# ✅ CHECKLIST DE RESTAURACIÓN AL HITO ESTABLE

**Hito**: `HITO-2025-01-XX-ESTADO-ACTUAL-ESTABLE.md`  
**Fecha de Restauración**: _______________

---

## 🔍 VERIFICACIÓN PRE-RESTAURACIÓN

### **1. Archivos Críticos Existentes**:
- [ ] `packages/frontend/src/EconeuraCockpit.tsx` (conversationId, memoria)
- [ ] `packages/backend/src/conversation/sendNeuraMessage.ts` (historial)
- [ ] `packages/backend/src/llm/invokeLLMAgent.ts` (conversationHistory)
- [ ] `packages/backend/src/infra/llm/OpenAIAdapter.ts` (historial en mensajes)
- [ ] `packages/backend/src/infra/llm/MistralAdapter.ts` (historial en mensajes)
- [ ] `packages/backend/src/shared/utils/fileExtractor.ts` (extracción archivos)
- [ ] `packages/backend/src/api/http/routes/invokeRoutes.ts` (conversationId, archivos)

### **2. Configuración**:
- [ ] `packages/backend/.env` contiene `OPENAI_API_KEY=[REDACTED]`
- [ ] `packages/backend/src/llm/llmAgentsRegistry.ts` tiene `model: 'mistral-medium'` para NEURA-CEO
- [ ] `packages/backend/src/infra/llm/OpenAIAdapter.ts` tiene `baseURL: 'https://api.mammouth.ai/v1'`

### **3. Dependencias**:
- [ ] `npm install` ejecutado en `packages/backend`
- [ ] `npm install` ejecutado en `packages/frontend`
- [ ] Sin errores de dependencias

---

## 🧪 PRUEBAS POST-RESTAURACIÓN

### **Test 1: Memoria del Chat** ✅
```
1. Abrir chat con NEURA-CEO
2. Enviar: "Hola, me llamo Juan"
3. Enviar: "¿Cómo me llamo?"
4. ✅ Debe responder: "Te llamas Juan"
```

### **Test 2: conversationId Persistente** ✅
```
1. Enviar mensaje → Verificar que se crea conversationId
2. Recargar página
3. Enviar otro mensaje
4. ✅ Debe usar el mismo conversationId (verificar en localStorage)
```

### **Test 3: Imágenes** ✅
```
1. Subir una imagen
2. Enviar: "¿Qué hay en esta imagen?"
3. ✅ Debe analizar la imagen correctamente
```

### **Test 4: Archivos** ✅
```
1. Subir un PDF o DOC
2. Enviar: "Resume este documento"
3. ✅ Debe extraer texto y resumir
```

### **Test 5: Modelo Mistral 3.1** ✅
```
1. Chat con NEURA-CEO
2. Enviar: "¿Qué modelo de IA eres?"
3. ✅ Debe responder de forma natural (sin mencionar explícitamente el modelo)
```

---

## 🔧 COMANDOS DE RESTAURACIÓN

### **Si necesitas restaurar archivos específicos**:
```bash
# Verificar estado de git
git status

# Ver cambios en archivos críticos
git diff packages/frontend/src/EconeuraCockpit.tsx
git diff packages/backend/src/conversation/sendNeuraMessage.ts

# Restaurar archivo específico (si es necesario)
git checkout HEAD -- packages/frontend/src/EconeuraCockpit.tsx
```

### **Reiniciar servicios**:
```bash
# Backend
cd packages/backend
npm run dev

# Frontend (en otra terminal)
cd packages/frontend
npm run dev
```

---

## ✅ VALIDACIÓN FINAL

- [ ] Chat mantiene memoria entre mensajes
- [ ] conversationId se guarda en localStorage
- [ ] Backend envía historial al LLM
- [ ] Modelo responde correctamente
- [ ] Imágenes se procesan
- [ ] Archivos se extraen
- [ ] Sin errores en consola
- [ ] Diseño se ve correctamente

---

**Estado de Restauración**: _______________  
**Resultado**: ✅ / ❌


