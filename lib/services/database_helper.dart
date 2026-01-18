import 'package:purchase_app/base/model_definition.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import '../models/local_setting.dart';
import '../models/manufacturer.dart';
import '../models/vendor.dart';
import '../models/material.dart';
import '../models/manufacturer_material.dart';
import '../models/vendor_price_list.dart';
import '../models/purchase_order.dart';
import '../models/purchase_order_item.dart';
import '../models/purchase_order_payment.dart';
import '../models/basket.dart';
import '../models/basket_item.dart';
import '../models/quotation.dart';
import '../models/quotation_item.dart';
import '../models/project.dart';
import '../models/currency.dart';
import '../models/unit_of_measure.dart';
import '../models/defaults.dart';
import '../base/data_definition.dart';
import '../base/change_modes.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static const _uuid = Uuid();

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('purchase_app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Manufacturers table
    await db.execute('''
      CREATE TABLE manufacturers (
        uuid TEXT PRIMARY KEY,
        id INTEGER,
        name TEXT NOT NULL,
        description TEXT,
        address TEXT,
        phone_number TEXT,
        email_address TEXT,
        website TEXT,
        photo_uuid TEXT,
        updated_at TEXT NOT NULL
      )
    ''');

    // Vendors table
    await db.execute('''
      CREATE TABLE vendors (
        uuid TEXT PRIMARY KEY,
        id INTEGER,
        name TEXT NOT NULL,
        description TEXT,
        address TEXT,
        geo_location TEXT,
        phone_number TEXT,
        email_address TEXT,
        website TEXT,
        photo_uuid TEXT,
        updated_at TEXT NOT NULL
      )
    ''');

    // Materials table
    await db.execute('''
      CREATE TABLE materials (
        uuid TEXT PRIMARY KEY,
        id INTEGER,
        name TEXT NOT NULL,
        description TEXT,
        unit_of_measure TEXT NOT NULL,
        website TEXT,
        photo_uuid TEXT,
        updated_at TEXT NOT NULL
      )
    ''');

    // Manufacturer Materials table
    await db.execute('''
      CREATE TABLE manufacturer_materials (
        uuid TEXT PRIMARY KEY,
        manufacturer_uuid TEXT NOT NULL,
        material_uuid TEXT NOT NULL,
        model TEXT NOT NULL,
        selling_lot_size REAL,
        max_retail_price REAL,
        currency TEXT,
        website TEXT,
        part_number TEXT,
        photo_uuid TEXT,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (manufacturer_uuid) REFERENCES manufacturers (uuid),
        FOREIGN KEY (material_uuid) REFERENCES materials (uuid)
      )
    ''');

    // Vendor Price List table
    await db.execute('''
      CREATE TABLE vendor_price_lists (
        uuid TEXT PRIMARY KEY,
        manufacturer_material_uuid TEXT NOT NULL,
        vendor_uuid TEXT NOT NULL,
        rate REAL NOT NULL,
        rate_before_tax REAL DEFAULT 0.0,
        tax_amount REAL NOT NULL,
        tax_percent REAL NOT NULL,
        currency TEXT,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (manufacturer_material_uuid) REFERENCES manufacturer_materials (uuid),
        FOREIGN KEY (vendor_uuid) REFERENCES vendors (uuid)
      )
    ''');

    // Purchase Orders table
    await db.execute('''
      CREATE TABLE purchase_orders (
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
        basket_uuid TEXT,
        quotation_uuid TEXT,
        project_uuid TEXT,
        description TEXT,
        delivery_address TEXT,
        phone_number TEXT,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (vendor_uuid) REFERENCES vendors (uuid),
        FOREIGN KEY (project_uuid) REFERENCES projects (uuid)
      )
    ''');

    // Purchase Order Items table
    await db.execute('''
      CREATE TABLE purchase_order_items (
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
        basket_item_uuid TEXT,
        quotation_item_uuid TEXT,
        unit_of_measure TEXT,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (purchase_order_uuid) REFERENCES purchase_orders (uuid),
        FOREIGN KEY (manufacturer_material_uuid) REFERENCES manufacturer_materials (uuid)
      )
    ''');

    // Purchase Order Payments table
    await db.execute('''
      CREATE TABLE purchase_order_payments (
        uuid TEXT PRIMARY KEY,
        purchase_order_uuid TEXT NOT NULL,
        date TEXT NOT NULL,
        amount REAL NOT NULL,
        currency TEXT DEFAULT 'INR',
        upi_ref_number TEXT,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (purchase_order_uuid) REFERENCES purchase_orders (uuid)
      )
    ''');

    // Basket table
    await db.execute('''
      CREATE TABLE baskets (
        uuid TEXT PRIMARY KEY,
        id INTEGER,
        date TEXT NOT NULL,
        description TEXT,
        expected_delivery_date TEXT,
        total_price REAL DEFAULT 0.0,
        currency TEXT DEFAULT 'INR',
        number_of_items INTEGER DEFAULT 0,
        project_uuid TEXT,
        delivery_address TEXT,
        phone_number TEXT,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (project_uuid) REFERENCES projects (uuid)
      )
    ''');

    // Basket Items table
    await db.execute('''
      CREATE TABLE basket_items (
        uuid TEXT PRIMARY KEY,
        basket_uuid TEXT NOT NULL,
        id INTEGER,
        manufacturer_material_uuid TEXT NOT NULL,
        material_uuid TEXT,
        model TEXT,
        manufacturer_uuid TEXT,
        quantity REAL NOT NULL DEFAULT 1.0,
        unit_of_measure TEXT,
        max_retail_price REAL,
        price REAL DEFAULT 0.0,
        currency TEXT DEFAULT 'INR',
        updated_at TEXT NOT NULL,
        FOREIGN KEY (basket_uuid) REFERENCES baskets (uuid),
        FOREIGN KEY (manufacturer_material_uuid) REFERENCES manufacturer_materials (uuid)
      )
    ''');

    // Basket Vendors table
    await db.execute('''
      CREATE TABLE quotations (
        uuid TEXT PRIMARY KEY,
        id INTEGER,
        basket_uuid TEXT NOT NULL,
        vendor_uuid TEXT NOT NULL,
        date TEXT NOT NULL,
        expected_delivery_date TEXT,
        base_price REAL DEFAULT 0.0,
        tax_amount REAL DEFAULT 0.0,
        total_amount REAL DEFAULT 0.0,
        currency TEXT DEFAULT 'INR',
        number_of_available_items INTEGER DEFAULT 0,
        number_of_unavailable_items INTEGER DEFAULT 0,
        project_uuid TEXT,
        description TEXT,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (basket_uuid) REFERENCES baskets (uuid),
        FOREIGN KEY (vendor_uuid) REFERENCES vendors (uuid),
        FOREIGN KEY (project_uuid) REFERENCES projects (uuid)
      )
    ''');

    // Basket Vendor Items table
    await db.execute('''
      CREATE TABLE quotation_items (
        uuid TEXT PRIMARY KEY,
        id INTEGER,
        quotation_uuid TEXT NOT NULL,
        basket_uuid TEXT NOT NULL,
        basket_item_uuid TEXT NOT NULL,
        vendor_price_list_uuid TEXT,
        item_available_with_vendor INTEGER DEFAULT 0,
        manufacturer_material_uuid TEXT,
        material_uuid TEXT,
        model TEXT,
        quantity REAL NOT NULL DEFAULT 1.0,
        max_retail_price REAL,
        rate REAL DEFAULT 0.0,
        rate_before_tax REAL DEFAULT 0.0,
        base_price REAL DEFAULT 0.0,
        tax_percent REAL DEFAULT 0.0,
        tax_amount REAL DEFAULT 0.0,
        total_amount REAL DEFAULT 0.0,
        currency TEXT DEFAULT 'INR',
        unit_of_measure TEXT,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (quotation_uuid) REFERENCES quotations (uuid),
        FOREIGN KEY (basket_uuid) REFERENCES baskets (uuid),
        FOREIGN KEY (basket_item_uuid) REFERENCES basket_items (uuid),
        FOREIGN KEY (vendor_price_list_uuid) REFERENCES vendor_price_lists (uuid)
      )
    ''');

    // Projects table
    await db.execute('''
      CREATE TABLE projects (
        uuid TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        address TEXT,
        phone_number TEXT,
        geo_location TEXT,
        start_date TEXT,
        end_date TEXT,
        completed INTEGER DEFAULT 0,
        updated_at TEXT NOT NULL
      )
    ''');

    // Unit of Measures table
    await db.execute('''
      CREATE TABLE unit_of_measures (
        name TEXT PRIMARY KEY,
        description TEXT,
        number_of_decimal_places INTEGER NOT NULL DEFAULT 2,
        updated_at TEXT NOT NULL
      )
    ''');

    // Currencies table
    await db.execute('''
      CREATE TABLE currencies (
        name TEXT PRIMARY KEY,
        description TEXT,
        symbol TEXT,
        number_of_decimal_places INTEGER,
        updated_at TEXT NOT NULL
      )
    ''');

    // Defaults table
    await db.execute('''
      CREATE TABLE defaults (
        type TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Local settings table for storing app configuration and state
    await db.execute('''
      CREATE TABLE local_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Change log table for delta sync
    await db.execute('''
      CREATE TABLE change_log (
        uuid TEXT PRIMARY KEY,
        table_index INTEGER NOT NULL,
        table_key TEXT NOT NULL,
        change_mode TEXT NOT NULL,
        updated_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    // Condensed change log table for optimized delta sync
    await db.execute('''
      CREATE TABLE condensed_change_log (
        uuid TEXT PRIMARY KEY,
        table_index INTEGER NOT NULL,
        table_key TEXT NOT NULL,
        change_mode TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create indexes for better performance
    await db.execute(
        'CREATE INDEX idx_manufacturer_materials_manufacturer ON manufacturer_materials(manufacturer_uuid)');
    await db.execute(
        'CREATE INDEX idx_manufacturer_materials_material ON manufacturer_materials(material_uuid)');
    await db.execute(
        'CREATE INDEX idx_vendor_price_lists_vendor ON vendor_price_lists(vendor_uuid)');
    await db.execute(
        'CREATE INDEX idx_vendor_price_lists_material ON vendor_price_lists(manufacturer_material_uuid)');
    await db.execute(
        'CREATE INDEX idx_purchase_order_items_po ON purchase_order_items(purchase_order_uuid)');
    await db.execute(
        'CREATE INDEX idx_basket_items_basket ON basket_items(basket_uuid)');
    await db.execute(
        'CREATE INDEX idx_basket_items_manufacturer_material ON basket_items(manufacturer_material_uuid)');
    await db.execute(
        'CREATE INDEX idx_quotations_basket ON quotations(basket_uuid)');
    await db.execute(
        'CREATE INDEX idx_quotations_vendor ON quotations(vendor_uuid)');
    await db.execute(
        'CREATE INDEX idx_quotation_items_basket_vendor ON quotation_items(quotation_uuid)');
    await db.execute(
        'CREATE INDEX idx_quotation_items_basket ON quotation_items(basket_uuid)');
    await db.execute(
        'CREATE INDEX idx_quotation_items_basket_item ON quotation_items(basket_item_uuid)');
    await db.execute(
        'CREATE INDEX idx_change_log_updated_at ON change_log(updated_at)');
    await db.execute(
        'CREATE INDEX idx_change_log_table_index ON change_log(table_index)');
    await db.execute(
        'CREATE INDEX idx_change_log_lookup ON change_log(table_index, table_key, change_mode)');
  }

  // Manufacturers CRUD
  Future<int> insertManufacturer(Manufacturer manufacturer) async {
    final db = await database;

    // Get the next numeric id if not provided
    int? nextId = manufacturer.id;
    nextId ??= await _getNextId(TableNames.manufacturers);

    final map = manufacturer.toDbMap();
    map['id'] = nextId;

    final result = await db.insert(TableNames.manufacturers, map);

    // Log change for delta sync
    await logChange(
        TableNames.manufacturers, manufacturer.uuid, ChangeModes.insert);
    return result;
  }

  Future<List<Manufacturer>> getAllManufacturers() async {
    final db = await database;
    final result = await db.query(TableNames.manufacturers, orderBy: 'name');
    return result.map((map) => Manufacturer.fromDbMap(map)).toList();
  }

  Future<Manufacturer?> getManufacturer(String uuid) async {
    final db = await database;
    final result = await db.query(
      TableNames.manufacturers,
      where: 'uuid = ?',
      whereArgs: [uuid],
    );
    if (result.isEmpty) return null;
    return Manufacturer.fromDbMap(result.first);
  }

  Future<int> updateManufacturer(Manufacturer manufacturer) async {
    final db = await database;
    final result = await db.update(
      TableNames.manufacturers,
      manufacturer.toDbMap(),
      where: 'uuid = ?',
      whereArgs: [manufacturer.uuid],
    );

    // Log change for delta sync
    if (result > 0) {
      await logChange(
          TableNames.manufacturers, manufacturer.uuid, ChangeModes.update);
    }

    return result;
  }

  Future<int> deleteManufacturer(String uuid) async {
    final db = await database;

    final result = await db.delete(
      TableNames.manufacturers,
      where: 'uuid = ?',
      whereArgs: [uuid],
    );

    // Log change for delta sync
    if (result > 0) {
      await logChange(TableNames.manufacturers, uuid, ChangeModes.delete);
    }

    return result;
  }

  // Check if manufacturer is in use
  Future<bool> isManufacturerInUse(String uuid) async {
    final db = await database;
    final result = await db.query(
      TableNames.manufacturerMaterials,
      where: 'manufacturer_uuid = ?',
      whereArgs: [uuid],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  // Vendors CRUD
  Future<int> insertVendor(Vendor vendor) async {
    final db = await database;

    // Get the next numeric id if not provided
    int? nextId = vendor.id;
    nextId ??= await _getNextId(TableNames.vendors);

    final map = vendor.toDbMap();
    map['id'] = nextId;

    final result = await db.insert(TableNames.vendors, map);

    // Log change for delta sync
    await logChange(TableNames.vendors, vendor.uuid, ChangeModes.insert);

    return result;
  }

  Future<List<Vendor>> getAllVendors() async {
    final db = await database;
    final result = await db.query(TableNames.vendors, orderBy: 'name');
    return result.map((map) => Vendor.fromDbMap(map)).toList();
  }

  Future<Vendor?> getVendor(String uuid) async {
    final db = await database;
    final result = await db.query(
      TableNames.vendors,
      where: 'uuid = ?',
      whereArgs: [uuid],
    );
    if (result.isEmpty) return null;
    return Vendor.fromDbMap(result.first);
  }

  Future<int> updateVendor(Vendor vendor) async {
    final db = await database;
    final result = await db.update(
      TableNames.vendors,
      vendor.toDbMap(),
      where: 'uuid = ?',
      whereArgs: [vendor.uuid],
    );

    // Log change for delta sync
    if (result > 0) {
      await logChange(TableNames.vendors, vendor.uuid, ChangeModes.update);
    }

    return result;
  }

  Future<int> deleteVendor(String uuid) async {
    final db = await database;

    final result = await db.delete(
      TableNames.vendors,
      where: 'uuid = ?',
      whereArgs: [uuid],
    );

    // Log change for delta sync
    if (result > 0) {
      await logChange(TableNames.vendors, uuid, ChangeModes.delete);
    }

    return result;
  }

  // Check if vendor is in use
  Future<bool> isVendorInUse(String uuid) async {
    final db = await database;

    // Check vendor_price_lists
    final vplResult = await db.query(
      TableNames.vendorPriceLists,
      where: 'vendor_uuid = ?',
      whereArgs: [uuid],
      limit: 1,
    );
    if (vplResult.isNotEmpty) return true;

    // Check purchase_orders
    final poResult = await db.query(
      TableNames.purchaseOrders,
      where: 'vendor_uuid = ?',
      whereArgs: [uuid],
      limit: 1,
    );
    return poResult.isNotEmpty;
  }

  // Projects CRUD
  Future<int> insertProject(Project project) async {
    final db = await database;
    final result = await db.insert(TableNames.projects, project.toDbMap());

    // Log change for delta sync
    await logChange(TableNames.projects, project.uuid, ChangeModes.insert);

    return result;
  }

  Future<List<Project>> getAllProjects() async {
    final db = await database;
    final result = await db.query(TableNames.projects, orderBy: 'name');
    return result.map((map) => Project.fromDbMap(map)).toList();
  }

  Future<Project?> getProject(String uuid) async {
    final db = await database;
    final result = await db.query(
      TableNames.projects,
      where: 'uuid = ?',
      whereArgs: [uuid],
    );
    if (result.isEmpty) return null;
    return Project.fromDbMap(result.first);
  }

  Future<int> updateProject(Project project) async {
    final db = await database;
    final result = await db.update(
      TableNames.projects,
      project.toDbMap(),
      where: 'uuid = ?',
      whereArgs: [project.uuid],
    );

    if (result > 0) {
      await logChange(TableNames.projects, project.uuid, ChangeModes.update);
    }

    return result;
  }

  Future<int> deleteProject(String uuid) async {
    final db = await database;
    final result = await db.delete(
      TableNames.projects,
      where: 'uuid = ?',
      whereArgs: [uuid],
    );

    if (result > 0) {
      await logChange(TableNames.projects, uuid, ChangeModes.delete);
    }

    return result;
  }

  // Materials CRUD
  Future<int> insertMaterial(Material material) async {
    final db = await database;

    // Get the next numeric id if not provided
    int? nextId = material.id;
    nextId ??= await _getNextId(TableNames.materials);

    final map = material.toDbMap();
    map['id'] = nextId;

    final result = await db.insert(TableNames.materials, map);

    // Log change for delta sync
    await logChange(TableNames.materials, material.uuid, ChangeModes.insert);

    return result;
  }

  Future<List<Material>> getAllMaterials() async {
    final db = await database;
    final result = await db.query(TableNames.materials, orderBy: 'name');
    return result.map((map) => Material.fromDbMap(map)).toList();
  }

  Future<Material?> getMaterial(String uuid) async {
    final db = await database;
    final result = await db.query(
      TableNames.materials,
      where: 'uuid = ?',
      whereArgs: [uuid],
    );
    if (result.isEmpty) return null;
    return Material.fromDbMap(result.first);
  }

  Future<int> updateMaterial(Material material) async {
    final db = await database;
    final result = await db.update(
      TableNames.materials,
      material.toDbMap(),
      where: 'uuid = ?',
      whereArgs: [material.uuid],
    );

    // Log change for delta sync
    if (result > 0) {
      await logChange(TableNames.materials, material.uuid, ChangeModes.update);
    }

    return result;
  }

  Future<int> deleteMaterial(String uuid) async {
    final db = await database;

    final result = await db.delete(
      TableNames.materials,
      where: 'uuid = ?',
      whereArgs: [uuid],
    );

    // Log change for delta sync
    if (result > 0) {
      await logChange(TableNames.materials, uuid, ChangeModes.delete);
    }

    return result;
  }

  // Check if material is in use
  Future<bool> isMaterialInUse(String uuid) async {
    final db = await database;

    // Check manufacturer_materials
    final mmResult = await db.query(
      TableNames.manufacturerMaterials,
      where: 'material_uuid = ?',
      whereArgs: [uuid],
      limit: 1,
    );
    if (mmResult.isNotEmpty) return true;

    // Check purchase_order_items (uses material_uuid after denormalization)
    final poiResult = await db.query(
      TableNames.purchaseOrderItems,
      where: 'material_uuid = ?',
      whereArgs: [uuid],
      limit: 1,
    );
    return poiResult.isNotEmpty;
  }

  // Manufacturer Materials CRUD
  Future<int> insertManufacturerMaterial(ManufacturerMaterial mm) async {
    final db = await database;
    final result =
        await db.insert(TableNames.manufacturerMaterials, mm.toDbMap());

    // Log change for delta sync
    await logChange(
        TableNames.manufacturerMaterials, mm.uuid, ChangeModes.insert);
    return result;
  }

  Future<List<ManufacturerMaterial>> getAllManufacturerMaterials() async {
    final db = await database;
    final result =
        await db.query(TableNames.manufacturerMaterials, orderBy: 'model');
    return result.map((map) => ManufacturerMaterial.fromDbMap(map)).toList();
  }

  // Efficient JOIN query to get all manufacturer materials with related data in one query
  Future<List<ManufacturerMaterialWithDetails>>
      getAllManufacturerMaterialsWithDetails({
    String? manufacturerUuid,
    String? materialUuid,
  }) async {
    final db = await database;
    String where = '1=1';
    List<dynamic> whereArgs = [];

    if (manufacturerUuid != null && manufacturerUuid.isNotEmpty) {
      where += ' AND mfr.uuid = ?';
      whereArgs.add(manufacturerUuid);
    }
    if (materialUuid != null && materialUuid.isNotEmpty) {
      where += ' AND mat.uuid = ?';
      whereArgs.add(materialUuid);
    }

    final result = await db.rawQuery('''
      SELECT 
        mm.uuid,
        mm.manufacturer_uuid,
        mm.material_uuid,
        mm.model,
        mm.selling_lot_size,
        mm.max_retail_price,
        mm.currency,
        mm.updated_at,
        mfr.name as manufacturer_name,
        mat.name as material_name,
        mat.unit_of_measure as material_unit_of_measure
      FROM manufacturer_materials mm
      INNER JOIN manufacturers mfr ON mm.manufacturer_uuid = mfr.uuid
      INNER JOIN materials mat ON mm.material_uuid = mat.uuid
      WHERE $where
      ORDER BY mat.name, mfr.name, mm.model
    ''', whereArgs);

    return result
        .map((map) => ManufacturerMaterialWithDetails.fromDbMap(map))
        .toList();
  }

  Future<List<ManufacturerMaterial>> getManufacturerMaterialsByMaterial(
      String materialUuid) async {
    final db = await database;
    final result = await db.query(
      TableNames.manufacturerMaterials,
      where: 'material_uuid = ?',
      whereArgs: [materialUuid],
      orderBy: 'model',
    );
    return result.map((map) => ManufacturerMaterial.fromDbMap(map)).toList();
  }

  Future<List<ManufacturerMaterial>> searchManufacturerMaterials({
    String? manufacturerUuid,
    String? materialUuid,
  }) async {
    final db = await database;
    String where = '1=1';
    List<dynamic> whereArgs = [];

    if (manufacturerUuid != null && manufacturerUuid.isNotEmpty) {
      where += ' AND manufacturer_uuid = ?';
      whereArgs.add(manufacturerUuid);
    }
    if (materialUuid != null && materialUuid.isNotEmpty) {
      where += ' AND material_uuid = ?';
      whereArgs.add(materialUuid);
    }

    final result = await db.query(
      TableNames.manufacturerMaterials,
      where: where,
      whereArgs: whereArgs,
      orderBy: 'model',
    );
    return result.map((map) => ManufacturerMaterial.fromDbMap(map)).toList();
  }

  Future<ManufacturerMaterial?> getManufacturerMaterial(String uuid) async {
    final db = await database;
    final result = await db.query(
      TableNames.manufacturerMaterials,
      where: 'uuid = ?',
      whereArgs: [uuid],
    );
    if (result.isEmpty) return null;
    return ManufacturerMaterial.fromDbMap(result.first);
  }

  Future<ManufacturerMaterialWithDetails?> getManufacturerMaterialWithDetails(
      String uuid) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT mm.*, 
             m.name as manufacturer_name,
             mat.name as material_name,
             mat.unit_of_measure as material_unit_of_measure
      FROM manufacturer_materials mm
      INNER JOIN manufacturers m ON mm.manufacturer_uuid = m.uuid
      INNER JOIN materials mat ON mm.material_uuid = mat.uuid
      WHERE mm.uuid = ?
    ''', [uuid]);
    if (result.isEmpty) return null;
    return ManufacturerMaterialWithDetails.fromDbMap(result.first);
  }

  Future<int> updateManufacturerMaterial(ManufacturerMaterial mm) async {
    final db = await database;
    final result = await db.update(
      TableNames.manufacturerMaterials,
      mm.toDbMap(),
      where: 'uuid = ?',
      whereArgs: [mm.uuid],
    );

    // Log change for delta sync
    if (result > 0) {
      await logChange(
          TableNames.manufacturerMaterials, mm.uuid, ChangeModes.update);
    }

    return result;
  }

  Future<int> deleteManufacturerMaterial(String uuid) async {
    final db = await database;

    final result = await db.delete(
      TableNames.manufacturerMaterials,
      where: 'uuid = ?',
      whereArgs: [uuid],
    );

    // Log change for delta sync
    if (result > 0) {
      await logChange(
          TableNames.manufacturerMaterials, uuid, ChangeModes.delete);
    }

    return result;
  }

  // Check if manufacturer material is in use
  Future<bool> isManufacturerMaterialInUse(String uuid) async {
    final db = await database;
    final vplResult = await db.query(
      TableNames.vendorPriceLists,
      where: 'manufacturer_material_uuid = ?',
      whereArgs: [uuid],
      limit: 1,
    );
    if (vplResult.isNotEmpty) return true;

    final poiResult = await db.query(
      TableNames.purchaseOrderItems,
      where: 'manufacturer_material_uuid = ?',
      whereArgs: [uuid],
      limit: 1,
    );
    return poiResult.isNotEmpty;
  }

  // Vendor Price Lists CRUD
  Future<int> insertVendorPriceList(VendorPriceList vpl) async {
    final db = await database;
    final result = await db.insert(TableNames.vendorPriceLists, vpl.toDbMap());

    // Log change for delta sync
    await logChange(TableNames.vendorPriceLists, vpl.uuid, ChangeModes.insert);
    return result;
  }

  Future<List<VendorPriceList>> getAllVendorPriceLists() async {
    final db = await database;
    final result =
        await db.query(TableNames.vendorPriceLists, orderBy: 'updated_at DESC');
    return result.map((map) => VendorPriceList.fromDbMap(map)).toList();
  }

  // Efficient JOIN query to get all vendor price lists with related data in one query
  Future<List<VendorPriceListWithDetails>> getAllVendorPriceListsWithDetails({
    String? vendorUuid,
    String? manufacturerUuid,
    String? materialUuid,
  }) async {
    final db = await database;
    String where = '1=1';
    List<dynamic> whereArgs = [];

    if (vendorUuid != null && vendorUuid.isNotEmpty) {
      where += ' AND v.uuid = ?';
      whereArgs.add(vendorUuid);
    }
    if (manufacturerUuid != null && manufacturerUuid.isNotEmpty) {
      where += ' AND mfr.uuid = ?';
      whereArgs.add(manufacturerUuid);
    }
    if (materialUuid != null && materialUuid.isNotEmpty) {
      where += ' AND mat.uuid = ?';
      whereArgs.add(materialUuid);
    }

    final result = await db.rawQuery('''
      SELECT 
        vpl.uuid,
        vpl.manufacturer_material_uuid,
        vpl.vendor_uuid,
        vpl.rate,
        vpl.rate_before_tax,
        vpl.currency,
        vpl.tax_percent,
        vpl.tax_amount,
        vpl.updated_at,
        v.name as vendor_name,
        mfr.name as manufacturer_name,
        mat.name as material_name,
        mat.unit_of_measure as material_unit_of_measure,
        mm.model as manufacturer_material_model
      FROM vendor_price_lists vpl
      INNER JOIN vendors v ON vpl.vendor_uuid = v.uuid
      INNER JOIN manufacturer_materials mm ON vpl.manufacturer_material_uuid = mm.uuid
      INNER JOIN manufacturers mfr ON mm.manufacturer_uuid = mfr.uuid
      INNER JOIN materials mat ON mm.material_uuid = mat.uuid
      WHERE $where
      ORDER BY v.name, mfr.name, mat.name, mm.model
    ''', whereArgs);

    return result
        .map((map) => VendorPriceListWithDetails.fromDbMap(map))
        .toList();
  }

  Future<List<VendorPriceList>> searchVendorPriceLists({
    String? vendorUuid,
    String? manufacturerUuid,
    String? materialUuid,
  }) async {
    final db = await database;
    String where = '1=1';
    List<dynamic> whereArgs = [];

    if (vendorUuid != null && vendorUuid.isNotEmpty) {
      where += ' AND vpl.vendor_uuid = ?';
      whereArgs.add(vendorUuid);
    }
    if (manufacturerUuid != null && manufacturerUuid.isNotEmpty) {
      where += ' AND mm.manufacturer_uuid = ?';
      whereArgs.add(manufacturerUuid);
    }
    if (materialUuid != null && materialUuid.isNotEmpty) {
      where += ' AND mm.material_uuid = ?';
      whereArgs.add(materialUuid);
    }

    final result = await db.rawQuery('''
      SELECT vpl.* FROM vendor_price_lists vpl
      INNER JOIN manufacturer_materials mm ON vpl.manufacturer_material_uuid = mm.uuid
      WHERE $where
      ORDER BY vpl.updated_at DESC
    ''', whereArgs);

    return result.map((map) => VendorPriceList.fromDbMap(map)).toList();
  }

  Future<List<VendorPriceList>> getVendorPriceListsByVendor(
      String vendorUuid) async {
    final db = await database;
    final result = await db.query(
      TableNames.vendorPriceLists,
      where: 'vendor_uuid = ?',
      whereArgs: [vendorUuid],
      orderBy: 'updated_at DESC',
    );
    return result.map((map) => VendorPriceList.fromDbMap(map)).toList();
  }

  Future<List<VendorPriceList>> getVendorPriceListsByManufacturerMaterial(
      String mmId) async {
    final db = await database;
    final result = await db.query(
      TableNames.vendorPriceLists,
      where: 'manufacturer_material_uuid = ?',
      whereArgs: [mmId],
      orderBy: 'updated_at DESC',
    );
    return result.map((map) => VendorPriceList.fromDbMap(map)).toList();
  }

  Future<VendorPriceList?> getVendorPriceList(String uuid) async {
    final db = await database;
    final result = await db.query(
      TableNames.vendorPriceLists,
      where: 'uuid = ?',
      whereArgs: [uuid],
    );
    if (result.isEmpty) return null;
    return VendorPriceList.fromDbMap(result.first);
  }

  Future<VendorPriceList?> getVendorPriceListByVendorAndMaterial(
      String vendorUuid, String manufacturerMaterialUuid) async {
    final db = await database;
    final result = await db.query(
      TableNames.vendorPriceLists,
      where: 'vendor_uuid = ? AND manufacturer_material_uuid = ?',
      whereArgs: [vendorUuid, manufacturerMaterialUuid],
    );
    if (result.isEmpty) return null;
    return VendorPriceList.fromDbMap(result.first);
  }

  Future<int> updateVendorPriceList(VendorPriceList vpl) async {
    final db = await database;
    final result = await db.update(
      TableNames.vendorPriceLists,
      vpl.toDbMap(),
      where: 'uuid = ?',
      whereArgs: [vpl.uuid],
    );

    // Log change for delta sync
    if (result > 0) {
      await logChange(
          TableNames.vendorPriceLists, vpl.uuid, ChangeModes.update);
    }

    return result;
  }

  Future<int> deleteVendorPriceList(String uuid) async {
    final db = await database;

    final result = await db.delete(
      TableNames.vendorPriceLists,
      where: 'uuid = ?',
      whereArgs: [uuid],
    );

    // Log change for delta sync
    if (result > 0) {
      await logChange(TableNames.vendorPriceLists, uuid, ChangeModes.delete);
    }

    return result;
  }

  // Purchase Orders CRUD
  Future<int> insertPurchaseOrder(PurchaseOrder po) async {
    final db = await database;

    // Get the next numeric id if not provided
    int? nextId = po.id;
    nextId ??= await _getNextId(TableNames.purchaseOrders);

    // Create a new map with the generated id
    final poMap = po.toDbMap();
    poMap['id'] = nextId;

    await db.insert(TableNames.purchaseOrders, poMap);

    // Log change for delta sync
    await logChange(TableNames.purchaseOrders, po.uuid, ChangeModes.insert);
    return nextId;
  }

  Future<List<Map<String, dynamic>>> getAllPurchaseOrders() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        po.*,
        p.name as project_name,
        p.description as project_description,
        p.address as project_address,
        p.start_date as project_start_date,
        p.end_date as project_end_date
      FROM purchase_orders po
      LEFT OUTER JOIN projects p ON po.project_uuid = p.uuid
      ORDER BY po.updated_at DESC, po.order_date DESC, po.expected_delivery_date DESC
    ''');
    return result;
  }

  Future<PurchaseOrder?> getPurchaseOrder(String uuid) async {
    final db = await database;
    final result = await db.query(
      TableNames.purchaseOrders,
      where: 'uuid = ?',
      whereArgs: [uuid],
    );
    if (result.isEmpty) return null;
    return PurchaseOrder.fromDbMap(result.first);
  }

  Future<int> updatePurchaseOrder(PurchaseOrder po) async {
    final db = await database;
    final result = await db.update(
      TableNames.purchaseOrders,
      po.toDbMap(),
      where: 'uuid = ?',
      whereArgs: [po.uuid],
    );

    // Log change for delta sync
    if (result > 0) {
      await logChange(TableNames.purchaseOrders, po.uuid, ChangeModes.update);
    }

    return result;
  }

  Future<int> deletePurchaseOrder(String uuid) async {
    final db = await database;

    // Get all child items to track their deletion
    final items = await db.query(
      TableNames.purchaseOrderItems,
      columns: ['uuid'],
      where: 'purchase_order_uuid = ?',
      whereArgs: [uuid],
    );

    // Track deletion of all child items
    for (final item in items) {
      // Log change for delta sync
      await logChange(TableNames.purchaseOrderItems, item['uuid'] as String,
          ChangeModes.delete);
    }

    // Get all payments to track their deletion
    final payments = await db.query(
      TableNames.purchaseOrderPayments,
      columns: ['uuid'],
      where: 'purchase_order_uuid = ?',
      whereArgs: [uuid],
    );

    // Track deletion of all payments
    for (final payment in payments) {
      // Log change for delta sync
      await logChange(TableNames.purchaseOrderPayments,
          payment['uuid'] as String, ChangeModes.delete);
    }

    // Delete items first
    await db.delete(
      TableNames.purchaseOrderItems,
      where: 'purchase_order_uuid = ?',
      whereArgs: [uuid],
    );

    // Delete payments
    await db.delete(
      TableNames.purchaseOrderPayments,
      where: 'purchase_order_uuid = ?',
      whereArgs: [uuid],
    );

    // Then delete the order
    final result = await db.delete(
      TableNames.purchaseOrders,
      where: 'uuid = ?',
      whereArgs: [uuid],
    );

    // Log change for delta sync
    if (result > 0) {
      await logChange(TableNames.purchaseOrders, uuid, ChangeModes.delete);
    }

    return result;
  }

  // Purchase Order Items CRUD
  Future<int> insertPurchaseOrderItem(PurchaseOrderItem poi) async {
    final db = await database;
    final result =
        await db.insert(TableNames.purchaseOrderItems, poi.toDbMap());
    // Log change for delta sync
    await logChange(
        TableNames.purchaseOrderItems, poi.uuid, ChangeModes.insert);

    return result;
  }

  Future<List<PurchaseOrderItem>> getPurchaseOrderItems(
      String purchaseOrderUuid) async {
    final db = await database;
    final result = await db.query(
      TableNames.purchaseOrderItems,
      where: 'purchase_order_uuid = ?',
      whereArgs: [purchaseOrderUuid],
      orderBy: 'updated_at',
    );
    return result.map((map) => PurchaseOrderItem.fromDbMap(map)).toList();
  }

  Future<PurchaseOrderItem?> getPurchaseOrderItem(String uuid) async {
    final db = await database;
    final result = await db.query(
      TableNames.purchaseOrderItems,
      where: 'uuid = ?',
      whereArgs: [uuid],
    );
    if (result.isEmpty) return null;
    return PurchaseOrderItem.fromDbMap(result.first);
  }

  Future<int> updatePurchaseOrderItem(PurchaseOrderItem poi) async {
    final db = await database;
    final result = await db.update(
      TableNames.purchaseOrderItems,
      poi.toDbMap(),
      where: 'uuid = ?',
      whereArgs: [poi.uuid],
    );

    // Log change for delta sync
    if (result > 0) {
      await logChange(
          TableNames.purchaseOrderItems, poi.uuid, ChangeModes.update);
    }

    return result;
  }

  Future<int> deletePurchaseOrderItem(String uuid) async {
    final db = await database;

    final result = await db.delete(
      TableNames.purchaseOrderItems,
      where: 'uuid = ?',
      whereArgs: [uuid],
    );

    // Log change for delta sync
    if (result > 0) {
      await logChange(TableNames.purchaseOrderItems, uuid, ChangeModes.delete);
    }

    return result;
  }

  // Purchase Order Payments CRUD
  Future<int> insertPurchaseOrderPayment(PurchaseOrderPayment payment) async {
    final db = await database;
    final result =
        await db.insert(TableNames.purchaseOrderPayments, payment.toDbMap());
    // Log change for delta sync
    await logChange(
        TableNames.purchaseOrderPayments, payment.uuid, ChangeModes.insert);

    return result;
  }

  Future<List<PurchaseOrderPayment>> getPurchaseOrderPayments(
      String purchaseOrderUuid) async {
    final db = await database;
    final result = await db.query(
      TableNames.purchaseOrderPayments,
      where: 'purchase_order_uuid = ?',
      whereArgs: [purchaseOrderUuid],
      orderBy: 'date DESC',
    );
    return result.map((map) => PurchaseOrderPayment.fromDbMap(map)).toList();
  }

  Future<PurchaseOrderPayment?> getPurchaseOrderPayment(String uuid) async {
    final db = await database;
    final result = await db.query(
      TableNames.purchaseOrderPayments,
      where: 'uuid = ?',
      whereArgs: [uuid],
    );
    if (result.isEmpty) return null;
    return PurchaseOrderPayment.fromDbMap(result.first);
  }

  Future<int> updatePurchaseOrderPayment(PurchaseOrderPayment payment) async {
    final db = await database;
    final result = await db.update(
      TableNames.purchaseOrderPayments,
      payment.toDbMap(),
      where: 'uuid = ?',
      whereArgs: [payment.uuid],
    );

    // Log change for delta sync
    if (result > 0) {
      await logChange(
          TableNames.purchaseOrderPayments, payment.uuid, ChangeModes.update);
    }

    return result;
  }

  Future<int> deletePurchaseOrderPayment(String uuid) async {
    final db = await database;

    final result = await db.delete(
      TableNames.purchaseOrderPayments,
      where: 'uuid = ?',
      whereArgs: [uuid],
    );

    // Log change for delta sync
    if (result > 0) {
      await logChange(
          TableNames.purchaseOrderPayments, uuid, ChangeModes.delete);
    }

    return result;
  }

  // Get manufacturer materials available for a vendor (through vendor price list)
  Future<List<ManufacturerMaterial>> getManufacturerMaterialsByVendor(
      String vendorUuid) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT DISTINCT mm.* FROM manufacturer_materials mm
      INNER JOIN vendor_price_lists vpl ON mm.uuid = vpl.manufacturer_material_uuid
      WHERE vpl.vendor_uuid = ?
      ORDER BY mm.model
    ''', [vendorUuid]);
    return result.map((map) => ManufacturerMaterial.fromDbMap(map)).toList();
  }

  // Get manufacturer materials with details and vendor pricing - for purchase order item selection
  Future<List<ManufacturerMaterialWithDetails>>
      getManufacturerMaterialsWithPricingByVendor(String vendorUuid) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        mm.uuid,
        mm.manufacturer_uuid,
        mm.material_uuid,
        mm.model,
        mm.selling_lot_size,
        mm.max_retail_price,
        mm.currency,
        mm.updated_at,
        mfr.name as manufacturer_name,
        mat.name as material_name,
        mat.unit_of_measure as material_unit_of_measure,
        vpl.rate as vendor_rate,
        vpl.rate_before_tax as vendor_rate_before_tax,
        vpl.currency as vendor_currency,
        vpl.tax_percent as vendor_tax_percent
      FROM manufacturer_materials mm
      INNER JOIN manufacturers mfr ON mm.manufacturer_uuid = mfr.uuid
      INNER JOIN materials mat ON mm.material_uuid = mat.uuid
      INNER JOIN vendor_price_lists vpl ON mm.uuid = vpl.manufacturer_material_uuid
      WHERE vpl.vendor_uuid = ?
      ORDER BY mat.name, mfr.name, mm.model
    ''', [vendorUuid]);
    return result
        .map((map) => ManufacturerMaterialWithDetails.fromDbMap(map))
        .toList();
  }

  // Check if model is in use (for materials screen)
  Future<bool> isModelInUse(String manufacturerMaterialUuid) async {
    return await isManufacturerMaterialInUse(manufacturerMaterialUuid);
  }

  // Clear all data from database
  Future<void> clearAllData() async {
    final db = await database;

    debugPrint('Clearing all data from database...');
    // Delete in reverse order of dependencies
    // Note: Using direct db.delete() to bypass change logging
    // This is intentional - cleanup is for local testing, not for sync
    for (String table in DataDefinition.getTablesByTypes([
      ModelTypes.configuration,
      ModelTypes.masterData,
      ModelTypes.transactionData,
      ModelTypes.log
    ])) {
      await db.delete(table);
    }

    // Reset sync timestamp and sync-paused state so next sync pulls all data from server
    // Keep web_app_url and secret_code as they are configuration values
    await db.delete(
      TableNames.localSettings,
      where: 'key IN (?, ?)',
      whereArgs: [
        LocalSettingsKeys.lastSyncTimestamp,
        LocalSettingsKeys.syncPaused
      ],
    );
    debugPrint('All data cleared successfully');
  }

  // Get record counts for all tables
  Future<Map<String, int>> getTableCounts(List<String> tableTypes) async {
    final db = await database;
    final Map<String, int> counts = {};

    for (var table in tableTypes) {
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM $table');
      counts[table] = Sqflite.firstIntValue(result) ?? 0;
    }

    return counts;
  }

  // Generate or update purchase order from basket vendor
  Future<PurchaseOrder> generatePurchaseOrderFromQuotation(
      String quotationUuid) async {
    final db = await database;

    // Get basket vendor
    final quotation = await getQuotation(quotationUuid);
    if (quotation == null) {
      throw Exception('Basket vendor not found');
    }

    // Check if purchase order already exists for this basket vendor
    final existingPOs = await db.query(
      TableNames.purchaseOrders,
      where: 'quotation_uuid = ?',
      whereArgs: [quotationUuid],
    );

    final now = DateTime.now();
    PurchaseOrder purchaseOrder;

    if (existingPOs.isEmpty) {
      // Create new purchase order
      final poUuid = _uuid.v4();
      purchaseOrder = PurchaseOrder(
        uuid: poUuid,
        vendorUuid: quotation.vendorUuid,
        date: DateTime.now(),
        basePrice: quotation.basePrice,
        taxAmount: quotation.taxAmount,
        totalAmount: quotation.totalAmount,
        currency: quotation.currency,
        orderDate: DateTime.now(),
        expectedDeliveryDate: quotation.expectedDeliveryDate,
        amountPaid: 0.0,
        amountBalance: quotation.totalAmount,
        completed: false,
        basketUuid: quotation.basketUuid,
        quotationUuid: quotation.uuid,
        updatedAt: now,
      );
      await insertPurchaseOrder(purchaseOrder);
    } else {
      // Update existing purchase order
      final existingPO = PurchaseOrder.fromDbMap(existingPOs.first);
      purchaseOrder = existingPO.copyWith(
        vendorUuid: quotation.vendorUuid,
        basePrice: quotation.basePrice,
        taxAmount: quotation.taxAmount,
        totalAmount: quotation.totalAmount,
        currency: quotation.currency,
        expectedDeliveryDate: quotation.expectedDeliveryDate,
        amountBalance: quotation.totalAmount - existingPO.amountPaid,
        updatedAt: now,
      );
      await updatePurchaseOrder(purchaseOrder);
    }

    // Get basket vendor items
    final quotationItems = await getQuotationItems(quotationUuid);

    // Get existing purchase order items for this purchase order
    final existingPOItems = await db.query(
      TableNames.purchaseOrderItems,
      where: 'purchase_order_uuid = ?',
      whereArgs: [purchaseOrder.uuid],
    );

    final existingPOItemsMap = {
      for (var item in existingPOItems)
        item['quotation_item_uuid'] as String?: item
    };

    // Track which basket vendor items we've processed
    final processedQuotationItemUuids = <String>{};

    // Create or update purchase order items
    for (var quotationItem in quotationItems) {
      processedQuotationItemUuids.add(quotationItem.uuid);

      if (existingPOItemsMap.containsKey(quotationItem.uuid)) {
        // Update existing item
        final existingItem = existingPOItemsMap[quotationItem.uuid]!;
        final poItem = PurchaseOrderItem(
          uuid: existingItem['uuid'] as String,
          purchaseOrderUuid: purchaseOrder.uuid,
          manufacturerMaterialUuid: quotationItem.manufacturerMaterialUuid!,
          materialUuid: quotationItem.materialUuid!,
          model: quotationItem.model ?? '',
          quantity: quotationItem.quantity,
          rate: quotationItem.rate,
          rateBeforeTax: quotationItem.rateBeforeTax,
          basePrice: quotationItem.basePrice,
          taxPercent: quotationItem.taxPercent,
          taxAmount: quotationItem.taxAmount,
          totalAmount: quotationItem.totalAmount,
          currency: quotationItem.currency,
          basketItemUuid: quotationItem.basketItemUuid,
          quotationItemUuid: quotationItem.uuid,
          updatedAt: now,
        );
        await updatePurchaseOrderItem(poItem);
      } else {
        // Create new item
        final poItemUuid = _uuid.v4();
        final poItem = PurchaseOrderItem(
          uuid: poItemUuid,
          purchaseOrderUuid: purchaseOrder.uuid,
          manufacturerMaterialUuid: quotationItem.manufacturerMaterialUuid!,
          materialUuid: quotationItem.materialUuid!,
          model: quotationItem.model ?? '',
          quantity: quotationItem.quantity,
          rate: quotationItem.rate,
          rateBeforeTax: quotationItem.rateBeforeTax,
          basePrice: quotationItem.basePrice,
          taxPercent: quotationItem.taxPercent,
          taxAmount: quotationItem.taxAmount,
          totalAmount: quotationItem.totalAmount,
          currency: quotationItem.currency,
          basketItemUuid: quotationItem.basketItemUuid,
          quotationItemUuid: quotationItem.uuid,
          updatedAt: now,
        );
        await insertPurchaseOrderItem(poItem);
      }
    }

    // Delete purchase order items that are no longer in basket vendor items
    for (var existingItem in existingPOItems) {
      final quotationItemUuid = existingItem['quotation_item_uuid'] as String?;
      if (quotationItemUuid != null &&
          !processedQuotationItemUuids.contains(quotationItemUuid)) {
        await deletePurchaseOrderItem(existingItem['uuid'] as String);
      }
    }

    // Recalculate purchase order totals (done automatically by insert/update)

    // Reload purchase order to get updated values
    final updatedPO = await getPurchaseOrder(purchaseOrder.uuid);
    return updatedPO!;
  }

  // Get purchase order by basket vendor UUID
  Future<PurchaseOrder?> getPurchaseOrderByQuotation(
      String quotationUuid) async {
    final db = await database;
    final result = await db.query(
      TableNames.purchaseOrders,
      where: 'quotation_uuid = ?',
      whereArgs: [quotationUuid],
    );

    if (result.isEmpty) return null;
    return PurchaseOrder.fromDbMap(result.first);
  }

  // Get purchase order by basket UUID
  Future<PurchaseOrder?> getPurchaseOrderByBasket(String basketUuid) async {
    final db = await database;
    final result = await db.query(
      TableNames.purchaseOrders,
      where: 'basket_uuid = ?',
      whereArgs: [basketUuid],
      orderBy: 'order_date DESC',
      limit: 1,
    );

    if (result.isEmpty) return null;
    return PurchaseOrder.fromDbMap(result.first);
  }

  // Local settings operations
  Future<void> setLocalSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      TableNames.localSettings,
      {
        'key': key,
        'value': value,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getLocalSetting(String key) async {
    final db = await database;
    final result = await db.query(
      TableNames.localSettings,
      where: 'key = ?',
      whereArgs: [key],
    );
    return result.isNotEmpty ? result.first['value'] as String : null;
  }

  Future<void> deleteLocalSetting(String key) async {
    final db = await database;
    await db.delete(
      TableNames.localSettings,
      where: 'key = ?',
      whereArgs: [key],
    );
  }

  /// Log a change to the change_log table for delta sync
  Future<void> logChange(
      String tableName, String tableKey, String changeMode) async {
    final tableDefinition = DataDefinition.getModelDefinition(tableName);
    if (tableDefinition == null) {
      // Table not configured for delta sync, skip logging
      return;
    }

    final db = await database;

    // Generate UUID for change log entry
    final changeLogUuid = _uuid.v4();

    await db.insert(TableNames.changeLog, {
      'uuid': changeLogUuid,
      'table_index': tableDefinition.tableIndex,
      'table_key': tableKey,
      'change_mode': changeMode,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Get change log entries since a specific timestamp
  Future<List<Map<String, dynamic>>> getChangeLog(
      String? sinceTimestamp) async {
    final db = await database;

    if (sinceTimestamp != null) {
      return await db.query(
        TableNames.changeLog,
        where: 'updated_at > ?',
        whereArgs: [sinceTimestamp],
        orderBy: 'updated_at ASC',
      );
    } else {
      return await db.query(
        TableNames.changeLog,
        orderBy: 'updated_at ASC',
      );
    }
  }

  /// Clear change log up to a specific timestamp
  Future<void> clearChangeLog(String upToTimestamp) async {
    final db = await database;
    await db.delete(
      TableNames.changeLog,
      where: 'updated_at <= ?',
      whereArgs: [upToTimestamp],
    );
  }

  /// Condense change log - keeps only the first INSERT/UPDATE and handles DELETE operations
  /// This method replicates the backend prepareCondensedChangeLogFromChangeLog() logic
  Future<List<Map<String, dynamic>>> condenseChangeLog(
      List<Map<String, dynamic>> changeLog) async {
    // Map to track changes per table and key: "tableIndex_tableKeyUuid" -> change entry
    final Map<String, Map<String, dynamic>> tableChangeHistory = {};

    // Process each change in chronological order
    for (var change in changeLog) {
      final tableIndex = change['table_index'] as int;
      final tableKey = change['table_key'] as String;
      final changeMode = change['change_mode'] as String;
      final key = '${tableIndex}_$tableKey';

      if (changeMode == 'D') {
        // DELETE: Remove any previous INSERT/UPDATE, or keep DELETE if no prior change
        if (tableChangeHistory.containsKey(key)) {
          // There was a previous INSERT/UPDATE, so we can remove it from history
          tableChangeHistory.remove(key);
        } else {
          // No previous INSERT/UPDATE, so keep this DELETE
          tableChangeHistory[key] = change;
        }
      } else {
        // INSERT or UPDATE: Keep only if this is the first occurrence for this key
        if (!tableChangeHistory.containsKey(key)) {
          tableChangeHistory[key] = change;
        }
        // If already exists, ignore this change (keep only the first one)
      }
    }

    // Convert to list and sort by table_index (ascending), then updated_at (ascending)
    final condensedList = tableChangeHistory.values.toList();
    condensedList.sort((a, b) {
      final tableIndexCompare =
          (a['table_index'] as int).compareTo(b['table_index'] as int);
      if (tableIndexCompare != 0) return tableIndexCompare;
      return (a['updated_at'] as String).compareTo(b['updated_at'] as String);
    });

    // Store in condensed_change_log table
    final db = await database;

    // Clear existing condensed log
    await db.delete(TableNames.condensedChangeLog);

    // Insert condensed entries
    for (var entry in condensedList) {
      await db.insert(TableNames.condensedChangeLog, entry);
    }

    return condensedList;
  }

  /// Check if there are pending changes in the change log
  Future<bool> hasPendingChanges() async {
    final db = await database;
    final result =
        await db.rawQuery('SELECT COUNT(*) as count FROM change_log');
    final count = Sqflite.firstIntValue(result) ?? 0;
    return count > 0;
  }

  /// Clear condensed change log table
  Future<void> clearCondensedChangeLog() async {
    final db = await database;
    await db.delete(TableNames.condensedChangeLog);
  }

  // Basket CRUD
  Future<int> insertBasket(Basket basket) async {
    final db = await database;

    // Get the next numeric id if not provided
    int? nextId = basket.id;
    nextId ??= await _getNextId(TableNames.baskets);

    final basketWithId = basket.copyWith(id: nextId);
    final result = await db.insert(TableNames.baskets, basketWithId.toDbMap());

    // Log change for delta sync
    await logChange(TableNames.baskets, basket.uuid, ChangeModes.insert);

    return result;
  }

  Future<List<Basket>> getAllBaskets() async {
    final db = await database;
    final result =
        await db.query(TableNames.baskets, orderBy: 'date DESC, id DESC');
    return result.map((map) => Basket.fromDbMap(map)).toList();
  }

  Future<Basket?> getBasket(String uuid) async {
    final db = await database;
    final result = await db.query(
      TableNames.baskets,
      where: 'uuid = ?',
      whereArgs: [uuid],
    );
    if (result.isEmpty) return null;
    return Basket.fromDbMap(result.first);
  }

  Future<int> updateBasket(Basket basket, {bool logChange = true}) async {
    final db = await database;
    final result = await db.update(
      TableNames.baskets,
      basket.toDbMap(),
      where: 'uuid = ?',
      whereArgs: [basket.uuid],
    );

    // Log change for delta sync (skip for automatic recalculations)
    if (result > 0 && logChange) {
      await this.logChange(TableNames.baskets, basket.uuid, ChangeModes.update);
    }

    return result;
  }

  Future<int> deleteBasket(String uuid) async {
    final db = await database;

    // Delete related basket items first
    await db.delete(TableNames.basketItems,
        where: 'basket_uuid = ?', whereArgs: [uuid]);

    // Delete related basket vendors and their items
    final vendors = await getQuotations(uuid);
    for (var vendor in vendors) {
      await db.delete(TableNames.quotationItems,
          where: 'quotation_uuid = ?', whereArgs: [vendor.uuid]);
    }
    await db.delete(TableNames.quotations,
        where: 'basket_uuid = ?', whereArgs: [uuid]);

    final result = await db.delete(
      TableNames.baskets,
      where: 'uuid = ?',
      whereArgs: [uuid],
    );

    // Log change for delta sync
    if (result > 0) {
      await logChange(TableNames.baskets, uuid, ChangeModes.delete);
    }

    return result;
  }

  // Basket Item CRUD
  Future<int> insertBasketItem(BasketItem item) async {
    final db = await database;

    // Get the next numeric id if not provided
    int? nextId = item.id;
    nextId ??=
        await _getNextIdForBasket(TableNames.basketItems, item.basketUuid);

    final itemWithId = item.copyWith(id: nextId);
    final result =
        await db.insert(TableNames.basketItems, itemWithId.toDbMap());

    // Log change for delta sync
    await logChange(TableNames.basketItems, item.uuid, ChangeModes.insert);

    // Update basket totals
    await _updateBasketTotals(item.basketUuid);

    // Add corresponding vendor items to all existing vendor quotations
    await _syncVendorItemsForBasketItem(item.basketUuid, itemWithId, 'insert');

    return result;
  }

  Future<List<BasketItem>> getBasketItems(String basketUuid) async {
    final db = await database;
    final result = await db.query(
      TableNames.basketItems,
      where: 'basket_uuid = ?',
      whereArgs: [basketUuid],
      orderBy: 'id ASC',
    );
    return result.map((map) => BasketItem.fromDbMap(map)).toList();
  }

  Future<BasketItem?> getBasketItem(String uuid) async {
    final db = await database;
    final result = await db.query(
      TableNames.basketItems,
      where: 'uuid = ?',
      whereArgs: [uuid],
    );
    if (result.isEmpty) return null;
    return BasketItem.fromDbMap(result.first);
  }

  Future<int> updateBasketItem(BasketItem item) async {
    final db = await database;
    final result = await db.update(
      TableNames.basketItems,
      item.toDbMap(),
      where: 'uuid = ?',
      whereArgs: [item.uuid],
    );

    // Log change for delta sync
    if (result > 0) {
      await logChange(TableNames.basketItems, item.uuid, ChangeModes.update);

      // Update basket totals
      await _updateBasketTotals(item.basketUuid);

      // Update corresponding vendor items
      await _syncVendorItemsForBasketItem(item.basketUuid, item, 'update');
    }

    return result;
  }

  Future<int> deleteBasketItem(String uuid) async {
    final db = await database;

    // Get the item to find basket_uuid
    final item = await getBasketItem(uuid);
    if (item == null) return 0;

    // Get all affected vendor quotations before deleting
    final affectedVendors = await db.query(
      TableNames.quotationItems,
      columns: ['quotation_uuid'],
      where: 'basket_item_uuid = ?',
      whereArgs: [uuid],
      distinct: true,
    );

    // Delete related basket vendor items
    await db.delete(TableNames.quotationItems,
        where: 'basket_item_uuid = ?', whereArgs: [uuid]);

    final result = await db.delete(
      TableNames.basketItems,
      where: 'uuid = ?',
      whereArgs: [uuid],
    );

    // Log change for delta sync
    if (result > 0) {
      await logChange(TableNames.basketItems, uuid, ChangeModes.delete);

      // Update basket totals
      await _updateBasketTotals(item.basketUuid);

      // Update totals for all affected vendor quotations
      for (var vendorMap in affectedVendors) {
        final vendorUuid = vendorMap['quotation_uuid'] as String;
        await _updateQuotationTotals(vendorUuid);
      }
    }

    return result;
  }

  // Basket Vendor CRUD
  Future<int> insertQuotation(Quotation vendor) async {
    final db = await database;

    // Get the next numeric id if not provided
    int? nextId = vendor.id;
    nextId ??=
        await _getNextIdForBasket(TableNames.quotations, vendor.basketUuid);

    final vendorWithId = vendor.copyWith(id: nextId);
    final result =
        await db.insert(TableNames.quotations, vendorWithId.toDbMap());

    // Log change for delta sync
    await logChange(TableNames.quotations, vendor.uuid, ChangeModes.insert);

    return result;
  }

  Future<List<Quotation>> getQuotations(String basketUuid) async {
    final db = await database;
    final result = await db.query(
      TableNames.quotations,
      where: 'basket_uuid = ?',
      whereArgs: [basketUuid],
      orderBy: 'id ASC',
    );
    return result.map((map) => Quotation.fromDbMap(map)).toList();
  }

  Future<List<Map<String, dynamic>>> getAllQuotations() async {
    final db = await database;
    // LEFT OUTER JOIN with projects to get project details
    final result = await db.rawQuery('''
      SELECT 
        q.*,
        p.name as project_name,
        p.description as project_description,
        p.address as project_address,
        p.start_date as project_start_date,
        p.end_date as project_end_date
      FROM quotations q
      LEFT OUTER JOIN projects p ON q.project_uuid = p.uuid
      ORDER BY q.id DESC
    ''');
    return result;
  }

  Future<Quotation?> getQuotation(String uuid) async {
    final db = await database;
    final result = await db.query(
      TableNames.quotations,
      where: 'uuid = ?',
      whereArgs: [uuid],
    );
    if (result.isEmpty) return null;
    return Quotation.fromDbMap(result.first);
  }

  Future<int> updateQuotation(Quotation vendor) async {
    final db = await database;
    final result = await db.update(
      TableNames.quotations,
      vendor.toDbMap(),
      where: 'uuid = ?',
      whereArgs: [vendor.uuid],
    );

    // Log change for delta sync
    if (result > 0) {
      await logChange(TableNames.quotations, vendor.uuid, ChangeModes.update);
    }

    return result;
  }

  Future<int> deleteQuotation(String uuid) async {
    final db = await database;

    // Delete related basket vendor items
    await db.delete(TableNames.quotationItems,
        where: 'quotation_uuid = ?', whereArgs: [uuid]);

    final result = await db.delete(
      TableNames.quotations,
      where: 'uuid = ?',
      whereArgs: [uuid],
    );

    // Log change for delta sync
    if (result > 0) {
      await logChange(TableNames.quotations, uuid, ChangeModes.delete);
    }

    return result;
  }

  // Basket Vendor Item CRUD
  Future<int> insertQuotationItem(QuotationItem item) async {
    final db = await database;
    final result = await db.insert(TableNames.quotationItems, item.toDbMap());
    // Log change for delta sync
    await logChange(TableNames.quotationItems, item.uuid, ChangeModes.insert);

    // Update basket vendor totals
    await _updateQuotationTotals(item.quotationUuid);

    return result;
  }

  Future<List<QuotationItem>> getQuotationItems(String quotationUuid) async {
    final db = await database;
    final result = await db.query(
      TableNames.quotationItems,
      where: 'quotation_uuid = ?',
      whereArgs: [quotationUuid],
    );
    return result.map((map) => QuotationItem.fromDbMap(map)).toList();
  }

  Future<QuotationItem?> getQuotationItem(String uuid) async {
    final db = await database;
    final result = await db.query(
      TableNames.quotationItems,
      where: 'uuid = ?',
      whereArgs: [uuid],
    );
    if (result.isEmpty) return null;
    return QuotationItem.fromDbMap(result.first);
  }

  Future<int> updateQuotationItem(QuotationItem item) async {
    final db = await database;
    final result = await db.update(
      TableNames.quotationItems,
      item.toDbMap(),
      where: 'uuid = ?',
      whereArgs: [item.uuid],
    );

    // Log change for delta sync
    if (result > 0) {
      await logChange(TableNames.quotationItems, item.uuid, ChangeModes.update);
      // Update basket vendor totals
      await _updateQuotationTotals(item.quotationUuid);
    }

    return result;
  }

  Future<int> deleteQuotationItem(String uuid) async {
    final db = await database;

    // Get the item to find quotation_uuid
    final item = await getQuotationItem(uuid);
    if (item == null) return 0;

    final result = await db.delete(
      TableNames.quotationItems,
      where: 'uuid = ?',
      whereArgs: [uuid],
    );

    // Log change for delta sync
    if (result > 0) {
      await logChange(TableNames.quotationItems, uuid, ChangeModes.delete);

      // Update basket vendor totals
      await _updateQuotationTotals(item.quotationUuid);
    }

    return result;
  }

  // Helper methods for basket operations
  Future<int> _getNextIdForBasket(String tableName, String basketUuid) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT MAX(id) as max_id FROM $tableName WHERE basket_uuid = ?',
      [basketUuid],
    );
    final maxId = result.first['max_id'] as int?;
    return (maxId ?? 0) + 1;
  }

  Future<void> _updateBasketTotals(String basketUuid) async {
    final db = await database;

    // Get all basket items for this basket
    final items = await getBasketItems(basketUuid);

    // Calculate totals
    double totalPrice = 0.0;
    int numberOfItems = items.length;

    for (var item in items) {
      totalPrice += item.price;
    }

    // Update basket
    await db.update(
      TableNames.baskets,
      {
        'total_price': totalPrice,
        'number_of_items': numberOfItems,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'uuid = ?',
      whereArgs: [basketUuid],
    );
  }

  Future<void> _updateQuotationTotals(String quotationUuid) async {
    final db = await database;

    // Get all basket vendor items for this vendor
    final items = await getQuotationItems(quotationUuid);

    // Calculate totals
    double basePrice = 0.0;
    double taxAmount = 0.0;
    double totalAmount = 0.0;
    int numberOfAvailableItems = 0;
    int numberOfUnavailableItems = 0;

    for (var item in items) {
      basePrice += item.basePrice;
      taxAmount += item.taxAmount;
      totalAmount += item.totalAmount;

      if (item.itemAvailableWithVendor) {
        numberOfAvailableItems++;
      } else {
        numberOfUnavailableItems++;
      }
    }

    // Update basket vendor
    await db.update(
      TableNames.quotations,
      {
        'base_price': basePrice,
        'tax_amount': taxAmount,
        'total_amount': totalAmount,
        'number_of_available_items': numberOfAvailableItems,
        'number_of_unavailable_items': numberOfUnavailableItems,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'uuid = ?',
      whereArgs: [quotationUuid],
    );
  }

  /// Sync vendor items when basket items are added/updated
  Future<void> _syncVendorItemsForBasketItem(
      String basketUuid, BasketItem basketItem, String operation) async {
    // Get all vendor quotations for this basket
    final vendors = await getQuotations(basketUuid);

    for (var vendor in vendors) {
      if (operation == 'insert') {
        // Add new vendor item for this basket item
        await _createVendorItemForBasketItem(vendor, basketItem);
      } else if (operation == 'update') {
        // Update existing vendor item
        await _updateVendorItemForBasketItem(vendor, basketItem);
      }
    }
  }

  /// Create vendor item for a basket item
  Future<void> _createVendorItemForBasketItem(
      Quotation vendor, BasketItem basketItem) async {
    final db = await database;

    // Check if vendor item already exists
    final existing = await db.query(
      TableNames.quotationItems,
      where: 'quotation_uuid = ? AND basket_item_uuid = ?',
      whereArgs: [vendor.uuid, basketItem.uuid],
    );

    if (existing.isNotEmpty) return; // Already exists

    // Get vendor price list for this item
    final vplList = await db.query(
      TableNames.vendorPriceLists,
      where: 'vendor_uuid = ? AND manufacturer_material_uuid = ?',
      whereArgs: [vendor.vendorUuid, basketItem.manufacturerMaterialUuid],
    );

    VendorPriceList? vpl;
    if (vplList.isNotEmpty) {
      vpl = VendorPriceList.fromDbMap(vplList.first);
    }

    // Get next ID for vendor item
    int? nextId =
        await _getNextIdForBasket(TableNames.quotationItems, vendor.basketUuid);

    // Create vendor item
    final item = QuotationItem(
      uuid: const Uuid().v4(),
      id: nextId,
      quotationUuid: vendor.uuid,
      basketUuid: vendor.basketUuid,
      basketItemUuid: basketItem.uuid,
      vendorPriceListUuid: vpl?.uuid,
      itemAvailableWithVendor: vpl != null,
      manufacturerMaterialUuid: basketItem.manufacturerMaterialUuid,
      materialUuid: basketItem.materialUuid,
      model: basketItem.model,
      quantity: basketItem.quantity,
      maxRetailPrice: basketItem.maxRetailPrice,
      rate: vpl?.rate ?? 0.0,
      rateBeforeTax: vpl?.rateBeforeTax ?? 0.0,
      basePrice: vpl != null ? (vpl.rateBeforeTax * basketItem.quantity) : 0.0,
      taxPercent: vpl?.taxPercent ?? 0.0,
      taxAmount: vpl != null
          ? (vpl.rateBeforeTax * basketItem.quantity * vpl.taxPercent / 100.0)
          : 0.0,
      totalAmount: vpl != null ? (vpl.rate * basketItem.quantity) : 0.0,
      currency: vendor.currency,
      updatedAt: DateTime.now(),
    );

    await db.insert(TableNames.quotationItems, item.toDbMap());
    await logChange(TableNames.quotationItems, item.uuid, ChangeModes.insert);

    // Update vendor totals
    await _updateQuotationTotals(vendor.uuid);
  }

  /// Update vendor item when basket item quantity changes
  Future<void> _updateVendorItemForBasketItem(
      Quotation vendor, BasketItem basketItem) async {
    final db = await database;

    // Find existing vendor item
    final existing = await db.query(
      TableNames.quotationItems,
      where: 'quotation_uuid = ? AND basket_item_uuid = ?',
      whereArgs: [vendor.uuid, basketItem.uuid],
    );

    if (existing.isEmpty) {
      // Item doesn't exist yet, create it
      await _createVendorItemForBasketItem(vendor, basketItem);
      return;
    }

    final vendorItem = QuotationItem.fromDbMap(existing.first);

    // Recalculate prices based on new quantity
    final updatedItem = vendorItem.copyWith(
      quantity: basketItem.quantity,
      basePrice: vendorItem.rateBeforeTax * basketItem.quantity,
      taxAmount: vendorItem.rateBeforeTax *
          basketItem.quantity *
          vendorItem.taxPercent /
          100.0,
      totalAmount: vendorItem.rate * basketItem.quantity,
      updatedAt: DateTime.now(),
    );

    await db.update(
      TableNames.quotationItems,
      updatedItem.toDbMap(),
      where: 'uuid = ?',
      whereArgs: [vendorItem.uuid],
    );

    await logChange(
        TableNames.quotationItems, vendorItem.uuid, ChangeModes.update);

    // Update vendor totals
    await _updateQuotationTotals(vendor.uuid);
  }

  /// Get the default currency object from the database
  /// Returns the currency from defaults table, or null if none found
  Future<Currency?> getDefaultCurrencyObject() async {
    final db = await database;

    // First get the default currency name from defaults table
    final defaultResult = await db.query(
      TableNames.defaults,
      where: 'type = ?',
      whereArgs: ['Currency'],
      limit: 1,
    );

    if (defaultResult.isEmpty) {
      return null;
    }

    final currencyName = defaultResult.first['value'] as String;

    // Now get the currency object
    final result = await db.query(
      TableNames.currencies,
      where: 'name = ?',
      whereArgs: [currencyName],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return Currency.fromDbMap(result.first);
    }

    return null;
  }

  /// Get all currencies
  /// Returns a list of all currencies ordered by name
  Future<List<Currency>> getAllCurrencies() async {
    final db = await database;
    final result = await db.query(
      TableNames.currencies,
      orderBy: 'name ASC',
    );

    return result.map((map) => Currency.fromDbMap(map)).toList();
  }

  /// Get the default unit of measure object from the database
  /// Returns the unit from defaults table, or null if none found
  Future<UnitOfMeasure?> getDefaultUnitOfMeasureObject() async {
    final db = await database;

    // First get the default unit name from defaults table
    final defaultResult = await db.query(
      TableNames.defaults,
      where: 'type = ?',
      whereArgs: ['UnitOfMeasure'],
      limit: 1,
    );

    if (defaultResult.isEmpty) {
      return null;
    }

    final unitName = defaultResult.first['value'] as String;

    // Now get the unit object
    final result = await db.query(
      TableNames.unitOfMeasures,
      where: 'name = ?',
      whereArgs: [unitName],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return UnitOfMeasure.fromDbMap(result.first);
    }

    return null;
  }

  /// Get a unit of measure by name
  /// Returns the unit with the specified name, or null if not found
  Future<UnitOfMeasure?> getUnitOfMeasureByName(String name) async {
    if (name.isEmpty) return null;

    final db = await database;
    final result = await db.query(
      TableNames.unitOfMeasures,
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return UnitOfMeasure.fromDbMap(result.first);
    }

    return null;
  }

  /// Get all units of measure
  /// Returns a list of all units of measure ordered by name
  Future<List<UnitOfMeasure>> getAllUnitsOfMeasure() async {
    final db = await database;
    final result = await db.query(
      TableNames.unitOfMeasures,
      orderBy: 'name ASC',
    );

    return result.map((map) => UnitOfMeasure.fromDbMap(map)).toList();
  }

  // Defaults CRUD operations

  /// Get all defaults
  /// Returns a list of all defaults ordered by type
  Future<List<Defaults>> getAllDefaults() async {
    final db = await database;
    final result = await db.query(
      TableNames.defaults,
      orderBy: 'type ASC',
    );

    return result.map((map) => Defaults.fromDbMap(map)).toList();
  }

  /// Get a default by type
  /// Returns the default with the specified type, or null if not found
  Future<Defaults?> getDefaultByType(String type) async {
    if (type.isEmpty) return null;

    final db = await database;
    final result = await db.query(
      TableNames.defaults,
      where: 'type = ?',
      whereArgs: [type],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return Defaults.fromDbMap(result.first);
    }

    return null;
  }

  /// Insert a new default
  /// Returns the number of rows inserted
  Future<int> insertDefault(Defaults defaultItem) async {
    final db = await database;
    return await db.insert(
      TableNames.defaults,
      defaultItem.toDbMap(),
    );
  }

  /// Update an existing default
  /// Returns the number of rows updated
  Future<int> updateDefault(Defaults defaultItem, String oldType) async {
    final db = await database;
    return await db.update(
      TableNames.defaults,
      defaultItem.toDbMap(),
      where: 'type = ?',
      whereArgs: [oldType],
    );
  }

  /// Delete a default by type
  /// Returns the number of rows deleted
  Future<int> deleteDefault(String type) async {
    final db = await database;
    return await db.delete(
      TableNames.defaults,
      where: 'type = ?',
      whereArgs: [type],
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  /// Helper to get the next numeric ID for manual auto-numbering
  Future<int> _getNextId(String tableName) async {
    final db = await database;
    final result =
        await db.rawQuery('SELECT MAX(id) as max_id FROM $tableName');
    final maxId = result.first['max_id'] as int?;
    return (maxId ?? 0) + 1;
  }

  Future<List<String>> getTableColumnNames(String tableName) async {
    final db = await database;
    final result = await db.rawQuery('PRAGMA table_info($tableName)');
    return result.map((column) => column['name'] as String).toList();
  }
}
