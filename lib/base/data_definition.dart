// Table name constants
import 'package:purchase_app/base/model_definition.dart';
import 'package:purchase_app/models/manufacturer.dart';
import 'package:purchase_app/models/vendor.dart';
import 'package:purchase_app/models/material.dart';
import 'package:purchase_app/models/manufacturer_material.dart';
import 'package:purchase_app/models/vendor_price_list.dart';
import 'package:purchase_app/models/purchase_order.dart';
import 'package:purchase_app/models/purchase_order_item.dart';
import 'package:purchase_app/models/purchase_order_payment.dart';
import 'package:purchase_app/models/basket.dart';
import 'package:purchase_app/models/basket_item.dart';
import 'package:purchase_app/models/quotation.dart';
import 'package:purchase_app/models/quotation_item.dart';
import 'package:purchase_app/models/project.dart';
import 'package:purchase_app/models/unit_of_measure.dart';
import 'package:purchase_app/models/currency.dart';
import 'package:purchase_app/models/change_log.dart';
import 'package:purchase_app/models/condensed_change_log.dart';
import 'package:purchase_app/models/local_setting.dart';
import 'package:purchase_app/models/defaults.dart';

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
  static const defaults = 'defaults';
  static const localSettings = 'local_settings';
  static const changeLog = 'change_log';
  static const condensedChangeLog = 'condensed_change_log';
}

abstract class DataDefinition {
  static final Map<String, ModelDefinition> _tableModels = {
    TableNames.manufacturers: Manufacturer.modelDefinition,
    TableNames.vendors: Vendor.modelDefinition,
    TableNames.materials: Material.modelDefinition,
    TableNames.manufacturerMaterials: ManufacturerMaterial.modelDefinition,
    TableNames.vendorPriceLists: VendorPriceList.modelDefinition,
    TableNames.purchaseOrders: PurchaseOrder.modelDefinition,
    TableNames.purchaseOrderItems: PurchaseOrderItem.modelDefinition,
    TableNames.purchaseOrderPayments: PurchaseOrderPayment.modelDefinition,
    TableNames.baskets: Basket.modelDefinition,
    TableNames.basketItems: BasketItem.modelDefinition,
    TableNames.quotations: Quotation.modelDefinition,
    TableNames.quotationItems: QuotationItem.modelDefinition,
    TableNames.projects: Project.modelDefinition,
    TableNames.unitOfMeasures: UnitOfMeasure.modelDefinition,
    TableNames.currencies: Currency.modelDefinition,
    TableNames.defaults: Defaults.modelDefinition,
    TableNames.changeLog: ChangeLog.modelDefinition,
    TableNames.condensedChangeLog: CondensedChangeLog.modelDefinition,
    TableNames.localSettings: LocalSetting.modelDefinition,
  };
  static final Map<int, ModelDefinition> _tableModelsByIndices = {
    Manufacturer.modelDefinition.tableIndex: Manufacturer.modelDefinition,
    Vendor.modelDefinition.tableIndex: Vendor.modelDefinition,
    Material.modelDefinition.tableIndex: Material.modelDefinition,
    ManufacturerMaterial.modelDefinition.tableIndex:
        ManufacturerMaterial.modelDefinition,
    VendorPriceList.modelDefinition.tableIndex: VendorPriceList.modelDefinition,
    PurchaseOrder.modelDefinition.tableIndex: PurchaseOrder.modelDefinition,
    PurchaseOrderItem.modelDefinition.tableIndex:
        PurchaseOrderItem.modelDefinition,
    PurchaseOrderPayment.modelDefinition.tableIndex:
        PurchaseOrderPayment.modelDefinition,
    Basket.modelDefinition.tableIndex: Basket.modelDefinition,
    BasketItem.modelDefinition.tableIndex: BasketItem.modelDefinition,
    Quotation.modelDefinition.tableIndex: Quotation.modelDefinition,
    QuotationItem.modelDefinition.tableIndex: QuotationItem.modelDefinition,
    Project.modelDefinition.tableIndex: Project.modelDefinition,
    UnitOfMeasure.modelDefinition.tableIndex: UnitOfMeasure.modelDefinition,
    Currency.modelDefinition.tableIndex: Currency.modelDefinition,
    Defaults.modelDefinition.tableIndex: Defaults.modelDefinition,
    ChangeLog.modelDefinition.tableIndex: ChangeLog.modelDefinition,
    CondensedChangeLog.modelDefinition.tableIndex:
        CondensedChangeLog.modelDefinition,
    LocalSetting.modelDefinition.tableIndex: LocalSetting.modelDefinition,
  };

  static final List<String> tableNames =
      List<String>.unmodifiable(_tableModels.keys.toList());

  static List<String> getTablesByTypes(List<String>? types) {
    return _tableModels.entries
        .where((entry) => types?.contains(entry.value.type) ?? true)
        .map((entry) => entry.key)
        .toList();
  }

  static ModelDefinition? getModelDefinition(String tableName) {
    return _tableModels[tableName];
  }

  /// Get table name by index
  static String? getTableNameByIndex(int tableIndex) {
    return _tableModelsByIndices[tableIndex]?.databaseTableName;
  }
}
