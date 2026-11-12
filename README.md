# DTGF Social — iOS app (Capacitor shell)

Skeleton created Thu Nov 5, 2026 (App Store fix build). **Nothing here
is signed or submitted** — code signing, App Store Connect, and the
archive all wait on Dylan's Apple Developer enrollment
(`../app-store-enrollment-checklist.md` is the enrollment-day runbook).

## Shape

- **Bundle ID:** `com.dtgfsocial.app` (from the dtgfsocial.com domain)
- **UI:** the live web app — `capacitor.config.json` points
  `server.url` at `https://dtgfsocial.com`, the same server-rendered
  app the web uses. One codebase, no forked frontend.
- **Native layer (the Guideline 4.2 depth):** the plugins in
  `package.json` — App, Browser, Camera, Push Notifications, Share —
  plus the StoreKit bridge below. These are real capabilities the web
  app calls (photo/video capture for posts and stories, share sheets,
  push for messages and moderation events, universal links into
  permalinks and invite links), not decoration.
- **Icon / splash:** the Crown Tile. Source art:
  `../app/public/logo.png` (512×512 today). **Enrollment-week asset
  task:** produce the 1024×1024 App Store icon master from the Crown
  Tile artwork plus the full icon set and splash screens
  (`npx @capacitor/assets generate` from the 1024 master).

## The IAP bridge contract (Guideline 3.1.1)

The membership page (web app) renders Buy buttons with
`data-iap-product="<productId>"` and expects the shell to inject:

```js
window.DTGFIAP = {
  // Run a StoreKit purchase for the product, then POST the receipt to
  // the server validator and reload the membership page on success:
  purchase(productId),   // -> POST /api/iap/verify { productId, transactionId, receiptData }
  restore(),             // -> re-verify every receipt Apple returns, same endpoint
};
```

- Product IDs (fixed — App Store Connect products must match
  character-for-character; the server catalog is `GET /api/iap/products`):
  - `com.dtgfsocial.light.yearly` — $12/yr
  - `com.dtgfsocial.light.monthly` — $1.50/mo
  - `com.dtgfsocial.premium.yearly` — $30/yr
  - `com.dtgfsocial.premium.monthly` — $3/mo
- The session cookie from the WebView login rides along on the verify
  call — purchases attach to the signed-in account.
- StoreKit implementation choice at build time: a maintained Capacitor
  StoreKit plugin (evaluate `@capacitor-community/in-app-purchases` or
  `cordova-plugin-purchase`) wrapped in the `DTGFIAP` contract above so
  the web app never knows which plugin shipped.
- Until the bridge exists, the Buy buttons route to `/membership/ios`
  (explains the iPhone path) — honest dead-end, never a fake purchase.

## Build steps (enrollment day, on a Mac)

1. `cd ios-app && npm install`
2. `npx cap add ios` (generates `ios/` — then apply
   `ios/Info.plist.additions.md`)
3. Set the Apple Team in Xcode (the enrolled account), bundle ID
   `com.dtgfsocial.app`.
4. Generate icons/splash from the Crown Tile 1024 master.
5. `npx cap sync ios` → archive in Xcode → upload to App Store Connect
   → TestFlight first, then submit with the review package in
   `../app-review-notes.md`.
6. Set `APPLE_IAP_SHARED_SECRET` on the production host (App Store
   Connect → the app → App Information → App-Specific Shared Secret)
   so `/api/iap/verify` goes live; smoke-test a sandbox purchase
   end-to-end (Sandbox tester account) before flipping to production
   receipts.
