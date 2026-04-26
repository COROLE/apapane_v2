# Production Backend Deployment

Use the GitHub Actions workflow `Deploy Public Backend` for production Firebase updates.

## Required GitHub Secret

- `FIREBASE_DEPLOY_SERVICE_ACCOUNT_JSON`

This secret must contain the full JSON for a service account that can deploy:

- Firestore rules and indexes
- Cloud Storage rules
- Cloud Functions

## Before Running The Workflow

- Confirm the target Firebase project is `apapane-94356`
- Confirm Functions secrets already exist in the Firebase project:
  - `GEMINI_API_KEY`
  - `OPENAI_API_KEY`
  - `PLAY_SERVICE_ACCOUNT_JSON`
  - `APPLE_SHARED_SECRET`
- Confirm the latest `Validate` workflow has passed

## Deployment Scope

The workflow deploys:

- `firestore:rules`
- `firestore:indexes`
- `storage`
- `functions`

## After Deployment

- Verify `generateStory`, `generateImage`, `generateImageHttp`, and `synthesizeVoice` from a release candidate build
- Verify purchase verification and account deletion still succeed
- Record the workflow run URL in the release notes or launch ticket
