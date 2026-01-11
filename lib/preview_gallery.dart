import 'package:flutter/material.dart';
import 'screens/basket_detail_screen.dart';
import 'screens/basket_item_detail_screen.dart';
import 'screens/basket_quotations_screen.dart';
import 'screens/baskets_screen.dart';
import 'screens/currencies_screen.dart';
import 'screens/currency_detail_screen.dart';
import 'screens/home_screen.dart';
import 'screens/import_sample_data_screen.dart';
import 'screens/login_screen.dart';
import 'screens/manufacturer_detail_screen.dart';
import 'screens/manufacturer_material_detail_screen.dart';
import 'screens/manufacturer_materials_screen.dart';
import 'screens/manufacturers_screen.dart';
import 'screens/material_detail_screen.dart';
import 'screens/materials_screen.dart';
import 'screens/project_detail_screen.dart';
import 'screens/projects_screen.dart';
import 'screens/purchase_order_detail_screen.dart';
import 'screens/purchase_order_item_detail_screen.dart';
import 'screens/purchase_orders_screen.dart';
import 'screens/quotation_detail_screen.dart';
import 'screens/quotation_item_detail_screen.dart';
import 'screens/quotations_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/sync_debug_screen.dart';
import 'screens/unit_of_measure_detail_screen.dart';
import 'screens/units_screen.dart';
import 'screens/vendor_detail_screen.dart';
import 'screens/vendor_price_list_detail_screen.dart';
import 'screens/vendor_price_lists_screen.dart';
import 'screens/vendors_screen.dart';

// Main entry point for preview gallery
void main() {
  runApp(const PreviewGallery());
}

/// Preview Gallery - Browse all screen previews in one place
///
/// To use this gallery:
/// 1. Temporarily change main.dart to run PreviewGallery()
/// 2. Run the app with `flutter run`
/// 3. Browse through all available screen previews
///
/// Example:
/// ```dart
/// void main() {
///   runApp(const PreviewGallery());
/// }
/// ```
class PreviewGallery extends StatelessWidget {
  const PreviewGallery({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Widget Preview Gallery',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const PreviewGalleryHome(),
    );
  }
}

