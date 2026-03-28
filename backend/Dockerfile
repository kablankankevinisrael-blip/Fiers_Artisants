# ══════════════════════════════════════════════════════════════════════
# Fiers Artisans — Backend Dockerfile (Multi-stage)
# ══════════════════════════════════════════════════════════════════════

# ── Stage 1 : Development ────────────────────────────────────────────
FROM node:20-alpine AS development

WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .

# ── Stage 2 : Build ─────────────────────────────────────────────────
FROM development AS build
RUN npm run build

# ── Stage 3 : Production ────────────────────────────────────────────
FROM node:20-alpine AS production

WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force
COPY --from=build /app/dist ./dist

EXPOSE 3000
CMD ["node", "dist/main.js"]
