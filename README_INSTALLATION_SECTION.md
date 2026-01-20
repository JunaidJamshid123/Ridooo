# 📦 Installation & Setup

This section can be added to your main README.md file.

---

## Prerequisites

- Flutter SDK (^3.7.0)
- Android Studio / Xcode (for mobile development)
- Google Maps API Key
- Supabase Account

## Quick Start

### 1. Clone the Repository

```bash
git clone <your-repo-url>
cd ridooo
```

### 2. Run Setup Script

**Windows (PowerShell):**
```powershell
.\setup.ps1
```

**macOS/Linux:**
```bash
chmod +x setup.sh
./setup.sh
```

This will:
- Create `.env` from template
- Create `android/local.properties` from template
- Create `ios/Runner/GeneratedConfig.plist` from template
- Run `flutter pub get`

### 3. Configure API Keys

#### Get Your API Keys

**Supabase:**
1. Create a project at [supabase.com](https://supabase.com)
2. Go to Project Settings → API
3. Copy your Project URL and anon key

**Google Maps:**
1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create a project
3. Enable these APIs:
   - Maps SDK for Android
   - Maps SDK for iOS
   - Directions API
   - Places API
   - Geocoding API
4. Create an API Key
5. (Recommended) Restrict the key to your app

#### Add Keys to Configuration Files

**Edit `.env`:**
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_supabase_anon_key
GOOGLE_MAPS_API_KEY=your_google_maps_api_key
```

**Edit `android/local.properties`:**
```properties
sdk.dir=/path/to/your/android/sdk
flutter.sdk=/path/to/your/flutter/sdk
GOOGLE_MAPS_API_KEY=your_google_maps_api_key
```

**Edit `ios/Runner/GeneratedConfig.plist`:**
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

### 4. Run the App

```bash
flutter run
```

## Manual Setup

If you prefer not to use the setup script:

```bash
# Copy template files
cp .env.example .env
cp android/local.properties.example android/local.properties
cp ios/Runner/GeneratedConfig.plist.example ios/Runner/GeneratedConfig.plist

# Edit the files above with your API keys

# Install dependencies
flutter pub get

# Run the app
flutter run
```

## 📖 Additional Documentation

- **[ENV_SETUP.md](ENV_SETUP.md)** - Detailed setup instructions
- **[SECURITY.md](SECURITY.md)** - Security policy and best practices
- **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** - Quick reference guide

## ⚠️ Important Notes

- **Never commit** `.env`, `android/local.properties`, or `ios/Runner/GeneratedConfig.plist`
- These files contain sensitive API keys and are gitignored
- Use the `.example` files as templates
- See [SECURITY.md](SECURITY.md) for security best practices

## 🆘 Troubleshooting

### "Unable to load .env file"
```bash
# Make sure .env exists
ls -la .env

# Reinstall dependencies
flutter clean
flutter pub get
```

### "API key not found" errors
```bash
# Verify your keys are set
cat .env
cat android/local.properties
cat ios/Runner/GeneratedConfig.plist

# Rebuild the app
flutter clean
flutter run
```

### Need Help?
See [ENV_SETUP.md](ENV_SETUP.md) for detailed troubleshooting steps.

---

## Development

After initial setup, typical development workflow:

```bash
# Get dependencies
flutter pub get

# Run the app
flutter run

# Run tests
flutter test

# Build for production
flutter build apk        # Android
flutter build ios        # iOS
```
