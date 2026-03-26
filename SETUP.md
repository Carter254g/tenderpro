# TenderPro AI — Setup & Deployment Guide

## Local Development

### 1. Install Flutter
```bash
# macOS (with Homebrew)
brew install flutter

# Or download from https://docs.flutter.dev/get-started/install
flutter doctor   # verify all checks pass
```

### 2. Clone & install deps
```bash
git clone https://github.com/YOUR_USERNAME/tenderpro_ai.git
cd tenderpro_ai
flutter pub get
```

### 3. Set your API key (local only)
Edit `lib/config/env.dart`:
```dart
defaultValue: 'sk-ant-YOUR_KEY_HERE',
```
> ⚠️ This is for local development only. Never push your key to GitHub.

### 4. Run on a device/emulator
```bash
flutter devices          # list connected devices
flutter run -d <device>  # run on specific device
```

---

## Building for Release

### Android APK
```bash
flutter build apk --release \
  --dart-define=ANTHROPIC_API_KEY=sk-ant-...
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

### Android App Bundle (Play Store)
```bash
flutter build appbundle --release \
  --dart-define=ANTHROPIC_API_KEY=sk-ant-...
```

### iOS (requires macOS + Xcode)
```bash
flutter build ios --release \
  --dart-define=ANTHROPIC_API_KEY=sk-ant-...
```
Then open `ios/Runner.xcworkspace` in Xcode to archive and upload.

---

## GitHub Actions (CI/CD)

### Setup
1. Push code to GitHub
2. Go to **Settings → Secrets and variables → Actions**
3. Click **New repository secret**
4. Add: `ANTHROPIC_API_KEY` = `sk-ant-...`

The workflow at `.github/workflows/build.yml` will then:
- Lint and test on every push/PR
- Build a release APK on every push to `main`
- Build iOS on every push to `main`

Artifacts are downloadable from the **Actions** tab for 14 days.

---

## Google Play Deployment

1. Create a signing keystore:
```bash
keytool -genkey -v -keystore tenderpro.keystore \
  -alias tenderpro -keyalg RSA -keysize 2048 -validity 10000
```

2. Create `android/key.properties` (this is in `.gitignore`):
```
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=tenderpro
storeFile=../tenderpro.keystore
```

3. Update `android/app/build.gradle` to use the signing config.

4. Build signed bundle:
```bash
flutter build appbundle --release \
  --dart-define=ANTHROPIC_API_KEY=sk-ant-...
```

5. Upload `build/app/outputs/bundle/release/app-release.aab` to Play Console.

---

## App Store (iOS) Deployment

1. Register app in [App Store Connect](https://appstoreconnect.apple.com/)
2. Configure signing certificates and provisioning profiles in Xcode
3. Build archive in Xcode: **Product → Archive**
4. Upload via Xcode Organizer or `xcrun altool`

---

## Environment Variables Reference

| Variable | Where to set | Description |
|---|---|---|
| `ANTHROPIC_API_KEY` | GitHub Secret / `--dart-define` | Claude API key |

---

## Troubleshooting

**`flutter doctor` shows issues**
Run `flutter doctor --verbose` and follow the remediation steps for each ✗.

**API key error in app**
Confirm the key is being injected: add a debug print of `Env.anthropicApiKey` in `main()` (remove before committing).

**Build fails on CI**
Check the Actions log. Most common causes: Flutter version mismatch, missing secret, or pubspec dependency conflict.
