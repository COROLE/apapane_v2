# Store Submission Checklist

Track these items outside the app code changes before public submission.

## Legal And Support

- [ ] Production privacy policy published at `https://corole.net/apapane/privacy`
- [ ] Production terms published at `https://corole.net/apapane/terms`
- [ ] Account deletion instructions published at `https://corole.net/apapane/account-deletion`
- [ ] Store listing support URL points at the published privacy policy or support page
- [ ] Support contact email is validated
- [ ] Published pages match:
  - `docs/legal/privacy-policy.md`
  - `docs/legal/terms-of-service.md`
  - `docs/account-deletion.md`

## App Store Connect

- [ ] App record exists for `com.coroleai.apapane`
- [ ] App privacy disclosure is completed
- [ ] Age rating is completed for a child-directed launch
- [ ] Subscription metadata is completed
- [ ] Review notes are prepared
- [ ] Screenshots for required device classes are uploaded
- [ ] TestFlight testers have verified the release candidate on physical devices
- [ ] Listing copy reflects `docs/store-listing-copy.md`
- [ ] Privacy selections reflect `docs/store-privacy-disclosure.md`

## Google Play Console

- [ ] App record exists for `com.coroleai.apapaneapp`
- [ ] Data safety form is completed
- [ ] Content rating questionnaire is completed
- [ ] In-app products `consumable` and `silver_subscription` are fully configured
- [ ] Store listing copy is finalized
- [ ] Screenshots and feature graphic are uploaded
- [ ] Internal testing build has passed physical-device verification
- [ ] Listing copy reflects `docs/store-listing-copy.md`
- [ ] Data safety answers reflect `docs/store-privacy-disclosure.md`

## Production Operations

- [ ] `FIREBASE_DEPLOY_SERVICE_ACCOUNT_JSON` GitHub secret is configured
- [ ] Firebase Functions secrets are present in project `apapane-94356`
- [ ] `.github/workflows/deploy-public-backend.yml` has been run successfully
- [ ] App Store and Play release notes are finalized
