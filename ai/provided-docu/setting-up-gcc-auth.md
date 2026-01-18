# Setting Up Google Cloud Console OAuth Authentication

## Overview

The automated Google Sheets setup feature requires OAuth 2.0 configuration for Android to enable Google Sign-In. This document provides step-by-step instructions for configuring the necessary credentials.

## Error Code Reference

If you encounter the error:
```
PlatformException(sign_in_failed, com.google.android.gms.common.api.ApiException: 10:, null, null)
```

Error code `10` indicates `DEVELOPER_ERROR`, which means OAuth credentials are not properly configured for your Android app.

## Prerequisites

- A Google Cloud Platform account
- Android development environment with debug keystore
- Package name: `com.purchase.purchase_app`

## Step-by-Step Configuration

### 1. Access Google Cloud Console

1. Navigate to [Google Cloud Console](https://console.cloud.google.com)
2. Create a new project or select an existing one
3. Note your project ID for reference

### 2. Enable Required APIs

1. Go to **APIs & Services** → **Library**
2. Search for and enable the following APIs:
   - **Google Sheets API**
   - **Google Apps Script API**
   - **Google Drive API** (for file creation)

### 3. Configure OAuth Consent Screen

1. Go to **APIs & Services** → **OAuth consent screen**
2. Select **External** user type (or Internal if using Google Workspace)
3. Fill in required fields:
   - App name: `Purchase App`
   - User support email: Your email
   - Developer contact email: Your email
4. Add scopes:
   - `https://www.googleapis.com/auth/spreadsheets`
   - `https://www.googleapis.com/auth/script.projects`
   - `https://www.googleapis.com/auth/drive.file`
5. Add test users (your email address)
6. Save and continue

### 4. Get SHA-1 Certificate Fingerprint

For **debug builds**, run this command in your terminal:

```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

For **release builds**, use your release keystore:

```bash
keytool -list -v -keystore /path/to/your/release.keystore -alias your-key-alias
```

Copy the **SHA-1** fingerprint from the output (looks like: `A1:B2:C3:D4:...`)

### 5. Create OAuth 2.0 Credentials

1. Go to **APIs & Services** → **Credentials**
2. Click **+ CREATE CREDENTIALS** → **OAuth client ID**
3. Select **Android** as the application type
4. Fill in the details:
   - **Name**: `Purchase App Android`
   - **Package name**: `com.purchase.purchase_app`
   - **SHA-1 certificate fingerprint**: Paste the fingerprint from step 4
5. Click **Create**

### 6. Download Configuration Files (Optional)

While `google-services.json` is not strictly required for `google_sign_in` package, having it can help with other Google services:

1. Go to **Project Settings** (gear icon)
2. Select your Android app
3. Download `google-services.json`
4. Place it in `android/app/google-services.json`

### 7. Verify Configuration

After configuration, test the sign-in:

1. Restart your Flutter app (full restart, not hot reload)
2. Navigate to **Setup Google Sheets** screen
3. Click **Sign in with Google**
4. You should see Google's consent screen
5. Grant permissions when prompted

## Troubleshooting

### Sign-in still fails after configuration

1. **Clear app data**: Uninstall and reinstall the app
2. **Check package name**: Ensure it matches exactly: `com.purchase.purchase_app`
3. **Verify SHA-1**: Make sure you used the correct keystore (debug vs release)
4. **Wait for propagation**: Changes can take a few minutes to propagate

### OAuth consent screen errors

1. Ensure test users are added if using External user type
2. Verify all required scopes are added
3. Check that the app is not in "Testing" mode if you need wider access

### Multiple SHA-1 fingerprints

If you develop on multiple machines or use both debug and release builds, you can add multiple SHA-1 fingerprints to the same OAuth client.

## Alternative: Manual Setup

If OAuth configuration is too complex or not feasible, you can set up Google Sheets manually:

### Manual Setup Steps

1. **Create Google Sheet**
   - Go to [Google Sheets](https://sheets.google.com)
   - Create a new spreadsheet
   - Name it appropriately (e.g., "Purchase App Data")

2. **Add Config Sheet**
   - Create a new sheet named `config`
   - Add headers in row 1: `name`, `value`, `description`
   - Add row 2: `APP_CODE`, `[your-secret-code]`, `the secret`

3. **Deploy Apps Script**
   - In Google Sheets, go to **Extensions** → **Apps Script**
   - Copy all `.js` files from `backend/google-app-script-code/` directory
   - Paste each file into the Apps Script editor
   - Save the project

4. **Deploy as Web App**
   - Click **Deploy** → **New deployment**
   - Type: **Web app**
   - Execute as: **Me** (your email)
   - Who has access: **Anyone**
   - Click **Deploy**
   - Copy the **Web App URL**

5. **Configure in Mobile App**
   - Open the Purchase App
   - Go to **Login** (not Setup Google Sheets)
   - Enter the Web App URL
   - Enter your secret code (APP_CODE from step 2)
   - Click Login

6. **Initialize Sheets** (Optional)
   - You can manually call the setup endpoint:
   ```bash
   curl -X POST [WEB_APP_URL] \
     -H "Content-Type: application/json" \
     -d '{"secret":"[YOUR_APP_CODE]","operation":"setupSheets"}'
   ```

## Security Considerations

### Protect Your Credentials

- Never commit `google-services.json` to public repositories
- Keep your APP_CODE secret secure
- Use strong, unique codes (minimum 8 characters, recommended 16+)
- Rotate secrets periodically

### Scope Permissions

The app requests these scopes:
- `spreadsheets`: Create and modify Google Sheets
- `script.projects`: Deploy Apps Script code
- `drive.file`: Create files in Google Drive

These are necessary for automated setup and cannot be reduced.

### OAuth Token Management

- Tokens are stored securely by the `google_sign_in` package
- They expire after 1 hour and are automatically refreshed
- Sign out when done to revoke access

## Resources

- [Google Cloud Console](https://console.cloud.google.com)
- [Google Sign-In for Android Documentation](https://developers.google.com/identity/sign-in/android/start)
- [Google Sheets API Documentation](https://developers.google.com/sheets/api)
- [Apps Script API Documentation](https://developers.google.com/apps-script/api)

## Support

If you continue to experience issues:

1. Check the error dialog in the app for specific error codes
2. Review the Google Cloud Console audit logs
3. Verify API quotas are not exceeded
4. Consider using the manual setup option as a reliable alternative
