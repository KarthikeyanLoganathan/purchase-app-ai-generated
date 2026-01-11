import 'currency.dart';
import 'unit_of_measure.dart';
import 'manufacturer.dart';
import 'vendor.dart';
import 'material.dart';
import 'manufacturer_material.dart';
import 'vendor_price_list.dart';
import 'project.dart';
import 'basket.dart';
import 'basket_item.dart';
import 'quotation.dart';
import 'quotation_item.dart';
import 'purchase_order.dart';
import 'purchase_order_item.dart';
import 'purchase_order_payment.dart';
import 'change_log.dart';
import 'condensed_change_log.dart';
import '../base/data_definition.dart';

/// Factory class for creating model instances from maps and converting them back
/// Provides centralized model instantiation logic for all database models
class ModelsFactory {
  /// Map of table names to their model factory constructors
  /// This allows us to use the model's fromMap method which knows the correct types
  static final Map<String, Function(Map<String, dynamic>)> _modelFactories = {
    TableNames.currencies: Currency.fromMap,
    TableNames.unitOfMeasures: UnitOfMeasure.fromMap,
    TableNames.manufacturers: Manufacturer.fromMap,
    TableNames.vendors: Vendor.fromMap,
    TableNames.materials: Material.fromMap,
    TableNames.manufacturerMaterials: ManufacturerMaterial.fromMap,
    TableNames.vendorPriceLists: VendorPriceList.fromMap,
    TableNames.projects: Project.fromMap,
    TableNames.baskets: Basket.fromMap,
    TableNames.basketItems: BasketItem.fromMap,
    TableNames.quotations: Quotation.fromMap,
    TableNames.quotationItems: QuotationItem.fromMap,
    TableNames.purchaseOrders: PurchaseOrder.fromMap,
    TableNames.purchaseOrderItems: PurchaseOrderItem.fromMap,
    TableNames.purchaseOrderPayments: PurchaseOrderPayment.fromMap,
    TableNames.changeLog: ChangeLog.fromMap,
    TableNames.condensedChangeLog: CondensedChangeLog.fromMap,
  };

  /// Create a model instance from a map for the given table
  /// Returns null if no factory is registered for the table
  static dynamic fromMap(String tableName, Map<String, dynamic> map) {
    final factory = _modelFactories[tableName];
    if (factory == null) {
      throw Exception('No model factory registered for table: $tableName');
    }
    return factory(map);
  }

  /// Convert a model instance back to a map for database storage
  /// Uses the model's toMap method
  static Map<String, dynamic> _toMap(dynamic modelInstance, String tableName) {
    // All our models have a toMap method
    if (modelInstance is Currency) return modelInstance.toMap();
    if (modelInstance is UnitOfMeasure) return modelInstance.toMap();
    if (modelInstance is Manufacturer) return modelInstance.toMap();
    if (modelInstance is Vendor) return modelInstance.toMap();
    if (modelInstance is Material) return modelInstance.toMap();
    if (modelInstance is ManufacturerMaterial) return modelInstance.toMap();
    if (modelInstance is VendorPriceList) return modelInstance.toMap();
    if (modelInstance is Project) return modelInstance.toMap();
    if (modelInstance is Basket) return modelInstance.toMap();
    if (modelInstance is BasketItem) return modelInstance.toMap();
    if (modelInstance is Quotation) return modelInstance.toMap();
    if (modelInstance is QuotationItem) return modelInstance.toMap();
    if (modelInstance is PurchaseOrder) return modelInstance.toMap();
    if (modelInstance is PurchaseOrderItem) return modelInstance.toMap();
    if (modelInstance is PurchaseOrderPayment) return modelInstance.toMap();
    if (modelInstance is ChangeLog) return modelInstance.toMap();
    if (modelInstance is CondensedChangeLog) return modelInstance.toMap();

    throw Exception('Unknown model type for table: $tableName');
  }

  static dynamic toMap(dynamic modelInstance, String tableName) {
    return _toMap(modelInstance, tableName);
  }

