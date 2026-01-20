# Security Policy

## Sensitive Information

This project uses environment variables to protect sensitive information including:

- **API Keys**: Google Maps, Supabase
- **Database URLs**: Supabase project URLs
- **Authentication tokens**: Supabase anon keys

## Protected Files

The following files contain sensitive information and are **NEVER** committed to version control:

- `.env`
- `android/local.properties`
- `ios/Runner/GeneratedConfig.plist`
- `google-services.json`
- `GoogleService-Info.plist`
- `android/key.properties`
- `android/app/upload-keystore.jks`

## Template Files

Use these template files to set up your local environment:

- `.env.example` → `.env`
- `android/local.properties.example` → `android/local.properties`
- `ios/Runner/GeneratedConfig.plist.example` → `ios/Runner/GeneratedConfig.plist`

## If You Accidentally Commit Sensitive Data

If you accidentally commit API keys or other sensitive information:

1. **Immediately rotate all exposed credentials**
   - Google Maps API: Go to Google Cloud Console → Credentials → Regenerate key
   - Supabase: Go to Project Settings → API → Reset anon key (if possible)

2. **Remove the sensitive data from Git history**
   ```bash
   git filter-branch --force --index-filter \
   "git rm --cached --ignore-unmatch PATH-TO-FILE" \
   --prune-empty --tag-name-filter cat -- --all
   ```

3. **Force push to remote** (coordinate with team first!)
   ```bash
   git push origin --force --all
   ```

4. **Notify team members** to re-clone the repository

## Best Practices

1. ✅ **Always use environment variables** for sensitive data
2. ✅ **Never hardcode** API keys in source code
3. ✅ **Use different keys** for development and production
4. ✅ **Restrict API keys** to specific apps/domains in console
5. ✅ **Review commits** before pushing to ensure no secrets included
6. ✅ **Enable GitHub secret scanning** if using GitHub
7. ✅ **Rotate keys regularly** as a security best practice

## Reporting Security Issues

If you discover a security vulnerability:

1. **Do NOT** open a public issue
2. Email the project maintainer directly
3. Include details about the vulnerability
4. Allow time for a fix before public disclosure

## Git Hooks (Optional)

Consider setting up a pre-commit hook to prevent committing sensitive files:

Create `.git/hooks/pre-commit`:

```bash
#!/bin/sh
# Check for sensitive files
if git diff --cached --name-only | grep -E '\\.env$|local\\.properties$|GeneratedConfig\\.plist$'; then
    echo "ERROR: Attempting to commit sensitive files!"
    echo "Please remove them from the commit."
    exit 1
fi
```

Make it executable:
```bash
chmod +x .git/hooks/pre-commit
```

## Environment Variable Checklist

Before deploying or sharing code:

- [ ] All API keys moved to `.env`
- [ ] `.env` is in `.gitignore`
- [ ] `.env.example` has placeholder values only
- [ ] `android/local.properties` is in `.gitignore`
- [ ] No hardcoded credentials in source files
- [ ] Production keys are different from development keys
- [ ] API keys are restricted by app/domain
