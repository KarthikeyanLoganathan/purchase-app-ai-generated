# Widget Previews in VS Code

All screen widgets now include preview support for easy visualization in Visual Studio Code using the **Preview Gallery**.

## What Was Added

- **Preview Gallery**: Interactive browser for all screens (`lib/preview_gallery.dart`)
- **Preview Classes**: Each screen file includes a standalone preview widget class  
- **VS Code Launch Config**: Easy F5 debugging directly to preview mode
- **Sample Data**: Detail screens pre-populated with mock data for realistic previews

## How to Use Widget Previews

### Method 1: Preview Gallery (Recommended)
The easiest way to preview all screens is using the Preview Gallery:

1. **Press F5 in VS Code** and select "Launch Preview Gallery"
   
   OR run from command line:
   ```bash
   flutter run -t lib/preview_gallery.dart
   ```

2. Browse through all available screen previews organized by category
3. Tap any screen to see its preview
4. Use hot reload (press 'r') to see changes instantly

### Method 2: Individual Preview Classes

Each screen file has its own preview class that you can use:

1. Open any screen file (e.g., `lib/screens/materials_screen.dart`)
2. Scroll to the bottom to find the preview class (e.g., `MaterialsScreenPreview`)
3. You can temporarily change `lib/main.dart` to run a specific preview:

```dart
import 'screens/materials_screen.dart';

void main() {
  runApp(const MaterialsScreenPreview());
}
```

### Method 3: Using Flutter Widget Preview Extension
1. Install the "Flutter Widget Preview" extension in VS Code (if not already installed)
2. Open any screen file (e.g., `materials_screen.dart`)
3. Look for the preview class at the end of the file (e.g., `MaterialsScreenPreview`)
4. The extension should automatically detect and show a preview option

### Method 2: Using Dart DevTools Widget Inspector
1. Run the preview widget directly in a test file or main.dart
2. Use the Flutter DevTools to inspect the widget tree

### Method 3: Quick Preview in main.dart
You can temporarily change your `main.dart` to preview any screen:

```dart
import 'package:flutter/material.dart';
import 'screens/materials_screen.dart'; // or any other screen

void main() {
  runApp(const MaterialsScreenPreview());
}
```

Then run with `flutter run` to see the preview.

## Quick Start Commands

```bash
# Run Widgetbook (Best for VS Code preview detection)
flutter run -t lib/widgetbook.dart

# Run Preview Gallery (Alternative browser)
# First, change main.dart to import and run PreviewGallery(), then:
flutter run

# Run Widgetbook on Web (Opens in browser)
flutter run -d chrome -t lib/widgetbook.dart
```

## VS Code Extension Setup

For best preview detection in VS Code:

1. **Install Widgetbook Extension** (Recommended):
   - Open VS Code Extensions (Cmd+Shift+X)
   - Search for "Widgetbook"
   - Install the official Widgetbook extension
   - Restart VS Code

2. **Install Flutter Widget Preview** (Alternative):
   - Search for "Flutter Widget Preview"
   - Install any compatible preview extension
   - These work better with Widgetbook integration

3. **Use the preview**:
   - Run `flutter run -t lib/widgetbook.dart`
   - Widget previews will be available in VS Code
   - You can browse all widgets interactively

## Preview Gallery

A comprehensive preview gallery is available in `lib/preview_gallery.dart` that provides:

✅ **Organized browsing** - All screens grouped by category
✅ **Quick navigation** - Tap to preview any screen instantly
✅ **Visual overview** - See all available screens at a glance
✅ **Sample data** - All detail screens pre-populated with mock data

### Categories in Preview Gallery:
- **Main Screens** - Home, Login, Settings
- **Master Data Lists** - Materials, Vendors, Manufacturers, Projects, Currencies, Units
- **Detail Screens** - Edit forms for all master data entities
- **Price Lists & Materials** - Manufacturer materials and vendor price lists
- **Purchase Orders** - PO list and detail screens
- **Baskets & Quotations** - Shopping basket and quotation management
- **Utility Screens** - Import data, sync debugging

## Preview Classes Available

All 32 screens now have preview classes:

### List Screens (No Parameters Required)
- `MaterialsScreenPreview`
- `VendorsScreenPreview`
- `ManufacturersScreenPreview`
- `ManufacturerMaterialsScreenPreview`
- `VendorPriceListsScreenPreview`
- `PurchaseOrdersScreenPreview`
- `BasketsScreenPreview`
- `QuotationsScreenPreview`
- `ProjectsScreenPreview`
- `CurrenciesScreenPreview`
- `UnitsScreenPreview`
- `HomeScreenPreview`
- `LoginScreenPreview`
- `SettingsScreenPreview`
- `ImportDataScreenPreview`
- `SyncDebugScreenPreview`
- `DatabaseBrowserScreenPreview`
- `BasketQuotationsScreenPreview`

### Detail Screens (With Sample Data)
- `MaterialDetailScreenPreview` - Shows material detail form with sample data
- `VendorDetailScreenPreview` - Shows vendor detail form with sample data
- `ManufacturerDetailScreenPreview` - Shows manufacturer detail form with sample data
- `ManufacturerMaterialDetailScreenPreview` - Shows manufacturer material detail with sample data
- `VendorPriceListDetailScreenPreview` - Shows price list detail with sample data
- `PurchaseOrderDetailScreenPreview` - Shows purchase order detail with sample data
- `PurchaseOrderItemDetailScreenPreview` - Shows PO item detail with sample data
- `BasketDetailScreenPreview` - Shows basket detail with sample data
- `BasketItemDetailScreenPreview` - Shows basket item detail with sample data
- `QuotationDetailScreenPreview` - Shows quotation detail with sample data
- `QuotationItemDetailScreenPreview` - Shows quotation item detail with sample data
- `ProjectDetailScreenPreview` - Shows project detail with sample data
- `CurrencyDetailScreenPreview` - Shows currency detail with sample data
- `UnitOfMeasureDetailScreenPreview` - Shows unit detail with sample data

## Example: Previewing Material Detail Screen

The preview classes for detail screens include sample data so they can render properly:

```dart
// Widget Preview for VS Code
class MaterialDetailScreenPreview extends StatelessWidget {
  const MaterialDetailScreenPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MaterialDetailScreen(
        material: models.Material(
          uuid: 'preview-uuid',
          name: 'Sample Material',
          description: 'A sample material for preview',
          unitOfMeasure: 'pcs',
          updatedAt: DateTime.now().toUtc(),
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
```

## Benefits

✅ Quick visual feedback without running the full app
✅ Easy UI testing and iteration
✅ Better development workflow
✅ No need to navigate through the app to reach a specific screen
✅ Useful for design reviews and documentation

## Note

Some screens that require database connections (like list screens) may show loading states or empty states in the preview since they don't have access to real data. This is expected behavior and helps visualize the loading/empty states of your screens.
