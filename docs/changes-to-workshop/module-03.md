# Module 03: Cloud Run Deployment

In this module, when you first attempt to run `gcloud run deploy`, you may encounter **insufficient permission** issues. This is often because the default Compute Engine service account lacks the necessary roles to perform the deployment and access required services.

To simplify this process, you can copy and paste the following scripts directly into your Cloud Shell.

## Granting Required Permissions

To ensure the workshop runs smoothly, you need to add specific roles to your default compute service account.

### Option 1: Automated Script (Recommended)

Copy and paste this entire block into your Cloud Shell and press **Enter**:

```bash
PROJECT_ID=$(gcloud config get-value project)
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')
DEFAULT_SA="$PROJECT_NUMBER-compute@developer.gserviceaccount.com"

# Enable compute engine API
gcloud services enable compute.googleapis.com

# Download, modify, and upload IAM policy
gcloud projects get-iam-policy $PROJECT_ID --format=json > policy.json

jq --arg sa "serviceAccount:$DEFAULT_SA" '.bindings += [
    {"role": "roles/storage.admin", "members": [$sa]},
    {"role": "roles/logging.logWriter", "members": [$sa]},
    {"role": "roles/artifactregistry.writer", "members": [$sa]},
    {"role": "roles/secretmanager.secretAccessor", "members": [$sa]},
    {"role": "roles/run.admin", "members": [$sa]},
    {"role": "roles/iam.serviceAccountUser", "members": [$sa]},
    {"role": "roles/aiplatform.user", "members": [$sa]},
    {"role": "roles/cloudbuild.workerPoolUser", "members": [$sa]}
]' policy.json > updated_policy.json

gcloud projects set-iam-policy $PROJECT_ID updated_policy.json

# Cleanup
rm policy.json updated_policy.json
```

### Option 2: Manual Configuration

If you prefer to grant roles manually, follow these steps:

1.  Navigate to **IAM & Admin > Service Accounts** in the Google Cloud Console.
2.  Locate the default compute service account, which usually follows the pattern: `xxxxxxxxxxxx-compute@developer.gserviceaccount.com`.
3.  Add the following roles to this service account:
    - **Storage Admin**: For accessing Cloud Storage buckets.
    - **Logs Writer**: For writing application logs.
    - **Artifact Registry Writer**: For pushing container images.
    - **Secret Manager Secret Accessor**: For accessing secrets.
    - **Cloud Run Admin**: For managing Cloud Run services.
    - **Service Account User**: To allow the service account to act as itself.
    - **Vertex AI User**: For AI-related features.
    - **Cloud Build WorkerPool User**: For build operations.

![Default Compute Service Account Roles](../assets/03-default-compute-roles-list.png)

## Deploying to Cloud Run

Once the permissions are set, you can deploy the application to Cloud Run.

Copy and paste this command into your Cloud Shell and press **Enter**:

```bash
gcloud run deploy app-mod-workshop \
   --region asia-southeast3 \
   --allow-unauthenticated \
   --source .
```
