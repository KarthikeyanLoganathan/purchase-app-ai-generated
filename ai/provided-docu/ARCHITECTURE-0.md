# Purchase Application - Architecture Documentation

## Overview

The Purchase Application is an offline-capable mobile purchasing system built with Flutter, using SQLite for local storage and Google Sheets as a cloud backend. The application enables purchase order management with vendor pricing, manufacturer materials, basket-based quotation comparison, and bidirectional data synchronization.

## Technology Stack

- **Frontend**: Flutter (Dart) - Cross-platform mobile application (Android/iOS)
- **Local Database**: SQLite - Offline data storage on mobile device
- **Backend**: Google Apps Script (JavaScript) - REST API layer
- **Cloud Storage**: Google Sheets - Cloud database and backup
- **Sync Mechanism**: Delta sync with bidirectional synchronization

---

## Backend Architecture (Google Apps Script)

### Component Structure

The backend is organized into modular namespaces for better maintainability:

#### 1. **Table Metadata** (`tableMetadata.js`)
- Defines core data tables with complete column schemas
- Data type definitions (UUID, INTEGER, AMOUNT, STRING, TIME_STAMP, etc.)
- Lookup formulas for denormalized views in Google Sheets
- Table indices for efficient sync tracking

**Table Indices:**
```javascript
{
  unit_of_measures: 101,
  currencies: 102,
  manufacturers: 201,
  vendors: 202,
  materials: 203,
  manufacturer_materials: 204,
  vendor_price_lists: 205,
  projects: 251,
  purchase_orders: 301,
  purchase_order_items: 302,
  purchase_order_payments: 303,
  basket_headers: 311,
  basket_items: 312,
  quotations: 321,
  quotation_items: 322
}
```

#### 2. **Delta Sync Engine** (`deltaSync.js`)

**Core Functions:**
- `upsertRecords(tableName, records)` - Insert or update records using UUID as primary key
- `deleteRecords(tableName, deletions)` - Delete records from sheets
- `applyDeltaChangesBatch(log, tableRecords)` - Batch processing of client changes
- `fetchTableRecordsForChanges(log)` - Efficient record retrieval for changed UUIDs
- `batchGetRecordsByUuids(sheet, tableName, uuids)` - Batch fetch for performance

**Features:**
- UUID-based upsert logic (find existing record or append new)
- Batch operations for efficiency
- Automatic column width optimization
- Processes deletes before inserts/updates

#### 3. **Change Log Management** (`changeLogUtils.js`)

**Functions:**
- `initializeChangeLogFromDataSheets()` - Initialize change log from all existing records
- `logChange(tableName, key, changeMode, updatedAt)` - Log single change
- `logChanges(tableName, keys, changeMode, updatedAt)` - Batch change logging
- `prepareCondensedChangeLogFromChangeLog(since)` - Create condensed log from raw log
- `writeCondensedChangeLog(since)` - Write condensed log to sheet
- `readCondensedChangeLog(offset, limit)` - Read with pagination

**Change Modes:**
- `'I'` - Insert (new record)
- `'U'` - Update (existing record modified)
- `'D'` - Delete (record removed)

**Change Log Schema:**
```javascript
{
  id: UUID,
  table_index: INTEGER,
  table_key_uuid: UUID (record UUID),
  change_mode: 'I' | 'U' | 'D',
  updated_at: TIMESTAMP
}
```

#### 4. **Web Service Endpoints** (`webService.js`)

**POST Endpoint** (`doPost()`):
```javascript
POST {webAppUrl}
Content-Type: application/json

// Authentication
{
  "operation": "login",
  "secret": "APP_CODE"
}

// Pull changes from server
{
  "operation": "delta_pull",
  "secret": "APP_CODE",
  "since": "2025-01-01T00:00:00.000Z",  // Optional
  "offset": 0,
  "limit": 200
}

// Push changes to server
{
  "operation": "delta_push",
  "secret": "APP_CODE",
  "log": [...],           // Change log entries
  "tableRecords": {...}   // Actual record data
}
```

**Security:**
- Secret code validation on every request
- Secret sent in request body (not URL) for better security
- Configurable APP_CODE in Google Sheets config sheet

**Pagination:**
- Default page size: 200 records
- Supports offset and limit parameters
- Returns total record count for progress tracking

#### 5. **Configuration Management** (`config.js`)
- Manages APP_CODE secret from config sheet
- Configuration value retrieval utilities

#### 6. **Setup & Utilities**
- `setup.js` - Sheet creation and schema initialization
- `utils.js` - UUID generation, date helpers, sheet operations
- `cleanup.js` - Data cleanup utilities
- `dataReaders.js` - Data reading functions with filter support

### Data Tables (Google Sheets)

1. **config** - Configuration and secrets (APP_CODE)
2. **unit_of_measures** - Unit of measure master data (kg, liter, piece, etc.)
3. **currencies** - Currency master data (USD, EUR, INR, etc.)
4. **manufacturers** - Manufacturer master data
5. **vendors** - Vendor master data
6. **materials** - Material master data
7. **manufacturer_materials** - Manufacturer-specific material variants
8. **vendor_price_lists** - Vendor pricing information
9. **projects** - Project master data for tracking purchases
10. **purchase_orders** - Purchase order headers
11. **purchase_order_items** - Purchase order line items
12. **purchase_order_payments** - Payment records
13. **basket_headers** - Shopping basket headers
14. **basket_items** - Items in baskets
15. **quotations** - Vendor quotations for baskets
16. **quotation_items** - Item-level pricing in quotations
17. **change_log** - Raw change tracking
18. **condensed_change_log** - Optimized change log for sync

---

## Frontend Architecture (Flutter)

### Database Layer (`lib/services/database_helper.dart`)

#### SQLite Schema

**Core Master Data Tables:**

1. **unit_of_measures**
   ```sql
   name TEXT PRIMARY KEY,
   description TEXT,
   number_of_decimal_places INTEGER NOT NULL DEFAULT 2,
   is_default INTEGER NOT NULL DEFAULT 0,
   updated_at TEXT NOT NULL
   ```

2. **currencies**
   ```sql
   name TEXT PRIMARY KEY,
   symbol TEXT,
   description TEXT,
   number_of_decimal_places INTEGER NOT NULL DEFAULT 2,
   is_default INTEGER NOT NULL DEFAULT 0,
   updated_at TEXT NOT NULL
   ```

3. **manufacturers**
   ```sql
   uuid TEXT PRIMARY KEY,
   id INTEGER,
   name TEXT NOT NULL,
   description TEXT,
   updated_at TEXT NOT NULL
   ```

4. **vendors**
   ```sql
   uuid TEXT PRIMARY KEY,
   id INTEGER,
   name TEXT NOT NULL,
   description TEXT,
   address TEXT,
   geo_location TEXT,
   updated_at TEXT NOT NULL
   ```

