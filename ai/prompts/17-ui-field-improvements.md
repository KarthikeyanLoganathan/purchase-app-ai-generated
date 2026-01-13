In backend/google-app-script-code/*.js files write operations to tables of types CONFIGURATION, MASTER_DATA, TRANSACTION_DATA; metadata from TABLE_DEFINITIONS, TABLE_META_INFO are used for column indices, This is good for performance, but to be reliable excel column headers on the respective data sheets to be used for sheet column indices rather than DEFINITIONS alone.  When user changes column sequences in google sheet, the logic has been bound to fail.  This needs a fix.

Check all write operations to excel and fix them



QuotationItemDetailScreen currency value is not visible.  Make Rate, RateBeforeTax and currency of same size

PurchaseOrderItemDetailScreen Rate, RateBeforeTax, Tax Amount, Base Price, Total Amount all to be formatted by currencies.number_of_decimal_places

QuotationItemDetailScreen Rate, RateBeforeTax, Tax Amount, Base Price, Total Amount all to be formatted by currencies.number_of_decimal_places


BasketItemDetailScreen max_retail_price, max_retail_price to be formatted by currencies.number_of_decimal_places
BasketItemDetailScreen quantity, selling_lot_size to be formatted by unit_of_measures.number_of_decimal_paces

BasketDetailScreen currency field does not have suggest enabled. wherever suggest feature is provided with a search field and drop down, tap outside to dismiss the suggest dropdown is required.  within suggest field cross(x) to clear search input is also required.  This two features are required in all screens uniformly


BasketDetailScreen total_price to be formatted by currencies.number_of_decimal_places


New Purchase Order PurchaseOrderDetailScreen
Vendor suggest feature is provided with a search field and drop down, tap outside to dismiss the suggest dropdown is required.  within suggest field cross(x) to clear search input is also required.  This two features are required in all screens uniformly


New Purchase Order PurchaseOrderDetailScreen
Current field needs suggest feature against currencies table, with a search field and drop down, tap outside to dismiss the suggest dropdown is required.  within suggest field cross(x) to clear search input is also required.  This two features are required in all screens uniformly

New Purchase Order PurchaseOrderDetailScreen
Base price, Tax amount, Total Amount, Amount Paid, Amount Balance to be formatted to currencies.number_of_decimal_places



New Purchase Order PurchaseOrderDetailScreen
Payments List:  Amount in fist line to be formatted to currencies.number_of_decimal_places

Add Payment Popup, Current field needs suggest feature against currencies table, with a search field and drop down, tap outside to dismiss the suggest dropdown is required.  within suggest field cross(x) to clear search input is also required.  This two features are required in all screens uniformly.  Amount field to be formatted to currencies.number_of_decimal_places


PurchaseOrdersScreen in the list Total, Paid, Balance to be formatted by currencies.number_of_decimal_places following currency foreign key on purchase_orders



When I return from CurrencyDetailScreen to CurrenciesScreen, the list has to refresh automatically



When I return from PurchaseOrderItemDetailScreen, PurchaseOrderDetailScreen, the Items list has to refresh 

When I return from PurchaseOrderItemDetailScreen, PurchaseOrderDetailScreen, the Payments list has to refresh 


CurrencyDetailScreen, CurrenciesScreen, UnitsScreen, UnitOfMeasureDetailScreen need 
CommonOverflowMenu.  To be uniform like any other screen


CurrenciesScreen lacks delete button.  CurrenciesScreen delete requires trackDeletion pass the primary key instead of uuid

UnitsScreen lacks delete button. CurrenciesScreen delete requires trackDeletion pass the primary key instead of uuid



CommonOverFlowMenu needs to include all the following options in the given order
- (icon) Settings
- Separator
- (sync-icon) Sync with Google Sheets
- (stop-icon) Stop Sync
- (icon) Play Sync / Pause Sync Toggle Button
- (icon) View Sync Log
- Separator
- (icon) Prepare Condensed Change Log
- Separator
- (icon) Data Statistics
- (icon) Data Browser
Include CommonOverFlowMenu uniformely in all screens.  If the functions offered by CommonOverFlowMenu are available as duplicate additional functions, remove those additional menu options.



Please go through individual screens and list overflow menu options available in those screens.  Get me a list.  This question is irrelevant of CommonOverFlowMenu.  I just need a plain list of menu functions available in all the screens. 

Give a List like the following

HomeScreen - Settings
HomeScreen - Data Statistics
...


Menu's list

(from CommonOverflowMenu) TRUE - BasketsScreen - Settings
(from CommonOverflowMenu) TRUE - BasketsScreen - Sync with Google Sheets
(from CommonOverflowMenu) TRUE - BasketsScreen - Stop Sync
(from CommonOverflowMenu) TRUE - BasketsScreen - Pause/Play Sync
(from CommonOverflowMenu) TRUE - BasketsScreen - View Sync Log
(from CommonOverflowMenu) TRUE - BasketsScreen - Prepare Condensed Change Log
(from CommonOverflowMenu) TRUE - BasketsScreen - Data Statistics
(from CommonOverflowMenu) TRUE - BasketsScreen - Data Browser

(from CommonOverflowMenu) FALSE - BasketDetailScreen - None (no overflow menu)

(from CommonOverflowMenu) FALSE - BasketItemDetailScreen - None (no overflow menu)

(from CommonOverflowMenu) TRUE - BasketQuotationsScreen - Settings
(from CommonOverflowMenu) TRUE - BasketQuotationsScreen - Sync with Google Sheets
(from CommonOverflowMenu) TRUE - BasketQuotationsScreen - Stop Sync
(from CommonOverflowMenu) TRUE - BasketQuotationsScreen - Pause/Play Sync
(from CommonOverflowMenu) TRUE - BasketQuotationsScreen - View Sync Log
(from CommonOverflowMenu) TRUE - BasketQuotationsScreen - Prepare Condensed Change Log
(from CommonOverflowMenu) TRUE - BasketQuotationsScreen - Data Statistics
(from CommonOverflowMenu) TRUE - BasketQuotationsScreen - Data Browser

(from CommonOverflowMenu) TRUE - CurrenciesScreen - Settings
(from CommonOverflowMenu) TRUE - CurrenciesScreen - Sync with Google Sheets
(from CommonOverflowMenu) TRUE - CurrenciesScreen - Stop Sync
(from CommonOverflowMenu) TRUE - CurrenciesScreen - Pause/Play Sync
(from CommonOverflowMenu) TRUE - CurrenciesScreen - View Sync Log
(from CommonOverflowMenu) TRUE - CurrenciesScreen - Prepare Condensed Change Log
(from CommonOverflowMenu) TRUE - CurrenciesScreen - Data Statistics
(from CommonOverflowMenu) TRUE - CurrenciesScreen - Data Browser

(from CommonOverflowMenu) TRUE - CurrencyDetailScreen - Settings
(from CommonOverflowMenu) TRUE - CurrencyDetailScreen - Sync with Google Sheets
(from CommonOverflowMenu) TRUE - CurrencyDetailScreen - Stop Sync
(from CommonOverflowMenu) TRUE - CurrencyDetailScreen - Pause/Play Sync
(from CommonOverflowMenu) TRUE - CurrencyDetailScreen - View Sync Log
(from CommonOverflowMenu) TRUE - CurrencyDetailScreen - Prepare Condensed Change Log
(from CommonOverflowMenu) TRUE - CurrencyDetailScreen - Data Statistics
(from CommonOverflowMenu) TRUE - CurrencyDetailScreen - Data Browser
(from CommonOverflowMenu) FALSE - CurrencyDetailScreen - Delete
(from CommonOverflowMenu) FALSE - CurrencyDetailScreen - Copy Key

(from CommonOverflowMenu) FALSE - DatabaseBrowserScreen - None (has custom actions)

(from CommonOverflowMenu) TRUE - HomeScreen - Settings
(from CommonOverflowMenu) TRUE - HomeScreen - Sync with Google Sheets
(from CommonOverflowMenu) TRUE - HomeScreen - Stop Sync
(from CommonOverflowMenu) TRUE - HomeScreen - Pause/Play Sync
(from CommonOverflowMenu) TRUE - HomeScreen - View Sync Log
(from CommonOverflowMenu) TRUE - HomeScreen - Prepare Condensed Change Log
(from CommonOverflowMenu) TRUE - HomeScreen - Data Statistics
(from CommonOverflowMenu) TRUE - HomeScreen - Data Browser

(from CommonOverflowMenu) FALSE - ImportDataScreen - None (no overflow menu)

(from CommonOverflowMenu) FALSE - LoginScreen - None (no overflow menu)

(from CommonOverflowMenu) TRUE - ManufacturersScreen - Settings
(from CommonOverflowMenu) TRUE - ManufacturersScreen - Sync with Google Sheets
(from CommonOverflowMenu) TRUE - ManufacturersScreen - Stop Sync
(from CommonOverflowMenu) TRUE - ManufacturersScreen - Pause/Play Sync
(from CommonOverflowMenu) TRUE - ManufacturersScreen - View Sync Log
(from CommonOverflowMenu) TRUE - ManufacturersScreen - Prepare Condensed Change Log
(from CommonOverflowMenu) TRUE - ManufacturersScreen - Data Statistics
(from CommonOverflowMenu) TRUE - ManufacturersScreen - Data Browser

(from CommonOverflowMenu) TRUE - ManufacturerDetailScreen - Settings
(from CommonOverflowMenu) TRUE - ManufacturerDetailScreen - Sync with Google Sheets
(from CommonOverflowMenu) TRUE - ManufacturerDetailScreen - Stop Sync
(from CommonOverflowMenu) TRUE - ManufacturerDetailScreen - Pause/Play Sync
(from CommonOverflowMenu) TRUE - ManufacturerDetailScreen - View Sync Log
(from CommonOverflowMenu) TRUE - ManufacturerDetailScreen - Prepare Condensed Change Log
(from CommonOverflowMenu) TRUE - ManufacturerDetailScreen - Data Statistics
(from CommonOverflowMenu) TRUE - ManufacturerDetailScreen - Data Browser
(from CommonOverflowMenu) FALSE - ManufacturerDetailScreen - Delete
(from CommonOverflowMenu) FALSE - ManufacturerDetailScreen - Copy Key

(from CommonOverflowMenu) TRUE - MaterialsScreen - Settings
(from CommonOverflowMenu) TRUE - MaterialsScreen - Sync with Google Sheets
(from CommonOverflowMenu) TRUE - MaterialsScreen - Stop Sync
(from CommonOverflowMenu) TRUE - MaterialsScreen - Pause/Play Sync
(from CommonOverflowMenu) TRUE - MaterialsScreen - View Sync Log
(from CommonOverflowMenu) TRUE - MaterialsScreen - Prepare Condensed Change Log
(from CommonOverflowMenu) TRUE - MaterialsScreen - Data Statistics
(from CommonOverflowMenu) TRUE - MaterialsScreen - Data Browser

(from CommonOverflowMenu) TRUE - MaterialDetailScreen - Settings
(from CommonOverflowMenu) TRUE - MaterialDetailScreen - Sync with Google Sheets
(from CommonOverflowMenu) TRUE - MaterialDetailScreen - Stop Sync
(from CommonOverflowMenu) TRUE - MaterialDetailScreen - Pause/Play Sync
(from CommonOverflowMenu) TRUE - MaterialDetailScreen - View Sync Log
(from CommonOverflowMenu) TRUE - MaterialDetailScreen - Prepare Condensed Change Log
(from CommonOverflowMenu) TRUE - MaterialDetailScreen - Data Statistics
(from CommonOverflowMenu) TRUE - MaterialDetailScreen - Data Browser
(from CommonOverflowMenu) FALSE - MaterialDetailScreen - Delete
(from CommonOverflowMenu) FALSE - MaterialDetailScreen - Copy Key

(from CommonOverflowMenu) TRUE - ManufacturerMaterialsScreen - Settings
(from CommonOverflowMenu) TRUE - ManufacturerMaterialsScreen - Sync with Google Sheets
(from CommonOverflowMenu) TRUE - ManufacturerMaterialsScreen - Stop Sync
(from CommonOverflowMenu) TRUE - ManufacturerMaterialsScreen - Pause/Play Sync
(from CommonOverflowMenu) TRUE - ManufacturerMaterialsScreen - View Sync Log
(from CommonOverflowMenu) TRUE - ManufacturerMaterialsScreen - Prepare Condensed Change Log
(from CommonOverflowMenu) TRUE - ManufacturerMaterialsScreen - Data Statistics
(from CommonOverflowMenu) TRUE - ManufacturerMaterialsScreen - Data Browser

(from CommonOverflowMenu) TRUE - ManufacturerMaterialDetailScreen - Settings
(from CommonOverflowMenu) TRUE - ManufacturerMaterialDetailScreen - Sync with Google Sheets
(from CommonOverflowMenu) TRUE - ManufacturerMaterialDetailScreen - Stop Sync
(from CommonOverflowMenu) TRUE - ManufacturerMaterialDetailScreen - Pause/Play Sync
(from CommonOverflowMenu) TRUE - ManufacturerMaterialDetailScreen - View Sync Log
(from CommonOverflowMenu) TRUE - ManufacturerMaterialDetailScreen - Prepare Condensed Change Log
(from CommonOverflowMenu) TRUE - ManufacturerMaterialDetailScreen - Data Statistics
(from CommonOverflowMenu) TRUE - ManufacturerMaterialDetailScreen - Data Browser
(from CommonOverflowMenu) FALSE - ManufacturerMaterialDetailScreen - Delete
(from CommonOverflowMenu) FALSE - ManufacturerMaterialDetailScreen - Copy Key

(from CommonOverflowMenu) FALSE - ProjectDetailScreen - Copy Key (separate IconButton)

(from CommonOverflowMenu) TRUE - ProjectsScreen - Settings
(from CommonOverflowMenu) TRUE - ProjectsScreen - Sync with Google Sheets
(from CommonOverflowMenu) TRUE - ProjectsScreen - Stop Sync
(from CommonOverflowMenu) TRUE - ProjectsScreen - Pause/Play Sync
(from CommonOverflowMenu) TRUE - ProjectsScreen - View Sync Log
(from CommonOverflowMenu) TRUE - ProjectsScreen - Prepare Condensed Change Log
(from CommonOverflowMenu) TRUE - ProjectsScreen - Data Statistics
(from CommonOverflowMenu) TRUE - ProjectsScreen - Data Browser

(from CommonOverflowMenu) TRUE - PurchaseOrdersScreen - Settings
(from CommonOverflowMenu) TRUE - PurchaseOrdersScreen - Sync with Google Sheets
(from CommonOverflowMenu) TRUE - PurchaseOrdersScreen - Stop Sync
(from CommonOverflowMenu) TRUE - PurchaseOrdersScreen - Pause/Play Sync
(from CommonOverflowMenu) TRUE - PurchaseOrdersScreen - View Sync Log
(from CommonOverflowMenu) TRUE - PurchaseOrdersScreen - Prepare Condensed Change Log
(from CommonOverflowMenu) TRUE - PurchaseOrdersScreen - Data Statistics
(from CommonOverflowMenu) TRUE - PurchaseOrdersScreen - Data Browser

(from CommonOverflowMenu) FALSE - PurchaseOrderDetailScreen - None (no overflow menu)

(from CommonOverflowMenu) FALSE - PurchaseOrderItemDetailScreen - None (no overflow menu)

(from CommonOverflowMenu) TRUE - QuotationsScreen - Settings
(from CommonOverflowMenu) TRUE - QuotationsScreen - Sync with Google Sheets
(from CommonOverflowMenu) TRUE - QuotationsScreen - Stop Sync
(from CommonOverflowMenu) TRUE - QuotationsScreen - Pause/Play Sync
(from CommonOverflowMenu) TRUE - QuotationsScreen - View Sync Log
(from CommonOverflowMenu) TRUE - QuotationsScreen - Prepare Condensed Change Log
(from CommonOverflowMenu) TRUE - QuotationsScreen - Data Statistics
(from CommonOverflowMenu) TRUE - QuotationsScreen - Data Browser

(from CommonOverflowMenu) FALSE - QuotationDetailScreen - None (no overflow menu)

(from CommonOverflowMenu) FALSE - QuotationItemDetailScreen - None (no overflow menu)

(from CommonOverflowMenu) TRUE - SettingsScreen - Settings
(from CommonOverflowMenu) TRUE - SettingsScreen - Sync with Google Sheets
(from CommonOverflowMenu) TRUE - SettingsScreen - Stop Sync
(from CommonOverflowMenu) TRUE - SettingsScreen - Pause/Play Sync
(from CommonOverflowMenu) TRUE - SettingsScreen - View Sync Log
(from CommonOverflowMenu) TRUE - SettingsScreen - Prepare Condensed Change Log
(from CommonOverflowMenu) TRUE - SettingsScreen - Data Statistics
(from CommonOverflowMenu) TRUE - SettingsScreen - Data Browser

(from CommonOverflowMenu) TRUE - UnitsScreen - Settings
(from CommonOverflowMenu) TRUE - UnitsScreen - Sync with Google Sheets
(from CommonOverflowMenu) TRUE - UnitsScreen - Stop Sync
(from CommonOverflowMenu) TRUE - UnitsScreen - Pause/Play Sync
(from CommonOverflowMenu) TRUE - UnitsScreen - View Sync Log
(from CommonOverflowMenu) TRUE - UnitsScreen - Prepare Condensed Change Log
(from CommonOverflowMenu) TRUE - UnitsScreen - Data Statistics
(from CommonOverflowMenu) TRUE - UnitsScreen - Data Browser

(from CommonOverflowMenu) TRUE - UnitOfMeasureDetailScreen - Settings
(from CommonOverflowMenu) TRUE - UnitOfMeasureDetailScreen - Sync with Google Sheets
(from CommonOverflowMenu) TRUE - UnitOfMeasureDetailScreen - Stop Sync
(from CommonOverflowMenu) TRUE - UnitOfMeasureDetailScreen - Pause/Play Sync
(from CommonOverflowMenu) TRUE - UnitOfMeasureDetailScreen - View Sync Log
(from CommonOverflowMenu) TRUE - UnitOfMeasureDetailScreen - Prepare Condensed Change Log
(from CommonOverflowMenu) TRUE - UnitOfMeasureDetailScreen - Data Statistics
(from CommonOverflowMenu) TRUE - UnitOfMeasureDetailScreen - Data Browser
(from CommonOverflowMenu) FALSE - UnitOfMeasureDetailScreen - Delete
(from CommonOverflowMenu) FALSE - UnitOfMeasureDetailScreen - Copy Key

(from CommonOverflowMenu) TRUE - VendorsScreen - Settings
(from CommonOverflowMenu) TRUE - VendorsScreen - Sync with Google Sheets
(from CommonOverflowMenu) TRUE - VendorsScreen - Stop Sync
(from CommonOverflowMenu) TRUE - VendorsScreen - Pause/Play Sync
(from CommonOverflowMenu) TRUE - VendorsScreen - View Sync Log
(from CommonOverflowMenu) TRUE - VendorsScreen - Prepare Condensed Change Log
(from CommonOverflowMenu) TRUE - VendorsScreen - Data Statistics
(from CommonOverflowMenu) TRUE - VendorsScreen - Data Browser

(from CommonOverflowMenu) TRUE - VendorDetailScreen - Settings
(from CommonOverflowMenu) TRUE - VendorDetailScreen - Sync with Google Sheets
(from CommonOverflowMenu) TRUE - VendorDetailScreen - Stop Sync
(from CommonOverflowMenu) TRUE - VendorDetailScreen - Pause/Play Sync
(from CommonOverflowMenu) TRUE - VendorDetailScreen - View Sync Log
(from CommonOverflowMenu) TRUE - VendorDetailScreen - Prepare Condensed Change Log
(from CommonOverflowMenu) TRUE - VendorDetailScreen - Data Statistics
(from CommonOverflowMenu) TRUE - VendorDetailScreen - Data Browser
(from CommonOverflowMenu) FALSE - VendorDetailScreen - Delete
(from CommonOverflowMenu) FALSE - VendorDetailScreen - Copy Key

(from CommonOverflowMenu) TRUE - VendorPriceListsScreen - Settings
(from CommonOverflowMenu) TRUE - VendorPriceListsScreen - Sync with Google Sheets
(from CommonOverflowMenu) TRUE - VendorPriceListsScreen - Stop Sync
(from CommonOverflowMenu) TRUE - VendorPriceListsScreen - Pause/Play Sync
(from CommonOverflowMenu) TRUE - VendorPriceListsScreen - View Sync Log
(from CommonOverflowMenu) TRUE - VendorPriceListsScreen - Prepare Condensed Change Log
(from CommonOverflowMenu) TRUE - VendorPriceListsScreen - Data Statistics
(from CommonOverflowMenu) TRUE - VendorPriceListsScreen - Data Browser

(from CommonOverflowMenu) TRUE - VendorPriceListDetailScreen - Settings
(from CommonOverflowMenu) TRUE - VendorPriceListDetailScreen - Sync with Google Sheets
(from CommonOverflowMenu) TRUE - VendorPriceListDetailScreen - Stop Sync
(from CommonOverflowMenu) TRUE - VendorPriceListDetailScreen - Pause/Play Sync
(from CommonOverflowMenu) TRUE - VendorPriceListDetailScreen - View Sync Log
(from CommonOverflowMenu) TRUE - VendorPriceListDetailScreen - Prepare Condensed Change Log
(from CommonOverflowMenu) TRUE - VendorPriceListDetailScreen - Data Statistics
(from CommonOverflowMenu) TRUE - VendorPriceListDetailScreen - Data Browser
(from CommonOverflowMenu) FALSE - VendorPriceListDetailScreen - Delete
(from CommonOverflowMenu) FALSE - VendorPriceListDetailScreen - Copy Key


Please integrate CommonOverFLowMenu QuotationDetailScreen, QuotationItemDetailScreen, PurchaseOrderDetailScreen, PurchaseOrderItemDetailScreen, ProjectDetailScreen, BasketDetailScreen, BasketItemDetailScreen




CommonOverFlowMenu needs to include all the following options in the given order
- (icon) Settings
- Separator
- (sync-icon) Sync with Google Sheets
- (stop-icon) Stop Sync
- (icon) Play Sync / Pause Sync Toggle Button
- (icon) View Sync Log
- Separator
- (icon) Prepare Condensed Change Log
- Separator
- (icon) Data Statistics
- (icon) Data Browser
Include CommonOverFlowMenu uniformely in all screens.  If the functions offered by CommonOverFlowMenu are available as duplicate additional functions, remove those additional menu options.



I don't want the functions that are present in CommonOverFlowMenu to be repeated in overflow menu of any screens.  I see ManufacturerMaterial having double entries for overflow menu item


