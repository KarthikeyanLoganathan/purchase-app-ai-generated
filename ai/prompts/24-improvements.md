when user is not logged in, Sync with Google Sheets option should be disabled.

In Home Screen sync now popup should not show up.


When I come back from UnitDetailScreen, Units screen is not refreshing.


Sync does not push units
Sync does not push currencies

When I logout, warn if sync is pending.  after database has to be cleard.

When I logout clear local data


during logout are you also clearing condensed_change_log



When application starts without a login, we have a welcome dialog

Welcome! Would you like to download data from Google Sheets now? This will sync all data. Later "Sync Now"

Let us do away with this.

When Lauching Home screen, the following should happen.
- User is not logged in already.  Provide two options to the user.
  - Login option.   OR
  - Import Sample Data

- In the CommonOverFlowMenu, provide option to Login (if user is not already logged in)



Why can't common overflow menu read the DeveloperMode state on its own.  Why should other screens handover the state.  Please change the approach


what are input paramters to commonoverflowmenu now

Required Parameters:
isLoggedIn (bool) - Whether user is currently logged in
isDeltaSyncing (bool) - Whether delta sync is currently running
onMenuItemSelected (Future<void> Function(String)) - Callback when menu item is selected

please remove isLoggedIn, isDeltaSyncing from CommonOverFlowMenu parameters.  They are suppsoed to be determined within CommonOverFlowMenu


introduce a LoginService.dart that handles login & logout.  It should also provide isLoggedIn() function

Remove login/logout capability from anywhere else and start reusing LoginService

Start using LoginService.isLoggedIn( ) and remove check CheckLoginStatus functions




The CommonOverflowMenu now accepts these input parameters:

Required Parameters:
isLoggedIn (bool) - Whether user is currently logged in
isDeltaSyncing (bool) - Whether delta sync is currently running
onMenuItemSelected (Future<void> Function(String)) - Callback when menu item is selected


CommonOverflowMenu should evaluate isLoggedIn on its own through LoginService it should not take input parameter


Can CommonOverflowMenu receive isDeltaSyncing from DeltaSyncService?  Can we remove paramter isDeltaSyncing from CommonOverflowMenu. Evaluate it when required through DeltaSyncService


I have introduced DatabaseHelper.alueNotifier<bool> developerMode. 

Help me initialize this value as application gets started

Help me listen to DatabaseHelper.developerMode in CommonOverflowMenu

In CommonOverflowMenu, I would like to avoid repeatedly loading 'developer-mode' from DB; I want this value DatabaseHelper.developerMode to reflect in _CommonOverflowMenuState._isDeveloperMode immediately



Choosing Exisitng Google Sheet?
is there a Google Drive File Select dialog in Flutter for choosing desired file type

Can we have a proper directory walking file picker?  It has to be a reusable widget that we are able to plugin in SetupGoogleSheetScreen

Can we extend this picker with file name search feature?

If searchTerm is given, it should search for given mimetype and give a plain list.

If searchTerm is not given, it should allow hierarchical walk through

support for both list and tree views depending upon the context



introduce AppInfoService in this app; incorporate it in main().  Enhance settings screen to show app info from AppInfoService.  Use AppInfoService to set User-Agent, X-App-Package, X-App-Version, X-App-Build in HTTP calls. 


appProperties in google sheet
During creation of google sheet, use AppInfoService properties.

During search on google drive for sheet, use app-package key

In google-drive-file-picker widget, use AppInfoService package to search files



Looks like the purpose of CommonOverflowMenu is getting defeated.  It should handle most of those events on its own.  Instead it is getting delegated to calling screen

this is antipattern