# Purchase App - Google Sheets Backend

This folder contains the Google Apps Script code that serves as the backend for the Purchase mobile app with secure authentication.

## Setup Instructions

### 1. Create a Google Sheet

1. Go to [Google Sheets](https://sheets.google.com)
2. Create a new blank spreadsheet
3. Name it "Purchase App Data" (or any name you prefer)

### 2. Deploy the Google Apps Script

1. In your Google Sheet, go to **Extensions > Apps Script**
2. Delete the default `Code.gs` content
3. Copy the entire contents of [`backend/Code.gs.js`](./Code.gs.js) from this repository
4. Paste it into the Apps Script editor into `Code.gs`
5. Save the project (name it like "Purchase App Backend")

### 3. Run the Setup Function

1. In the Apps Script editor, select the `setup` function from the dropdown
2. Click the **Run** button (▶️)
3. You'll be asked to authorize the script - click "Review Permissions"
4. Select your Google account
5. Click "Advanced" → "Go to Purchase App Backend (unsafe)"
6. Click "Allow"
7. The script will create all necessary sheets in your spreadsheet

**Important:** After setup completes, a `config` sheet will be created with your unique `APP_CODE` secret. Keep this secure!

### 4. Get Your Secret Code

1. Return to your Google Sheet
2. Open the **config** sheet
3. In cell **B1**, copy the **APP_CODE** value
4. ⚠️ **Keep this code private!** It's your authentication secret

### 5. Deploy as Web App

1. In the Apps Script editor, click **Deploy > New deployment**
2. Click the gear icon ⚙️ next to "Select type"
3. Choose **Web app**
4. Configure:
   - **Description**: "Purchase App API v1"
   - **Execute as**: Me
   - **Who has access**: Anyone (protected by secret code)
5. Click **Deploy**
6. Copy the **Web app URL** - you'll need this for the mobile app

**Important:** If you update the code later, create a **New deployment** (not "Manage deployments") for changes to take effect.

### 6. Configure the Mobile App

1. Open the mobile app
2. On the login screen, enter:
   - **Google Sheets Web App URL**: The URL from step 5
   - **App Secret Code**: The APP_CODE from the config sheet (step 4)
3. Click **Connect and Login**
4. Credentials will be saved locally for auto-login

### 7. Test the Setup

1. In the Apps Script editor, select the `testSetup` function
2. Click **Run**
3. Check the execution log (View > Logs)
4. You should see all 8 sheets listed (config + 7 data tables)

## API Endpoints

### POST - All Operations (Secure)

**Note:** All requests use POST method with secret code in the request body for security. Secret codes are NOT sent in URL parameters.

#### Pull (Download) Records
```
POST {webAppUrl}
Content-Type: application/json

{
  "operation": "pull",
  "table": "manufacturers",
  "secret": "YOUR_APP_CODE",
  "since": "2025-01-01T00:00:00.000Z"
}
```

Response:
```json
{
  "success": true,
  "sample-data": [
    {
      "uuid": "abc-123",
      "name": "Test Manufacturer",
      "updated_at": "2025-01-15T12:00:00.000Z"
    }
  ]
}
```

#### Push (Upload) Records
```
POST {webAppUrl}
Content-Type: application/json

{
  "operation": "push",
  "table": "manufacturers",
  "secret": "YOUR_APP_CODE",
  "records": [
    {
      "uuid": "abc-123",
      "name": "Test Manufacturer",
      "updated_at": "2025-01-15T12:00:00.000Z"
    }
  ]
}
```

Response:
```json
{
  "success": true,
  "updated": 1
}
```

### GET - Deprecated

GET requests will return an error directing you to use POST:
```json
{
  "error": "This API only accepts POST requests. Please use POST with secret in request body."
}
```

## Sheets Structure

The script creates the following sheets:

1. **config** - Configuration and secrets (APP_CODE)
2. **manufacturers** - Manufacturer master data
3. **vendors** - Vendor master data
4. **materials** - Material master data
5. **manufacturer_materials** - Manufacturer-specific material variants
6. **vendor_price_lists** - Vendor pricing information
7. **purchase_orders** - Purchase order headers
8. **purchase_order_items** - Purchase order line items

Each data sheet has a header row with column names matching the SQLite database schema.

## Sync Mechanism

The sync works bidirectionally:

1. **Pull (Download)**: Mobile app requests records updated since last sync
2. **Push (Upload)**: Mobile app sends locally modified records to Google Sheets
3. **Conflict Resolution**: Last write wins (based on `updated_at` timestamp)
4. **Authentication**: Every request validates secret code before processing

## Security

### Authentication
- Every API request requires the `secret` parameter in the request body
- Secret code is validated against the `config` sheet before processing
- Invalid or missing secrets return error responses

### Best Practices
- ✅ Keep your APP_CODE private
- ✅ Don't share your Web App URL publicly
- ✅ Secret is sent in HTTPS-encrypted POST body (not URL)
- ✅ Change APP_CODE in config sheet if compromised
- ✅ Use the logout feature in mobile app when sharing device

### Network Security
- All communication uses HTTPS (enforced by Google)
- Secret code is never exposed in URL parameters or logs
- Credentials stored locally on device in encrypted SQLite database

## Troubleshooting

**"Sheet not found" error**
- Run the `setup()` function first

**"Invalid secret code" error**
- Verify you copied the APP_CODE correctly from the config sheet
- Check that you're using the secret from the correct Google Sheet
- Logout and login again in the mobile app

**"APP_CODE not configured" error**
- Open the config sheet in your Google Sheet
- Change the APP_CODE value from the default to a secure secret
- Save the sheet

**"Authorization required" error**
- Re-authorize the script in Apps Script settings

**"Execution failed" error**
- Check the Apps Script execution logs (View > Executions)
- Verify the web app is deployed correctly
- Ensure you created a **New deployment** after code changes

**Sync not working in mobile app**
- Verify the web app URL is correct (ends with `/exec`)
- Check internet connectivity
- Verify secret code matches config sheet
- Review app logs for error messages
- Try logout and login again

**Data not syncing after code update**
- Create a **New deployment** (not "Manage deployments")
- Copy the new Web App URL
- Update credentials in mobile app

## Version History

- **v2.0** - POST-only API with operation parameter, secret in request body
- **v1.5** - Added config sheet and APP_CODE authentication
- **v1.0** - Initial release with GET/POST endpoints