class PreviewGalleryHome extends StatelessWidget {
  const PreviewGalleryHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Widget Preview Gallery'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Main Screens',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildPreviewTile(
            context,
            'Home Screen',
            'Main dashboard and navigation',
            Icons.home,
            const HomeScreenPreview(),
          ),
          _buildPreviewTile(
            context,
            'Login Screen',
            'Authentication and sync setup',
            Icons.login,
            const LoginScreenPreview(),
          ),
          _buildPreviewTile(
            context,
            'Settings Screen',
            'App settings and configuration',
            Icons.settings,
            const SettingsScreenPreview(),
          ),
          const Divider(height: 32),
          const Text(
            'Master Data Lists',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildPreviewTile(
            context,
            'Materials',
            'Browse all materials',
            Icons.inventory_2,
            const MaterialsScreenPreview(),
          ),
          _buildPreviewTile(
            context,
            'Vendors',
            'Browse all vendors',
            Icons.business,
            const VendorsScreenPreview(),
          ),
          _buildPreviewTile(
            context,
            'Manufacturers',
            'Browse all manufacturers',
            Icons.factory,
            const ManufacturersScreenPreview(),
          ),
          _buildPreviewTile(
            context,
            'Projects',
            'Browse all projects',
            Icons.work,
            const ProjectsScreenPreview(),
          ),
          _buildPreviewTile(
            context,
            'Currencies',
            'Browse all currencies',
            Icons.attach_money,
            const CurrenciesScreenPreview(),
          ),
          _buildPreviewTile(
            context,
            'Units of Measure',
            'Browse all units',
            Icons.straighten,
            const UnitsScreenPreview(),
          ),
          const Divider(height: 32),
          const Text(
            'Detail Screens',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildPreviewTile(
            context,
            'Material Detail',
            'Edit material information',
            Icons.edit,
            const MaterialDetailScreenPreview(),
          ),
          _buildPreviewTile(
            context,
            'Vendor Detail',
            'Edit vendor information',
            Icons.edit,
            const VendorDetailScreenPreview(),
          ),
          _buildPreviewTile(
            context,
            'Manufacturer Detail',
            'Edit manufacturer information',
            Icons.edit,
            const ManufacturerDetailScreenPreview(),
          ),
          _buildPreviewTile(
            context,
            'Project Detail',
            'Edit project information',
            Icons.edit,
            const ProjectDetailScreenPreview(),
          ),
          _buildPreviewTile(
            context,
            'Currency Detail',
            'Edit currency information',
            Icons.edit,
            const CurrencyDetailScreenPreview(),
          ),
          _buildPreviewTile(
            context,
            'Unit of Measure Detail',
            'Edit unit information',
            Icons.edit,
            const UnitOfMeasureDetailScreenPreview(),
          ),
          const Divider(height: 32),
          const Text(
            'Price Lists & Materials',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildPreviewTile(
            context,
            'Manufacturer Materials',
            'Browse manufacturer materials',
            Icons.list,
            const ManufacturerMaterialsScreenPreview(),
          ),
          _buildPreviewTile(
            context,
            'Manufacturer Material Detail',
            'Edit manufacturer material',
            Icons.edit,
            const ManufacturerMaterialDetailScreenPreview(),
          ),
          _buildPreviewTile(
            context,
            'Vendor Price Lists',
            'Browse vendor price lists',
            Icons.price_check,
            const VendorPriceListsScreenPreview(),
          ),
          _buildPreviewTile(
            context,
            'Vendor Price List Detail',
            'Edit price list',
            Icons.edit,
            const VendorPriceListDetailScreenPreview(),
          ),
          const Divider(height: 32),
          const Text(
            'Purchase Orders',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildPreviewTile(
            context,
            'Purchase Orders',
            'Browse all purchase orders',
            Icons.shopping_cart,
            const PurchaseOrdersScreenPreview(),
          ),
          _buildPreviewTile(
            context,
            'Purchase Order Detail',
            'Edit purchase order',
            Icons.edit,
            const PurchaseOrderDetailScreenPreview(),
          ),
          _buildPreviewTile(
            context,
            'Purchase Order Item Detail',
            'Edit PO item',
            Icons.edit,
            const PurchaseOrderItemDetailScreenPreview(),
          ),
          const Divider(height: 32),
          const Text(
            'Baskets & Quotations',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildPreviewTile(
            context,
            'Baskets',
            'Browse all baskets',
            Icons.shopping_basket,
            const BasketsScreenPreview(),
          ),
          _buildPreviewTile(
            context,
            'Basket Detail',
            'Edit basket',
            Icons.edit,
            const BasketDetailScreenPreview(),
          ),
          _buildPreviewTile(
            context,
            'Basket Item Detail',
            'Edit basket item',
            Icons.edit,
            const BasketItemDetailScreenPreview(),
          ),
          _buildPreviewTile(
            context,
            'Basket Quotations',
            'View basket quotations',
            Icons.request_quote,
            const BasketQuotationsScreenPreview(),
          ),
          _buildPreviewTile(
            context,
            'Quotations',
            'Browse all quotations',
            Icons.request_quote,
            const QuotationsScreenPreview(),
          ),
          _buildPreviewTile(
            context,
            'Quotation Detail',
            'Edit quotation',
            Icons.edit,
            const QuotationDetailScreenPreview(),
          ),
          _buildPreviewTile(
            context,
            'Quotation Item Detail',
            'Edit quotation item',
            Icons.edit,
            const QuotationItemDetailScreenPreview(),
          ),
          const Divider(height: 32),
          const Text(
            'Utility Screens',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildPreviewTile(
            context,
            'Import Data',
            'Import data from CSV files',
            Icons.upload_file,
            const ImportSampleDataScreenPreview(),
          ),
          _buildPreviewTile(
            context,
            'Sync Debug',
            'Debug synchronization',
            Icons.bug_report,
            const SyncDebugScreenPreview(),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Widget previewWidget,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, size: 32, color: Theme.of(context).primaryColor),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => previewWidget,
            ),
          );
        },
      ),
    );
  }
}
