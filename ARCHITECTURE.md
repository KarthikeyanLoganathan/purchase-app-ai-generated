# Purchase Application - System Architecture

## Overview

The Purchase Application is a Flutter-based mobile application designed for managing purchasing workflows, including vendors, manufacturers, materials, price lists, and purchase orders. The app features offline-first architecture with SQLite local storage and optional cloud synchronization with Google Sheets backend.

## Technology Stack

### Frontend
- **Framework**: Flutter 3.0+
- **Language**: Dart
- **UI Components**: Material Design 3
- **Platform Support**: Android & iOS

### Data Layer
- **Local Database**: SQLite (via sqflite package)
- **Data Persistence**: Offline-first with local SQLite database
- **File Operations**: CSV import/export capabilities

### Backend
- **Cloud Backend**: Google Apps Script (Google Sheets)
- **API Communication**: HTTP REST API
- **Synchronization**: Delta sync with change log tracking
- **Authentication**: Secret code-based authentication

### Key Dependencies
- `sqflite`: SQLite database support
- `http`: REST API communication
- `uuid`: Unique identifier generation
- `intl`: Internationalization and number/date formatting
- `pdf` & `printing`: PDF generation and printing
- `share_plus`: Cross-platform sharing
- `csv`: CSV file processing
- `file_picker`: File selection
- `logger`: Structured logging

## Architecture Pattern

The application follows a **layered architecture** with clear separation of concerns:

```
┌─────────────────────────────────────────┐
│         Presentation Layer              │
│   (Screens, Widgets, UI Components)     │
└─────────────────────────────────────────┘
                    ↕
┌─────────────────────────────────────────┐
│         Business Logic Layer            │
│      (Services, Utilities, Helpers)     │
└─────────────────────────────────────────┘
                    ↕
┌─────────────────────────────────────────┐
│          Data Access Layer              │
│    (Models, Database Helper, Repos)     │
└─────────────────────────────────────────┘
                    ↕
┌─────────────────────────────────────────┐
│          Storage Layer                  │
│  (SQLite Database, Local Preferences)   │
└─────────────────────────────────────────┘
```

## System Components

### 1. Presentation Layer

#### Screens (`lib/screens/`)
The application consists of multiple CRUD screens organized by entity:

**Master Data Management:**
- `manufacturers_screen.dart` / `manufacturer_detail_screen.dart`
- `vendors_screen.dart` / `vendor_detail_screen.dart`
- `materials_screen.dart` / `material_detail_screen.dart`
- `manufacturer_materials_screen.dart` / `manufacturer_material_detail_screen.dart`
- `vendor_price_lists_screen.dart` / `vendor_price_list_detail_screen.dart`
- `projects_screen.dart` / `project_detail_screen.dart`
- `currencies_screen.dart` / `currency_detail_screen.dart`
- `units_screen.dart` / `unit_of_measure_detail_screen.dart`

**Transaction Management:**
- `purchase_orders_screen.dart` / `purchase_order_detail_screen.dart`
- `purchase_order_item_detail_screen.dart`
- `baskets_screen.dart` / `basket_detail_screen.dart`
- `basket_item_detail_screen.dart`
- `basket_quotations_screen.dart`
- `quotations_screen.dart` / `quotation_detail_screen.dart`
- `quotation_item_detail_screen.dart`

**Application Screens:**
- `home_screen.dart` - Main navigation hub
- `login_screen.dart` - Google Sheets sync authentication
- `settings_screen.dart` - Application settings
- `import_data_screen.dart` - CSV data import
- `database_browser_screen.dart` - SQLite database viewer
- `sync_debug_screen.dart` - Synchronization debugging

#### Widgets (`lib/widgets/`)
- `common_overflow_menu.dart` - Reusable overflow menu component

#### Preview Gallery (`lib/previews/`)
- Widget preview components for development

### 2. Business Logic Layer

#### Services (`lib/services/`)

