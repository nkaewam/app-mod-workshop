#!/bin/bash
PROJECT_ID=$(gcloud config get-value project)
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')
DEFAULT_SA="$PROJECT_NUMBER-compute@developer.gserviceaccount.com"

# 1. Download the current policy to a temporary file
gcloud projects get-iam-policy $PROJECT_ID --format=json > policy.json

# 2. Add the new bindings to the local JSON file using 'jq'
# This adds all your requested roles to the default compute service account in one go
# ASSUMING: no service account has been assigned any of these roles yet
jq --arg sa "serviceAccount:$DEFAULT_SA" '.bindings += [
    {"role": "roles/storage.admin", "members": [$sa]},
    {"role": "roles/logging.logWriter", "members": [$sa]},
    {"role": "roles/artifactregistry.writer", "members": [$sa]},
    {"role": "roles/secretmanager.secretAccessor", "members": [$sa]},
    {"role": "roles/run.admin", "members": [$sa]},
    {"role": "roles/iam.serviceAccountUser", "members": [$sa]},
    {"role": "roles/aiplatform.user", "members": [$sa]}
]' policy.json > updated_policy.json

# 3. Upload the modified policy back to GCP (The single query)
gcloud projects set-iam-policy $PROJECT_ID updated_policy.json