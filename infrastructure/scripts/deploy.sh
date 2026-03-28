#!/bin/bash
# ══════════════════════════════════════════════════════════════════════
# Fiers Artisans — Script de déploiement
# ══════════════════════════════════════════════════════════════════════

set -euo pipefail

echo "🚀 Déploiement Fiers Artisans..."

cd /opt/fierartisans

# Pull les dernières images
echo "📦 Pull des images..."
docker compose -f infrastructure/docker-compose.yml pull

# Build le backend
echo "🔨 Build du backend..."
docker compose -f infrastructure/docker-compose.yml build api

# Restart avec zero-downtime (rolling)
echo "🔄 Restart des services..."
docker compose -f infrastructure/docker-compose.yml up -d --no-deps api

# Cleanup
echo "🧹 Nettoyage des anciennes images..."
docker image prune -f

echo "✅ Déploiement terminé !"
docker compose -f infrastructure/docker-compose.yml ps