**DatabaseHelper (`database_helper.dart`)**
- Singleton pattern for database access
- Database schema initialization and migrations
- CRUD operations for all entities
- Change log tracking for synchronization
- Condensed change log management
- Statistics and reporting queries
- Data import/export operations

**DeltaSyncService (`delta_sync_service.dart`)**
- Bidirectional synchronization with Google Sheets backend
- Delta sync using change logs (only changed data)
- Conflict resolution strategies
- Progress tracking and callbacks
- Error handling and retry logic
- Sync state management (pause/resume)
- Debug logging for troubleshooting

**AuthService (`auth_service.dart`)**
- Simple authentication service
- Credential validation for Google Sheets sync
- Session management

**CSVImportService (`csv_import_service.dart`)**
- CSV file parsing and import
- Data validation
- Bulk insert operations

#### Utilities (`lib/utils/`)
- `app_helper.dart` - General application utilities
- `database_browser_helper.dart` - Database inspection utilities
- `sync_helper.dart` - Synchronization helper functions

#### Configuration (`lib/config/`)
- `sync_config.dart` - Synchronization configuration settings

### 3. Data Access Layer

#### Models (`lib/models/`)
Domain models representing business entities:

**Master Data:**
- `manufacturer.dart` - Manufacturer information
- `vendor.dart` - Vendor/supplier information
- `material.dart` - Material/product catalog
- `manufacturer_material.dart` - Manufacturer-specific materials
- `vendor_price_list.dart` - Vendor pricing information
- `project.dart` - Project tracking
- `currency.dart` - Currency definitions
- `unit_of_measure.dart` - Unit of measure definitions

**Transactional Data:**
- `purchase_order.dart` - Purchase order headers
- `purchase_order_item.dart` - Purchase order line items
- `purchase_order_payment.dart` - Payment records
- `basket_header.dart` - Shopping basket headers
- `basket_item.dart` - Shopping basket items
- `quotation.dart` - Quotation headers
- `quotation_item.dart` - Quotation line items

Each model includes:
- Properties mapping to database columns
- `toMap()` method for database serialization
- `fromMap()` factory constructor for deserialization
- `copyWith()` method for immutable updates

### 4. Storage Layer

#### SQLite Database Schema

**Master Data Tables:**
- `manufacturers` - Manufacturer records
- `vendors` - Vendor/supplier records
- `materials` - Material catalog
- `manufacturer_materials` - Manufacturer-material relationships
- `vendor_price_lists` - Vendor pricing
- `projects` - Project definitions
- `currencies` - Currency master data
- `unit_of_measures` - Unit of measure definitions

**Transaction Tables:**
- `purchase_orders` - Purchase order headers
- `purchase_order_items` - Purchase order line items
- `purchase_order_payments` - Payment records
- `basket_headers` - Shopping basket headers
- `basket_items` - Shopping basket items
- `quotations` - Quotation headers
- `quotation_items` - Quotation line items

**System Tables:**
- `local_settings` - Application settings (key-value pairs)
- `change_log` - Detailed change tracking for sync
- `condensed_change_log` - Optimized change log for sync efficiency

#### Database Features
- **UUID-based primary keys**: Ensuring global uniqueness for offline sync
- **Auto-incrementing IDs**: For user-friendly display
- **Soft deletes**: Tracking deleted records for synchronization
- **Timestamps**: Created and updated timestamps for audit trail
- **Foreign key relationships**: Maintaining data integrity
- **Indexing**: Optimized queries on frequently accessed columns

## Data Synchronization Architecture

### Sync Flow

```
┌─────────────────┐         ┌──────────────────┐         ┌─────────────────┐
│  Mobile App     │◄───────►│  Google Apps     │◄───────►│  Google Sheets  │
│  (SQLite)       │   HTTP  │  Script (API)    │         │  (Data Store)   │
└─────────────────┘         └──────────────────┘         └─────────────────┘
        │
        ├── Local Change Log
        ├── Condensed Change Log
        └── Last Sync Timestamp
```

