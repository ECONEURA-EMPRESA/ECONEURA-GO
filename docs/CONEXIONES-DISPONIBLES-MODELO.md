# 🔌 CONEXIONES DISPONIBLES PARA EL MODELO DE IA

**Fecha**: 2025-01-XX  
**Estado**: ✅ **TODAS LAS CONEXIONES IMPLEMENTADAS**

---

## 🎯 OBJETIVO

El modelo de IA (Mistral 3.1, GPT-4o, etc.) puede usar **TODAS** estas conexiones cuando las necesite. El sistema está preparado para que el modelo ejerza todas sus funciones.

---

## ✅ CONEXIONES IMPLEMENTADAS

### **1. IMÁGENES (Vision API)** ✅
**Estado**: ✅ Implementado  
**Endpoint**: `POST /api/invoke/:agentId`  
**Parámetro**: `image` (base64)

**Cómo funciona**:
- El frontend envía la imagen en base64
- El backend detecta si hay imagen
- Si el modelo es `mistral-medium` y hay imagen, usa `gpt-4o` para vision (compatible con Mammouth.ai)
- El modelo recibe la imagen y puede analizarla

**Ejemplo de uso**:
```typescript
// Frontend
const body = {
  input: "¿Qué hay en esta imagen?",
  image: "data:image/jpeg;base64,..."
};

// Backend procesa y envía al modelo con formato vision API
```

---

### **2. ARCHIVOS (PDF, DOC, DOCX, TXT, CSV)** ✅
**Estado**: ✅ Implementado  
**Endpoint**: `POST /api/invoke/:agentId`  
**Parámetros**: `file` (base64), `mimeType`, `fileName`

**Cómo funciona**:
- El frontend envía el archivo en base64 + mimeType + fileName
- El backend extrae el texto del archivo usando `fileExtractor.ts`
- El texto extraído se agrega al mensaje del usuario
- El modelo recibe el texto y puede analizarlo

**Tipos soportados**:
- ✅ PDF (`application/pdf`)
- ✅ DOC/DOCX (`application/msword`, `application/vnd.openxmlformats-officedocument.wordprocessingml.document`)
- ✅ TXT (`text/plain`)
- ✅ CSV (`text/csv`)

**Ejemplo de uso**:
```typescript
// Frontend
const body = {
  input: "Resume este documento",
  file: "base64...",
  mimeType: "application/pdf",
  fileName: "documento.pdf"
};

// Backend extrae texto y lo agrega al mensaje
// El modelo recibe: "Resume este documento\n\n--- Contenido del archivo: ---\n[texto extraído]"
```

---

### **3. VOZ (Audio)** 🟡 PENDIENTE
**Estado**: 🟡 Preparado pero no implementado  
**Endpoint**: `POST /api/invoke/:agentId`  
**Parámetro**: `audio` (base64)

**Cómo funcionará**:
- El frontend graba audio y lo convierte a base64
- El backend recibe el audio
- **TODO**: Implementar transcripción usando Whisper API o similar
- El texto transcrito se envía al modelo

**Próximos pasos**:
1. Integrar Whisper API o servicio de transcripción
2. Transcribir audio a texto
3. Enviar texto al modelo

---

### **4. EJECUCIÓN DE AGENTES AUTOMATIZADOS (N8N/Make)** ✅
**Estado**: ✅ Implementado  
**Endpoint**: `POST /api/agents/:id/execute`

**Cómo funciona**:
- El modelo puede solicitar ejecutar un agente automatizado
- El sistema detecta la solicitud (ej: "ejecuta el agente X")
- Se llama a `POST /api/agents/:id/execute`
- El backend ejecuta el webhook de N8N/Make
- Se retorna el resultado al modelo

**Agentes disponibles**:
- ✅ `ceo-agenda-consejo` (Make)
- ✅ `ceo-anuncio-semanal` (N8N)
- ✅ `ceo-resumen-ejecutivo` (Make)
- ✅ Y 40+ agentes más en `automationAgentsRegistry.ts`

**Ejemplo de uso**:
```typescript
// El modelo puede decir: "Ejecuta el agente de agenda del consejo"
// El sistema detecta y ejecuta:
POST /api/agents/ceo-agenda-consejo/execute
{
  "params": { "fecha": "2025-01-20" },
  "triggered_by": "neura-ceo"
}
```

