# Internal Smoke Checklist

Use this checklist for every Android internal testing build and every iOS TestFlight build.

## Run Metadata

- [ ] Date recorded
- [ ] Tester name recorded
- [ ] Platform and OS version recorded
- [ ] Build number recorded
- [ ] Environment confirmed as production Firebase project (`apapane-94356`)

## Guest Journey

- [ ] App launches without a signed-in parent account
- [ ] Guest can start story creation
- [ ] Guest can complete the prompt flow
- [ ] Guest can generate a story successfully
- [ ] Guest can generate at least one image successfully
- [ ] Guest can play generated voice audio successfully

## Parent Gate And Sign-In

- [ ] Parent gate blocks protected actions before unlock
- [ ] Parent can unlock the parent area
- [ ] Google sign-in succeeds
- [ ] Apple sign-in succeeds on iOS
- [ ] Sign-out returns the app to guest mode

## Purchase Flow

- [ ] Product catalog loads
- [ ] Consumable purchase succeeds
- [ ] Subscription purchase succeeds
- [ ] Restore purchases succeeds
- [ ] Subscription management link opens correctly

## Account And Data

- [ ] Profile update succeeds
- [ ] Privacy policy link opens correctly
- [ ] Terms of service link opens correctly
- [ ] Support email link opens correctly
- [ ] Account deletion succeeds
- [ ] Deleted account data is removed from Auth, Firestore, and Storage

## Sign-Off

- [ ] Android internal build accepted for release candidate use
- [ ] iOS TestFlight build accepted for release candidate use
- [ ] Open issues are linked in the release tracking ticket