### Delta Sync Process

1. **Local Changes Detection**
   - Track all INSERT/UPDATE/DELETE operations in `change_log` table
   - Condense multiple changes to same record into single entry
   - Store in `condensed_change_log` for efficient sync

2. **Upload Phase**
   - Send condensed change log to Google Sheets backend
   - Backend processes changes and updates sheets
   - Return success/failure status

3. **Download Phase**
   - Request changes from Google Sheets since last sync timestamp
   - Backend returns all changes after timestamp
   - Apply changes to local SQLite database
   - Handle conflicts (server wins strategy)

4. **Conflict Resolution**
   - Server-side changes take precedence over local changes
   - Merge changes where possible
   - Log conflicts for user review

5. **Sync Completion**
   - Update last sync timestamp
   - Clear condensed change log
   - Notify user of sync status

### Security
- **Secret Code Authentication**: App code required for API access
- **HTTPS Communication**: Encrypted data transmission
- **No personal data in URLs**: All data sent in request body

## Application Flow

### Startup Sequence

1. **App Initialization** (`main.dart`)
   - Initialize Flutter binding
   - Initialize SQLite database
   - Launch `PurchaseApp` widget

2. **Splash Screen**
   - Display app icon and loading indicator
   - Check for saved credentials (optional)
   - Navigate to Home Screen

3. **Home Screen**
   - Display main navigation menu
   - Access to all functional modules
   - Sync status indicator
   - Access to settings and utilities

### Navigation Structure

```
Home Screen
├── Master Data
│   ├── Manufacturers
│   ├── Vendors
│   ├── Materials
│   ├── Manufacturer Materials
│   ├── Vendor Price Lists
│   ├── Projects
│   ├── Currencies
│   └── Units of Measure
├── Transactions
│   ├── Purchase Orders
│   ├── Baskets
│   └── Quotations
├── Utilities
│   ├── Import Data (CSV)
│   ├── Database Browser
│   ├── Sync with Google Sheets
│   └── Sync Debug
└── Settings
    ├── Login/Logout
    ├── Clear All Data
    └── App Information
```

### User Workflows

**1. Purchase Order Creation**
```
Baskets → Add Items → Create Quotations → Convert to Purchase Order → Add Payments
```

**2. Data Import**
```
Import Screen → Select CSV → Map Columns → Validate → Import → Confirm
```

**3. Cloud Synchronization**
```
Login (if needed) → Sync → Upload Changes → Download Updates → Complete
```

## Key Design Patterns

### 1. Singleton Pattern
- `DatabaseHelper` - Single database instance
- `DeltaSyncService` - Single sync service instance
- `AuthService` - Single authentication instance

### 2. Factory Pattern
- Model `fromMap()` constructors for object creation from database records

### 3. Observer Pattern
- Route observer for navigation tracking
- Progress callbacks for sync operations

### 4. Repository Pattern (Implicit)
- DatabaseHelper acts as repository for all entities
- Centralized data access logic

## Offline-First Strategy

The application is designed to work **fully offline** with optional cloud sync:

1. **Local Storage Priority**
   - All data stored locally in SQLite
   - No internet required for core functionality
   - Immediate response times

2. **Background Synchronization**
   - Sync triggered manually by user
   - Can pause/resume sync operations
   - Works in background with progress updates

3. **Conflict Handling**
   - Server data takes precedence
   - Local changes tracked and merged where possible
   - User notified of conflicts

4. **Data Integrity**
   - Foreign key constraints in SQLite
   - UUID-based identifiers prevent conflicts
   - Transaction support for atomic operations

## Scalability Considerations

### Current Limitations
- SQLite suitable for small to medium datasets (< 100K records)
- Single-user application design
- No real-time collaboration features

### Future Enhancements
- Multi-user support with user-based filtering
- Real-time sync with WebSocket connections
- Cloud-native database backend (Firebase, Supabase)
- Advanced conflict resolution UI
- Attachment support (images, documents)
- Offline queue for sync operations
- Incremental sync optimization

