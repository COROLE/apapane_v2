# Public Release Checklist

## Firebase

- Fill `.env` or CI secrets with the public Firebase values from `.env.example`.
- Create `ios/Flutter/FirebaseConfig.xcconfig` from `ios/Flutter/FirebaseConfig.xcconfig.example` and set `GOOGLE_IOS_URL_SCHEME`.
- Configure Android and iOS Google Sign-In in Firebase and register production SHA certificates.
- Ensure the signed-in Firebase CLI account has access to project `apapane-94356` before backend deploys.
- `FIREBASE_ANDROID_API_KEY`, `FIREBASE_IOS_API_KEY`, app IDs, sender ID, and storage bucket are now fixed to the `apapane-94356` project in `.env.example`.
- `FIREBASE_IOS_BUNDLE_ID`, `GOOGLE_WEB_SERVER_CLIENT_ID`, `GOOGLE_IOS_CLIENT_ID`, and `GOOGLE_IOS_URL_SCHEME` must match the live Firebase Auth configuration after each OAuth or signing-certificate change.
- Deploy Cloud Functions with server secrets:
  - `GEMINI_API_KEY`
  - `OPENAI_API_KEY`
  - `PLAY_SERVICE_ACCOUNT_JSON`
  - `APPLE_SHARED_SECRET`
- Cloud Functions now require App Check for public traffic. Release builds must send App Check on callable APIs and on the HTTP image generation endpoint.
- Enable Google Cloud Text-to-Speech API in project `apapane-94356`.
- Cloud Functions runtime is pinned to Node.js 22.
- GitHub Actions workflow for backend deploys:
  - `.github/workflows/deploy-public-backend.yml`
  - Required secret: `FIREBASE_DEPLOY_SERVICE_ACCOUNT_JSON`
- Windows helper for secret setup:
  - `.\scripts\manual\set-functions-secrets.ps1 -PlayServiceAccountJsonPath <path-to-play-service-account.json> -AppleSharedSecret <app-store-shared-secret>`
- Deploy backend resources from the repo root after access is confirmed:
  - `npx firebase-tools deploy --project apapane-94356 --only firestore:rules,firestore:indexes,storage,functions`
- Production workflow and preflight notes:
  - `docs/production-backend-deployment.md`

## Store Setup

- Create Android app `com.coroleai.apapaneapp` in Play Console.
- Create iOS app `com.corole.apapane` in App Store Connect.
- Register in-app products:
  - `consumable`
  - `silver_subscription`
- Confirm the Google Sign-In OAuth client IDs match the release keystore and iOS bundle id.
- Confirm Sign in with Apple is enabled on the `com.corole.apapane` App ID and the App Store provisioning profile has been regenerated after enabling it.
- Publish the company-site legal pages:
  - `https://corole.net/apapane/privacy`
  - `https://corole.net/apapane/terms`
  - `https://corole.net/apapane/account-deletion`
- Source documents for publishing:
  - `docs/legal/privacy-policy.md`
  - `docs/legal/terms-of-service.md`
  - `docs/account-deletion.md`
- Use `https://corole.net/apapane/privacy` as the default support-facing URL in store metadata.
- For child-directed launch, keep guest mode enabled, keep the public story feed disabled, and gate sign-in, purchases, and external links behind the in-app parental check.
- Disable Firebase Analytics collection for release and declare Crashlytics as diagnostics-only in store privacy disclosures.
- Track store assets, disclosures, and submission notes in `docs/store-submission-checklist.md`.
- Draft store copy and disclosure notes:
  - `docs/store-listing-copy.md`
  - `docs/store-privacy-disclosure.md`

## Quality Gates

- `flutter analyze --no-fatal-warnings --no-fatal-infos`
- `flutter test`
- `npm --prefix functions run lint`
- `npm --prefix functions test`
- Validate guest play, parent sign-in, story generation, image upload, purchase, restore purchase, logout, and account deletion.
- Validate privacy policy, terms, and support links from the parent area.
- Validate Play internal and TestFlight builds on physical devices before submission.
- Record internal verification results in `docs/internal-smoke-checklist.md`.
