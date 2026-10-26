#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────
# deploy.sh — Déploiement rapide Jur-gui sur GCP Cloud Run
# Usage: ./deploy.sh [PROJECT_ID] [REGION]
# ──────────────────────────────────────────────────────────────
set -euo pipefail

PROJECT_ID="${1:-$(gcloud config get-value project 2>/dev/null)}"
REGION="${2:-europe-west1}"
SERVICE_NAME="jurgui-api"
IMAGE="gcr.io/${PROJECT_ID}/${SERVICE_NAME}"

echo "🐑 Jur-gui — Déploiement Cloud Run"
echo "   Projet : ${PROJECT_ID}"
echo "   Région : ${REGION}"
echo "   Service: ${SERVICE_NAME}"
echo ""

# 1. Activer les APIs nécessaires
echo "📦 Activation des APIs GCP..."
gcloud services enable \
  cloudbuild.googleapis.com \
  run.googleapis.com \
  secretmanager.googleapis.com \
  containerregistry.googleapis.com \
  --project="${PROJECT_ID}"

# 2. Créer les secrets (si pas encore fait)
echo "🔐 Vérification des secrets..."
if ! gcloud secrets describe jurgui-database-url --project="${PROJECT_ID}" &>/dev/null; then
  echo "   → Création du secret jurgui-database-url"
  echo "   ⚠️  Tu dois y mettre ta DATABASE_URL Neon :"
  echo "   gcloud secrets versions add jurgui-database-url --data-file=- <<< 'postgresql+asyncpg://user:pass@ep-xxx.neon.tech/jurgui_db'"
  gcloud secrets create jurgui-database-url --project="${PROJECT_ID}" --replication-policy="automatic"
fi

if ! gcloud secrets describe jurgui-secret-key --project="${PROJECT_ID}" &>/dev/null; then
  echo "   → Création du secret jurgui-secret-key"
  SECRET=$(python3 -c "import secrets; print(secrets.token_urlsafe(64))")
  printf '%s' "${SECRET}" | gcloud secrets create jurgui-secret-key \
    --project="${PROJECT_ID}" \
    --replication-policy="automatic" \
    --data-file=-
  echo "   ✅ SECRET_KEY générée automatiquement"
fi

# 3. Build & Push
echo "🐳 Build de l'image Docker..."
docker build -t "${IMAGE}:latest" -f backend/Dockerfile backend

echo "📤 Push vers Container Registry..."
docker push "${IMAGE}:latest"

# 4. Deploy to Cloud Run
echo "🚀 Déploiement sur Cloud Run..."
gcloud run deploy "${SERVICE_NAME}" \
  --image "${IMAGE}:latest" \
  --region "${REGION}" \
  --platform managed \
  --allow-unauthenticated \
  --set-env-vars "ENVIRONMENT=production,DATABASE_SSL=true,ALLOWED_ORIGINS=*" \
  --set-secrets "DATABASE_URL=jurgui-database-url:latest,SECRET_KEY=jurgui-secret-key:latest" \
  --memory 512Mi \
  --cpu 1 \
  --min-instances 0 \
  --max-instances 3 \
  --port 8080 \
  --project="${PROJECT_ID}"

# 5. Récupérer l'URL
URL=$(gcloud run services describe "${SERVICE_NAME}" \
  --region="${REGION}" \
  --project="${PROJECT_ID}" \
  --format="value(status.url)")

echo ""
echo "═══════════════════════════════════════════════════"
echo "✅ Jur-gui déployé avec succès !"
echo "   🌐 URL: ${URL}"
echo "   📋 Health: ${URL}/health"
echo "   📖 Docs:   ${URL}/docs"
echo "═══════════════════════════════════════════════════"
