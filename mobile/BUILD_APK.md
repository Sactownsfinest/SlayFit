# Building SlayFit APK

## Quick Start

### 1. Prerequisites
- Flutter SDK installed and in PATH
- Android SDK with API 21+
- JDK 11+

### 2. Build APK

```bash
cd mobile
flutter clean
flutter pub get

# Build release APK (optimized size)
flutter build apk --release

# Or build APKs split by architecture (smaller files)
flutter build apk --split-per-abi
```

### 3. Output
APK files will be at:
- **Single APK**: `mobile/build/app/outputs/flutter-apk/app-release.apk`
- **Split APKs**: `mobile/build/app/outputs/flutter-apk/app-*.apk`

### 4. Install on Device
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

## Configuration

### Update Backend URL
Edit `mobile/lib/config/api_config.dart`:
```dart
const String API_BASE_URL = 'http://your-server.com/api';
```

### App Details
Edit `mobile/pubspec.yaml` and `mobile/android/app/build.gradle`:
- App name
- Package name (com.example.slayfit)
- Version codes
- Min SDK version (21)

---

## Advanced Options

### Build with specific version
```bash
flutter build apk --build-number=2 --build-name=1.0.1
```

### Obfuscate code (security)
```bash
flutter build apk --release --obfuscate --split-debug-info=./logs
```

### Check app size
```bash
flutter build apk --release --analyze-size
```

---

## Troubleshooting

### "Android SDK not found"
```bash
flutter config --android-sdk /path/to/android-sdk
flutter doctor
```

### NDK version issues
```bash
flutter clean
rm -rf android/.gradle
flutter pub get
```

### Gradle build fails
```bash
cd mobile/android
./gradlew clean
cd ../..
flutter build apk --release
```

---

## Distribution

### Without Google Play
1. Build release APK
2. Host on your website or S3
3. Share download link
4. Users download and install manually

### Distribution URL Format
```
https://your-domain.com/apk/slayfit-v1.0.0.apk
```

---

## Signing APK for Google Play (Optional)

Create signing key:
```bash
keytool -genkey -v -keystore ~/slayfit.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias slayfit
```

Use in Gradle:
```bash
flutter build appbundle --release
```

---

## File Size Optimization

- **Development APK**: ~150-200 MB
- **Release APK (single)**: ~45-60 MB
- **Release APK (split)**: ~25-35 MB

### Reduce size further
- Remove unused dependencies
- Enable minification
- Use ProGuard/R8
- Optimize assets

---

For more info: https://flutter.dev/docs/deployment/android
