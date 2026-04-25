# Auth Provider Setup

Use these checks when Apple or Google login fails in TestFlight, Play internal testing, or a local device build.

## iOS

- App Store Connect and Xcode must use bundle id `com.corole.apapane`.
- Apple Developer must enable **Sign in with Apple** for the `com.corole.apapane` App ID, then regenerate the App Store provisioning profile used by match.
- Firebase project `apapane-94356` must contain an iOS app registered with bundle id `com.corole.apapane`.
- Download that app's `GoogleService-Info.plist` and update the release `.env` values:
  - `FIREBASE_IOS_APP_ID=1:712097133007:ios:89f2a0613d43cfd7c7e2ba`
  - `FIREBASE_IOS_API_KEY`
  - `FIREBASE_IOS_BUNDLE_ID=com.corole.apapane`
  - `GOOGLE_IOS_CLIENT_ID=712097133007-u56rlhqrvaukv1birtf3rfjl6qiqlr79.apps.googleusercontent.com`
  - `GOOGLE_IOS_URL_SCHEME=com.googleusercontent.apps.712097133007-u56rlhqrvaukv1birtf3rfjl6qiqlr79`

## Android

- Firebase project `apapane-94356` must contain Android app `com.coroleai.apapaneapp`.
- Register these SHA fingerprints for Google Sign-In:
  - Upload certificate SHA-1: `60:3D:D3:F4:CD:E1:29:93:DD:FF:40:88:51:CC:5A:A4:DE:84:C2:FA`
  - Upload certificate SHA-256: `B0:AD:F2:A7:16:63:6F:FD:26:77:DA:11:90:48:45:7D:C9:DF:AB:C3:AF:46:30:46:12:48:1A:99:76:29:CF:09`
  - Local debug SHA-1: `DF:13:D7:32:12:AB:85:D1:29:1B:61:C1:3C:81:C2:EC:6E:39:EC:01`
  - Local debug SHA-256: `B3:45:BC:0D:40:1E:40:1E:F1:20:F3:AF:96:F7:0A:61:A6:E7:94:10:22:28:81:20:E6:D7:E2:6F:25:EB:AE:11`
- After registering fingerprints, download a fresh `android/app/google-services.json` and keep `GOOGLE_WEB_SERVER_CLIENT_ID` aligned with the web client in Firebase Auth.

## Smoke Test

- Install a fresh build, open the parent login screen, and verify Google login creates or restores a `publicUsers/{uid}` document.
- On a physical iPhone/iPad, verify Apple login completes and also creates or restores the same profile document shape.
