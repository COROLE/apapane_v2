# Agent Notes

Operational notes for future agents working in this repository. Treat the
release docs under `docs/` as the source of truth; this file is a fast handoff
for deployment state, blockers, and commands.

## Deployment Overview

- Flutter app deployment uses GitHub Actions `Deploy Internal` for TestFlight
  and Google Play internal testing.
- Firebase backend deployment targets project `apapane-94356` and includes:
  Firestore rules/indexes, Storage rules, and Cloud Functions.
- Do not treat a TestFlight upload as a complete release when backend APIs or
  rules changed. The selectable story mode work adds new callable functions and
  Firestore rules, so the Firebase backend must be deployed too.
- Existing store product IDs must stay unchanged: `consumable` and
  `silver_subscription`.

## Useful Docs

- Internal/TestFlight/Play: `docs/internal-deployment.md`
- Production backend: `docs/production-backend-deployment.md`
- Public release checklist: `docs/public-release.md`
- Store smoke checklist: `docs/internal-smoke-checklist.md`

## Standard Verification Commands

Run these whenever possible after code changes:

```powershell
flutter analyze --no-fatal-warnings --no-fatal-infos
flutter test
npm --prefix functions run lint
npm --prefix functions test
```

For the story mode / preview / Silver credit refactor, all four commands passed.

## TestFlight Deployment

Use GitHub Actions `Deploy Internal`.

```powershell
gh run list --workflow "Deploy Internal" --limit 5
gh run view <run-id> --json status,conclusion,url,jobs
gh run view <run-id> --log-failed
```

Observed result on 2026-04-28 JST:

- Branch: `codex/ios-actions-check`
- Commit: `d9ac92f Add selectable story generation modes`
- Run: `25027934506`
- URL: `https://github.com/COROLE/apapane_v2/actions/runs/25027934506`
- Result: success
- The `iOS TestFlight` job completed through `Upload to TestFlight`.
- `Android Internal` was skipped for that branch push.

Notes:

- iOS builds run on a macOS runner and use Flutter, CocoaPods, Fastlane, match
  signing assets, and App Store Connect API credentials.
- App Store Connect now rejects IPA uploads built with the iOS 18.5 SDK. Keep
  the iOS TestFlight job on `macos-26` or another runner that includes Xcode 26
  / iOS 26 SDK or later.
- The workflow restores `.env` from `APP_DOTENV_BASE64` and builds with
  `flutter build ipa --dart-define-from-file=.env`.
- After upload, App Store Connect processing and tester availability still need
  to be checked outside this repo.

## Backend Deployment

Preferred path: GitHub Actions `Deploy Public Backend`.

```powershell
gh workflow list --all
gh run list --workflow "Deploy Public Backend" --limit 5
gh run view <run-id> --json status,conclusion,url,jobs
gh run view <run-id> --log-failed
```

The backend deploy command is:

```powershell
firebase deploy `
  --project apapane-94356 `
  --only firestore:rules,firestore:indexes,storage,functions `
  --non-interactive
```

Required GitHub Actions secret:

- `FIREBASE_DEPLOY_SERVICE_ACCOUNT_JSON`

This secret must contain the full JSON for a service account that can deploy to
`apapane-94356`: Firestore rules/indexes, Storage rules, and Cloud Functions.
It is not the same credential as `PLAY_SERVICE_ACCOUNT_JSON`.

Required existing Cloud Functions secrets:

- `GEMINI_API_KEY`
- `PLAY_SERVICE_ACCOUNT_JSON`
- `APPLE_SHARED_SECRET`

## Backend Deployment Notes From 2026-04-28

Initial GitHub Actions backend deployment failed because the deploy service
account secret was missing, but the backend was later deployed successfully from
the local Firebase CLI after `firebase login --reauth`.

- Temporary branch: `codex/backend-deploy-d9ac92f`
- Temporary commit: `7b2bb30 Trigger backend deploy from deploy branch`
- Run: `25028547854`
- URL: `https://github.com/COROLE/apapane_v2/actions/runs/25028547854`
- Result: failure
- Failed step: `Write deploy service account`
- Root cause: `FIREBASE_DEPLOY_SERVICE_ACCOUNT_JSON` was empty.

Extra checks performed:

- `gh secret list --repo COROLE/apapane_v2` did not show
  `FIREBASE_DEPLOY_SERVICE_ACCOUNT_JSON`.
- Local Firebase CLI user credentials were expired and required
  `firebase login --reauth`.
- `C:\Users\akira\.codex-secrets\apapane\play-service-account.json` is a Play
  service account for project `apapane`, not a Firebase deploy service account
  for `apapane-94356`. A Firebase deploy dry-run with that credential failed
  with 403.

Successful local backend deploy:

- Command:

```powershell
npx firebase-tools@14 deploy `
  --project apapane-94356 `
  --only firestore:rules,firestore:indexes,storage,functions `
  --non-interactive