5. **materials**
   ```sql
   uuid TEXT PRIMARY KEY,
   id INTEGER,
   name TEXT NOT NULL,
   description TEXT,
   unit_of_measure TEXT NOT NULL,
   updated_at TEXT NOT NULL,
   FOREIGN KEY (unit_of_measure) REFERENCES unit_of_measures(name)
   ```

6. **manufacturer_materials**
   ```sql
   uuid TEXT PRIMARY KEY,
   manufacturer_uuid TEXT NOT NULL,
   material_uuid TEXT NOT NULL,
   model TEXT NOT NULL,
   selling_lot_size INTEGER,
   max_retail_price REAL,
   currency TEXT,
   updated_at TEXT NOT NULL,
   FOREIGN KEY (manufacturer_uuid) REFERENCES manufacturers(uuid),
   FOREIGN KEY (material_uuid) REFERENCES materials(uuid),
   FOREIGN KEY (currency) REFERENCES currencies(name)
   ```

7. **vendor_price_lists**
   ```sql
   uuid TEXT PRIMARY KEY,
   manufacturer_material_uuid TEXT NOT NULL,
   vendor_uuid TEXT NOT NULL,
   rate REAL NOT NULL,
   rate_before_tax REAL DEFAULT 0.0,
   currency TEXT,
   tax_percent REAL NOT NULL,
   tax_amount REAL NOT NULL,
   updated_at TEXT NOT NULL,
   FOREIGN KEY (manufacturer_material_uuid) REFERENCES manufacturer_materials(uuid),
   FOREIGN KEY (vendor_uuid) REFERENCES vendors(uuid),
   FOREIGN KEY (currency) REFERENCES currencies(name)
   ```

8. **projects**
   ```sql
   uuid TEXT PRIMARY KEY,
   id INTEGER,
   name TEXT NOT NULL,
   description TEXT,
   address TEXT,
   start_date TEXT,
   end_date TEXT,
   completed INTEGER DEFAULT 0,
   updated_at TEXT NOT NULL
   ```

**Purchase Order Tables:**

9. **purchase_orders**
   ```sql
   uuid TEXT PRIMARY KEY,
   id INTEGER,
   vendor_uuid TEXT NOT NULL,
   date TEXT NOT NULL,
   base_price REAL NOT NULL,
   tax_amount REAL NOT NULL,
   total_amount REAL NOT NULL,
   currency TEXT,
   order_date TEXT NOT NULL,
   expected_delivery_date TEXT,
   amount_paid REAL DEFAULT 0.0,
   amount_balance REAL DEFAULT 0.0,
   completed INTEGER DEFAULT 0,
   updated_at TEXT NOT NULL,
   FOREIGN KEY (vendor_uuid) REFERENCES vendors(uuid),
   FOREIGN KEY (currency) REFERENCES currencies(name)
   ```

10. **purchase_order_items**
    ```sql
    uuid TEXT PRIMARY KEY,
    purchase_order_uuid TEXT NOT NULL,
    manufacturer_material_uuid TEXT NOT NULL,
    material_uuid TEXT DEFAULT '',
    model TEXT DEFAULT '',
    quantity REAL NOT NULL,
    rate REAL NOT NULL,
    rate_before_tax REAL DEFAULT 0.0,
    base_price REAL NOT NULL,
    tax_percent REAL NOT NULL,
    tax_amount REAL NOT NULL,
    total_amount REAL NOT NULL,
    currency TEXT,
    updated_at TEXT NOT NULL,
    FOREIGN KEY (purchase_order_uuid) REFERENCES purchase_orders(uuid),
    FOREIGN KEY (manufacturer_material_uuid) REFERENCES manufacturer_materials(uuid),
    FOREIGN KEY (currency) REFERENCES currencies(name)
    ```

11. **purchase_order_payments**
    ```sql
    uuid TEXT PRIMARY KEY,
    purchase_order_uuid TEXT NOT NULL,
    date TEXT NOT NULL,
    amount REAL NOT NULL,
    currency TEXT DEFAULT 'INR',
    upi_ref_number TEXT,
    updated_at TEXT NOT NULL,
    FOREIGN KEY (purchase_order_uuid) REFERENCES purchase_orders(uuid),
    FOREIGN KEY (currency) REFERENCES currencies(name)
    ```

**Basket & Vendor Quotation Tables:**

12. **basket_headers**
    ```sql
    uuid TEXT PRIMARY KEY,
    id INTEGER,
    date TEXT NOT NULL,
    description TEXT,
    expected_delivery_date TEXT,
    currency TEXT DEFAULT 'INR',
    base_price REAL DEFAULT 0.0,
    tax_amount REAL DEFAULT 0.0,
    total_amount REAL DEFAULT 0.0,
    number_of_items INTEGER DEFAULT 0,
    updated_at TEXT NOT NULL,
    FOREIGN KEY (currency) REFERENCES currencies(name)
    ```

13. **basket_items**
    ```sql
    uuid TEXT PRIMARY KEY,
    id INTEGER,
    basket_uuid TEXT NOT NULL,
    manufacturer_material_uuid TEXT NOT NULL,
    manufacturer_uuid TEXT NOT NULL,
    material_uuid TEXT NOT NULL,
    model TEXT NOT NULL,
    quantity REAL NOT NULL,
    unit TEXT NOT NULL,
    max_retail_price REAL DEFAULT 0.0,
    currency TEXT DEFAULT 'INR',
    total_price REAL DEFAULT 0.0,
    updated_at TEXT NOT NULL,
    FOREIGN KEY (basket_uuid) REFERENCES basket_headers(uuid),
    FOREIGN KEY (manufacturer_material_uuid) REFERENCES manufacturer_materials(uuid),
    FOREIGN KEY (manufacturer_uuid) REFERENCES manufacturers(uuid),
    FOREIGN KEY (material_uuid) REFERENCES materials(uuid),
    FOREIGN KEY (unit) REFERENCES unit_of_measures(name),
    FOREIGN KEY (currency) REFERENCES currencies(name)
    ```

14. **quotations**
    ```sql
    uuid TEXT PRIMARY KEY,
    id INTEGER,
    basket_uuid TEXT NOT NULL,
    vendor_uuid TEXT NOT NULL,
    date TEXT NOT NULL,
    expected_delivery_date TEXT,
    currency TEXT DEFAULT 'INR',
    base_price REAL DEFAULT 0.0,
    tax_amount REAL DEFAULT 0.0,
    total_amount REAL DEFAULT 0.0,
    number_of_available_items INTEGER DEFAULT 0,
    number_of_unavailable_items INTEGER DEFAULT 0,
    updated_at TEXT NOT NULL,
    FOREIGN KEY (basket_uuid) REFERENCES basket_headers(uuid),
    FOREIGN KEY (vendor_uuid) REFERENCES vendors(uuid),
    FOREIGN KEY (currency) REFERENCES currencies(name)
    ```

