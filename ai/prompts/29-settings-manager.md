Let us introduce GlobalSettings - keeping certain information in main memory

GlobalSettings hold the following information.  they are loaded when application is started.  They are updated as and when the value is changing from UI
- Developer Mode
- Default Currency
- Mapping of all unit of measure defintions (name -> UnitOfMeasure entity)
- Mapping of all currency defintions (name -> UnitOfMeasure entity)
- Login Information
  - web_app_url from local_settings
  - secret_code from local_settings
- last_sync_timestamp from local_settings
Keep them as private information; provide getters and setters


I need a Settings class
- final ValueNotifier<bool> developerMode = ValueNotifier<bool>(false);
- final ValueNotifier<bool> syncPaused = ValueNotifier<bool>(false);
- final ValueNotifier<string> webAppUrl = ValueNotifier<string>(false);
- final ValueNotifier<string> secretCode = ValueNotifier<secret_code>(false);
- final ValueNotifier<_lastDeltaSyncTime> lastSyncTimeStamp = ValueNotifier<_lastDeltaSyncTime>(false);
- web_app_url
- secret_code
- last_sync_timestamp
- developer-mode
- sync-paused



can we have a singleton SettingsManager class that keeps the settings values for members of LocalSettingKeys, provides setters and getters.  Calls DatabaseHelper to read/write them to database. On start of application loads those values in to memory


caching global settings like developer mode globally.  Not to reselect everytime
caching is logged in globally. update it on login/logout.




Handling Currency numeberOfDecimalPlaces in screens, UnitOfMeasure numberOfDecimalPlaces in screens.  Plase use SettingsManager methods getCurrencyDecimalPlaces, getUnitOfMeasureDecimalPlaces.  

Change logic in all screens to use SettingsManager getters allCurrencies, allUnitOfMeasures
