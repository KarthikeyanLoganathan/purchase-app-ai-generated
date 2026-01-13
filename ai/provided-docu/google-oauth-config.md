# Google Cloud Console OAuth Setup Guide

This guide explains how to set up OAuth configuration in Google Cloud Console for the Purchase App's Google Sign-In functionality.

## Step 1: Create/Select a Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Click the project dropdown at the top
3. Click "New Project" or select an existing one
4. Give it a name (e.g., "Purchase App")
5. Click "Create"

## Step 2: Enable Required APIs

1. In the left sidebar, go to **APIs & Services** → **Library**
2. Search for and enable these APIs:
   - **Google Sheets API**
   - **Google Apps Script API**
   - **Google Drive API**

## Step 3: Configure OAuth Consent Screen

1. Go to **APIs & Services** → **OAuth consent screen**
2. Choose **External** user type (unless you have Google Workspace)
3. Click "Create"
4. Fill in required fields:
   - App name: "Purchase App"
   - User support email: your email
   - Developer contact email: your email
5. Click "Save and Continue"
6. Add scopes (click "Add or Remove Scopes"):
   - `https://www.googleapis.com/auth/spreadsheets`
   - `https://www.googleapis.com/auth/script.projects`
   - `https://www.googleapis.com/auth/script.deployments`
   - `https://www.googleapis.com/auth/drive.file`
7. Click "Save and Continue"
8. Add test users (your email address)
9. Click "Save and Continue"

## Step 4: Get SHA-1 Certificate Fingerprint

### For Debug Builds

Run this command in your terminal:

```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Copy the **SHA-1** fingerprint (looks like `AA:BB:CC:DD:...`)

### For Release Builds

You'll also need:

```bash
keytool -list -v -keystore /path/to/your/release.keystore -alias your-key-alias
```

## Step 5: Create OAuth 2.0 Client ID (Android)

1. Go to **APIs & Services** → **Credentials**
2. Click **"+ CREATE CREDENTIALS"** → **OAuth client ID**
3. Select **Android** as application type
4. Fill in:
   - **Name**: "Purchase App Android"
   - **Package name**: `com.purchase.purchase_app` (from your AndroidManifest.xml)
   - **SHA-1 certificate fingerprint**: paste the SHA-1 from Step 4
5. Click **Create**

## Step 6: Create OAuth 2.0 Client ID (Web) - for iOS/Web

You may also need a Web client ID:

1. Click **"+ CREATE CREDENTIALS"** → **OAuth client ID**
2. Select **Web application**
3. Name it "Purchase App Web"
4. Click **Create**
5. **Copy the Client ID** - you'll need this

## Step 7: Update Your Flutter App

### Option A: Without google-services.json (Current Setup - Simplest)

The app currently uses this configuration in `lib/screens/setup_google_sheet_screen.dart`:

```dart
final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: [
    'https://www.googleapis.com/auth/spreadsheets',
    'https://www.googleapis.com/auth/script.projects',
    'https://www.googleapis.com/auth/script.deployments',
    'https://www.googleapis.com/auth/drive.file',
  ],
  // serverClientId is optional - only needed for iOS/Web or backend verification
  // serverClientId: 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com',
);
```

**Note:** The `serverClientId` is commented out because it's not required for Android-only apps. Uncomment and set it only if you need iOS/Web support or server-side token verification.

### Option B: With google-services.json (recommended for production)

You need to create a Firebase project and link it:

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Add your Google Cloud project or create new one
3. Add Android app with package name `com.purchase.purchase_app`
4. Download `google-services.json`
5. Place it in `android/app/google-services.json`
6. Update `android/build.gradle.kts` to include:
   ```kotlin
   dependencies {
       classpath("com.google.gms:google-services:4.4.0")
   }
   ```
7. Update `android/app/build.gradle.kts` plugins section:
   ```kotlin
   plugins {
       id("com.android.application")
       id("kotlin-android")
       id("dev.flutter.flutter-gradle-plugin")
       id("com.google.gms.google-services")  // Add this line
   }
   ```

**Note:** This app already has `google-services` plugin configured in `android/app/build.gradle.kts`.

## Step 8: Verify Package Name

The app uses package name: **`com.purchase.purchase_app`**

This is defined in `android/app/build.gradle.kts`:
```kotlin
android {
    namespace = "com.purchase.purchase_app"
    // ...
    defaultConfig {
        applicationId = "com.purchase.purchase_app"
        // ...
    }
}
```

**Important:** Make sure this matches the package name you entered when creating the OAuth client in Step 5.

## Step 9: Test the Sign-In

1. Run `flutter clean`
2. Run `flutter pub get`
3. Rebuild and run your app
4. Try signing in again

### New Feature: Google Resource Management

After signing in, the app now displays existing Google resources:
- **Google Sheets** - View and delete linked spreadsheets
- **Apps Script Projects** - View and delete associated script projects

These are stored in the local database (`local_settings` table) with keys:
- `google_sheet_id` - The spreadsheet ID
- `google_script_id` - The Apps Script project ID

You can delete these resources directly from the Setup Google Sheet screen.

## Troubleshooting Tips

- **"Sign in failed: PlatformException"**: SHA-1 mismatch or OAuth client not configured
- **"API not enabled"**: Make sure all APIs are enabled in Step 2
- **"Access blocked"**: Add your email as a test user in OAuth consent screen
- **SHA-1 changes**: Debug and release keystores have different SHA-1s. Make sure to add both SHA-1 fingerprints if you're testing with both debug and release builds

## Common Issues

### Issue: "Developer Error" or "API not enabled"

**Solution**: 
- Ensure all required APIs are enabled in Google Cloud Console
- Wait a few minutes after enabling APIs for changes to propagate

### Issue: "Sign in failed" with no specific error

**Solution**:
- Verify SHA-1 fingerprint is correct and matches the keystore you're using
- Check that the package name in AndroidManifest.xml matches the OAuth client configuration
- Ensure you're using the correct Google account (one added as a test user)

### Issue: "Access blocked: This app's request is invalid"

**Solution**:
- Make sure your app is in testing mode in OAuth consent screen
- Add your email as a test user
- Check that all required scopes are configured

## Prerequisites: Installing gcloud CLI

To use the automation scripts, you need to install the gcloud CLI first.

### On macOS

#### Option 1: Using Homebrew (Recommended - Easiest)

```bash
brew install --cask google-cloud-sdk
```

Then initialize:
```bash
gcloud init
```

#### Option 2: Using the Official Installer

1. Download the installer:
```bash
# For Apple Silicon (M1/M2/M3)
curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-darwin-arm64.tar.gz