15. **quotation_items**
    ```sql
    uuid TEXT PRIMARY KEY,
    id INTEGER,
    quotation_uuid TEXT NOT NULL,
    basket_uuid TEXT NOT NULL,
    basket_item_uuid TEXT NOT NULL,
    manufacturer_material_uuid TEXT NOT NULL,
    quantity REAL NOT NULL,
    rate REAL NOT NULL,
    rate_before_tax REAL DEFAULT 0.0,
    tax_percent REAL NOT NULL,
    tax_amount REAL NOT NULL,
    base_price REAL DEFAULT 0.0,
    total_amount REAL NOT NULL,
    currency TEXT DEFAULT 'INR',
    item_available INTEGER DEFAULT 1,
    updated_at TEXT NOT NULL,
    FOREIGN KEY (quotation_uuid) REFERENCES quotations(uuid),
    FOREIGN KEY (basket_uuid) REFERENCES basket_headers(uuid),
    FOREIGN KEY (basket_item_uuid) REFERENCES basket_items(uuid),
    FOREIGN KEY (manufacturer_material_uuid) REFERENCES manufacturer_materials(uuid),
    FOREIGN KEY (currency) REFERENCES currencies(name)
    ```

**Sync Tables:**

16. **change_log**
    ```sql
    uuid TEXT PRIMARY KEY,
    table_index INTEGER NOT NULL,
    table_key_uuid TEXT NOT NULL,
    change_mode TEXT NOT NULL,
    updated_at TEXT NOT NULL DEFAULT (datetime('now'))
    ```

17. **condensed_change_log**
    ```sql
    uuid TEXT PRIMARY KEY,
    table_index INTEGER NOT NULL,
    table_key_uuid TEXT NOT NULL,
    change_mode TEXT NOT NULL,
    updated_at TEXT NOT NULL
    ```

18. **sync_metadata**
    ```sql
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL,
    updated_at TEXT NOT NULL
    ```

19. **local_settings**
    ```sql
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL,
    updated_at TEXT NOT NULL
    ```

**Indexes:**
- Foreign key indexes on all reference columns
- `idx_change_log_table_index` on change_log(table_index)
- `idx_change_log_updated_at` on change_log(updated_at)
- `idx_basket_headers_date` on basket_headers(date)
- `idx_basket_headers_updated_at` on basket_headers(updated_at)
- `idx_basket_items_basket` on basket_items(basket_uuid)
- `idx_basket_items_manufacturer_material` on basket_items(manufacturer_material_uuid)
- `idx_basket_items_updated_at` on basket_items(updated_at)
- `idx_quotations_basket` on quotations(basket_uuid)
- `idx_quotations_vendor` on quotations(vendor_uuid)
- `idx_quotations_updated_at` on quotations(updated_at)
- `idx_quotation_items_quotation` on quotation_items(quotation_uuid)
- `idx_quotation_items_basket` on quotation_items(basket_uuid)
- `idx_quotation_items_basket_item` on quotation_items(basket_item_uuid)
- `idx_quotation_items_updated_at` on quotation_items(updated_at)
- Performance indexes on frequently queried columns

### Sync Service (`lib/services/delta_sync_service.dart`)

#### Two-Phase Sync Process

**Phase 1: PULL (Download from Server)**
```dart
1. Request changes from server since last sync timestamp
2. Server consolidates change_log into condensed_change_log
3. Server returns paginated change log entries
4. Server fetches actual records for changed UUIDs
5. Client receives log entries and record data
6. Client applies changes locally:
   - For each change, compare timestamps
   - If server record is newer, update local record
   - If local record is newer, keep local version
```

**Change Log Condensing:**
Before sending changes to the server, the client condenses the change log to eliminate redundant entries:

1. **Multiple UPDATEs**: Keep only the first UPDATE for each record
   - Example: 10 UPDATEs for same basket → 1 UPDATE sent

2. **INSERT followed by DELETE**: Remove both entries
   - Example: Temporary record created and deleted → Nothing sent

3. **UPDATE followed by DELETE**: Remove both entries  
   - Example: Record modified then deleted → Only DELETE sent

4. **DELETE only** (no prior INSERT/UPDATE): Keep the DELETE
   - Example: Standalone DELETE → DELETE sent

This condensing happens in the `condenseChangeLog()` method and significantly reduces:
- Network traffic
- Sync time
- Backend processing
- Google Sheets duplicate records

**Phase 2: PUSH (Upload to Server)**
```dart
1. Query local change_log since last sync
2. Condense the change log (remove redundancies)
3. Group condensed changes by table
4. Fetch actual record data for insert/update operations
5. Send batches of condensed changes to server (200 records/batch)
6. Server applies changes:
   - Process deletes first
   - Then process inserts/updates per table
   - Log changes to server change_log
7. Server returns count of processed changes
8. Clear local change_log after successful push
```

#### Conflict Resolution

**Last-Write-Wins Strategy:**
- Every record has an `updated_at` timestamp
- During sync, the version with the **latest timestamp wins**
- No manual merge required
- Simple and deterministic

**Example:**
```
Local Record:  {uuid: "abc", name: "Product A", updated_at: "2025-01-02T10:00:00Z"}
Server Record: {uuid: "abc", name: "Product B", updated_at: "2025-01-02T11:00:00Z"}
Result:        Server wins (newer timestamp)
```

#### Sync Configuration

**Table Order (dependency-based):**
1. unit_of_measures (independent)
2. currencies (independent)
3. manufacturers (independent)
4. vendors (independent)
5. materials (→ unit_of_measures)
6. manufacturer_materials (→ manufacturers, materials, currencies)
7. vendor_price_lists (→ manufacturer_materials, vendors, currencies)
8. projects (independent)
9. purchase_orders (→ vendors, currencies)
10. purchase_order_items (→ purchase_orders, manufacturer_materials, currencies)
11. purchase_order_payments (→ purchase_orders, currencies)
12. basket_headers (→ currencies)
13. basket_items (→ basket_headers, manufacturer_materials, manufacturers, materials, unit_of_measures, currencies)
14. quotations (→ basket_headers, vendors, currencies)
15. quotation_items (→ quotations, basket_headers, basket_items, manufacturer_materials, currencies)

**Sync Metadata:**
- `last_sync_timestamp` - Last successful sync time
- `web_app_url` - Google Apps Script web app URL
- `secret_code` - APP_CODE for authentication

**Local Settings:**
- `developer-mode` - Toggle developer features visibility
- `sync-paused` - Pause/resume automatic sync operations

