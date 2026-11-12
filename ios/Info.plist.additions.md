# Info.plist additions — apply after `npx cap add ios` (enrollment day)

Add these keys to `ios/App/App/Info.plist` in Xcode (or merge before the
first archive). Each maps to a line in the Nov 5 triple-check audit.

## Export compliance (audit item 1.10) — the encryption answer

```xml
<key>ITSAppUsesNonExemptEncryption</key>
<false/>
```

DTGF Social uses only exempt encryption: standard HTTPS/TLS plus
WebCrypto (ECDH P-256 → HKDF → AES-GCM-256) for end-to-end encrypted
1:1 DMs, all through platform/standard algorithms with keys on the
user's device. Answer the App Store Connect export-compliance question
"Yes, the app uses encryption" → select the exemption (uses only
standard algorithms implemented in the OS / exempt under EAR 740.17) —
with this plist key set, the prompt stops appearing on every build.

## Permission usage strings (camera / photos / microphone)

Required because members post photos and videos and record story
replies; the app hard-crashes without them the first time a picker or
camera opens.

```xml
<key>NSCameraUsageDescription</key>
<string>DTGF Social uses your camera so you can take photos and videos for your posts and stories.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>DTGF Social accesses your photo library so you can choose photos and videos to post.</string>
<key>NSMicrophoneUsageDescription</key>
<string>DTGF Social uses your microphone when you record videos for posts and stories.</string>
```

## Push notifications (Guideline 4.2 native-depth item)

```xml
<key>UIBackgroundModes</key>
<array>
  <string>remote-notification</string>
</array>
```

Plus: enable the Push Notifications capability in the App ID
(App Store Connect → Identifiers) and upload the APNs Auth Key (.p8)
created on enrollment day. Server-side sending is a launch-wiring task
on the production host — the app must not ship a push token pipeline
that reports "on" before the server can send (honesty rule).

## Universal links (deep links — audit's 4.2 notes)

- Associated Domains entitlement: `applinks:dtgfsocial.com`
- The production host must serve
  `https://dtgfsocial.com/.well-known/apple-app-site-association`
  naming app id `<TEAMID>.com.dtgfsocial.app` with paths for
  `/p/*` (post permalinks), `/join*`, `/u/*`.
- Custom URL scheme as the fallback: `dtgfsocial://`.

## Display values

- Bundle display name: **DTGF Social**
- Version 1.0 / Build 1 for the first submission; marketing version
  bumps per release, build number bumps per upload.
