For a gmail user, how to automate the setup of google sheet with google apps script right from the flutter mobile app

Earlier you gave this proposal [ai-docu/automation-proposal.md]

In CommonOverFlowMenu, when user is not logged in, offer a menu option "Setup Google Sheets" as second item below "Login". This "Setup Google Sheets" should not be visible when user is successfulled logged in

Implemenet a screen SetupGoogleSheet.

- Implement Google Sign-in workflow.
- Obtain required access code as required
  - If required google store access code in local_settings SQLite table or another standard secret storage in the mobile device.

Having obtained google account access

- Obtain desired Google Sheet Name as input value from the user
- Obtain desired AppCode as input from the user (appCode)
- Provide generate Google Sheet option.
- generate a new google sheet using respective api
- get hold of Google Apps Script Project of the new Google Sheet (ngs)
  - Create Sheet "config" in the ngs
    - with first row values ["name", "value", "description"]
    - with second row values ["APP_CODE", appCode given above, "the secret"]
  - Use AssetManifest as you used in CsvImportService
    - Get hold of backend/google-app-script-code/\*.js files
    - Copy these files to the Google Apps Script project
  - Deploy the Google Apps Script project Web App
    - Execute as Signed-in google suer above
    - Who can Access: Anyone
    - Get hold of the Deployment Web App URL (appUrl)
    - Store the appUrl and appCode into local_settings using await \_deltaSyncService.saveCredentials(appUrl, appCode)
      - I am wondering if we have to retain this access code. If everything goes fine, the access code, refresh codes can be discarded
  - Setup Google Sheet worksheets by calling Google Apps Script Web App URL
    - POST appUrl
    - ContentType: application/json
    - Body: { secret: appCode, operation: "setupSheets"}
    - If this fails with timeout, provide option to retry instead of giving up
  - If everything is successful, then on pressing back button, it should be treated like successful login scenario

can we have more diagnostic outputs on the debug console. I am not sure what has happend and what has finished as the UI gives rolling flash message.

At the end, I see the it was a library deployment, I wanted a Web App deployment

I manually deleted the google sheet and it went to trash.

How did our App remember the google sheet. I didnt see this info getting stored in local settings

Runtime Error below
Setup failed: DetailedApiRequestError(status: 400, message: Invalid requests[0].addSheet: A sheet with the name "config" already exists. Please enter another name.)

If config sheet already exists, it should change the config sheet rather than tring to create duplicate sheet

SetupGoogleSheetScreen

It keeps creating new Google Apps Script project for a given google sheet.

This is not desired.

Keep track of previously created google apps script project and continue to redeploy to that project

Also check the status of the google sheet id, if it was moved to trash, you need to create new google sheet. Forget the old sheet name, sheet id and script id.

debugprint needs to print google sheet id and URL

currently we are storing 5 different things in local settings.

- google_sheet_id
- google_sheet_name
- google_script_id

- web_app_url
- secret_code
- last_sync_timestamp
- developer-mode
- sync-paused

From the google sheet are we able to get hold of the corresponding apps script project id?

If so, we just need to store google_sheet_id.

I think we dont need to store google_sheet_name also. From google_script_id we are able to read the sheet name

Deployed Google Apps script is saying it is accessible to anyone with google account

The web app will be authorized to run using your account data.

But, I wanted option of anyone being able to execute it

Deployed apps script is at webAppUrl https://script.google.com/macros/s/AKfycbwE5OO7HyM8KZZRNtmMvSfKx5wN93s3Ztj4BPxYVGlxeHPH8CK_Z5k2lADBf6fMbwCyiw/exec

But this deployed web app requires user's permission to run the script - the web app is capable of changing data of the generated worksheet

Check the attached screenshot

In "Step 1: Enable Apps Script API", we open URL "https://script.google.com/home/usersettings"

"Step 3: Configuration" has to be split into