**Features:**
- Progress callbacks for UI updates
- Debug logging (up to 500 entries)
- Error collection and reporting
- Sync lock to prevent concurrent syncs
- Pagination (200 records per batch)
- Automatic retry on redirect (HTTP 301/302)
- Change log condensing for efficiency
- Pause/Play sync control
- Automatic sync on app resume (when not paused)

### Data Models (`lib/models/`)

Each model includes:
- **UUID Primary Key**: Globally unique identifier
- **Optional Auto-Increment ID**: User-friendly sequential number
- **Timestamps**: `updated_at` for sync tracking
- **Type Safety**: Null-safe parsing helpers
- **Serialization**: `toMap()` and `fromMap()` methods
- **Immutability**: `copyWith()` for creating modified copies

**Helper Functions:**
```dart
// Safe parsing to prevent runtime errors
double _toDouble(dynamic value) { ... }
int? _toIntNullable(dynamic value) { ... }
```

**Extended Models:**
- `ManufacturerMaterialWithDetails` - Includes manufacturer/material names
- `VendorPriceListWithDetails` - Includes vendor/manufacturer/material names
- `BasketItemWithDetails` - Includes full item details for display
- `QuotationWithDetails` - Includes vendor name and item count
- Used for efficient JOINed queries and display

### Screen Architecture (`lib/screens/`)

**Screen Types:**
1. **Login Screen** - Credential configuration and validation
2. **Home Screen** - Navigation hub with menu cards
3. **List Screens** - Browse and search records with pull-to-refresh
4. **Detail Screens** - Create, edit, delete individual records
5. **Comparison Screens** - Vendor quotation comparison
6. **Sync Debug Screen** - Troubleshooting and logs
7. **Import Data Screen** - CSV data import
8. **Settings Screen** - Developer mode, sync controls, data management
9. **Database Browser Screen** - View and query raw SQLite data

**Common Patterns:**
- StatefulWidget with DatabaseHelper instance
- Loading states with CircularProgressIndicator
- Async data loading in initState
- Form validation with GlobalKey<FormState>
- Unsaved changes warnings with PopScope
- Search/filter capabilities with TextField
- Pull-to-refresh on list screens with RefreshIndicator
- Auto-save functionality for seamless UX
- Searchable Autocomplete widgets instead of dropdowns
- CommonOverflowMenu for consistent app-wide actions

**Navigation Patterns:**
- Auto-refresh on screen return using PopScope
- Navigator.push with await for result handling
- Material page routes for smooth transitions

**UI Components:**
- **CommonOverflowMenu**: Reusable overflow menu widget providing:
  - Settings access
  - Sync with Google Sheets
  - Stop Sync (emergency stop for running sync)
  - Pause/Play Sync toggle (prevent automatic syncs)
  - View Sync Log (debug interface)
  - Developer-only features:
    - Prepare Condensed Change Log
    - Data Statistics
    - Database Browser
  - Screen-specific additional menu items
  - Consistent menu structure across all screens

---

## Key Features

### 1. Units of Measure Management
- Create, read, update units of measure
- Name as primary key (e.g., "kg", "liter", "piece")
- Description field for full name
- Number of decimal places for quantity precision (0-4)
- Default unit flag
- Cannot delete (protected master data)
- Referenced by materials and basket items

### 2. Currencies Management
- Create, read, update currencies
- Name as primary key (e.g., "USD", "EUR", "INR")
- Symbol field (e.g., "$", "€", "₹")
- Description field for full name
- Number of decimal places for amount precision (0-4)
- Default currency flag
- Cannot delete (protected master data)
- Referenced by all financial transactions
- Used for decimal formatting throughout the app

### 3. Manufacturers Management
- Create, read, update, delete manufacturers
- Track name and description
- Auto-generated ID for user reference
- Referenced by manufacturer_materials
- Searchable autocomplete in forms

### 4. Vendors Management
- Full CRUD operations
- Address and geo-location tracking
- Auto-generated ID
- Referenced by purchase orders, price lists, and quotations
- Searchable autocomplete in vendor selection

### 5. Materials Management
- Material master data
- Unit of measure (UOM) tracking with foreign key
- Description field
- Referenced by manufacturer_materials
- Model/variant support
- Searchable autocomplete in forms

### 6. Manufacturer Materials
- Links manufacturers to materials with specific models
- Model/variant tracking (e.g., different sizes, colors)
- Selling lot size configuration
- Maximum retail price with currency reference
- Enables same material from multiple manufacturers
- Delete protection if in use
- Searchable selection in basket items
- Formatted display: "Manufacturer - Material - Model"

### 7. Vendor Price Lists
- Pricing by vendor for each manufacturer material
- Rate (with tax included)
- Rate before tax (calculated automatically)
- Tax percent and calculated tax amount
- Multi-currency support with foreign key
- Enables vendor price comparison
- Search filters: vendor, manufacturer, material
- Bidirectional calculation between rate and rate before tax
- Formatted amounts using currency decimal places

**Calculation:**
```
tax_amount = rate_before_tax × (tax_percent / 100)
rate = rate_before_tax + tax_amount

OR (reverse):
rate_before_tax = rate / (1 + tax_percent / 100)
tax_amount = rate - rate_before_tax
```

### 8. Projects Management
- Create, read, update, delete projects
- Track project name, description, address
- Start date and end date tracking
- Completion status flag
- Auto-generated ID for user reference
- Future use: Link purchase orders to projects
- Searchable autocomplete in forms

### 9. Basket & Vendor Quotation System

#### Basket Management
- **Create Baskets**: Shopping cart for items to quote
- **Basket Header**: Date, description, expected delivery, currency with foreign key
- **Auto-persist**: New baskets saved immediately on creation
- **Totals Calculation**: Auto-calculated from basket items
- **Item Count Tracking**: Automatic count of items in basket
- **Multi-vendor Support**: Get quotes from multiple vendors
- **Currency-based Formatting**: All amounts formatted per currency settings

#### Basket Items
- **Item Selection**: Search and add manufacturer materials
- **Quantity Specification**: Quantity with unit from material (foreign key)
- **Item Display**: "Manufacturer - Material - Model" format
- **Auto-sync**: Changes automatically sync to quotation items
- **Delete Protection**: Updates all affected quotations
- **Price Tracking**: MRP and total price from manufacturer material
- **Decimal Formatting**: Quantity formatted per unit decimal places

**Display Format:**
```
Line 1: Manufacturer - Material - Model
Line 2: Qty: [quantity formatted] [unit] × [MRP formatted] [currency] = [total formatted]
```

