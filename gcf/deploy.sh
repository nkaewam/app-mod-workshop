#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Core deployment configuration
FUNCTION_REGION="asia-southeast3"
FUNCTION_NAME="app-mod-generate-caption"
TRIGGER_REGION="asia-southeast1"
ENTRY_POINT="generate_caption"
MEMORY_LIMIT="512Mi"
# Note: gcloud run deploy detects the runtime from source (e.g., requirements.txt). 
# To strictly enforce Python 3.11, ensure a .python-version file exists or use build-env-vars if supported.

# Automatically get the current project ID
PROJECT_ID=$(gcloud config get-value project)
if [ -z "$PROJECT_ID" ]; then
    echo "Error: Could not determine PROJECT_ID. Please run 'gcloud config set project YOUR_PROJECT_ID'"
    exit 1
fi

PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)')
SERVICE_ACCOUNT="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"

# Storage Bucket Configuration 
BUCKET_NAME="gcp-app-mod-workshop-public-images"

# Database Configuration 
DB_USER="app_user"
DB_PASS_SECRET="APP_MOD_WORKSHOP_DB_PASS"
DB_HOST="34.15.154.21"
DB_NAME="app_db"

echo "========================================================="
echo "🚀 Deploying Cloud Run Service: $FUNCTION_NAME"
echo "📦 Project: $PROJECT_ID"
echo "🌍 Region: $REGION"
echo "========================================================="

# 1. Deploy the Cloud Run Service
# We use --function to specify the entry point for the Function Buildpack.
# We explicitly allow no unauthenticated invocations (Eventarc handles auth).
gcloud run deploy "$FUNCTION_NAME" \
  --source="." \
  --function="$ENTRY_POINT" \
  --region="$FUNCTION_REGION" \
  --memory="$MEMORY_LIMIT" \
  --set-env-vars="DB_USER=$DB_USER,DB_HOST=$DB_HOST,DB_NAME=$DB_NAME" \
  --set-secrets="DB_PASS=${DB_PASS_SECRET}:latest" \
  --service-account="$SERVICE_ACCOUNT" \
  --no-allow-unauthenticated

echo "✅ Service deployed. Configuring permissions..."

# 2. Grant Invoker Permissions
# Eventarc uses the service account identity to invoke the Cloud Run service.
# We must ensure that SA has the 'roles/run.invoker' role on this specific service.
gcloud run services add-iam-policy-binding "$FUNCTION_NAME" \
  --region="$FUNCTION_REGION" \
  --member="serviceAccount:$SERVICE_ACCOUNT" \
  --role="roles/run.invoker"

echo "✅ Permissions granted. Configuring Trigger..."

# 3. Create Eventarc Trigger
# We check if the trigger exists first to avoid errors on re-runs.
TRIGGER_NAME="${FUNCTION_NAME}-trigger"

if gcloud eventarc triggers describe "$TRIGGER_NAME" --location="$TRIGGER_REGION" &>/dev/null; then
    echo "⚠️  Trigger '$TRIGGER_NAME' already exists. Skipping creation."
else
    echo "🔗 Creating Eventarc Trigger: $TRIGGER_NAME"
    gcloud eventarc triggers create "$TRIGGER_NAME" \
      --location="$TRIGGER_REGION" \
      --destination-run-service="$FUNCTION_NAME" \
      --destination-run-region="$FUNCTION_REGION" \
      --event-filters="type=google.cloud.storage.object.v1.finalized" \
      --event-filters="bucket=$BUCKET_NAME" \
      --service-account="$SERVICE_ACCOUNT"
    
    echo "✅ Trigger created successfully!"
fi

echo ""
echo "🎉 Deployment Complete!"