- "Step 3: Sheet Creation & Backend Deployment"
- "Step 4: Authenticate Deployed Application"
  - Like "Step 1: Enable Apps Script API", provide option to Open URL webAppUrl in browser
  - there user will be prompted to give permission to the script to access google sheets. After that step is completed, user should be able to setup sheets in the next step below
- "Step 5: Setup Sheets"

Deployed apps script is at webAppUrl https://script.google.com/macros/s/AKfycbwE5OO7HyM8KZZRNtmMvSfKx5wN93s3Ztj4BPxYVGlxeHPH8CK_Z5k2lADBf6fMbwCyiw/exec

But this deployed web app requires user's permission to run the script - the web app is capable of changing data of the generated worksheet

Check the attached screenshot

In "Step 1: Enable Apps Script API", we open URL "https://script.google.com/home/usersettings"

"Step 3: Configuration" has to be split into

- "Step 3: Sheet Creation & Backend Deployment"
- "Step 4: Authenticate Deployed Application"
  - Like "Step 1: Enable Apps Script API", provide option to Open URL webAppUrl in browser
  - there user will be prompted to give permission to the script to access google sheets. After that step is completed, user should be able to setup sheets in the next step below
- "Step 5: Setup Sheets"


Setup Google Sheet Steps
- Step 1: Enable Apps Script API - Opens settings page for user to enable API

- Step 2: Google Sign-in - User signs in with Google account

- Step 3: Sheet Creation & Backend Deployment - Creates sheet, deploys Apps Script backend

  - User enters sheet name and app code
  - Clicks "Deploy Backend" button
  - Creates Google Sheet, config sheet, Apps Script project, deploys Web App


- Step 4: Authenticate Deployed Application - User authorizes the deployed app

  - Opens the deployed Web App URL in browser
  - User goes through OAuth consent screen
  - Authorizes the app to access their sheets

- Step 5: Setup Sheets - Initializes the sheets structure

  - After authorization, clicks "Setup Sheets" button
  - Calls the setupSheets endpoint
  - Saves credentials and completes setup
  - This ensures the user explicitly authorizes the app before trying to call it, avoiding the permission errors.





Open Settings Page can occupy full width centered.

Similarly Step 2, Step 3, Step 4, Step 5 buttons can also take full width and be centered


Setup Google SheetsSetupGoogleSheetScreen screen  should store the following at the end of step 5 in local_settings table
key | value 
--|--
web_app_url | deployed web app url from from step 3
secret_code | user input of appCode from screen




SetupGoogleSheetScreen the lookup for existing google apps script projects for a given sheet id is not working. 

I got multiple deployments of google app script projects for a given sheet




Before "Step 1: Enable Apps Script API", 
- select from local_settings get values for google_sheet_id google_script_id
- Display Google Sheet Name (Get google sheet name calling appropraite google api). Put a button next to it to delete it
  - if user presses delete button
    - confirm with user if he wishes to delete the sheet
      - delete the google sheet
      - delete local_settings entry for oogle_sheet_id and google_script_id
- Display Google Script Project Name (button next to it to delete it)
  - if user presses delete button
    - confirm with user if he wishes to delete apps script project
      - delete the google apps script project
      - delete local_settings entry for google_script_id
  


section with the following quoted information is only for the application developer.  It is not for the mobile app user.  so, delete that last section

> Google Sign-In requires OAuth configuration. If sign-in fails, you can:
> 
> 1. Configure OAuth in Google Cloud Console (recommended)
> 2. Use the Manual Setup option instead
> 
> Tap the error message for detailed configuration steps.



Existing Google Resources. 
Google Sheet:
ID: shows value as $_existingSheetId
App Script Project:
ID: shows value as $_existingScriptId

It is not showing actual values


Existing Google Resources. On clicking on the Open Goole Sheet link gives error Document Lookup failed.  It is not possible, the document was deleted.  This message comes from google drive application

But I am able to navigate to the google app script project



