# 🚀 Quick Reference - Environment Variables

## 📝 File Locations

```
.env                                    # Flutter environment variables (DO NOT COMMIT)
.env.example                            # Template for .env (COMMIT THIS)
android/local.properties                # Android config & keys (DO NOT COMMIT)
android/local.properties.example        # Template (COMMIT THIS)
ios/Runner/GeneratedConfig.plist        # iOS config (DO NOT COMMIT)
ios/Runner/GeneratedConfig.plist.example # Template (COMMIT THIS)
```

## 🔑 Environment Variables Reference

### .env File
```env
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key
GOOGLE_MAPS_API_KEY=your_google_maps_api_key
```

### android/local.properties
```properties
sdk.dir=C:\\Users\\YourName\\AppData\\Local\\Android\\sdk
flutter.sdk=C:\\flutter
GOOGLE_MAPS_API_KEY=your_google_maps_api_key
```

### ios/Runner/GeneratedConfig.plist
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>GOOGLE_MAPS_API_KEY</key>
    <string>your_google_maps_api_key</string>
</dict>
</plist>
```

## 💻 Usage in Code

### Dart/Flutter
```dart
import 'package:ridooo/core/config/env_config.dart';

// Access environment variables
String supabaseUrl = EnvConfig.supabaseUrl;
String supabaseKey = EnvConfig.supabaseAnonKey;
String mapsApiKey = EnvConfig.googleMapsApiKey;
```

### Android (Automatic)
The API key is automatically injected into `AndroidManifest.xml` via Gradle.

### iOS (Automatic)
The API key is automatically loaded from `GeneratedConfig.plist` in `AppDelegate.swift`.

## ⚡ Quick Commands

### First-Time Setup
```bash
# Windows
.\setup.ps1

# macOS/Linux
chmod +x setup.sh
./setup.sh
```

### Manual Setup
```bash
# Copy templates
cp .env.example .env
cp android/local.properties.example android/local.properties
cp ios/Runner/GeneratedConfig.plist.example ios/Runner/GeneratedConfig.plist

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Verification
```bash
# Check if sensitive files are ignored
git check-ignore .env android/local.properties ios/Runner/GeneratedConfig.plist

# Check what will be committed
git status

# Search for hardcoded secrets
git grep "AIzaSy" -- ':!*.md'
git grep "supabase.co" -- ':!*.md'
```

## 🔍 Where API Keys Are Used

### Google Maps API Key
- **Dart**: `lib/core/services/directions_service.dart`
- **Dart**: `lib/core/services/places_service.dart`
- **Android**: `android/app/src/main/AndroidManifest.xml`
- **iOS**: `ios/Runner/AppDelegate.swift`

### Supabase URL & Key
- **Dart**: `lib/core/config/supabase_config.dart`
- **Dart**: `lib/main.dart` (initialization)

## 🛡️ Security Checklist

Before pushing to Git:
- [ ] `.env` is listed in `.gitignore`
- [ ] `android/local.properties` is listed in `.gitignore`
- [ ] `ios/Runner/GeneratedConfig.plist` is listed in `.gitignore`
- [ ] No API keys in source code (except `.example` files)
- [ ] `git status` shows no sensitive files
- [ ] Template files have placeholder values only

## 🆘 Common Issues

### "Unable to load .env"
```bash
# Make sure .env exists
ls -la .env

# Verify it's in assets in pubspec.yaml
grep ".env" pubspec.yaml

# Reinstall
flutter clean
flutter pub get
```

### "API key not found" (Android)
```bash
# Check local.properties
cat android/local.properties | grep GOOGLE_MAPS_API_KEY

# Rebuild
cd android
./gradlew clean
cd ..
flutter run
```

### "API key not found" (iOS)
```bash
# Check plist file exists
ls -la ios/Runner/GeneratedConfig.plist

# Rebuild
flutter clean
flutter run
```

## 📚 Documentation

- **Complete Setup**: `ENV_SETUP.md`
- **Security Info**: `SECURITY.md`
- **Pre-Push Guide**: `PRE_PUSH_CHECKLIST.md`
- **Migration Info**: `MIGRATION_SUMMARY.md`

## 🎯 Get API Keys

### Google Maps
1. Go to: https://console.cloud.google.com
2. Create/select project
3. Enable: Maps SDK (Android/iOS), Directions API, Places API, Geocoding API
4. Create API Key
5. Restrict to your app package name

### Supabase
1. Go to: https://supabase.com
2. Create/select project
3. Settings → API
4. Copy Project URL and anon/public key

---

**Quick Start**: Run `.\setup.ps1` (Windows) or `./setup.sh` (Unix) and follow the prompts!
