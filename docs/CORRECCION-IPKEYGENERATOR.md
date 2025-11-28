# ✅ CORRECCIÓN - ipKeyGenerator IPv6

## 🔧 PROBLEMA RESUELTO

**Error:**
```
ValidationError: Custom keyGenerator appears to use request IP without calling the ipKeyGenerator helper function for IPv6 addresses.
```

**Causa:**
- `ipKeyGenerator` espera un `string` (IP), no el `Request` completo
- Uso incorrecto: `ipKeyGenerator(req)` ❌
- Uso correcto: `ipKeyGenerator(req.ip)` ✅

---

## ✅ SOLUCIÓN APLICADA

### Archivos corregidos:

1. **`packages/backend/src/api/http/middleware/rateLimiter.ts`**
   ```typescript
   // ANTES (❌)
   return `ip:${ipKeyGenerator(req)}`;
   
   // DESPUÉS (✅)
   const ip = req.ip ?? req.socket.remoteAddress ?? 'unknown';
   return `ip:${ipKeyGenerator(ip)}`;
   ```

2. **`packages/backend/src/api/http/middleware/userRateLimiter.ts`**
   ```typescript
   // ANTES (❌)
   return `rl:ip:${ipKeyGenerator(req)}`;
   
   // DESPUÉS (✅)
   const ip = req.ip ?? req.socket.remoteAddress ?? 'unknown';
   return `rl:ip:${ipKeyGenerator(ip)}`;
   ```

---

## 📚 DOCUMENTACIÓN

Según `express-rate-limit` v8.2.1:
- `ipKeyGenerator(ip: string, ipv6Subnet?: number | false): string`
- **Parámetro:** `ip` (string) - La dirección IP, usualmente `req.ip`
- **Retorna:** string - La key generada desde la IP

**Uso correcto:**
```typescript
import { ipKeyGenerator } from 'express-rate-limit';

keyGenerator: (req) => {
  const ip = req.ip ?? 'unknown';
  return `ip:${ipKeyGenerator(ip)}`;
}
```

---

## ✅ VERIFICACIÓN

```powershell
npm run build      # ✅ Compila sin errores
npm run type-check # ✅ Sin errores TypeScript
npm run dev        # ✅ Servidor inicia sin errores de validación
```

---

**Estado:** ✅ **RESUELTO**

