# fastlane — Flutter release and store screenshots

**As of 2026-09.** Distilled from apps actually shipped to both stores, so the lane split is the
part that matters: it exists because uploading the wrong thing overwrites something live.

Official docs: https://docs.fastlane.tools/actions/upload_to_app_store/

## The lanes

| Lane | iOS | Android |
|---|---|---|
| `binary` | build IPA → TestFlight | build AAB → internal track |
| `metadata` | store text only — no binary, no screenshots | same; lands without a new version |
| `screenshots` | fills **empty slots only**, keeps what's live | images and feature graphic only |
| `screenshots_replace` | **wipes and replaces** every screenshot | — |
| `screenshots_ipad` | iPad only, iPhone untouched | — |
| `release_all` | binary → metadata → screenshots | — |

## What the split is protecting you from

- **`screenshots` vs `screenshots_replace`.** App Store Connect's `overwrite_screenshots: true`
  deletes what is live before uploading. Reach for the replace lane only when you mean to lose them.
- **`screenshots_ipad` exists because there is no "iPad only" upload.** Push iPad shots the normal
  way and the iPhone ones go with them. The lane stages a temp tree holding only `*_ipad.png`,
  renamed, uploads that, and deletes it.
- **`metadata` is version-independent.** Store text can go out without shipping a build — useful
  when review kicked back a description.
- **Generate screenshots before uploading, never after.** `SCREENSHOT_HOOK` runs your generator
  (a node script, `fastlane snapshot`, anything) in `before_all` for screenshot lanes only, so a
  stale batch can't overwrite a fresh one.

## Setup

1. Copy `Fastfile.ios` to `ios/fastlane/Fastfile` and `Fastfile.android` to `android/fastlane/Fastfile`.
2. Export what the iOS lanes need: `APP_NAME`, `APP_BUNDLE_ID`, `APPLE_APP_ID`, and either
   `APPSTORE_API_KEY_ID` + `APPSTORE_ISSUER_ID` + `APPSTORE_API_KEY_CONTENT` or
   `APP_STORE_CONNECT_API_KEY_PATH`. Android reads its service-account JSON from `SUPPLY_JSON_KEY`.
3. **No key ever enters the repo.** `.p8`, `api_key.json` and the Play service account belong in
   your keychain, your CI secrets, or a gitignored path — never a commit.
4. Screenshots live at `ios/fastlane/screenshots/<locale>/*.png`, with iPad ones suffixed `_ipad.png`.

Nothing here is imported by anything. Copy it, change it, and when fastlane moves on, this file
going stale breaks nothing.
