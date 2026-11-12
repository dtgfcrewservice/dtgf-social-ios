# iOS CI — repository secrets setup

`ios-build.yml` (manual trigger: Actions → "iOS build" → Run workflow)
builds DTGF Social on a GitHub macOS runner, signs it with the Apple
Distribution certificate + App Store provisioning profile we already
hold, and uploads the .ipa to App Store Connect with the ASC API key.

**Repo layout assumption:** the GitHub repository root is the `ios-app/`
folder (the workflow paths are relative to it). If the repo root ever
becomes `social-platform/`, move `.github/` up one level and prefix the
workflow's `ios/...` and npm paths with `ios-app/`.

## The six secrets

Create under repo → Settings → Secrets and variables → Actions.
All six are required; the workflow fails fast without them.

| Secret | What it contains |
|---|---|
| `ASC_DIST_CERT_P12_BASE64` | Base64 of a PKCS#12 (.p12) bundle holding our Apple Distribution certificate **and its private key**. We hold both halves locally (`~/.asc/dist.cer` + `~/.asc/dist-key.pem` on the Muse VM) — build the .p12 once with the openssl commands below and base64 it. |
| `ASC_DIST_CERT_PASSWORD` | The password chosen when exporting that .p12. Not an Apple password — it's invented at export time; the workflow uses it to import the bundle. |
| `ASC_PROVISIONING_PROFILE_BASE64` | Base64 of the App Store provisioning profile file (`DTGF_Social_App_Store.mobileprovision`, profile "DTGF Social App Store", UUID `d2434c4f-3c9a-4559-a314-156796135c1b`). We hold it locally on the Muse VM. |
| `ASC_API_KEY_P8_BASE64` | Base64 of the App Store Connect API key file (`AuthKey_4W79BUHZ28.p8`) — the same key Muse uses for the ASC API. altool reads it from `~/.appstoreconnect/private_keys/` on the runner to authorize the upload. |
| `ASC_API_KEY_ID` | The key's ID: `4W79BUHZ28`. |
| `ASC_API_ISSUER_ID` | The issuer ID: `333fe182-c2f0-4c96-afb2-ff1f041d8dc7`. |

## Producing the values (on the machine holding ~/.asc)

```sh
# 1. Build the .p12 from the certificate + private key we already hold
#    (you invent P12_PASSWORD here; it becomes ASC_DIST_CERT_PASSWORD)
openssl pkcs12 -export \
  -inkey ~/.asc/dist-key.pem \
  -in <(openssl x509 -inform DER -in ~/.asc/dist.cer) \
  -name "Apple Distribution: DYLAN TODD GERARDI" \
  -out /tmp/dist.p12 -passout pass:P12_PASSWORD

# 2. Base64 each file (paste the single-line output into the secret)
base64 -w0 /tmp/dist.p12                                     # ASC_DIST_CERT_P12_BASE64
base64 -w0 ~/.asc/DTGF_Social_App_Store.mobileprovision      # ASC_PROVISIONING_PROFILE_BASE64
base64 -w0 ~/.asc/AuthKey_4W79BUHZ28.p8                      # ASC_API_KEY_P8_BASE64
```

(On macOS use plain `base64 -i <file>` — output wraps, which GitHub
secrets accept; whitespace is ignored by the workflow's decode step
either way. Delete /tmp/dist.p12 after pasting.)

## Validity / renewal

- Distribution certificate serial `24DB833F93CF28FD4D7EF4A29B6C28D5`
  and the provisioning profile both expire **2027-11-12**. Renewing
  means: mint a new cert + profile (the ASC API flow Muse used on
  2026-11-12), rebuild the .p12, and replace the three file secrets.
- The build number uploaded is the workflow run number, so repeat runs
  never collide in App Store Connect; marketing version (1.0) is bumped
  deliberately in the Xcode project, not by CI.
- A green run uploads the build to App Store Connect (processing →
  TestFlight). Submitting for review stays a separate, deliberate step
  (manual release), exactly as planned.