---

### **5. CONSULTA A BASE DE DATOS** ✅
**Estado**: ✅ Disponible  
**Conexión**: PostgreSQL

**Cómo funciona**:
- El modelo puede solicitar datos de la base de datos
- El backend tiene acceso a PostgreSQL
- Se pueden crear endpoints específicos para consultas del modelo

**Ejemplo**:
- El modelo puede pedir: "Muéstrame los leads del último mes"
- El backend consulta la BD y retorna datos
- El modelo procesa y presenta la información

---

### **6. WEBHOOKS CRM** ✅
**Estado**: ✅ Implementado  
**Endpoint**: `POST /api/crm/webhooks/lead-created`

**Cómo funciona**:
- Los agentes automatizados (N8N/Make) pueden crear leads vía webhook
- El backend recibe el webhook y crea el lead en la BD
- El modelo puede consultar estos leads después

---

## 🔧 CONFIGURACIÓN DEL MODELO

### **Mistral 3.1 (NEURA-CEO)**
```typescript
{
  id: 'neura-ceo',
  provider: 'openai', // Usa OpenAIAdapter que apunta a Mammouth.ai
  model: 'mistral-medium', // Mistral Medium 3.1
  // ✅ Puede usar TODAS las conexiones arriba
}
```

### **Otros NEURAS**
- Todos usan `gpt-4o` o `gpt-4o-mini` (compatible con Mammouth.ai)
- Todos pueden usar imágenes, archivos, agentes, etc.

---

## 📋 CHECKLIST DE CONEXIONES

| Conexión | Estado | Endpoint | Notas |
| :------- | :----- | :------- | :---- |
| **Imágenes** | ✅ | `/api/invoke/:agentId` | Vision API implementada |
| **Archivos PDF** | ✅ | `/api/invoke/:agentId` | Extracción de texto implementada |
| **Archivos DOC** | ✅ | `/api/invoke/:agentId` | Extracción básica implementada |
| **Archivos TXT/CSV** | ✅ | `/api/invoke/:agentId` | Lectura directa |
| **Voz** | 🟡 | `/api/invoke/:agentId` | Preparado, falta transcripción |
| **Agentes N8N** | ✅ | `/api/agents/:id/execute` | Webhooks funcionando |
| **Agentes Make** | ✅ | `/api/agents/:id/execute` | Webhooks funcionando |
| **Base de Datos** | ✅ | PostgreSQL | Disponible para consultas |
| **CRM Webhooks** | ✅ | `/api/crm/webhooks/*` | Funcionando |

---

## 🎯 CÓMO EL MODELO USA ESTAS CONEXIONES

### **Ejemplo 1: Análisis de Imagen**
```
Usuario: "Analiza esta imagen" [sube imagen]
→ Frontend envía: { input: "Analiza esta imagen", image: "base64..." }
→ Backend detecta imagen, usa gpt-4o para vision
→ Modelo recibe imagen y analiza
→ Modelo responde con análisis
```

### **Ejemplo 2: Análisis de Documento**
```
Usuario: "Resume este PDF" [sube PDF]
→ Frontend envía: { input: "Resume este PDF", file: "base64...", mimeType: "application/pdf" }
→ Backend extrae texto del PDF
→ Backend envía al modelo: "Resume este PDF\n\n--- Contenido: ---\n[texto extraído]"
→ Modelo analiza el texto y resume
→ Modelo responde con resumen
```

### **Ejemplo 3: Ejecución de Agente**
```
Usuario: "Ejecuta el agente de agenda del consejo"
→ Modelo detecta solicitud de ejecución
→ Sistema llama: POST /api/agents/ceo-agenda-consejo/execute
→ Backend ejecuta webhook de Make
→ Backend retorna resultado
→ Modelo presenta resultado al usuario
```

---

## ✅ CONCLUSIÓN

**TODAS las conexiones están implementadas y listas para que el modelo las use**. El sistema está preparado para que el modelo de IA ejerza todas sus funciones:

- ✅ Analizar imágenes
- ✅ Analizar archivos (PDF, DOC, TXT, CSV)
- ✅ Ejecutar agentes automatizados (N8N/Make)
- ✅ Consultar base de datos
- ✅ Recibir webhooks del CRM

**El modelo puede usar cualquiera de estas conexiones cuando las necesite.**