# For Intel Mac
curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-darwin-x86_64.tar.gz
```

2. Extract and install:
```bash
tar -xf google-cloud-cli-darwin-*.tar.gz
./google-cloud-sdk/install.sh
```

3. Initialize:
```bash
./google-cloud-sdk/bin/gcloud init
```

#### Option 3: Direct Download

Visit: https://cloud.google.com/sdk/docs/install-sdk

### On Linux

```bash
# Add Cloud SDK distribution URI as a package source
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list

# Import Google Cloud public key
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -

# Update and install
sudo apt-get update && sudo apt-get install google-cloud-cli
```

### On Windows

1. Download the installer: https://dl.google.com/dl/cloudsdk/channels/rapid/GoogleCloudSDKInstaller.exe
2. Run the installer
3. Follow the installation wizard
4. Initialize: `gcloud init`

### After Installation

1. **Login to Google Cloud:**
   ```bash
   gcloud auth login
   ```

2. **List your projects:**
   ```bash
   gcloud projects list
   ```

3. **Set default project:**
   ```bash
   gcloud config set project YOUR_PROJECT_ID
   ```

4. **Verify Installation:**
   ```bash
   gcloud --version
   ```

   You should see output like:
   ```
   Google Cloud SDK 459.0.0
   ```

## Automation Options

While Google Cloud Console OAuth setup cannot be fully automated due to security requirements, you can automate some parts:

### Option 1: Semi-Automated Script with gcloud CLI

```bash
#!/bin/bash
# setup-gcp-oauth.sh

# Variables - UPDATE THESE
PROJECT_ID="purchase-app-12345"  # Your GCP project ID
PACKAGE_NAME="com.purchase.purchase_app"
SHA1_DEBUG=$(keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android 2>/dev/null | grep "SHA1:" | cut -d' ' -f3)

echo "==================================================================="
echo "Google Cloud Platform OAuth Setup Helper"
echo "==================================================================="
echo ""

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo "ERROR: gcloud CLI is not installed"
    echo "Install from: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Set the project
echo "Setting project to: $PROJECT_ID"
gcloud config set project $PROJECT_ID

# Enable required APIs
echo ""
echo "Enabling required APIs..."
gcloud services enable sheets.googleapis.com
gcloud services enable script.googleapis.com
gcloud services enable drive.googleapis.com
echo "Note: script.googleapis.com includes both projects and deployments scopes"
echo "✓ APIs enabled successfully!"

# Get SHA-1 fingerprint
echo ""
echo "==================================================================="
echo "Debug Keystore SHA-1 Fingerprint:"
echo "$SHA1_DEBUG"
echo "==================================================================="
echo ""

