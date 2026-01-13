# Android Signing Setup Guide - Debug & Release

## Current Setup

Your [build.gradle.kts](android/app/build.gradle.kts) now has both **debug** and **release** signing configurations:

- **Debug Profile**: Uses default debug keystore at `~/.android/debug.keystore`
- **Release Profile**: Uses custom keystore (when configured via `key.properties`)

## Complete Setup for Both Debug and Release

### Step 1: Get Debug Keystore SHA-1 (Already Exists)

The debug keystore is automatically created by Android SDK. Get its SHA-1:

```bash
keytool -list -v -keystore ~/.android/debug.keystore \
  -alias androiddebugkey -storepass android -keypass android | \
  grep -A 2 "Certificate fingerprints"
```

**Your Debug SHA-1:**
```
SHA1: 07:5B:6B:7E:61:0E:B4:D9:25:B4:0C:BE:34:72:8A:DE:36:54:D2:FC
```

> ✅ This is already configured in your current setup

---

### Step 2: Create Release Keystore

Create a directory for your keystores and generate a release keystore:

```bash
# Create directory (if it doesn't exist)
mkdir -p android/keystore

# Generate release keystore
keytool -genkey -v -keystore android/keystore/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```
>Note that keytool asked only one password to be entered and repeated.
>It defaults key password as keystore password.
>So, we hve only one password being dealt here.

You'll be prompted for:
- **Keystore password**: Choose a strong password (remember this!)
- **Key password**: Can be same as keystore password (remember this!)
- **Your details**: Name, organization, location, etc.

**CRITICAL**: Store these passwords securely! You cannot recover them if lost.

---

### Step 3: Create key.properties File

Create `android/key.properties` with your release keystore details:

```bash
cd android
cat > key.properties << 'EOF'
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=keystore/upload-keystore.jks
EOF
```

Or copy from the example:
```bash
cp key.properties.example key.properties
# Then edit key.properties with your actual passwords
```

> **Note**: This file is gitignored for security. Never commit it to version control!

**How key.properties works:**
- ✅ You keep it in the `android/` folder
- ✅ Gradle reads it during build (see [build.gradle.kts](android/app/build.gradle.kts) lines 8-12)
- ❌ `keytool` command doesn't use it - keytool works directly with .jks files
- ✅ Only used by `flutter build` commands, not by `keytool`

---

### Step 4: Get Release Keystore SHA-1

Extract SHA-1 fingerprint from your **release keystore file** (not from key.properties):

```bash
# Note: keytool reads the .jks file directly, not key.properties
keytool -list -v -keystore android/keystore/upload-keystore.jks \
  -alias upload | grep -A 2 "Certificate fingerprints"
```

**You'll be prompted for the keystore password** (the one you set in Step 2).

> 📝 **Important**: The `keytool` command works directly with the keystore file (.jks). It doesn't know about `key.properties`. You need to manually provide the path to the .jks file and enter the password when prompted.

You'll get output like:
```
Certificate fingerprints:
   SHA1: 7C:9C:27:DF:1C:5F:34:47:A0:53:B7:CF:87:2B:93:D0:73:66:A0:3C
   SHA256: 13:30:4D:8B:BD:67:96:E4:CE:F0:DF:43:4D:E0:AE:37:A8:BF:2A:E9:7D:0F:13:32:7E:0E:86:24:FD:1D:86:93
```

**Save this SHA-1** - you'll need it in the next step!

---

### Step 5: How the Build Process Works

Understanding the relationship between files:

```
┌─────────────────────────────────────────────────────────────┐
│ When you run: flutter build apk --release                   │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ 1. Gradle reads: android/key.properties                     │
│    - Gets: storeFile path, passwords, alias                 │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. Gradle opens: android/keystore/upload-keystore.jks       │
│    (using credentials from key.properties)                  │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. Gradle signs your APK using the release keystore         │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ When you run: keytool -list -v -keystore ...                │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌────────────────────────────────────────────────────────────-─┐
│ keytool reads ONLY the .jks file (doesn't use key.properties)│
│ You must specify the file path and password manually         │
└────────────────────────────────────────────────────────────-─┘
```

---

## Step 6: Configure Google Cloud Console (BOTH Debug & Release)

You need to register **BOTH** SHA-1 fingerprints for Google Sign-In to work in both debug and release builds.

#### Option A: Two Separate OAuth Clients (Recommended)

1. Go to: https://console.cloud.google.com/apis/credentials?project=purchase-app-7f2c3

2. **Create Debug OAuth Client:**
   - Click **"+ CREATE CREDENTIALS"** → **"OAuth client ID"** → **"Android"**
   - **Name**: `Purchase App (Debug)`
   - **Package name**: `com.purchase.purchase_app`
   - **SHA-1**: `07:5B:6B:7E:61:0E:B4:D9:25:B4:0C:BE:34:72:8A:DE:36:54:D2:FC`
   - Click **CREATE**

