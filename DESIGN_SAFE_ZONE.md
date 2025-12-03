# 🎨 ZONA SEGURA: Cambios de Diseño (LOGIN + COCKPIT)

**Objetivo**: Modificar solo estilos visuales sin romper funcionalidad

---

## ✅ ARCHIVOS SEGUROS PARA EDITAR

### 🎨 Estilos CSS (100% Seguro)
```
packages/frontend/src/index.css
packages/frontend/src/App.css
```
**Qué puedes cambiar**:
- Colores, gradientes, backgrounds
- Tamaños de fuente, padding, margins
- Animaciones, transiciones
- Sombras, bordes, opacidades

### 🖼️ Componentes Visuales (Seguro si solo tocas JSX/estilos)
```
packages/frontend/src/components/Login.tsx          # LOGIN form
packages/frontend/src/EconeuraCockpit.tsx           # COCKPIT principal
packages/frontend/src/components/CockpitHeader.tsx  # Header del cockpit
packages/frontend/src/components/EconeuraSidebar.tsx # Sidebar
```

**Regla de Oro**: Solo modifica:
- `style={{ ... }}` en JSX
- `className="..."`
- Texto visible (spans, labels, headings)
- Colores hardcodeados

**NO TOQUES**:
- `onClick={...}`
- `onChange={...}`
- `useState`, `useEffect`
- Imports de hooks o funciones

---

## ❌ ARCHIVOS PROHIBIDOS (NO TOCAR)

### 🚫 Backend (Riesgo Alto)
```
packages/backend/src/**/*.ts          # TODO el backend
.github/workflows/deploy.yml          # Deployment config
packages/backend/src/routes/health.ts # Health checks
```

### 🚫 Schemas y Validación (Riesgo Alto)
```
packages/backend/src/api/http/routes/agentsRoutes.ts
packages/backend/src/infra/automation/*.ts
Cualquier archivo con z.object() o z.record()
```

### 🚫 Hooks y Lógica Frontend (Riesgo Medio)
```
packages/frontend/src/hooks/*.ts      # useAuth, useChat, etc.
packages/frontend/src/contexts/*.tsx  # AuthContext, etc.
packages/frontend/src/services/*.ts   # API calls
```

---

## 🔄 Workflow Seguro para Cambios de Diseño

### 1. Antes de Empezar
```bash
# Verifica que estés en estado limpio
git status

# Crea rama de diseño
git checkout -b design/login-cockpit-improvements
```

### 2. Hacer Cambios
- Abre solo archivos de la ZONA SEGURA
- Modifica estilos, colores, textos
- Guarda cambios

### 3. Verificación Rápida (1 minuto)
```bash
# Verifica que NO rompiste TypeScript
npx turbo run type-check --filter=@econeura/web...

# Si sale OK (0 errors), estás bien
# Si sale ERROR, revierte tus cambios
```

### 4. Commit y Push
```bash
git add packages/frontend/src
git commit -m "design: mejorar estilos de LOGIN [solo diseño]"
git push origin design/login-cockpit-improvements
```

---

## 🛡️ Protecciones Automáticas

### Checklist Pre-Commit
Antes de hacer `git commit`, ejecuta:
```bash
npx turbo run type-check --filter=@econeura/web...
```

**Regla**: Si falla, NO hagas commit. Revierte cambios.

### Verificación de "Solo Diseño"
```bash
# Muestra qué archivos cambiaste
git diff --name-only

# DEBE mostrar solo archivos de packages/frontend/src
# Si ves archivos de backend/, workflows/, o routes/, ¡PARA!
```

---

## 🎯 Ejemplos de Cambios Seguros

### ✅ Cambiar Color del Botón de Login
```tsx
// Login.tsx - SEGURO
<button
  style={{
    background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)', // ✅ OK
    padding: '12px 24px', // ✅ OK
    borderRadius: '8px'    // ✅ OK
  }}
  onClick={handleLogin} // ❌ NO TOCAR ESTO
>
  Iniciar Sesión
</button>
```

### ✅ Cambiar Colores del Cockpit
```tsx
// EconeuraCockpit.tsx - SEGURO
<div
  style={{
    backgroundColor: '#1a1a2e', // ✅ OK
    color: '#eaeaea'            // ✅ OK
  }}
>
  {/* Contenido */}
</div>
```

### ❌ NUNCA Hagas Esto
```tsx
// ❌ MAL - Modificar lógica
const [user, setUser] = useState(null); // ❌ NO TOCAR
useEffect(() => { ... }); // ❌ NO TOCAR

// ❌ MAL - Modificar validación
const schema = z.object({ ... }); // ❌ NO TOCAR
```

---

## 🚨 Si Algo Se Rompe

### Revertir Cambios Inmediatamente
```bash
# Deshacer todos los cambios no commiteados
git restore .

# O volver al último commit
git reset --hard HEAD
```

### Volver al Milestone
```bash
# Si rompiste algo y lo commiteaste
git checkout v1.0.0-working-login
git checkout -b restore-design
```

---

## 📋 Checklist Diaria

Antes de terminar tu sesión de diseño:

- [ ] `git diff --name-only` → Solo archivos frontend/src
- [ ] `npx turbo run type-check --filter=@econeura/web...` → 0 errors
- [ ] econeura.com sigue mostrando LOGIN correctamente
- [ ] No modifiqué ningún archivo de backend/
- [ ] No toqué useState, useEffect, o funciones onClick

---

**Recuerda**: Si solo cambias estilos en CSS o JSX (colores, tamaños, textos), es IMPOSIBLE romper el backend.

_Diseña con confianza, verifica antes de commit._ 🎨