```

- Result: success
- Deployed project: `apapane-94356`
- Created functions:
  - `generateStoryPreview`
  - `getStoryCreationStatus`
  - `reserveStoryGeneration`
  - `completeStoryGeneration`
  - `cancelStoryGeneration`
- Updated functions:
  - `generateStory`
  - `synthesizeVoice`
  - `verifyPurchase`
  - `deleteAccount`
  - `generateImage`
  - `generateImageHttp`
- Released:
  - `firestore_rules/firestore.rules`
  - `firestore_rules/firestore.indexes.json`
  - `storage_rules/storage.rules`
- Function URL:
  `https://us-central1-apapane-94356.cloudfunctions.net/generateImageHttp`

To make future GitHub Actions backend deployment work:

1. Create or locate a service account JSON that can deploy Firebase resources to
   `apapane-94356`.
2. Set the GitHub secret:

```powershell
gh secret set FIREBASE_DEPLOY_SERVICE_ACCOUNT_JSON `
  --repo COROLE/apapane_v2 `
  --body-file <firebase-deploy-service-account.json>
```

3. Rerun `Deploy Public Backend`.
4. If `workflow_dispatch` cannot start the workflow, confirm that the workflow
   file exists on the GitHub default branch.
5. If Actions is not usable, reauthenticate locally and deploy from the repo
   root:

```powershell
npx firebase-tools@14 login --reauth
npx firebase-tools@14 deploy `
  --project apapane-94356 `
  --only firestore:rules,firestore:indexes,storage,functions `
  --non-interactive
```

## Workflow Dispatch Caveat

GitHub `workflow_dispatch` may fail if the workflow file is not present on the
default branch.

Observed on 2026-04-28 JST:

- GitHub default branch: `master`
- `Deploy Public Backend` existed on the local work branch but could not be
  started with `gh workflow run` because GitHub did not see it on the default
  branch.
- A temporary push trigger was added on `codex/backend-deploy-d9ac92f` to start
  the Actions run.
- After the missing secret is fixed, prefer putting the backend workflow on the
  default branch or formalizing a deploy branch/workflow_dispatch path.

## Post Backend Deploy Smoke Checks

After a successful backend deploy, verify from a release candidate build:

- `generateStoryPreview`
- `reserveStoryGeneration`
- `generateStory`
- `completeStoryGeneration`
- `cancelStoryGeneration`
- `generateImage`
- `generateImageHttp`
- `synthesizeVoice`
- purchase verification
- account deletion
- Firestore rules for `subscriptionUsage` and `generationRequests`

## Current Branch Notes

State as of 2026-04-29 JST:

- Main implementation branch: `codex/ios-actions-check`
- TestFlight upload: completed
- Backend Firebase deploy: completed locally after Firebase CLI reauth
- GitHub Actions backend deploy: still blocked until
  `FIREBASE_DEPLOY_SERVICE_ACCOUNT_JSON` is added
- Preview quality hotfix: Cloud Functions were redeployed locally after adding
  backend checks that reject repeated `pagePlan` entries and generic filler
  preview text.
- Image generation hotfix: client now rejects incomplete generated stories when
  any body page image is missing, so reservation cancel/refund runs instead of
  completing with only a few images. Cloud Functions image rate limit was raised
  for 8/12 page stories and image generation failures now emit structured logs.
- Display validation hotfix: story generation is not completed until the app has
  actually loaded bytes for every generated body-page image. The previous check
  only required an image source string, which still allowed fallback art if a
  generated image URL failed to load on device.
- Image transport hotfix: generated image functions now return base64 even when
  Storage upload succeeds, and the app prefers base64 over remote preview URLs
  for newly generated pages. Client image call timeout is 420 seconds and the
  image function timeout is 360 seconds because production image calls were
  observed taking roughly 130-148 seconds each.
- Image generation reliability hotfix: body-page images are now generated in
  batches of 3 instead of fully sequentially, the separate cover image request
  was removed, and the first body-page image is used as the title image.
- Image provider switch: image generation was moved from OpenAI GPT Image to
  Gemini Imagen 4 Fast via the existing `GEMINI_API_KEY`. A direct production
  `generateImageHttp` smoke call had returned `Billing hard limit has been
  reached.` on OpenAI, so the backend no longer requires `OPENAI_API_KEY` for
  story images.
- Gemini Imagen switch deploy:
  - Commit: `3e7e023 Switch story images to Gemini Imagen`
  - Firebase Functions deploy: success with `npx firebase-tools@14 deploy --project apapane-94356 --only functions --non-interactive`
  - Production `generateImageHttp` smoke: success, `model=imagen-4.0-fast-generate-001`, base64 returned, Storage URL returned, elapsed about 9.4 seconds
  - TestFlight run: `25059842604`, URL `https://github.com/COROLE/apapane_v2/actions/runs/25059842604`, result success through `Upload to TestFlight`