SetupGoogleSheetScreen  after step 5.  dont autoclose this screen.  Let user explicitly press back button

As soon as new Google sheet is created, or as soon as google app script is deployed, "Existing Google Resources" section should show up

In "Existing Google Resource" section, As soon as I delete the Apps Script Project or Google Sheet, "Deploy Backend" should get enabled.

In "Existing Google Resource" section, As soon as I Google Sheet, "Deploy Backend" should get enabled.


SetupGoogleSheetScreen

After Step 5 Success Introduce Step 6
Offer the following options
- Import Sample Data
   - post import of sample data
   - invoke ChangeLogUtils.initializeChangeLogFromDataTables
- Import Data from zip file




Step 5 Setup Sheets is optional.  For an existng sheet, if the required 


## SetupGoogleSheetScreen UI Layout

The major UI sections in `setup_google_sheet_screen.dart` are displayed in the following sequence:

### 1. Step 1: Google Sign-in
- Sign in/Sign out button
- Shows current user email when signed in

### 2. Existing Google Resources
- **Visibility**: Conditional - shown only if signed in and resources exist
- **Content**:
  - Displays existing Google Sheet with delete/open actions
  - Shows existing Apps Script Project with open action
- **Styling**: Green-colored card

### 3. Step 2: Enable Apps Script API
- **Styling**: Warning card (amber/orange)
- Instructions to enable the API
- Link to Google settings page

### 4. Step 3: Sheet Creation & Backend Deployment
- Google Sheet Name input field
- App Code (Secret) input field
- Deploy Backend button

### 5. Step 4: Authenticate Deployed Application
- **Visibility**: Conditional - shown after deployment
- **Styling**: Purple card
- Instructions for authorizing the app
- Open Deployed App button

### 6. Step 5: Setup Sheets
- **Visibility**: Conditional - shown after deployment
- Setup Sheets button to initialize the spreadsheet

### 7. Step 6: Import Data (Optional)
- **Visibility**: Conditional - shown after sheets setup
- Import Sample Data from Assets button
- Import Data from Zip File button

### 8. Status Section
- **Visibility**: Conditional - shown when there's a status message
- Shows progress/success/error messages
- Displays Web App URL when available
- **Styling**: Color-coded - blue (loading), red (error), green (success)

### 9. Instructions
- **Visibility**: Always visible
- Blue info card at bottom
- General setup instructions




In SetupGoogleSheetScreen I want the sequence to be
Step 1: Google Sign-in
Existing Google Resources
Step 2: Enable Apps Script API
Step 3: Sheet Creation & Backend Deployment
Step 4: Authenticate Deployed Application
Step 5: Setup Sheets
Step 6: Import Data (Optional)
Status Section
Instructions





remove all the logic of trying to determine scriptId from sheetId

once you have a sheet, getDeveloperMetadata on the sheet for key 'theGoogleAppScriptId'.  That is the script ID.

When you create a new google sheet, and sunsequently create a script project for that sheetId, add developer metadata with key 'theGoogleAppScriptId' value newly generated scriptId

With this we dont have a need to store google_script_id.  Remvoe that logic



In SetupGoogleSheetScreen, the last step to be initial upload data to Google Sheet with id _currentSpreadsheetId.  add last step to do this upload.
For each tableName in TableNames.allDataTables
  - get tableColumnNames using dbHelper.getTableColumnNames
  - sheet = get Google Sheet Worksheet by Name = tableName
  - get sheetColumnNames = column values from first row
- Delete rows in excel where row is greater than 2, clear contents of row 2
  - SQLite: SELECT * from tableName - walk through all records in batches of 200 lines
    - Iterate over selected records (row)
      - Prepare excelRow
        - Map values from database column layout to Excel column layout. Use row, tableColumnNames, sheetColumnNames
      - collect excelRows 
    - append excelRows into sheet
SQLite Delete from change_log
SQLite Delete from consolidated_change_log