3. **Create Release OAuth Client:**
   - Click **"+ CREATE CREDENTIALS"** → **"OAuth client ID"** → **"Android"**
   - **Name**: `Purchase App (Release)`
   - **Package name**: `com.purchase.purchase_app`
   - **SHA-1**: `7C:9C:27:DF:1C:5F:34:47:A0:53:B7:CF:87:2B:93:D0:73:66:A0:3C`
   - Click **CREATE**

#### Option B: Add Multiple SHA-1s to One Client (Alternative)

Some versions of Google Cloud Console allow adding multiple SHA-1s to a single OAuth client:

1. Open your existing Android OAuth client
2. Click **"Add fingerprint"**
3. Add both debug and release SHA-1 fingerprints

---

### Step 7: Update google-services.json

After adding OAuth clients, download the updated configuration:

1. Go to Firebase Console: https://console.firebase.google.com/project/purchase-app-7f2c3/settings/general

2. Find your Android app: `com.purchase.purchase_app`

3. Click **Download google-services.json**

4. Replace your current file:
   ```bash
   # Backup current file
   cp android/app/google-services.json android/app/google-services.json.backup
   
   # Copy new file
   cp ~/Downloads/google-services.json android/app/google-services.json
   ```

5. **Verify** the file contains oauth_client entries with BOTH SHA-1 hashes:
   ```bash
   grep -A 5 "certificate_hash" android/app/google-services.json
   ```

---

## Step 8: Build and Test

### Debug Build

```bash
# Run in debug mode (uses debug keystore)
flutter run --debug

# Or build debug APK
flutter build apk --debug
```

**What happens:**
- Uses debug keystore at `~/.android/debug.keystore`
- Uses debug SHA-1: `07:5B:6B:7E:61:0E:B4:D9:25:B4:0C:BE:34:72:8A:DE:36:54:D2:FC`
- Google Sign-In works with debug OAuth client

---

### Release Build

```bash
# Clean previous builds
flutter clean

# Build release APK (uses release keystore from key.properties)
flutter build apk --release

# Or build App Bundle for Play Store
flutter build appbundle --release

# Test release build on device
flutter install --release
```

**What happens:**
- Uses release keystore at `keystore/upload-keystore.jks`
- Uses your release SHA-1 from the custom keystore
- Google Sign-In works with release OAuth client

---

## Verification Checklist

Before testing Google Sign-In, verify:

- [ ] **Debug SHA-1** added to Google Cloud Console
- [ ] **Release SHA-1** added to Google Cloud Console  
- [ ] `key.properties` file created with correct passwords
- [ ] Release keystore file exists at `keystore/upload-keystore.jks`
- [ ] Updated `google-services.json` downloaded and replaced
- [ ] App uninstalled and reinstalled on test device
- [ ] Waited 5-10 minutes for Google OAuth changes to propagate

---

## Testing Google Sign-In

### Test Debug Build

1. Build and install debug APK:
   ```bash
   flutter build apk --debug
   adb install build/app/outputs/flutter-apk/app-debug.apk
   ```

2. Open app and test Google Sign-In
3. Should work with debug OAuth client

### Test Release Build

1. Build and install release APK:
   ```bash
   flutter build apk --release
   adb install build/app/outputs/flutter-apk/app-release.apk
   ```

2. Open app and test Google Sign-In
3. Should work with release OAuth client

---

## Current Configuration Status

### Step 6: Update google-services.json

After adding OAuth clients, download the updated configuration:

1. Go to Firebase Console: https://console.firebase.google.com/project/purchase-app-7f2c3/settings/general

2. Find your Android app: `com.purchase.purchase_app`

### Debug Build ✅
- ✅ Debug keystore exists (automatic)
- ✅ Debug SHA-1 extracted: `07:5B:6B:7E:61:0E:B4:D9:25:B4:0C:BE:34:72:8A:DE:36:54:D2:FC`
- ⚠️ Debug SHA-1 needs to be in Google Cloud Console
- ⚠️ Debug OAuth client needs to be created/verified

### Release Build ⚠️
- ⚠️ Release keystore needs to be created
- ⚠️ `key.properties` file needs to be created
- ⚠️ Release SHA-1 needs to be extracted
- ⚠️ Release SHA-1 needs to be added to Google Cloud Console
- ⚠️ Release OAuth client needs to be created
- ⚠️ Updated `google-services.json` needs to be downloaded

### Summary
Both debug and release builds need their respective SHA-1 fingerprints registered in Google Cloud Console for Google Sign-In to work properly
   ```bash
   # Backup current file
   cp android/app/google-services.json android/app/google-services.json.backup
   
   # Copy new file
   cp ~/Downloads/google-services.json android/app/google-services.json
   ```

5. **Verify** the file contains oauth_client entries with BOTH SHA-1 hashes:
   ```bash
   grep -A 5 "certificate_hash" android/app/google-services.json
   ```

## Step 5: Build Release APK

```bash
# Clean build
flutter clean

# Build release APK (will use release signing if key.properties exists)
flutter build apk --release

# Or build App Bundle for Play Store
flutter build appbundle --release
```

## Testing

### Debug Build
```bash
flutter run --debug
# Uses debug keystore automatically
```

### Release Build  
```bash
flutter run --release
# Uses release keystore if key.properties exists, otherwise debug keystore
```