  static const Map<String, Type? Function(String)> _getFieldType = {
    TableNames.currencies: Currency.getFieldType,
    TableNames.unitOfMeasures: UnitOfMeasure.getFieldType,
    TableNames.manufacturers: Manufacturer.getFieldType,
    TableNames.vendors: Vendor.getFieldType,
    TableNames.materials: Material.getFieldType,
    TableNames.manufacturerMaterials: ManufacturerMaterial.getFieldType,
    TableNames.vendorPriceLists: VendorPriceList.getFieldType,
    TableNames.projects: Project.getFieldType,
    TableNames.baskets: Basket.getFieldType,
    TableNames.basketItems: BasketItem.getFieldType,
    TableNames.quotations: Quotation.getFieldType,
    TableNames.quotationItems: QuotationItem.getFieldType,
    TableNames.purchaseOrders: PurchaseOrder.getFieldType,
    TableNames.purchaseOrderItems: PurchaseOrderItem.getFieldType,
    TableNames.purchaseOrderPayments: PurchaseOrderPayment.getFieldType,
    TableNames.changeLog: ChangeLog.getFieldType,
    TableNames.condensedChangeLog: CondensedChangeLog.getFieldType,
  };

  static dynamic getFieldType(String tableName, String fieldName) {
    return _getFieldType[tableName]?.call(fieldName);
  }

  static const Map<String, String? Function(String)> _getDatabaseFieldName = {
    TableNames.currencies: Currency.getDatabaseFieldName,
    TableNames.unitOfMeasures: UnitOfMeasure.getDatabaseFieldName,
    TableNames.manufacturers: Manufacturer.getDatabaseFieldName,
    TableNames.vendors: Vendor.getDatabaseFieldName,
    TableNames.materials: Material.getDatabaseFieldName,
    TableNames.manufacturerMaterials: ManufacturerMaterial.getDatabaseFieldName,
    TableNames.vendorPriceLists: VendorPriceList.getDatabaseFieldName,
    TableNames.projects: Project.getDatabaseFieldName,
    TableNames.baskets: Basket.getDatabaseFieldName,
    TableNames.basketItems: BasketItem.getDatabaseFieldName,
    TableNames.quotations: Quotation.getDatabaseFieldName,
    TableNames.quotationItems: QuotationItem.getDatabaseFieldName,
    TableNames.purchaseOrders: PurchaseOrder.getDatabaseFieldName,
    TableNames.purchaseOrderItems: PurchaseOrderItem.getDatabaseFieldName,
    TableNames.purchaseOrderPayments: PurchaseOrderPayment.getDatabaseFieldName,
    TableNames.changeLog: ChangeLog.getDatabaseFieldName,
    TableNames.condensedChangeLog: CondensedChangeLog.getDatabaseFieldName,
  };

  static dynamic getDatabaseFieldNameByEntityField(
      String tableName, String entityField) {
    return _getDatabaseFieldName[tableName]?.call(entityField);
  }

  static const Map<String, String? Function(String)> _getEntityFieldName = {
    TableNames.currencies: Currency.getEntityFieldName,
    TableNames.unitOfMeasures: UnitOfMeasure.getEntityFieldName,
    TableNames.manufacturers: Manufacturer.getEntityFieldName,
    TableNames.vendors: Vendor.getEntityFieldName,
    TableNames.materials: Material.getEntityFieldName,
    TableNames.manufacturerMaterials: ManufacturerMaterial.getEntityFieldName,
    TableNames.vendorPriceLists: VendorPriceList.getEntityFieldName,
    TableNames.projects: Project.getEntityFieldName,
    TableNames.baskets: Basket.getEntityFieldName,
    TableNames.basketItems: BasketItem.getEntityFieldName,
    TableNames.quotations: Quotation.getEntityFieldName,
    TableNames.quotationItems: QuotationItem.getEntityFieldName,
    TableNames.purchaseOrders: PurchaseOrder.getEntityFieldName,
    TableNames.purchaseOrderItems: PurchaseOrderItem.getEntityFieldName,
    TableNames.purchaseOrderPayments: PurchaseOrderPayment.getEntityFieldName,
    TableNames.changeLog: ChangeLog.getEntityFieldName,
    TableNames.condensedChangeLog: CondensedChangeLog.getEntityFieldName,
  };

  static dynamic getEntityFieldNameByDatabaseField(
      String tableName, String dataBaseFieldName) {
    return _getEntityFieldName[tableName]?.call(dataBaseFieldName);
  }

  /// Check if a factory exists for the given table
  static bool hasFactory(String tableName) {
    return _modelFactories.containsKey(tableName);
  }

  /// Get all registered table names
  static List<String> get registeredTables => _modelFactories.keys.toList();
}
