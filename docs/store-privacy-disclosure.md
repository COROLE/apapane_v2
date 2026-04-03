# Store Privacy Disclosure Notes

最終更新日: 2026-03-29

This file is a release-prep note for store console inputs. Final selections must still be confirmed in the latest App Store Connect / Google Play forms before submission.

## Current Product Assumptions

- Initial public release keeps guest mode enabled
- Public story sharing is disabled
- Firebase Analytics collection is disabled in release
- Crash reporting is enabled for diagnostics
- Sign-in and purchases are available only through the parent flow

## App Store Privacy Notes

### Tracking

- Tracking: `No`

### Data categories likely to disclose

- Contact Info
  - Email address, when a signed-in account is created through the identity provider and linked to the account
- User ID
  - Firebase-authenticated account identifiers
- User Content
  - Story prompts and generated story content saved to the user account
  - Profile image selected by the user
- Purchases
  - Entitlement state, purchase IDs, subscription status
- Diagnostics
  - Crash diagnostics and basic error reports

### Data categories likely not to disclose as collected by the app

- Advertising data
- Health data
- Contacts
- Precise location
- Browsing history
- Publicly shared user-generated content in the initial release
- Analytics usage tracking, because Firebase Analytics collection is disabled in release

### Review note

Because Firebase SDK manifests and App Store questionnaire wording can change, confirm the final matrix against the exact SDK versions shipped in the release candidate.

## Google Play Data Safety Notes

### Data collected

- Personal info
  - Email address when supplied by the sign-in provider
- App info and performance
  - Crash logs, diagnostics
- User-generated content
  - Story content, profile image
- Financial info
  - Purchase / subscription entitlement state

### Data processed for security

- App Check token verification
- Rate limiting and abuse-prevention logs

### Data not intended for sale or advertising

- No advertising ID usage
- No tracking for third-party advertising
- No public content feed in the initial release

## Submission Reminder

- Re-check App Store Connect privacy nutrition labels after the final release build is generated
- Re-check Google Play Data safety answers after any SDK, auth, billing, or analytics setting change