#### Vendor Quotations
- **Create Quotations**: Add vendors to basket for quotes
- **Generate Items**: Auto-create items from basket items
- **Pricing Lookup**: Uses vendor price list for initial rates
- **Totals**: Base price, tax, total auto-calculated
- **Item Count**: Shows available and unavailable item counts
- **Comparison**: Side-by-side vendor comparison view
- **Best Price Highlighting**: Lowest total marked with 🏆
- **Currency Formatting**: All amounts formatted per currency settings

**Hierarchical Title Format:**
```
🛒 # [Basket ID] | Quotation # [Vendor Quotation ID]
```

#### Vendor Quotation Items
- **Item-level Pricing**: Rate, rate before tax, tax percent
- **All Editable**: All price fields can be edited
- **Auto-save**: Changes saved immediately on edit
- **Bidirectional Calculation**: Edit any field, others recalculate
- **Item Availability**: Toggle available/unavailable status
- **Automatic Totals**: Updates quotation totals on change
- **Currency Formatting**: All amounts formatted per currency settings
- **Quantity Formatting**: Formatted per unit decimal places

**Hierarchical Title Format:**
```
🛒 # [Basket ID] | Quotation # [Vendor Quotation ID] | Item ID
```

**Item Display:**
```
Manufacturer - Material - Model
Qty: [quantity formatted] [unit]
Rate: [rate formatted] [currency]
Total: [total formatted] [currency]
```

#### Automatic Synchronization
When basket items are modified, vendor items automatically sync:

**Insert Basket Item:**
```
1. Item added to basket
2. For each existing quotation:
   - Create corresponding vendor item
   - Look up vendor price list for pricing
   - Set quantity from basket item
   - Calculate prices and taxes
   - Update quotation totals
```

**Update Basket Item:**
```
1. Basket item quantity changed
2. For each quotation:
   - Update vendor item quantity
   - Recalculate prices
   - Update quotation totals
```

**Delete Basket Item:**
```
1. Item deleted from basket
2. Query all affected quotations
3. Delete vendor items for that basket item
4. For each affected quotation:
   - Recalculate totals
   - Update quotations record
```

#### Vendor Comparison
- **Side-by-side View**: Compare all vendors for a basket
- **Totals Display**: See base price, tax, total for each vendor
- **Item Count**: Number of items in each quotation
- **Quick Access**: Tap to view/edit individual quotations
- **Easy Navigation**: Return to basket with updated data

### 10. Purchase Orders
- Auto-refresh on screen return using PopScope
- Navigator.push with await for result handling
- Material page routes for smooth transitions

---

## Key Features

### 1. Manufacturers Management
- Create, read, update, delete manufacturers
- Track name and description
- Auto-generated ID for user reference
- Referenced by manufactuToggle available/unavailable status
- **Automatic Totals**: Updates quotation totals on change
- **Currency Formatting**: All amounts formatted per currency settings
- **Quantity Formatting**: Formatted per unit decimal places

**Hierarchical Title Format:**
```
🛒 # [Basket ID] | Quotation # [Vendor Quotation ID] | Item ID
```

**Item Display:**
```

### 10. Purchase Orders

#### Header Management
- **Vendor Selection**: Searchable vendor autocomplete
- **Order Dates**: Order date (default: current date), expected delivery date
- **Financial Totals**: Base price, tax amount, total amount (auto-calculated from items)
- **Payment Tracking**: Amount paid, amount balance
- **Status**: Completion flag (prevents edits when completed)
- **Currency**: Multi-currency support with foreign key
- **Formatted Amounts**: All financial fields formatted per currency settings

#### Item Management
- **Material Selection**: Searchable autocomplete, filtered by vendor's price list
- **Quantity & Pricing**: Quantity, rate, rate before tax
- **Tax Calculation**: Tax percent inherited from vendor price list
- **Automatic Calculations**:
  ```
  base_price = quantity × rate_before_tax
  tax_amount = base_price × (tax_percent / 100)
  total_amount = base_price + tax_amount
  ```
- **Material Tracking**: Material ID and model copied from manufacturer material
- **Delete Protection**: Cannot delete items from completed orders
- **Currency Formatting**: All amounts formatted per currency settings
- **Quantity Formatting**: Formatted per unit decimal places

#### Payment Management
- Multiple payments per purchase order
- Payment date and amount
- Currency specification with foreign key
- UPI reference number for digital payments
- Automatic balance calculation:
  ```
  amount_balance = total_amount - amount_paid
  ```
- **Currency Formatting**: Amount formatted per currency settings

#### Rollup Calculations
Purchase order header amounts are calculated from items:
```
PO.base_price = SUM(item.base_price)
PO.tax_amount = SUM(item.tax_amount)
PO.total_amount = SUM(item.total_amount)
```

#### PDF Generation
- Export purchase order as PDF
- Includes vendor details, order information
- Line items with quantities, rates, taxes
- Payment history
- Totals summary
- Shareable via email, messaging, etc.

### 11. Data Import/Export
- CSV import for units of measure, currencies, manufacturers, materials, vendors, projects
- Export current sheet to CSV (Google Sheets)
- Sample data available in `sample-data/` folder
- Automatic UUID generation for imported records
- Validation and error reporting

### 12. Synchronization
- Manual sync trigger from app via CommonOverflowMenu
- Login/credential validation
- Progress indicators with live updates
- Debug logs for troubleshooting (up to 500 entries)
- Error reporting and recovery
- Change log condensing for efficiency
- Pause/Play controls:
  - **Play Sync**: Normal operation with automatic syncs
  - **Pause Sync**: Prevents automatic syncs (manual sync still works)
  - State persisted in local_settings
- Stop sync capability for emergency termination
- Automatic sync on app resume (when not paused)
- Background sync prevention when paused

### 13. Developer Features
- **Developer Mode Toggle**: Show/hide advanced features
- **Database Browser**: View and query raw SQLite tables
- **Data Statistics**: View record counts per table
- **Condensed Change Log**: Prepare and view condensed logs
- **Sync Debug Screen**: Real-time sync logs with auto-refresh
- **Settings Screen**: Centralized configuration
- All developer features accessible via CommonOverflowMenu

---

## Data Flow & Relationships

## Data Flow & Relationships

### Entity Relationship Diagram

**Master Data Relationships:**
```
┌──────────────────┐  ┌──────────────┐
│Unit_of_Measures  │  │  Currencies  │
└────────┬─────────┘  └──────┬───────┘
         │                   │
         │ 1:N               │ 1:N (to multiple tables)
         ▼                   │
┌──────────────┐             │
│  Materials   │◄────────────┘ (currency for MRP)
└──────┬───────┘
       │
       │ N:1
       ▼
┌──────────────────────┐      ┌──────────────┐
│Manufacturer_Materials│◄─────│Manufacturers │
│(model variants)      │ N:1  └──────────────┘
└──────────────────────┘
```

**Vendor-Related Relationships:**
```
                    ┌──────────────────────┐
                    │Manufacturer_Materials│
                    └──────────┬───────────┘
                               │
                               │ N:1
                               ▼
