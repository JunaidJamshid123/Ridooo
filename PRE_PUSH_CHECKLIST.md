# Pre-Push Checklist

Before pushing your code to GitHub, ensure:

## 🔒 Security

- [ ] `.env` file is **NOT** being committed (check `git status`)
- [ ] `android/local.properties` is **NOT** being committed
- [ ] `ios/Runner/GeneratedConfig.plist` is **NOT** being committed
- [ ] No API keys are hardcoded in any source files
- [ ] No database passwords or credentials in code
- [ ] `.gitignore` includes all sensitive files

## ✅ Verification Commands

Run these commands to verify:

```bash
# Check what files will be committed
git status

# Check for sensitive patterns in staged files
git diff --cached | grep -i "AIzaSy\|sk_\|pk_\|api.*key\|secret"

# Verify .env is ignored
git check-ignore .env
# Should output: .env

# Verify local.properties is ignored
git check-ignore android/local.properties
# Should output: android/local.properties
```

## 📋 Quick Scan

Search for potential leaked secrets:

```bash
# Search for Google API keys pattern
git grep -i "AIzaSy" -- ':!*.md' ':!ENV_SETUP.md' ':!SECURITY.md'

# Search for Supabase URLs
git grep -i "supabase.co" -- ':!*.md' ':!ENV_SETUP.md'

# Search for "secret" or "key" assignments
git grep -E "(secret|key)\s*=\s*['\"]" -- ':!*.md'
```

## 🎯 Expected Results

These files **SHOULD** be committed:
- ✅ `.env.example`
- ✅ `android/local.properties.example`
- ✅ `ios/Runner/GeneratedConfig.plist.example`
- ✅ `ENV_SETUP.md`
- ✅ `SECURITY.md`
- ✅ Updated `.gitignore`

These files **SHOULD NOT** be committed:
- ❌ `.env`
- ❌ `android/local.properties`
- ❌ `ios/Runner/GeneratedConfig.plist`

## 🔧 Code Changes

Your code should reference environment variables:

```dart
// ✅ CORRECT - Using environment variables
static String get supabaseUrl => EnvConfig.supabaseUrl;
static String get googleMapsApiKey => EnvConfig.googleMapsApiKey;

// ❌ WRONG - Hardcoded values
static const String supabaseUrl = 'https://actual-url.supabase.co';
static const String apiKey = 'AIzaSy...';
```

## 🚀 Ready to Push?

If all checks pass:

```bash
# Add your changes
git add .

# Commit with a meaningful message
git commit -m "feat: secure API keys with environment variables"

# Push to GitHub
git push origin main
```

## ⚠️ If You Find Issues

If you find any sensitive data:

1. Remove it from the commit:
   ```bash
   git reset HEAD <file>
   ```

2. Move sensitive data to environment variables

3. Update `.gitignore` if needed

4. Try again!

## 📚 Additional Resources

- See [ENV_SETUP.md](ENV_SETUP.md) for setup instructions
- See [SECURITY.md](SECURITY.md) for security best practices
- See [.gitignore](.gitignore) for ignored files list
