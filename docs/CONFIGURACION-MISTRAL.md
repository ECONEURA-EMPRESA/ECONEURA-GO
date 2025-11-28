# 🔧 CONFIGURACIÓN MISTRAL 3.1 PARA NEURAS

**Fecha**: Enero 2025  
**Estado**: ✅ Configurado y listo

---

## 📋 PASO 1: Configurar API Key

### **1. Agregar la clave al archivo `.env`:**

```powershell
cd C:\Users\Usuario\ECONEURA-FULL\packages\backend
```

Abre el archivo `.env` (o créalo si no existe) y agrega:

```env
MISTRAL_API_KEY=[REDACTED]
```

### **2. Verificar que el archivo `.env` NO se suba a Git:**

El archivo `.env` debe estar en `.gitignore`. Verifica:

```powershell
# Verificar que .env está en .gitignore
Get-Content .gitignore | Select-String "\.env"
```

Si no aparece, agrega esta línea a `.gitignore`:
```
.env
```

---

## ✅ PASO 2: Reiniciar Backend

### **1. Detener el backend actual:**
- Presiona `Ctrl+C` en la terminal donde está corriendo el backend

### **2. Reiniciar el backend:**
```powershell
cd C:\Users\Usuario\ECONEURA-FULL\packages\backend
npm run dev
```

### **3. Verificar que arrancó correctamente:**
Deberías ver:
```
✅ ECONEURA backend escuchando en el puerto 3000
```

**⚠️ Si ves un error sobre `MISTRAL_API_KEY no configurada`:**
- Verifica que el archivo `.env` existe en `packages/backend/`
- Verifica que la clave está correctamente escrita (sin espacios extra)
- Reinicia el backend

---

## 🎯 PASO 3: Verificar que Funciona

### **1. Probar un agente NEURA:**

Abre el frontend en http://localhost:5174 y:
1. Inicia sesión
2. Ve a cualquier departamento (ej: Marketing y Ventas)
3. Haz clic en un agente NEURA (ej: NEURA CMO)
4. Envía un mensaje de prueba

### **2. Verificar logs del backend:**

En la terminal del backend deberías ver logs como:
```
[MistralAdapter] Generando respuesta con modelo: mistral-large-latest
```

Si ves errores, revisa:
- Que la API key sea correcta
- Que tengas conexión a internet
- Que la API de Mistral esté disponible

---

## 📊 MODELOS CONFIGURADOS

Los agentes NEURA están configurados con los siguientes modelos de Mistral:

| Agente | Modelo | Provider |
|--------|--------|----------|
| NEURA CEO | `mistral-large-latest` | Mistral |
| NEURA CTO | `mistral-large-latest` | Mistral |
| NEURA CFO | `mistral-medium-latest` | Mistral |
| NEURA CMO | `mistral-medium-latest` | Mistral |
| NEURA Ventas | `mistral-medium-latest` | Mistral |
| NEURA Atención Cliente | `mistral-medium-latest` | Mistral |
| NEURA RRHH | `mistral-medium-latest` | Mistral |
| NEURA Operaciones | `mistral-medium-latest` | Mistral |
| NEURA Legal | `mistral-medium-latest` | Mistral |
| NEURA Datos | `mistral-medium-latest` | Mistral |
| NEURA Innovación | `mistral-large-latest` | Mistral |

---

## 🔒 SEGURIDAD

**⚠️ IMPORTANTE:**
- **NUNCA** subas el archivo `.env` a Git
- **NUNCA** compartas tu API key públicamente
- **NUNCA** hardcodees la API key en el código
- La API key está configurada como variable de entorno y se lee desde `.env`

---

## 🚨 TROUBLESHOOTING

### **Error: "MISTRAL_API_KEY no configurada"**
- Verifica que el archivo `.env` existe en `packages/backend/`
- Verifica que la línea `MISTRAL_API_KEY=...` está presente
- Reinicia el backend después de agregar la clave

### **Error: "Mistral API error: 401 Unauthorized"**
- Verifica que la API key sea correcta
- Verifica que la API key no haya expirado
- Obtén una nueva clave en https://console.mistral.ai/

### **Error: "Mistral API error: 429 Too Many Requests"**
- Has excedido el límite de rate limiting de tu plan
- Espera unos minutos antes de volver a intentar
- Considera actualizar tu plan en Mistral

### **Los agentes no responden**
- Verifica los logs del backend para ver errores específicos
- Verifica que el frontend esté conectado al backend correcto
- Verifica que la conexión a internet funcione

---

## ✅ VERIFICACIÓN FINAL

Después de configurar, verifica:

- [ ] ✅ Archivo `.env` creado en `packages/backend/`
- [ ] ✅ `MISTRAL_API_KEY` configurada correctamente
- [ ] ✅ Backend reiniciado sin errores
- [ ] ✅ Frontend puede comunicarse con los agentes
- [ ] ✅ Los agentes NEURA responden correctamente
- [ ] ✅ `.env` está en `.gitignore` (no se subirá a Git)

---

## 🎯 ESTADO

**✅ MISTRAL 3.1 CONFIGURADO Y LISTO PARA USAR**

Todos los agentes NEURA están ahora usando Mistral 3.1 como proveedor de IA.