┌──────────────┐         ┌──────────────────┐
│   Vendors    │────────►│Vendor_Price_Lists│
└──────┬───────┘  1:N    │(pricing by vendor│
       │                 │ per material)    │
       │                 └──────────────────┘
       │ 1:N
       ├────────────────────┬────────────────────┐
       │                    │                    │
       ▼                    ▼                    ▼
┌──────────────┐    ┌───────────────┐    ┌─────────────────┐
│Quotations    │    │Purchase_Orders│    │(other vendor    │
│              │    │               │    │ relationships)  │
└──────────────┘    └───────────────┘    └─────────────────┘
```

**Basket Workflow:**
```
                    ┌──────────────┐
                    │Basket_Headers│
                    └──────┬───────┘
                           │
                           │ 1:N
              ┌────────────┴────────────┐
              │                         │
              ▼                         ▼
       ┌──────────────┐          ┌──────────────┐
       │Basket_Items  │          │Quotations    │
       │              │          │(by vendor)   │
       └──────┬───────┘          └──────┬───────┘
              │                         │
              │                         │ 1:N
              │                         ▼
              │                  ┌──────────────────┐
              │                  │Quotation_Items   │
              │                  │(pricing per item)│
              │                  └──────┬───────────┘
              │                         │
              │ basket_item_uuid        │
              └─────────────────────────┘
                   (links items to quotes)
```

**Purchase Order Structure:**
```
            ┌─────────────────┐
            │Purchase_Orders  │
            │(header with     │
            │ totals)         │
            └────────┬────────┘
                     │
                     │ 1:N
          ┌──────────┴──────────┐
          │                     │
          ▼                     ▼
┌──────────────────┐   ┌──────────────────────┐
│Purchase_Order    │   │Purchase_Order        │
│  _Items          │   │  _Payments           │
│(line items with  │   │(payment records with │
│ quantities &     │   │ amounts & dates)     │
│ pricing)         │   │                      │
└──────────────────┘   └──────────────────────┘
```

### Data Dependency Order (for sync)

1. **Level 1 (Independent - Foundation)**:
   - unit_of_measures
   - currencies

2. **Level 2 (Depends on Level 1)**:
   - manufacturers (independent)
   - vendors (independent)
   - materials (→ unit_of_measures)
   - projects (independent)

3. **Level 3 (Depends on Level 2)**:
   - manufacturer_materials (→ manufacturers, materials, currencies)

4. **Level 4 (Depends on Level 3)**:
   - vendor_price_lists (→ manufacturer_materials, vendors, currencies)
   - basket_headers (→ currencies)
   - purchase_orders (→ vendors, currencies)

5. **Level 5 (Depends on Level 4)**:
   - basket_items (→ basket_headers, manufacturer_materials, manufacturers, materials, unit_of_measures, currencies)
   - quotations (→ basket_headers, vendors, currencies)
   - purchase_order_items (→ purchase_orders, manufacturer_materials, currencies)
   - purchase_order_payments (→ purchase_orders, currencies)

6. **Level 6 (Most Dependent)**:
   - quotation_items (→ quotations, basket_headers, basket_items, manufacturer_materials, currencies)
## Data Flow & Relationships

### Entity Relationship Diagram

**Master Data Relationships:**
```
┌──────────────────┐  ┌──────────────┐
│Unit_of_Measures  │  │  Currencies  │
└────────┬─────────┘  └──────┬───────┘
         │                   │
         │ 1:N               │ 1:N (to multiple tables)
         ▼                   │
┌──────────────┐             │
│  Materials   │◄────────────┘ (currency for MRP)
└──────┬───────┘
       │
       │ N:1
       ▼
┌──────────────────────┐      ┌──────────────┐
│Manufacturer_Materials│◄─────│Manufacturers │
│(model variants)      │ N:1  └──────────────┘
└──────────────────────┘
```

**Vendor-Related Relationships:**
```
                    ┌──────────────────────┐
                    │Manufacturer_Materials│
                    └──────────┬───────────┘
                               │
                               │ N:1
                               ▼
┌──────────────┐         ┌──────────────────┐
│   Vendors    │────────►│Vendor_Price_Lists│
└──────┬───────┘  1:N    │(pricing by vendor│
       │                 │ per material)    │
       │                 └──────────────────┘
       │ 1:N
       ├────────────────────┬────────────────────┐
       │                    │                    │
       ▼                    ▼                    ▼
┌──────────────┐    ┌───────────────┐    ┌─────────────────┐
│Quotations    │    │Purchase_Orders│    │(other vendor    │
│              │    │               │    │ relationships)  │
└──────────────┘    └───────────────┘    └─────────────────┘
```

**Basket Workflow:**
```
                    ┌──────────────┐
                    │Basket_Headers│
                    └──────┬───────┘
                           │
                           │ 1:N
              ┌────────────┴────────────┐
              │                         │
              ▼                         ▼
       ┌──────────────┐          ┌──────────────┐
       │Basket_Items  │          │Quotations    │
       │              │          │(by vendor)   │
       └──────┬───────┘          └──────┬───────┘
              │                         │
              │                         │ 1:N
              │                         ▼
              │                  ┌──────────────────┐
              │                  │Quotation_Items   │
              │                  │(pricing per item)│
              │                  └──────┬───────────┘
              │                         │
              │ basket_item_uuid        │
              └─────────────────────────┘
                   (links items to quotes)
```

**Purchase Order Structure:**
```
            ┌─────────────────┐
            │Purchase_Orders  │
            │(header with     │
            │ totals)         │
            └────────┬────────┘
                     │
                     │ 1:N
          ┌──────────┴──────────┐
          │                     │
          ▼                     ▼
