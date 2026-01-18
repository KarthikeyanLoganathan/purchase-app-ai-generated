
caching number formatting
amount formatting to go through cached access
quantity formatting to go through cached access




Introduce a new entity, following existing conventions in both Flutter and in backend/google-app-script-code as given below.  Give this table an index number 051
- defaults with fields
  - TYPE String - (allowed values Currency, UnitOfMeasure)
  - VALUE String

In unit_of_measures, currencies, remove is_default field.
Remove the field from corresponding usage in CurrenciesScreen CurrencyDetailScreen UnitOfMeasureDetailScreen UnitsScreen

getDefaultCurrency to select from defaults table
getDefaultCurrencyObject to be adjusted to select from defaults and then to select from currencies


help me create DetailsScreen, DefaultsDetailScreen, integrate with HomeScreen

Did you integrate CommonOverflowMenu in new screens


In DefaultsScreen, DefaultsDefailScreen, instead of directly hitting DB tables, can you go through _dbHelper methods to select, insert, update, delete.

Also, to get unit values, currency values, go through _dbHelper again rather than selecting tables directly



wherever formatting percent number of decimal places, get number decimal places using method SettingManager.instance.getPercentDecimalPlaces()

migrate call from 
toStringAsFixed(2)
to 
toStringAsFixed(SettingManager.instance.getPercentDecimalPlaces())