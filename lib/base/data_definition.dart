// Table name constants
abstract class TableNames {
  static const manufacturers = 'manufacturers';
  static const vendors = 'vendors';
  static const materials = 'materials';
  static const manufacturerMaterials = 'manufacturer_materials';
  static const vendorPriceLists = 'vendor_price_lists';
  static const purchaseOrders = 'purchase_orders';
  static const purchaseOrderItems = 'purchase_order_items';
  static const purchaseOrderPayments = 'purchase_order_payments';
  static const baskets = 'baskets';
  static const basketItems = 'basket_items';
  static const quotations = 'quotations';
  static const quotationItems = 'quotation_items';
  static const projects = 'projects';
  static const unitOfMeasures = 'unit_of_measures';
  static const currencies = 'currencies';
  static const localSettings = 'local_settings';
  static const changeLog = 'change_log';
  static const condensedChangeLog = 'condensed_change_log';
}

abstract class DataDefinition {
  static const Map<String, String> _tableKeyColumns = {
    TableNames.manufacturers: 'uuid',
    TableNames.vendors: 'uuid',
    TableNames.materials: 'uuid',
    TableNames.manufacturerMaterials: 'uuid',
    TableNames.vendorPriceLists: 'uuid',
    TableNames.purchaseOrders: 'uuid',
    TableNames.purchaseOrderItems: 'uuid',
    TableNames.purchaseOrderPayments: 'uuid',
    TableNames.baskets: 'uuid',
    TableNames.basketItems: 'uuid',
    TableNames.quotations: 'uuid',
    TableNames.quotationItems: 'uuid',
    TableNames.projects: 'uuid',
    TableNames.unitOfMeasures: 'name',
    TableNames.currencies: 'name',
    TableNames.changeLog: 'uuid',
    TableNames.condensedChangeLog: 'uuid',
  };

  /// Table indices for change log tracking
  static const Map<String, int> _tableIndices = {
    TableNames.unitOfMeasures: 101,
    TableNames.currencies: 102,
    TableNames.manufacturers: 201,
    TableNames.vendors: 202,
    TableNames.materials: 203,
    TableNames.manufacturerMaterials: 204,
    TableNames.vendorPriceLists: 205,
    TableNames.projects: 251,
    TableNames.purchaseOrders: 301,
    TableNames.purchaseOrderItems: 302,
    TableNames.purchaseOrderPayments: 303,
    TableNames.baskets: 311,
    TableNames.basketItems: 312,
    TableNames.quotations: 321,
    TableNames.quotationItems: 322,
  };

  static const Map<int, String> _tableNamesByIndices = {
    101: TableNames.unitOfMeasures,
    102: TableNames.currencies,
    201: TableNames.manufacturers,
    202: TableNames.vendors,
    203: TableNames.materials,
    204: TableNames.manufacturerMaterials,
    205: TableNames.vendorPriceLists,
    251: TableNames.projects,
    301: TableNames.purchaseOrders,
    302: TableNames.purchaseOrderItems,
    303: TableNames.purchaseOrderPayments,
    311: TableNames.baskets,
    312: TableNames.basketItems,
    321: TableNames.quotations,
    322: TableNames.quotationItems,
  };
  // User-friendly table names for UI display
  static const Map<String, String> _tableDisplayNames = {
    TableNames.manufacturers: 'Manufacturers',
    TableNames.vendors: 'Vendors',
    TableNames.materials: 'Materials',
    TableNames.manufacturerMaterials: 'Manufacturer Materials',
    TableNames.vendorPriceLists: 'Vendor Price Lists',
    TableNames.purchaseOrders: 'Purchase Orders',
    TableNames.purchaseOrderItems: 'Purchase Order Items',
    TableNames.purchaseOrderPayments: 'Purchase Order Payments',
    TableNames.baskets: 'Baskets',
    TableNames.basketItems: 'Basket Items',
    TableNames.quotations: 'Basket Vendor Quotations',
    TableNames.projects: 'Projects',
    TableNames.unitOfMeasures: 'Units of Measure',
    TableNames.currencies: 'Currencies',
    TableNames.changeLog: 'Change Log',
  };

  static String getKeyColumn(String tableName) {
    return _tableKeyColumns[tableName] ?? 'uuid';
  }

  static String getTableDisplayName(String tableName) {
    return _tableDisplayNames[tableName] ?? tableName;
  }

  static const allApplicationTables = [
    TableNames.unitOfMeasures,
    TableNames.currencies,
    TableNames.manufacturers,
    TableNames.vendors,
    TableNames.materials,
    TableNames.manufacturerMaterials,
    TableNames.vendorPriceLists,
    TableNames.projects,
    TableNames.baskets,
    TableNames.basketItems,
    TableNames.quotations,
    TableNames.quotationItems,
    TableNames.purchaseOrders,
    TableNames.purchaseOrderItems,
    TableNames.purchaseOrderPayments,
  ];

  static const allLogTables = [
    TableNames.changeLog,
    TableNames.condensedChangeLog,
  ];

  // List of all data tables (for clearAllData)
  static const allDataTables = [
    ...allApplicationTables,
    ...allLogTables,
  ];

  // List of all tables (for getTableCounts)
  static const allTables = [
    ...allApplicationTables,
    ...allLogTables,
    TableNames.localSettings,
  ];

  /// Get table index by name
  static int? getTableIndex(String tableName) {
    return _tableIndices[tableName];
  }

  /// Get table name by index
  static String? getTableNameByIndex(int tableIndex) {
    return _tableNamesByIndices[tableIndex];
  }

  /// Get all sync table names in order
  static List<String> getSyncTables() {
    final entries = _tableIndices.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return entries.map((e) => e.key).toList();
  }
}
