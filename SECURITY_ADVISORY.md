# ⚠️ IMPORTANT SECURITY NOTICE

## Google Cloud API Key Security

**CRITICAL:** If you're reading this and have access to an actual Google Maps API key that was previously exposed in this repository, you should:

### Immediate Actions Required:

1. **Regenerate Your API Key Immediately**
   - Go to [Google Cloud Console](https://console.cloud.google.com)
   - Navigate to: APIs & Services → Credentials
   - Find your API key
   - Click "Regenerate Key" or create a new key
   - Delete the old exposed key

2. **Restrict Your New API Key**
   - Set application restrictions (Android/iOS app package name)
   - Set API restrictions (only enable needed APIs)
   - Add HTTP referrer restrictions if applicable
   - Never use the same key for development and production

3. **Update Your Local Environment**
   - Update `.env` file with the new key
   - Update `android/local.properties` with the new key
   - Update `ios/Runner/GeneratedConfig.plist` with the new key

### Why This Matters

An exposed Google Maps API key can be:
- Used by anyone to consume your API quota
- Abused to generate costs on your Google Cloud account
- Used to make unauthorized API calls

### API Key Restrictions Checklist

Set these restrictions in Google Cloud Console:

#### Application Restrictions
- [ ] Android app: Set package name (com.example.ridooo)
- [ ] iOS app: Set bundle identifier
- [ ] SHA-1 certificate fingerprint (for Android)

#### API Restrictions
Enable ONLY these APIs:
- [ ] Maps SDK for Android
- [ ] Maps SDK for iOS
- [ ] Directions API
- [ ] Places API
- [ ] Geocoding API
- [ ] Distance Matrix API

### Monitoring Your API Usage

1. Set up budget alerts in Google Cloud Console
2. Monitor API usage regularly
3. Set quota limits to prevent abuse
4. Enable billing alerts

### Best Practices Going Forward

1. ✅ **Always** use environment variables
2. ✅ **Never** commit `.env` files
3. ✅ **Always** restrict API keys
4. ✅ **Rotate** keys regularly (every 90 days recommended)
5. ✅ **Different keys** for dev/staging/production
6. ✅ **Monitor** usage and costs
7. ✅ **Enable** billing alerts

### Supabase Security

Similar precautions apply to Supabase:

1. **Use Row Level Security (RLS)**
   - Enable RLS on all tables
   - Create appropriate policies
   - Never expose service_role key

2. **Anon Key is Safe for Public Use**
   - The anon key is designed to be public
   - Security comes from RLS policies
   - However, still use environment variables for clean code

3. **Monitor Database Usage**
   - Set up usage alerts
   - Monitor query performance
   - Watch for unusual patterns

### If You Suspect Key Compromise

1. **Immediately** disable/regenerate the key
2. **Check** Google Cloud billing for unauthorized usage
3. **Review** API usage logs
4. **Set up** stricter restrictions
5. **Consider** contacting Google Cloud Support if needed

### Questions?

See these files for more information:
- [ENV_SETUP.md](ENV_SETUP.md) - Environment setup
- [SECURITY.md](SECURITY.md) - Security policy
- [QUICK_REFERENCE.md](QUICK_REFERENCE.md) - Quick reference

---

**Last Updated**: January 20, 2026

**Status**: All credentials moved to environment variables ✅
