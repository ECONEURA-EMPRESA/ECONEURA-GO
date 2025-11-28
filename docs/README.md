# 📚 Documentación ECONEURA-FULL

**Versión**: 2025  
**Última actualización**: Enero 2025

---

## 🎯 Índice Rápido

### **Documentación Actual (Activa)**

- **[Arquitectura](architecture/)** - Arquitectura del sistema, dominios, modelos
- **[API Reference](api/)** - Referencia completa de la API
- **[Deployment](deployment/)** - Guías de despliegue, CI/CD, Azure
- **[CRM](crm/)** - Documentación del CRM Premium (Panel de Gestión)
- **[Operations](operations/)** - Operaciones, monitoreo, métricas
- **[Development](development/)** - Guías de desarrollo, testing, troubleshooting
- **[Milestones](milestones/)** - Hitos y logros del proyecto

### **Documentación Histórica**

- **[Archive](archive/)** - Documentos históricos (migraciones, procesos, fases completadas)

---

## 📖 Guías Principales

### **Para Desarrolladores**

1. **¿Cómo empezar?** → Ver [Development/README.md](development/README.md)
2. **¿Arquitectura?** → Ver [Architecture/ARCHITECTURE.md](architecture/ARCHITECTURE.md)
3. **¿API?** → Ver [API/API-REFERENCE.md](api/API-REFERENCE.md)
4. **¿Testing?** → Ver [Development/TESTING-STRATEGY.md](development/TESTING-STRATEGY.md)
5. **¿Problemas?** → Ver [Development/TROUBLESHOOTING-GUIA-COMPLETA.md](development/TROUBLESHOOTING-GUIA-COMPLETA.md)

### **Para DevOps**

1. **¿Cómo desplegar?** → Ver [Deployment/README.md](deployment/README.md)
2. **¿Azure?** → Ver [Deployment/AZURE-INFRA.md](deployment/AZURE-INFRA.md)
3. **¿CI/CD?** → Ver [Deployment/CI-CD.md](deployment/CI-CD.md)
4. **¿GitHub?** → Ver [Deployment/GITHUB_SETUP_GUIDE.md](deployment/GITHUB_SETUP_GUIDE.md)
5. **¿Monitoreo?** → Ver [Operations/PERFORMANCE-MONITORING.md](operations/PERFORMANCE-MONITORING.md)

### **Para Product Managers**

1. **¿CRM?** → Ver [CRM/PANEL-DIFERENCIADOR-ECONEURA.md](crm/PANEL-DIFERENCIADOR-ECONEURA.md)
2. **¿Estrategia?** → Ver [CRM/ESTRATEGIA-PANEL-GESTION-10-10.md](crm/ESTRATEGIA-PANEL-GESTION-10-10.md)
3. **¿Hitos?** → Ver [Milestones/](milestones/)

---

## 🏗️ Estructura de Documentación

```
docs/
├── architecture/          # Arquitectura del sistema
│   ├── ARCHITECTURE.md
│   ├── DOMAIN-NEURAS.md
│   └── RBAC-MODEL.md
├── api/                  # Referencia de API
│   └── API-REFERENCE.md
├── deployment/            # Deployment y CI/CD
│   ├── AZURE-INFRA.md
│   ├── CI-CD.md
│   ├── GITHUB_SETUP_GUIDE.md
│   └── GITHUB_WORKFLOWS_REFERENCE.md
├── crm/                  # CRM Premium (ACTUAL)
│   ├── PANEL-DIFERENCIADOR-ECONEURA.md
│   ├── ESTRATEGIA-PANEL-GESTION-10-10.md
│   ├── CONFIGURACION-AGENTES-N8N.md
│   ├── CRM-PRODUCCION-READY.md
│   ├── EVALUACION-CRM-9.2-10-PLAN-ACCION.md
│   └── archive/
│       └── process/      # Documentos históricos del CRM
├── operations/           # Operaciones y monitoreo
│   ├── OPERATIONS.md
│   ├── PERFORMANCE-MONITORING.md
│   └── KUSTO-QUERIES.md
├── development/          # Desarrollo
│   ├── TESTING-STRATEGY.md
│   └── TROUBLESHOOTING-GUIA-COMPLETA.md
├── milestones/           # Hitos del proyecto
│   ├── HITO-2025-01-XX-CRM-PANEL-GESTION-AGENTES.md
│   └── HITO-2025-11-16-SOLUCIONES-PREVENTIVAS-COMPLETAS.md
└── archive/               # Documentación histórica
    ├── migration/        # Logs de migración
    ├── process/          # Procesos internos (autocríticas, correcciones)
    ├── commands/          # Comandos históricos
    ├── deployment-history/ # Historial de despliegues
    └── phases/           # Fases completadas
```

---

## 🔍 Búsqueda Rápida

| Necesito... | Ve a... |
|------------|---------|
| Entender la arquitectura | [Architecture/ARCHITECTURE.md](architecture/ARCHITECTURE.md) |
| Ver endpoints de API | [API/API-REFERENCE.md](api/API-REFERENCE.md) |
| Desplegar en Azure | [Deployment/AZURE-INFRA.md](deployment/AZURE-INFRA.md) |
| Configurar CI/CD | [Deployment/CI-CD.md](deployment/CI-CD.md) |
| Entender el CRM | [CRM/PANEL-DIFERENCIADOR-ECONEURA.md](crm/PANEL-DIFERENCIADOR-ECONEURA.md) |
| Configurar agentes N8N | [CRM/CONFIGURACION-AGENTES-N8N.md](crm/CONFIGURACION-AGENTES-N8N.md) |
| Ver hitos recientes | [Milestones/](milestones/) |
| Resolver problemas | [Development/TROUBLESHOOTING-GUIA-COMPLETA.md](development/TROUBLESHOOTING-GUIA-COMPLETA.md) |
| Ver métricas | [Operations/PERFORMANCE-MONITORING.md](operations/PERFORMANCE-MONITORING.md) |

---

## 📝 Notas

- **Documentación actual**: Está en las carpetas principales (architecture, api, deployment, crm, etc.)
- **Documentación histórica**: Está en `archive/` (no se elimina, solo se archiva)
- **Hitos importantes**: Están en `milestones/` (trabajo actual y logros)

---

**Última reorganización**: Enero 2025  
**Estado**: ✅ Organizada y navegable