- Image reliability follow-up:
  - Commit: `3143ad1 Make story image generation more reliable`
  - Client image generation concurrency was reduced from 3 to 1 to avoid mobile
    network failures while receiving multiple large image responses.
  - Functions image normalization was reduced to 900x1600 JPEG quality 84 to
    lower response payload size.
  - Firebase Functions deploy after reauth: success with
    `npx firebase-tools@14 deploy --project apapane-94356 --only functions --non-interactive`
  - Production `generateImageHttp` smoke after lightweight deploy: success,
    `model=imagen-4.0-fast-generate-001`, base64 returned, Storage URL returned,
    elapsed about 7.6 seconds, base64 length about 173k characters.
  - TestFlight initially failed on run `25099125550` because App Store Connect
    now rejects iOS 18.5 SDK / Xcode 16.4 uploads.
  - Commit: `2682199 Use Xcode 26 runner for TestFlight`
  - TestFlight run: `25100150937`, URL `https://github.com/COROLE/apapane_v2/actions/runs/25100150937`, result success through `Upload to TestFlight`.
- Partial image failure behavior:
  - Commit: `3b0d070 Do not abort stories on partial image failure`
  - Story creation no longer cancels the whole reservation when a subset of
    page images fails generation or verification. Failed pages are recovered
    during story prewarm; if remote recovery still fails, a local fallback image
    is cached into the page so the story can be completed and saved.
  - TestFlight run: `25102588267`, URL `https://github.com/COROLE/apapane_v2/actions/runs/25102588267`, result success through `Upload to TestFlight`.
- Image relevance hotfix:
  - Commit: `4c89226 Improve story image prompt relevance`
  - Story JSON generation now instructs Gemini to keep Japanese story text but
    write image-only fields such as `coverScene`, `characterSheet`, and
    `pages[].visualFocus` in concrete English for Imagen.
  - Client image prompts now front-load `MUST depict this exact scene`, shorten
    weaker cast wording, keep explicit visible-cast guidance, and raise remote
    recovery timeout from 45 seconds to 120 seconds before local fallback.
  - Verification passed:
    `flutter analyze --no-fatal-warnings --no-fatal-infos`, `flutter test`,
    `npm --prefix functions run lint`, and `npm --prefix functions test`.
  - Firebase Functions deploy: success with
    `npx firebase-tools@14 deploy --project apapane-94356 --only functions --non-interactive`.
  - Production `generateImageHttp` smoke after deploy: success,
    `model=imagen-4.0-fast-generate-001`, base64 returned, Storage URL returned,
    elapsed about 12.8 seconds, base64 length about 306k characters.
  - TestFlight run: `25112816000`, URL `https://github.com/COROLE/apapane_v2/actions/runs/25112816000`, workflow run number/build number `49`, result success through `Upload to TestFlight`.
  - Earlier duplicate deploy runs `25112533065` and `25112729099` were cancelled
    before upload; use `25112816000` as the valid TestFlight run for this fix.
- Imagen quality model trial:
  - Commit: `f3a5c39 Switch Imagen model to quality variant`
  - Backend image model was changed from `imagen-4.0-fast-generate-001` to
    `imagen-4.0-generate-001` to test whether the non-Fast Imagen 4 model
    follows story-specific prompts better.
  - Verification passed: `npm --prefix functions run lint` and
    `npm --prefix functions test`.
  - Firebase Functions deploy: success with
    `npx firebase-tools@14 deploy --project apapane-94356 --only functions --non-interactive`.
  - Production `generateImageHttp` smoke after deploy: success,
    `model=imagen-4.0-generate-001`, base64 returned, Storage URL returned,
    elapsed about 20.7 seconds, base64 length about 426k characters.
  - Push-triggered TestFlight run `25115450599` was cancelled because this was a
    backend-only model constant change and did not require a new app binary.
- Structured Imagen prompt pipeline:
  - Commit: `64300c0 Implement structured Imagen prompt pipeline`
  - Story image generation no longer sends raw Japanese story/page text directly
    to Imagen. The app now calls `generateImageSpecs` once per book to build a
    `CharacterProfile` and page-level `ImagePageSpec[]`; `generateImage` and
    `generateImageHttp` then build the final English Imagen prompt server-side.
  - Existing `prompt` image API input remains as legacy compatibility, but new
    story generation and recovery prefer `imagePageSpec`.
  - Verification passed:
    `flutter analyze --no-fatal-warnings --no-fatal-infos`, `flutter test`,
    `npm --prefix functions run lint`, and `npm --prefix functions test`.
  - Firebase Functions deploy: success with
    `npx firebase-tools@14 deploy --project apapane-94356 --only functions --non-interactive`.
  - Created function: `generateImageSpecs`. Updated image functions:
    `generateImage`, `generateImageHttp`.
  - Production `generateImageSpecs` smoke after deploy: success, returned a
    character profile and 4 page specs for mini mode.
  - Production `generateImageHttp` smoke with `imagePageSpec` after deploy:
    success, `model=imagen-4.0-generate-001`, base64 returned, Storage URL
    returned, base64 length about 283k characters.
  - TestFlight run: `25117014464`, URL
    `https://github.com/COROLE/apapane_v2/actions/runs/25117014464`, workflow
    build number `51`, result success through `Upload to TestFlight`.
- Temporary backend deploy branch exists: `codex/backend-deploy-d9ac92f`
- Unrelated untracked local files were left untouched:
  - `scripts/manual/generate-app-store-ipad-screenshots.ps1`
  - `scripts/manual/generate-app-store-screenshots.ps1`
  - `store_assets/app-store/`