## Security Architecture

### Current Implementation
- Secret code authentication for Google Sheets sync
- HTTPS for API communication
- Local data unencrypted (SQLite default)

### Recommended Enhancements
- SQLite database encryption (SQLCipher)
- Secure storage for credentials
- OAuth 2.0 for Google Sheets access
- Role-based access control
- Audit logging
- Data backup and recovery

## Testing Strategy

### Current State
- Manual testing for UI and functionality
- No automated test suite

### Recommended Testing
- **Unit Tests**: Model serialization, business logic
- **Widget Tests**: UI component testing
- **Integration Tests**: Database operations, sync logic
- **E2E Tests**: Complete user workflows
- **Performance Tests**: Large dataset handling

## Build and Deployment

### Android
```bash
flutter build apk --release           # APK for direct distribution
flutter build appbundle --release     # App Bundle for Play Store
```

### iOS
```bash
flutter build ios --release
```

### Supported Platforms
- Android (API level 21+)
- iOS (iOS 12+)
- Potential for Web, Windows, macOS, Linux (Flutter cross-platform)

## Monitoring and Debugging

### Built-in Tools
1. **Database Browser Screen**
   - View all tables and data
   - Inspect schema and record counts
   - Manual data verification

2. **Sync Debug Screen**
   - View sync logs
   - Monitor change log entries
   - Troubleshoot sync issues

3. **Logger Integration**
   - Structured logging with timestamps
   - Different log levels (info, warning, error)
   - Console output for development

### Debugging Features
- Debug logs collection
- Sync operation tracking
- Change log inspection
- Network request/response logging

## Data Model Relationships

```
Manufacturer ──┬─→ Manufacturer Material ──→ Material
               │
Vendor ────────┼─→ Vendor Price List ──────→ Material
               │
               ├─→ Purchase Order ──┬─→ Purchase Order Item ──→ Material
               │                    └─→ Purchase Order Payment
               │
Project ───────┤
               │
Basket Header ─┼─→ Basket Item ──────────→ Material
               │
Quotation ─────┴─→ Quotation Item ────────→ Material

Currency ──────────→ (Used by various transactions)
Unit of Measure ───→ (Used by materials and line items)
```

## File Structure

```
purchase/
├── lib/
│   ├── main.dart                 # Application entry point
│   ├── preview_gallery.dart      # Widget preview gallery
│   ├── config/                   # Configuration files
│   ├── models/                   # Data models
│   ├── screens/                  # UI screens
│   ├── services/                 # Business logic services
│   ├── utils/                    # Utility functions
│   ├── widgets/                  # Reusable widgets
│   └── previews/                 # Widget previews
├── android/                      # Android native code
├── ios/                          # iOS native code
├── backend/                      # Google Apps Script backend
├── sample-data/                         # Sample CSV data
├── docu/                         # Documentation and screenshots
├── assets/                       # Application assets
├── test/                         # Test files
└── pubspec.yaml                  # Dependencies and configuration
```

## Version Control and Deployment

### Git Workflow
- Main branch for stable releases
- Feature branches for development
- AI-assisted development with prompt history in `ai/` folder

### Release Process
1. Update version in `pubspec.yaml`
2. Build release artifacts
3. Test on target devices
4. Deploy APK or upload to stores
5. Update documentation

## Conclusion

The Purchase Application demonstrates a well-structured Flutter application with offline-first architecture, cloud synchronization capabilities, and comprehensive master data and transaction management. The layered architecture ensures maintainability and scalability, while the use of established design patterns promotes code quality and consistency.

The application is suitable for small to medium-sized purchasing operations requiring mobile access, offline capabilities, and optional cloud backup through Google Sheets integration.

---

**Last Updated**: January 7, 2026  
**Version**: 1.0.0  
**Maintainer**: Development Team
