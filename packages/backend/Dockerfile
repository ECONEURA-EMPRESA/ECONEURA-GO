# Multi-stage Dockerfile for Backend
# Optimized for production builds

# Stage 1: Dependencies
FROM node:20-alpine AS deps
WORKDIR /app

# Copy package files
COPY package*.json ./
COPY packages/backend/package*.json ./packages/backend/

# Install dependencies
RUN npm ci --workspace=@econeura/backend --legacy-peer-deps

# Stage 2: Builder
FROM node:20-alpine AS builder
WORKDIR /app

# Copy dependencies from deps stage
COPY --from=deps /app/node_modules ./node_modules
COPY --from=deps /app/packages/backend/node_modules ./packages/backend/node_modules

# Copy source code
COPY packages/backend ./packages/backend
COPY packages/config ./packages/config
COPY tsconfig.base.json ./

# Build
WORKDIR /app/packages/backend
RUN npm run build

# Stage 3: Runner
FROM node:20-alpine AS runner
WORKDIR /app

# Create non-root user
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 backend

# Copy built app and dependencies
COPY --from=builder --chown=backend:nodejs /app/packages/backend/dist ./dist
COPY --from=deps --chown=backend:nodejs /app/packages/backend/node_modules ./node_modules
COPY --from=builder --chown=backend:nodejs /app/packages/backend/package.json ./

# Set environment
ENV NODE_ENV=production
ENV PORT=3000

USER backend

EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD node -e "require('http').get('http://localhost:3000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

CMD ["node", "dist/index.js"]