## Troubleshooting Google Sign-In Error 10

If you still get `PlatformException(sign_in_failed, C0.e: 10: , null, null)`:

1. **Verify SHA-1 is registered**: Check Google Cloud Console has the correct SHA-1
2. **Clear app data**: Uninstall and reinstall the app on your phone
3. **Wait for propagation**: Google OAuth changes can take 5-10 minutes
4. **Check package name**: Ensure it matches exactly: `com.purchase.purchase_app`
5. **Verify google-services.json**: Should have oauth_client entries with your SHA-1 hashes

## Current Configuration Status

✅ **Debug signing**: Configured (uses default debug keystore)  
⚠️ **Release signing**: Needs setup (create key.properties)  
⚠️ **Google OAuth**: Add release SHA-1 to Cloud Console  

## GitHub Actions / CI/CD Setup

### ⚠️ NEVER Commit Keystores to Git!

Your keystores and `key.properties` are gitignored for security. For GitHub Actions builds, use GitHub Secrets instead.

### Step 1: Encode Your Keystore

```bash
# On macOS/Linux:
base64 -i android/keystore/upload-keystore.jks | pbcopy
# The base64 string is now in your clipboard

# On Windows (PowerShell):
[Convert]::ToBase64String([IO.File]::ReadAllBytes("android\keystore\upload-keystore.jks")) | Set-Clipboard
```

### Step 2: Add GitHub Secrets

Go to your GitHub repository → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

Add these **4 secrets**:

| Secret Name | Value | Example |
|------------|-------|---------|
| `KEYSTORE_BASE64` | (paste clipboard) | `MIIKPAIBAzCCCf...` (very long) |
| `KEYSTORE_PASSWORD` | Your keystore password | `MyStr0ngP@ssw0rd` |
| `KEY_PASSWORD` | Your key password | `MyStr0ngP@ssw0rd` |
| `KEY_ALIAS` | Your key alias | `upload` |

### Step 3: How GitHub Actions Works

When you push a tag (e.g., `v1.0.0`), the workflow in [.github/workflows/release.yml](../.github/workflows/release.yml):

1. ✅ Checks if `KEYSTORE_BASE64` secret exists
2. ✅ If yes, decodes it to `android/keystore/upload-keystore.jks`
3. ✅ Creates `android/key.properties` from secrets
4. ✅ Builds a **release-signed APK**
5. ✅ If no secrets, builds with **debug signing** (works but less secure)
6. ✅ Creates GitHub release with the APK

**Workflow code:**
```yaml
- name: Configure signing (if secrets available)
  if: secrets.KEYSTORE_BASE64 != ''
  run: |
    # Decode keystore from base64
    echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 -d > android/keystore/upload-keystore.jks
    
    # Create key.properties
    cat > android/key.properties << EOF
    storePassword=${{ secrets.KEYSTORE_PASSWORD }}
    keyPassword=${{ secrets.KEY_PASSWORD }}
    keyAlias=${{ secrets.KEY_ALIAS }}
    storeFile=keystore/upload-keystore.jks
    EOF

- name: Build APK
  run: flutter build apk --release
```

### Step 4: Trigger a Release Build

```bash
# Create and push a tag
git tag v1.0.0
git push origin v1.0.0

# GitHub Actions will automatically:
# 1. Build the release APK with your signing key
# 2. Create a GitHub Release
# 3. Attach the signed APK
```

### Step 5: Verify the Build

1. Go to **Actions** tab in GitHub
2. Watch the build progress
3. Check **Releases** tab for the signed APK
4. Download and verify the SHA-1:
   ```bash
   # Extract SHA-1 from APK
   keytool -printcert -jarfile app-release.apk | grep SHA1
   ```

### Security Benefits of GitHub Secrets

✅ **Encrypted at rest**: Secrets are encrypted in GitHub's database  
✅ **Redacted in logs**: Never appear in build logs  
✅ **Scoped access**: Only workflows can access them  
✅ **Temporary**: Decoded files exist only during build, then destroyed  
✅ **No git history**: Never in repository or commit history  

### Fallback Behavior

If GitHub Secrets are **not configured**:
- Builds still succeed ✅
- Uses Gradle's auto-generated debug keystore
- APK is signed but with debug signature
- Release notes indicate "Debug-signed (for testing only)"
- Good for testing, **not for production**

### When to Use Each Approach

| Scenario | Use |
|----------|-----|
| **Local development** | `key.properties` + local keystore |
| **GitHub Actions** | GitHub Secrets (base64 encoded) |
| **Other CI/CD** | Environment variables or secret managers |
| **Manual builds** | `key.properties` + local keystore |

## Security Notes

- ✅ `key.properties` is in .gitignore
- ✅ `*.jks` and `*.keystore` are in .gitignore  
- ✅ `keystore/` directory is in .gitignore
- ⚠️ **NEVER commit keystores to git** - use GitHub Secrets for CI/CD
- ⚠️ **Backup your keystore file safely!** If lost, you cannot update your app on Play Store
- ⚠️ Store passwords in a password manager
- ⚠️ Keystore files are irreplaceable - losing them means losing your app identity
