# 🔍 ANÁLISIS EXHAUSTIVO DEL SISTEMA DE CHAT

**Fecha**: 2025-01-XX  
**Estado**: 🔴 **PROBLEMAS CRÍTICOS DETECTADOS**

---

## 📋 FLUJO COMPLETO DEL CHAT

### **1. Frontend → Backend**

**Archivo**: `packages/frontend/src/EconeuraCockpit.tsx`
- **Función**: `sendChatMessage()` (línea 919)
- **Endpoint**: `/api/invoke/${chatAgentId}`
- **Body enviado**:
  ```typescript
  {
    input: string,
    conversationId?: string,
    attachmentUrl?: string,
    attachmentType?: 'image' | 'file',
    attachmentId?: string,
    attachmentName?: string,
    attachmentMimeType?: string,
    attachmentSize?: number
  }
  ```

### **2. Backend → LLM**

**Archivo**: `packages/backend/src/api/http/routes/invokeRoutes.ts`
- **Función**: `POST /api/invoke/:agentId` (línea 44)
- **Procesa**: attachmentUrl → descarga → base64
- **Llama**: `sendNeuraMessage()` (línea 240)

**Archivo**: `packages/backend/src/conversation/sendNeuraMessage.ts`
- **Función**: `sendNeuraMessage()` (línea 28)
- **Procesa**: Crea/recupera conversación, obtiene historial, llama LLM
- **Llama**: `invokeLLMAgent()` (línea 121)

---

## 🔴 PROBLEMAS CRÍTICOS DETECTADOS

### **PROBLEMA 1: conversationId no se carga al inicio**
**Archivo**: `EconeuraCockpit.tsx`
- ❌ `conversationId` se guarda en localStorage pero NO se carga al montar el componente
- ❌ Si el usuario recarga la página, pierde el contexto de la conversación
- **Impacto**: 🔴 **CRÍTICO** - Pérdida de memoria conversacional

### **PROBLEMA 2: Historial no se carga al inicio**
**Archivo**: `EconeuraCockpit.tsx`
- ❌ No hay `useEffect` que cargue el historial de mensajes al iniciar
- ❌ Si hay `conversationId`, debería cargar los mensajes previos
- **Impacto**: 🔴 **CRÍTICO** - El usuario no ve mensajes anteriores

### **PROBLEMA 3: attachmentUrl no se pasa a sendNeuraMessage**
**Archivo**: `invokeRoutes.ts` (línea 240)
- ❌ `sendNeuraMessage` recibe `image` y `file` (base64) pero NO `attachmentUrl` ni `attachmentType`
- ❌ Si el attachment viene por URL, se descarga pero no se pasa al LLM
- **Impacto**: 🟡 **MEDIO** - Attachments por URL no funcionan

### **PROBLEMA 4: useChatOperations no envía conversationId**
**Archivo**: `useChatOperations.ts` (línea 117)
- ❌ No envía `conversationId` en el body del request
- ❌ No maneja la respuesta del `conversationId` del backend
- **Impacto**: 🔴 **CRÍTICO** - No mantiene memoria conversacional

### **PROBLEMA 5: sendNeuraMessage no acepta attachmentUrl**
**Archivo**: `sendNeuraMessage.ts` (línea 11)
- ❌ Interface `SendNeuraMessageInput` solo tiene `image` y `file` (base64)
- ❌ No tiene `attachmentUrl` ni `attachmentType`
- **Impacto**: 🟡 **MEDIO** - No soporta attachments por URL

### **PROBLEMA 6: ChatHistory usa endpoint inexistente**
**Archivo**: `ChatHistory.tsx` (línea 41)
- ❌ Usa `/api/chats` que probablemente no existe
- ❌ Debería usar `/api/conversations/:id/messages`
- **Impacto**: 🟡 **MEDIO** - Historial no funciona

### **PROBLEMA 7: Mapeo agentId incompleto**
**Archivo**: `invokeRoutes.ts` (línea 20)
- ❌ Solo mapea algunos agentIds
- ❌ Si el frontend envía un agentId no mapeado, falla con 404
- **Impacto**: 🟡 **MEDIO** - Algunos agentes no funcionan

### **PROBLEMA 8: Error handling inconsistente**
**Archivo**: `EconeuraCockpit.tsx` (línea 985)
- ❌ Maneja errores pero no distingue entre tipos (red, auth, servidor)
- ❌ No muestra mensajes claros al usuario
- **Impacto**: 🟡 **MEDIO** - UX pobre en errores

