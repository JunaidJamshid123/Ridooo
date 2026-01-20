# Environment Setup Guide

## Important: Securing API Keys and Sensitive Information

This project uses environment variables to keep API keys and sensitive information secure and out of version control.

## Initial Setup

### 1. Install Dependencies

After cloning the repository, run:

```bash
flutter pub get
```

### 2. Configure Environment Variables

#### For Flutter (Dart code):

1. Copy the `.env.example` file to `.env`:
   ```bash
   cp .env.example .env
   ```

2. Edit the `.env` file and add your actual API keys:
   ```env
   SUPABASE_URL=your_actual_supabase_url
   SUPABASE_ANON_KEY=your_actual_supabase_anon_key
   GOOGLE_MAPS_API_KEY=your_actual_google_maps_api_key
   ```

#### For Android:

1. Copy `android/local.properties.example` to `android/local.properties`:
   ```bash
   cp android/local.properties.example android/local.properties
   ```

2. Edit `android/local.properties` and update:
   - Set your Android SDK path
   - Set your Flutter SDK path  
   - Add your Google Maps API key

   Example:
   ```properties
   sdk.dir=C:\\Users\\YourName\\AppData\\Local\\Android\\sdk
   flutter.sdk=C:\\flutter
   GOOGLE_MAPS_API_KEY=your_actual_google_maps_api_key
   ```

#### For iOS:

Create `ios/Runner/GeneratedConfig.plist` with:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>GOOGLE_MAPS_API_KEY</key>
    <string>your_actual_google_maps_api_key</string>
</dict>
</plist>
```

### 3. API Keys You'll Need

#### Supabase
1. Go to [https://supabase.com](https://supabase.com)
2. Create a project or use an existing one
3. Go to Project Settings → API
4. Copy the Project URL and anon/public key

#### Google Maps API
1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create a project or select an existing one
3. Enable the following APIs:
   - Maps SDK for Android
   - Maps SDK for iOS
   - Directions API
   - Places API
   - Geocoding API
4. Create credentials (API Key)
5. Restrict the API key to your app's package name

## What's Protected

The following files contain sensitive information and are excluded from Git:

- `.env` - Environment variables for Flutter
- `android/local.properties` - Android configuration and API keys
- `ios/Runner/GeneratedConfig.plist` - iOS configuration
- Any `google-services.json` or `GoogleService-Info.plist` files

## What's in Version Control

Safe template files that are committed:

- `.env.example` - Template for environment variables
- `android/local.properties.example` - Template for Android config

## Verification

To verify your setup is correct:

1. Check that `.env` exists and has your actual keys
2. Check that `android/local.properties` exists with your paths and API key
3. For iOS, check that `ios/Runner/GeneratedConfig.plist` exists
4. Run `flutter pub get`
5. Try building the app: `flutter run`

## Troubleshooting

### "Unable to load .env file"
- Make sure `.env` exists in the project root
- Verify the file has the correct values (no quotes around values)

### "API key not found" on Android
- Check that `android/local.properties` has `GOOGLE_MAPS_API_KEY`
- Rebuild the app: `flutter clean && flutter pub get && flutter run`

### "API key not found" on iOS
- Ensure `ios/Runner/GeneratedConfig.plist` exists with your API key
- Clean and rebuild: `flutter clean && flutter run`

## Security Best Practices

1. **Never commit** `.env`, `local.properties`, or any file with actual API keys
2. **Always** use the `.example` files as templates for other developers
3. **Rotate API keys** if they are accidentally committed to version control
4. Use **separate API keys** for development and production
5. Consider using **API key restrictions** in Google Cloud Console

## Team Setup

When a new developer joins:

1. Clone the repository
2. Copy all `.example` files to their actual names
3. Request API keys from the team lead
4. Follow the setup steps above