# Display manual steps
echo "AUTOMATED STEPS COMPLETED!"
echo ""
echo "==================================================================="
echo "MANUAL STEPS REQUIRED (Cannot be automated):"
echo "==================================================================="
echo ""
echo "1. Configure OAuth Consent Screen:"
echo "   https://console.cloud.google.com/apis/credentials/consent?project=$PROJECT_ID"
echo ""
echo "   - User Type: External"
echo "   - App name: Purchase App"
echo "   - Add scopes:"
echo "     • https://www.googleapis.com/auth/spreadsheets"
echo "     • https://www.googleapis.com/auth/script.projects"
echo "     • https://www.googleapis.com/auth/script.deployments"
echo "     • https://www.googleapis.com/auth/drive.file"
echo "   - Add your email as test user"
echo ""
echo "2. Create Android OAuth Client:"
echo "   https://console.cloud.google.com/apis/credentials?project=$PROJECT_ID"
echo ""
echo "   - Click: CREATE CREDENTIALS → OAuth client ID"
echo "   - Application type: Android"
echo "   - Package name: $PACKAGE_NAME"
echo "   - SHA-1 fingerprint: $SHA1_DEBUG"
echo ""
echo "3. (Optional) Create Web OAuth Client for iOS/Web support:"
echo "   - Application type: Web application"
echo "   - Copy the Client ID for your Flutter app"
echo ""
echo "==================================================================="
echo "For release builds, also run:"
echo "keytool -list -v -keystore /path/to/release.keystore -alias your-key-alias"
echo "==================================================================="
```

Save as `setup-gcp-oauth.sh`, make executable with `chmod +x setup-gcp-oauth.sh`, then run `./setup-gcp-oauth.sh`.

### Option 2: Quick SHA-1 Getter Script

```bash
#!/bin/bash
# get-sha1.sh

echo "==================================================================="
echo "Android Keystore SHA-1 Fingerprints"
echo "==================================================================="
echo ""

echo "DEBUG Keystore SHA-1:"
SHA1_DEBUG=$(keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android 2>/dev/null | grep "SHA1:" | cut -d' ' -f3)
echo "$SHA1_DEBUG"
echo ""

if [ -f "$1" ]; then
    echo "RELEASE Keystore SHA-1 (from: $1):"
    keytool -list -v -keystore "$1" | grep "SHA1:" | cut -d' ' -f3
    echo ""
fi

echo "==================================================================="
echo "Copy the SHA-1 fingerprint above and use it in:"
echo "Google Cloud Console → Credentials → Android OAuth Client"
echo "==================================================================="
```

Usage:
- Debug: `./get-sha1.sh`
- Release: `./get-sha1.sh /path/to/release.keystore`

### Option 3: Terraform (Infrastructure as Code)

```hcl
# main.tf
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
}

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

# Enable APIs
resource "google_project_service" "sheets" {
  service            = "sheets.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "script" {
  service            = "script.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "drive" {
  service            = "drive.googleapis.com"
  disable_on_destroy = false
}

# Note: OAuth consent screen configuration is not fully supported in Terraform
# You must configure it manually in the Google Cloud Console
```

Run with:
```bash
terraform init
terraform apply -var="project_id=your-project-id"
```

### Why Full Automation Is Not Possible

Google intentionally requires manual steps for security reasons:

1. **OAuth Consent Screen** - Requires human verification of app details and brand
2. **Test User Configuration** - Must manually specify which emails can access
3. **Scope Justification** - Sensitive scopes require explanation
4. **Terms Acceptance** - Must be accepted interactively
5. **Credentials Download** - Security measure to prevent automated credential harvesting

### Recommended Workflow

1. **Run the automation script** (enables APIs, gets SHA-1)
2. **Follow the provided links** to complete manual steps
3. **Bookmark the OAuth consent URL** for future test user additions
4. **Save credentials securely** (never commit to git)

## Additional Resources

- [Google Sign-In for Flutter](https://pub.dev/packages/google_sign_in)
- [Google Cloud Console](https://console.cloud.google.com/)
- [Firebase Console](https://console.firebase.google.com/)
- [OAuth 2.0 Documentation](https://developers.google.com/identity/protocols/oauth2)
- [gcloud CLI Installation](https://cloud.google.com/sdk/docs/install)
- [Terraform Google Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)

## Notes

- OAuth consent screen must be configured before creating credentials
- Test users are limited to 100 in testing mode
- For production, you'll need to submit your app for verification if you use sensitive scopes
- Keep your client IDs and secrets secure; never commit them to public repositories
- The automation scripts are helpers only - they cannot replace all manual steps
- Debug and release keystores have different SHA-1 fingerprints - add both to your OAuth client