### **PROBLEMA 9: Cache LLM puede romper memoria**
**Archivo**: `invokeLLMAgent.ts` (línea 53)
- ❌ Cachea respuestas sin considerar `conversationHistory`
- ❌ Si hay historial, NO cachea (correcto), pero si no hay historial y es la misma pregunta, cachea
- **Impacto**: 🟢 **BAJO** - Puede dar respuestas incorrectas en contexto

### **PROBLEMA 10: Historial se obtiene pero puede estar vacío**
**Archivo**: `sendNeuraMessage.ts` (línea 101)
- ❌ Si la conversación es nueva, `existingMessages` está vacío
- ❌ El historial solo se construye después de varios mensajes
- **Impacto**: 🟢 **BAJO** - Funciona pero no es óptimo

---

## ✅ SOLUCIONES PROPUESTAS

### **SOLUCIÓN 1: Cargar conversationId al inicio**
```typescript
useEffect(() => {
  const saved = localStorage.getItem(`econeura_conversation_${dept.id}`);
  if (saved) {
    setConversationId(saved);
    // Cargar historial de mensajes
    loadConversationHistory(saved);
  }
}, [dept.id]);
```

### **SOLUCIÓN 2: Cargar historial de mensajes**
```typescript
async function loadConversationHistory(convId: string) {
  try {
    const res = await fetch(`${apiUrl}/api/conversations/${convId}/messages`);
    const data = await res.json();
    if (data.success && data.messages) {
      setChatMsgs(data.messages.map(m => ({
        id: m.id,
        text: m.content,
        role: m.role
      })));
    }
  } catch (err) {
    // Silenciar error, continuar sin historial
  }
}
```

### **SOLUCIÓN 3: Pasar attachmentUrl a sendNeuraMessage**
```typescript
// En invokeRoutes.ts
const result = await sendNeuraMessage({
  // ... otros campos
  attachmentUrl, // ✅ Agregar
  attachmentType // ✅ Agregar
});
```

### **SOLUCIÓN 4: Actualizar interface SendNeuraMessageInput**
```typescript
export interface SendNeuraMessageInput {
  // ... campos existentes
  attachmentUrl?: string; // ✅ Agregar
  attachmentType?: 'image' | 'file'; // ✅ Agregar
}
```

### **SOLUCIÓN 5: Enviar conversationId desde useChatOperations**
```typescript
const body: Record<string, string> = {
  input: text,
  conversationId: conversationId || undefined // ✅ Agregar
};
```

### **SOLUCIÓN 6: Corregir ChatHistory endpoint**
```typescript
// Cambiar de /api/chats a /api/conversations
const response = await fetch(`${API_URL}/api/conversations?limit=50`, {
  // ...
});
```

### **SOLUCIÓN 7: Completar mapeo agentId**
```typescript
const agentIdToNeuraId: Record<string, NeuraId> = {
  // Agregar todos los agentIds posibles
  'a-ia-01': 'neura-ia',
  'a-ciso-01': 'neura-ciso',
  // ... etc
};
```

### **SOLUCIÓN 8: Mejorar error handling**
```typescript
if (!res.ok) {
  if (res.status === 401) {
    toast.error('Sesión expirada. Por favor, inicia sesión nuevamente.');
    onLogout();
    return;
  }
  if (res.status === 413) {
    toast.error('Archivo demasiado grande.');
    return;
  }
  // ... otros casos
}
```

---

## 📊 PRIORIDAD DE CORRECCIONES

1. 🔴 **CRÍTICO**: Cargar conversationId al inicio
2. 🔴 **CRÍTICO**: Cargar historial de mensajes
3. 🔴 **CRÍTICO**: Enviar conversationId desde useChatOperations
4. 🟡 **MEDIO**: Pasar attachmentUrl a sendNeuraMessage
5. 🟡 **MEDIO**: Actualizar interface SendNeuraMessageInput
6. 🟡 **MEDIO**: Corregir ChatHistory endpoint
7. 🟡 **MEDIO**: Completar mapeo agentId
8. 🟡 **MEDIO**: Mejorar error handling
9. 🟢 **BAJO**: Optimizar cache LLM
10. 🟢 **BAJO**: Optimizar historial vacío

---

**Última actualización**: 2025-01-XX  
**Estado**: 🔴 **10 PROBLEMAS DETECTADOS - CORRECCIONES PENDIENTES**