┌──────────────────┐   ┌──────────────────────┐
│Purchase_Order    │   │Purchase_Order        │
│  _Items          │   │  _Payments           │
│(line items with  │   │(payment records with │
│ quantities &     │   │ amounts & dates)     │
│ pricing)         │   │                      │
└──────────────────┘   └──────────────────────┘
```

### Data Dependency Order (for sync)

1. **Level 1 (Independent)**:
   - manufacturers
   - vendors
   - materials

2. **Level 2 (Depends on Level 1)**:
   - manufacturer_materials (→ manufacturers, materials)

3. **Level 3 (Depends on Level 2)**:
   - vendor_price_lists (→ manufacturer_materials, vendors)
   - basket_header (independent)

4. **Level 4 (Depends on Level 3)**:
   - basket_items (→ basket_header, manufacturer_materials)
   - quotations (→ basket_header, vendors)
   - purchase_orders (→ vendors)

5. **Level 5 (Depends on Level 4)**:
   - quotation_items (→ quotations, basket_items, manufacturer_materials)
   - purchase_order_items (→ purchase_orders, manufacturer_materials)
   - purchase_order_payments (→ purchase_orders)

---

## Synchronization Workflow

### Initial Setup

1. **Google Sheets Setup**:
   ```
   1. Create new Google Sheet
   2. Open Extensions → Apps Script
   3. Copy backend code from backend/google-app-script-code/
   4. Run setup() function
   5. Authorize script
   6. Copy APP_CODE from config sheet
   7. Deploy as Web App (Anyone with link)
   8. Copy Web App URL
   ```

2. **Mobile App Configuration**:
   ```
   1. Open app → Login screen
   2. Enter Web App URL
   3. Enter APP_CODE secret
   4. Click "Connect and Login"
   5. Credentials saved locally
   ```

### Sync Execution Flow

```
┌─────────────┐
│   START     │
└──────┬──────┘
       │
       ▼
┌─────────────────────┐
│ Validate Credentials│
│  (secret code)      │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│  PHASE 1: PULL      │
│                     │
│ 1. Request changes  │
│    since last sync  │
│ 2. Server creates   │
│    condensed log    │
│ 3. Fetch records    │
│    in batches       │
│ 4. Apply to local   │
│    DB (if newer)    │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│  PHASE 2: PUSH      │
│                     │
│ 1. Read local       │
│    change_log       │
│ 2. Fetch record     │
│    data             │
│ 3. Send in batches  │
│ 4. Server applies   │
│    changes          │
│ 5. Server logs      │
│    changes          │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│ Update last_sync    │
│    timestamp        │
└──────┬──────────────┘
       │
       ▼
┌─────────────┐
│   SUCCESS   │
└─────────────┘
```

### Change Tracking Mechanism

**On Local Data Modification:**
```dart
1. User creates/updates/deletes a record
2. DatabaseHelper updates the record in SQLite
3. DatabaseHelper logs change to change_log table:
   {
     table_index: 8,           // quotations
     key: "uuid-123",          // record UUID
     change_mode: 'U',         // Update
     updated_at: "2025-01-03T10:30:00Z"
   }
