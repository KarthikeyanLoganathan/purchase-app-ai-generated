# Google Sheets Sync Setup Guide

This guide explains how to set up bidirectional synchronization between your Purchase Application and Google Sheets.

## Table of Contents

1. [Overview](#overview)
2. [Google Sheets Setup](#google-sheets-setup)
3. [Mobile App Configuration](#mobile-app-configuration)
4. [How Sync Works](#how-sync-works)
5. [Security](#security)
6. [Troubleshooting](#troubleshooting)

---

## Overview

The Purchase Application can sync all data with a Google Sheet, enabling:
- ✅ **Cloud backup** of all purchase data
- ✅ **Data sharing** across multiple devices
- ✅ **Web-based editing** in Google Sheets
- ✅ **Bidirectional sync** - changes in either location are merged
- ✅ **Conflict resolution** based on timestamps
- ✅ **Secure access** with secret code authentication

---

## Google Sheets Setup

### Step 1: Create a New Google Sheet

1. Go to [Google Sheets](https://sheets.google.com)
2. Click **+ Blank** to create a new spreadsheet
3. Name it (e.g., "Purchase Data")

### Step 2: Add the Apps Script

1. In your Google Sheet, click **Extensions** → **Apps Script**
2. Delete any existing code in the editor
3. Copy the entire contents of `backend/Code.gs` from this repository
4. Paste it into the Apps Script editor
5. Click **Save** (💾 icon)

### Step 3: Run Initial Setup

1. In the Apps Script editor, select the **`setup`** function from the dropdown
2. Click **Run** (▶️ icon)
3. Grant permissions when prompted:
   - Click **Review permissions**
   - Select your Google account
   - Click **Advanced** → **Go to [Your Project] (unsafe)**
   - Click **Allow**

4. After setup completes, return to your Google Sheet
5. You will see **8 new sheets** created:
   - `config` - Contains your APP_CODE secret
   - `manufacturers`
   - `vendors`
   - `materials`
   - `manufacturer_materials`
   - `vendor_price_lists`
   - `purchase_orders`
   - `purchase_order_items`
   - `purchase_order_payments`

### Step 4: Get Your Secret Code

1. Open the **`config`** sheet
2. In cell **B1**, you'll see your **APP_CODE** (a unique random string)
3. **Copy this code** - you'll need it for the mobile app
4. ⚠️ **Keep this code private!** Anyone with this code can access your data

### Step 5: Deploy as Web App

1. Return to the Apps Script editor
2. Click **Deploy** → **New deployment**
3. Click the gear icon ⚙️ next to "Select type"
4. Choose **Web app**
5. Configure:
   - **Description**: "Purchase App Sync API" (or any name)
   - **Execute as**: **Me** (your email)
   - **Who has access**: **Anyone** (don't worry, access requires your secret code)
6. Click **Deploy**
7. **Copy the Web App URL** - it looks like:
   ```
   https://script.google.com/macros/s/AKfycby.../exec
   ```
8. Click **Done**

**Important:** If you modify the Apps Script code later, you must create a **New deployment** (not "Manage deployments") to see the changes take effect.

---

## Mobile App Configuration

### First Time Login

1. Open the Purchase Application on your mobile device
2. You'll see the **Login Screen** with two fields:
   - **Google Sheets Web App URL**
   - **App Secret Code**

3. Enter the details:
   - Paste the **Web App URL** from Step 5 above
   - Paste the **APP_CODE** from the config sheet (Step 4)

4. Click **Connect and Login**

5. If credentials are valid:
   - ✅ You'll be taken to the home screen
   - ✅ Credentials are saved securely in local database
   - ✅ Next time you open the app, you'll be logged in automatically

### Auto-Login

After your first successful login:
- The app saves your Web App URL and Secret Code locally
- Every time you open the app, it checks for saved credentials
- If found, you're automatically logged in to the home screen
- No need to re-enter credentials unless you logout

### Manual Sync

- Click the **Sync** button (↻) in the top-right of the home screen
- The app will:
  1. Download new/updated records from Google Sheets
  2. Upload your local changes to Google Sheets
  3. Show a summary: "Downloaded X, Uploaded Y"

### Auto-Sync on Exit

When you exit or minimize the app:
- The app checks if you have unsynced local changes
- If changes are detected, you'll see a dialog:
  ```
  "You have unsaved changes that need to be synced.
   Do you want to sync now before exiting?"
  ```
- Choose:
  - **Sync Now**: Syncs immediately before closing
  - **Exit Without Sync**: Closes without syncing (changes stay local)

### Logout

To disconnect from Google Sheets:
1. Click the **Logout** button (🚪) in the top-right
2. Confirm the dialog
3. Your sync credentials will be cleared
4. You'll return to the login screen

---

## How Sync Works

### Bidirectional Synchronization

The sync process has two phases:

#### 1. Pull (Download from Google Sheets)
- Fetches records updated in Google Sheets since last sync
- Compares timestamps (`updated_at`)
- If Google Sheets version is newer, local record is updated
- If local version is newer, local record is kept

#### 2. Push (Upload to Google Sheets)
- Finds local records modified since last sync
- Sends them to Google Sheets
- Google Sheets updates or inserts records
- Uses `uuid` field to match records

### Conflict Resolution

**Timestamp-based:**
- Every record has an `updated_at` timestamp
- During sync, the version with the **latest timestamp wins**
- If you edit the same record on both sides:
  - The most recent change will overwrite the older one
  - **No manual merge** - last write wins

### Sync Tables

All data tables are synced in dependency order:
1. `manufacturers`
2. `vendors`
3. `materials`
4. `manufacturer_materials`
5. `vendor_price_lists`
6. `purchase_orders`
7. `purchase_order_items`
8. `purchase_order_payments`

---

## Security

### Authentication

- Every API request requires the **secret code** in the request body
- All requests use **POST method** (including data retrieval) for security
- Google Apps Script validates the code against `config!B1`
- Invalid requests return error responses
- No credentials exposed in URL parameters or browser history

### Credential Storage

- Web App URL and Secret Code are stored in **SQLite** on your device
- Database file is private to the app (Android/iOS sandboxing)
- Credentials are **never transmitted** except during sync API calls

### Network Security

- All communication uses **HTTPS** (enforced by Google)
- Secret code is sent in **POST request body** as JSON:
  ```json
  {
    "operation": "pull",
    "table": "manufacturers",
    "secret": "YOUR_SECRET_CODE",
    "since": "2025-01-15T10:30:00.000Z"
  }
  ```
- **Never exposed in URL parameters** - prevents logging in server logs, browser history, or network proxies

### Best Practices

- ✅ Keep your APP_CODE private
- ✅ Don't share your Web App URL publicly
- ✅ If compromised, generate a new secret code:
  1. Change the value in `config!B1`
  2. Update the code in your mobile app (logout and login again)
- ✅ Use the **Logout** feature if sharing your device

---

## Troubleshooting

### "Invalid URL or Secret Code"

**Cause:** Credentials don't match or API is unreachable

**Solutions:**
1. Double-check the Web App URL (copy the full URL including `https://`)
2. Verify the APP_CODE from `config!B1` in your Google Sheet
3. Ensure you clicked **Deploy → New deployment** in Apps Script
4. Check that you granted permissions during setup

### "Sync credentials not configured"

**Cause:** You haven't logged in yet or logged out

**Solution:**
- Click the **Logout** button and log in again with correct credentials

### Sync button does nothing

**Cause:** No credentials saved

**Solution:**
- Check if you're logged in
- Try logging out and back in

### Data not appearing after sync

**Cause:** Google Sheets might be empty or timestamps are incorrect

**Solutions:**
1. Check your Google Sheet - are there records in the data sheets?
2. Verify the `updated_at` column has valid ISO timestamps
3. Try **pulling** specific test data:
   - Add a record manually to Google Sheets
   - Set `updated_at` to current time: `=TEXT(NOW(),"YYYY-MM-DD")&"T"&TEXT(NOW(),"HH:MM:SS")&".000Z"`
   - Click sync in the app

### Changes not uploading

**Cause:** Last sync timestamp might be newer than local changes

**Solutions:**
1. Check the `updated_at` value of your local record
2. Try editing the record again (this updates the timestamp)
3. Click sync

### Multiple records with same data

**Cause:** UUID mismatch - records aren't being matched correctly

**Solution:**
- This usually happens if you manually created records in Google Sheets
- Ensure every record has a unique `uuid` field
- Delete duplicate records from Google Sheets

---

## Advanced: Manual Sync Reset

If sync gets stuck or behaves unexpectedly:

1. **In the mobile app:**
   - Go to Home Screen
   - Click **Clear All Data** (⚠️ This deletes all local data!)
   - Logout and login again
   - Click Sync to re-download from Google Sheets

2. **In Google Sheets:**
   - You can manually edit data in any sheet
   - Always set `updated_at` to current time when editing
   - Format: `2025-01-15T10:30:00.000Z` (ISO 8601)

---

## Summary

### Setup Checklist

- [ ] Create Google Sheet
- [ ] Add Apps Script code from `backend/Code.gs`
- [ ] Run `setup()` function and grant permissions
- [ ] Copy APP_CODE from `config` sheet
- [ ] Deploy as Web App
- [ ] Copy Web App URL
- [ ] Open mobile app
- [ ] Enter URL and Secret Code
- [ ] Click "Connect and Login"
- [ ] Test sync with sample data

### Daily Usage

- ✅ App auto-logs in after first setup
- ✅ Manual sync anytime with the sync button
- ✅ Auto-prompt to sync before exiting if changes exist
- ✅ Edit data in app or Google Sheets - both work!

---

## Support

For issues or questions:
1. Check [Troubleshooting](#troubleshooting) section
2. Review the Apps Script execution logs:
   - Apps Script editor → **Executions** tab
3. Check mobile app logs for error messages
4. Verify all permissions were granted in Google account settings

