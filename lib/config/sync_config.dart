import '../services/database_helper.dart';

/// Sync configuration for delta sync mechanism
class SyncConfig {
  /// Table indices for change log tracking
  static const Map<String, int> tableIndices = {
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

  static const Map<int, String> tableNamesByIndices = {
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

  /// Change modes
  static const String changeModeInsert = 'I';
  static const String changeModeUpdate = 'U';
  static const String changeModeDelete = 'D';

  /// Get table index by name
  static int? getTableIndex(String tableName) {
    return tableIndices[tableName];
  }

  /// Get table name by index
  static String? getTableName(int tableIndex) {
    return tableNamesByIndices[tableIndex];
  }

  /// Get all sync table names in order
  static List<String> getSyncTables() {
    final entries = tableIndices.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return entries.map((e) => e.key).toList();
  }
}
