# Internal Deployment

## Scope

- Android: Google Play internal testing
- iOS: TestFlight internal testing
- Public release requirements are tracked in `docs/public-release.md`.
- Record each physical-device verification pass in `docs/internal-smoke-checklist.md`.

## One-Time Bootstrap

### 1. GitHub default branch

This workflow only deploys on `main`.

1. Push the current release branch to `main`.
2. Switch the repository default branch to `main`.
3. Add branch protection so `validate` is a required status check.

If you use GitHub CLI, the helper script below can do the branch migration and branch protection after this branch is pushed:

```powershell
.\scripts\github\bootstrap-main.ps1
```

### 2. Google Play Console

Create the app record for `com.coroleai.apapaneapp`, enable Play App Signing, and create the `internal` track.

Register the in-app products before the first automated upload:

- `consumable`
- `silver_subscription`

The app record itself cannot be created from this repository. Do that once in Play Console before running the workflow.

### 3. App Store Connect

Create the `Apapane` app record with bundle id `com.coroleai.apapane`, then create:

- Apple Distribution certificate
- `IOS_APP_STORE` provisioning profile
- TestFlight internal group `Internal`

The first app record and tester setup are manual App Store Connect steps.

## GitHub Secrets And Variables

### Required secrets

- `APP_DOTENV_BASE64`
- `ANDROID_UPLOAD_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`
- `PLAY_SERVICE_ACCOUNT_JSON`
- `APPSTORE_API_PRIVATE_KEY`
- `APPSTORE_CERTIFICATES_FILE_BASE64`
- `APPSTORE_CERTIFICATES_PASSWORD`

### Required variables

- `APPSTORE_API_KEY_ID`
- `APPSTORE_ISSUER_ID`

## Local Secret File Templates

- Environment variables template: `.env.example`
- Android signing template: `android/key.properties.example`
- iOS Firebase build settings template: `ios/Flutter/FirebaseConfig.xcconfig.example`

`APP_DOTENV_BASE64` should be the base64-encoded contents of a `.env` file containing:

```env
FIREBASE_API_KEY=
FIREBASE_PROJECT_ID=
FIREBASE_MESSAGING_SENDER_ID=
FIREBASE_STORAGE_BUCKET=
FIREBASE_ANDROID_APP_ID=
FIREBASE_IOS_APP_ID=
GOOGLE_WEB_SERVER_CLIENT_ID=
GOOGLE_IOS_CLIENT_ID=
GOOGLE_IOS_URL_SCHEME=
SUPPORT_EMAIL=
PRIVACY_POLICY_URL=
TERMS_OF_SERVICE_URL=
```

PowerShell example:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes(".env"))
```

## Workflow Behavior

- File: `.github/workflows/deploy-internal.yml`
- Continuous validation: `.github/workflows/validate.yml`
- Trigger: push to `main`
- Manual trigger: `workflow_dispatch`
- Validation job: `flutter pub get`, `flutter analyze --no-fatal-warnings --no-fatal-infos`, `flutter test`
- Functions validation in CI: `npm ci`, `npm run lint`, `npm test`
- Android job: build signed AAB and upload with Fastlane `supply` to Play `internal`
- iOS job: import certs, download the `IOS_APP_STORE` profile, build signed IPA, upload to TestFlight
- Child-directed release note: internal builds should keep guest mode enabled and verify that parent sign-in, purchases, and external links remain behind the in-app parental gate.

Manual dispatch supports Android-only or iOS-only reruns through workflow inputs.

## Local Validation

Android release builds require:

1. `android/key.properties`
2. `android/app/upload-keystore.jks`
3. A deployment `.env` file

Then run:

```powershell
flutter build appbundle --release --build-number 1 --dart-define-from-file=.env
```

iOS release/TestFlight builds must run on macOS with Xcode and Apple signing assets installed. The GitHub Actions workflow is the supported path for iOS packaging.

For local iOS archive builds, create `ios/Flutter/FirebaseConfig.xcconfig` with:

```xcconfig
GOOGLE_IOS_URL_SCHEME=<your reversed Google iOS client id>
```

Helper scripts:

- `scripts/manual/generate-android-keystore.ps1`
- `scripts/manual/build-android-internal.ps1`
- `scripts/manual/build-ios-testflight.sh`
- `scripts/manual/set-functions-secrets.ps1`
- `docs/internal-smoke-checklist.md`
