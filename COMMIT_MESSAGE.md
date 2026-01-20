# Suggested Commit Message

```
feat: secure API keys and sensitive data with environment variables

- Moved Supabase URL and anon key to .env file
- Moved Google Maps API key to environment configuration
- Created env_config.dart to load environment variables
- Updated supabase_config.dart to use EnvConfig
- Updated directions_service.dart to use EnvConfig
- Updated places_service.dart to use EnvConfig
- Updated Android manifest to use Gradle placeholders
- Updated iOS AppDelegate to load from plist
- Added flutter_dotenv dependency
- Updated .gitignore to exclude sensitive files
- Created setup documentation and scripts

BREAKING CHANGE: Developers must now set up .env file
See ENV_SETUP.md for setup instructions

Files that need local configuration:
- .env (copy from .env.example)
- android/local.properties (copy from example)
- ios/Runner/GeneratedConfig.plist (copy from example)

Security improvements:
- No API keys in version control
- Easy key rotation if compromised
- Support for different keys per environment
- Follows open-source security best practices
```

---

## Alternative Short Commit Message

```
feat: secure API keys with environment variables

All API keys and sensitive URLs moved to environment variables.
New developers: run setup.ps1 or setup.sh
See ENV_SETUP.md for details.
```

---

## Files Changed Summary

**Modified Files (Security Updates):**
- lib/core/config/supabase_config.dart
- lib/core/services/directions_service.dart
- lib/core/services/places_service.dart
- android/app/src/main/AndroidManifest.xml
- android/app/build.gradle.kts
- ios/Runner/AppDelegate.swift
- lib/main.dart
- pubspec.yaml
- .gitignore

**New Files (Configuration & Documentation):**
- .env.example
- .env (local only, not committed)
- lib/core/config/env_config.dart
- android/local.properties.example
- ios/Runner/GeneratedConfig.plist.example
- ios/Runner/GeneratedConfig.plist (local only, not committed)
- ENV_SETUP.md
- SECURITY.md
- PRE_PUSH_CHECKLIST.md
- MIGRATION_SUMMARY.md
- QUICK_REFERENCE.md
- setup.ps1
- setup.sh

**Files Protected (Not in Git):**
- .env
- android/local.properties
- ios/Runner/GeneratedConfig.plist