4. Change remains in change_log until next sync
```

**On Sync:**
```dart
1. PUSH phase reads all change_log entries since last sync
2. Groups by table_index
3. For 'D' (delete): sends just the UUID
4. For 'I'/'U': fetches full record data
5. Sends to server
6. Server applies and logs to its change_log
7. Client change_log can be purged after successful sync (optional)
```

---

## Best Practices & Design Patterns

### 1. Offline-First Architecture
- All data stored locally in SQLite
- App fully functional without network
- Sync when network available
- No data loss on connectivity issues

### 2. UUID-Based Primary Keys
- Globally unique identifiers
- No ID conflicts across devices
- Enables distributed data creation
- Safe for offline operations
- Auto-increment IDs only for user display

### 3. Timestamp-Based Conflict Resolution
- Simple last-write-wins strategy
- No complex merge logic needed
- Deterministic and predictable
- `updated_at` on every record

### 4. Change Log for Incremental Sync
- Only changed records transferred
- Efficient bandwidth usage
- Fast sync times
- Condensed log for optimization
- Indexed by table and timestamp

### 5. Batch Processing
- 200 records per API request
- Reduces HTTP overhead
- Prevents timeout issues
- Progress tracking possible

### 6. Denormalized Views (Google Sheets)
- Lookup formulas for reference columns
- Human-readable data
- Easy manual verification
- No impact on mobile app

### 7. Type Safety
- Null-safe parsing throughout
- Helper functions prevent crashes
- Default values for missing data
- Graceful degradation

### 8. Security
- Secret code authentication
- Credentials not in URL
- POST-only API endpoints
- No public data access

### 9. Delete Protection
- Check references before delete
- Prevent orphaned records
- User-friendly error messages
- Maintain data integrity

### 10. Auto-Save Pattern
- Immediate persistence on change
- No explicit save button needed
- Controller listeners for auto-save
- PopScope for auto-return with data

### 11. Searchable Autocomplete
- Replace dropdowns with Autocomplete widgets
- Type-to-search functionality
- `onTapOutside` for easy dismissal
- Better UX for long lists
- Multi-word search support

### 12. Automatic Synchronization
- Basket items sync to vendor items
- Quantity changes propagate automatically
- Totals recalculated on every change
- Maintains data consistency

---

## UI/UX Patterns

### Navigation
- Material Design bottom navigation
- Card-based home screen
- Hierarchical navigation with back button
- PopScope for handling back navigation
- Auto-refresh on return from detail screens

### Forms
- TextFormField with validation
- Autocomplete for searchable selections
- Real-time calculation and updates
- Auto-save on field changes
- Visual feedback for required fields

### Lists
- Pull-to-refresh on all list screens
- Search/filter at top
- Swipe-to-delete (Dismissible)
- Empty state messages
- Loading indicators

### Data Entry
- Searchable autocomplete instead of dropdowns
- Numeric keyboards for number fields
- Date pickers for date fields
- Currency format helpers
- Input formatters for validation

### Feedback
- SnackBars for success/error messages
- CircularProgressIndicator for loading
- Confirmation dialogs for destructive actions
- Color coding (red for delete, green for success)
- Toast messages for quick feedback

---

## File Structure

```
purchase/
├── android/                      # Android native project
├── ios/                          # iOS native project
├── lib/                          # Flutter application code
│   ├── main.dart                 # App entry point
│   ├── config/
│   │   └── sync_config.dart      # Sync configuration constants
│   ├── models/                   # Data models
│   │   ├── manufacturer.dart
│   │   ├── vendor.dart
│   │   ├── material.dart
│   │   ├── manufacturer_material.dart
│   │   ├── vendor_price_list.dart
│   │   ├── basket_header.dart
│   │   ├── basket_item.dart
│   │   ├── quotation.dart
│   │   ├── quotation_item.dart
│   │   ├── purchase_order.dart
│   │   ├── purchase_order_item.dart
│   │   └── purchase_order_payment.dart
│   ├── services/                 # Business logic layer
│   │   ├── database_helper.dart  # SQLite operations
│   │   ├── delta_sync_service.dart # Sync logic
│   │   ├── auth_service.dart     # Authentication
│   │   └── csv_import_service.dart # Data import
│   └── screens/                  # UI screens
│       ├── login_screen.dart
│       ├── home_screen.dart
│       ├── manufacturers_screen.dart
│       ├── manufacturer_detail_screen.dart
│       ├── vendors_screen.dart
│       ├── vendor_detail_screen.dart
│       ├── materials_screen.dart
│       ├── material_detail_screen.dart
│       ├── manufacturer_materials_screen.dart
│       ├── manufacturer_material_detail_screen.dart
│       ├── vendor_price_lists_screen.dart
│       ├── vendor_price_list_detail_screen.dart
│       ├── baskets_screen.dart
│       ├── basket_detail_screen.dart
│       ├── basket_item_detail_screen.dart
│       ├── quotations_screen.dart
│       ├── quotation_detail_screen.dart
│       ├── quotation_item_detail_screen.dart
│       ├── purchase_orders_screen.dart
│       ├── purchase_order_detail_screen.dart
│       ├── purchase_order_item_detail_screen.dart
│       ├── sync_debug_screen.dart
│       └── import_data_screen.dart
├── backend/                      # Google Apps Script backend
│   ├── google-app-script-code/
│   │   ├── Code.js               # Entry point
│   │   ├── constants.js          # Global constants
│   │   ├── tableMetadata.js      # Table definitions
│   │   ├── config.js             # Configuration management
│   │   ├── setup.js              # Sheet initialization
│   │   ├── utils.js              # Utility functions
│   │   ├── webService.js         # API endpoints
│   │   ├── webSecurity.js        # Authentication
│   │   ├── deltaSync.js          # Sync logic
│   │   ├── changeLogUtils.js     # Change tracking
│   │   ├── dataReaders.js        # Data reading
│   │   ├── cleanup.js            # Data cleanup
│   │   ├── sheetEventHandlers.js # Event handlers
│   │   └── README.md             # Backend documentation
│   └── README.md                 # Setup instructions
├── sample-data/                         # Sample CSV data
│   ├── manufacturers.csv
│   ├── vendors.csv
│   ├── materials.csv
│   └── README.md
├── docu/                         # Screenshots
├── README.md                     # Main documentation
├── SYNC_SETUP.md                 # Sync setup guide
└── ARCHITECTURE.md               # This file
```

---

## Performance Considerations

### Mobile App
- **Indexed Queries**: All foreign keys indexed
- **Batch Operations**: Bulk inserts/updates
- **Lazy Loading**: Load data only when needed
- **Connection Pooling**: Single DatabaseHelper instance
- **Efficient JOINs**: Extended models reduce queries
- **Auto-save**: Debounced saves prevent excessive writes

### Google Sheets Backend
- **Batch Processing**: Process multiple changes at once
- **Condensed Change Log**: Reduces redundant entries
- **Efficient Lookups**: Uses maps/dictionaries for O(1) access
- **Minimal Sheet Operations**: Read/write entire ranges at once
- **Auto-resize Optimization**: Only after bulk updates

### Network
- **Pagination**: 200 records per request
- **Compression**: JSON is compact
- **Delta Sync**: Only changed records
- **Request Batching**: Minimize HTTP overhead

### Scalability Limits

**Google Sheets:**
- Max 5 million cells per spreadsheet
- Max 40,000 new rows per day
- 6 minute execution time limit per script run

**Recommended:**
- Archive old purchase orders and baskets periodically
- Keep active data under 10,000 records per table
- Monitor script execution times
- Use pagination for large datasets

---

## Future Enhancements

### Potential Features
1. **Multi-user Support**: User-based record ownership
2. **Approval Workflows**: Basket/PO approval chains
3. **Notifications**: Email/SMS on important events
4. **Reports**: PDF reports, analytics dashboards
5. **Barcode Scanning**: Quick material lookup
6. **Photo Attachments**: Material/vendor photos
7. **Offline Maps**: Vendor location navigation
8. **Currency Conversion**: Auto-update exchange rates
9. **Inventory Management**: Stock tracking
10. **Invoice Generation**: Convert PO to invoice
11. **Basket Templates**: Save frequently ordered items
12. **Vendor Performance**: Track delivery times, quality
13. **Budget Tracking**: Budget vs actual spending
14. **Requisition System**: Request approval before ordering

### Technical Improvements
1. **Incremental Sync**: Resume failed syncs
2. **Conflict UI**: Show conflicts, let user resolve
3. **Background Sync**: Auto-sync periodically
4. **Compression**: Compress large payloads
5. **Caching**: Cache frequently accessed data
6. **Search Index**: Full-text search
7. **Data Validation**: Server-side validation
8. **Audit Log**: Detailed change history
9. **Backup/Restore**: Automated backups
10. **Migration Tools**: Schema version management
11. **Optimistic Updates**: Update UI before server confirmation
12. **Batch Auto-save**: Debounced saves for performance

---

## Troubleshooting

### Common Issues

**Sync Fails:**
- Check web app URL is correct
- Verify secret code matches config sheet
- Ensure web app deployed with "Anyone" access
- Check Google Sheets quota limits
- Review sync debug logs

**Data Not Appearing:**
- Verify sync completed successfully
- Check timestamps on records
- Ensure no conflicts (check logs)
- Verify foreign key relationships

**Slow Sync:**
- Reduce batch size if timeouts occur
- Archive old data
- Check network connectivity
- Monitor Google Scripts execution time

**Cannot Delete Record:**
- Check if record is referenced elsewhere
- Review "in use" error messages
- Delete dependent records first
- Cascade deletes if appropriate

**Vendor Items Not Syncing:**
- Check basket item changes are saved
- Verify quotations exist
- Review database logs for errors
- Ensure foreign key integrity

**Autocomplete Not Working:**
- Check data is loaded (_isLoading = false)
- Verify lists are not empty
- Review search logic in optionsBuilder
- Check onTapOutside is working

---

## Version History

- **v2.0** (Current Release - January 2026)
  - Basket and quotation system
  - Automatic item synchronization
  - Vendor comparison features
  - Searchable autocomplete fields
  - Auto-save functionality
  - Enhanced UX patterns

- **v1.0** (Initial Release)
  - Core CRUD operations
  - Delta sync implementation
  - Purchase order management
  - PDF generation
  - CSV import

---

## References

- [Flutter Documentation](https://flutter.dev/docs)
- [Google Apps Script](https://developers.google.com/apps-script)
- [SQLite Documentation](https://www.sqlite.org/docs.html)
- [Material Design Guidelines](https://material.io/design)
- [Dart Language](https://dart.dev/)

---

## Contributing

When modifying this application:

1. **Maintain Schema Compatibility**: Sync requires matching schemas
2. **Update Both Sides**: Changes to tables need both backend and frontend updates
3. **Test Sync**: Always test sync after schema changes
4. **Document Changes**: Update this architecture doc
5. **Version Changes**: Consider migration paths for existing data
6. **Follow Patterns**: Use established patterns (auto-save, autocomplete, etc.)
7. **Test Foreign Keys**: Ensure referential integrity maintained

---

## License

[Specify your license here]

---

## Contact

[Your contact information]
