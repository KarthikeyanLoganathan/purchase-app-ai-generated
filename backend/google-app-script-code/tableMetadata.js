const DATA_TYPES = Object.freeze({
    UUID: "dc134eea-29d5-4af6-9bcc-e45076770d9a", //different different values to be used for comparison
    TABLE_IDENTIFIER_INDEX: 1, //different different values to be used for comparison
    ID: 2, //different different values to be used for comparison
    INTEGER: 3, //different different values to be used for comparison
    AMOUNT: 4.5, //different different values to be used for comparison
    QUANTITY: 5.5, //different different values to be used for comparison
    DOUBLE: 6.5, //different different values to be used for comparison
    NAME: "NAME", //different different values to be used for comparison
    STRING: "String", //different different values to be used for comparison
    CURRENCY: "Currency", //different different values to be used for comparison
    UNIT_OF_MEASURE: "unit_of_measure", //different different values to be used for comparison
    PERCENT: 0.1, //different different values to be used for comparison
    DESCRIPTION: "Description", //different different values to be used for comparison
    TIME_STAMP: new Date(), //different different values to be used for comparison
    BOOLEAN: true, //different different values to be used for comparison
    CHANGE_MODE: "I", //different different values to be used for comparison
    PHOTO: "photo_uuid", //different different values to be used for comparison
    WEBSITE: "website", //different different values to be used for comparison
    PHONE_NUMBER: "phone_number", //different different values to be used for comparison
    EMAIL_ADDRESS: "email_address", //different different values to be used for comparison
    ADDRESS: "address", //different different values to be used for comparison
    GEO_LOCATION: "geo_location", //different different values to be used for comparison
});

const TABLE_TYPES = Object.freeze({
    METADATA: "METADATA",
    CONFIGURATION_DATA: "CONFIGURATION_DATA",
    MASTER_DATA: "MASTER_DATA",
    TRANSACTION_DATA: "TRANSACTION_DATA",
    LOG: "LOG",
});

const TABLES = Object.freeze({
    unit_of_measures: "unit_of_measures",
    currencies: "currencies",
    manufacturers: "manufacturers",
    vendors: "vendors",
    materials: "materials",
    manufacturer_materials: "manufacturer_materials",
    vendor_price_lists: "vendor_price_lists",
    purchase_orders: "purchase_orders",
    purchase_order_items: "purchase_order_items",
    purchase_order_payments: "purchase_order_payments",
    baskets: "baskets",
    basket_items: "basket_items",
    quotations: "quotations",
    quotation_items: "quotation_items",
    projects: "projects",
    change_log: "change_log",
    condensed_change_log: "condensed_change_log",
});

const _TABLE_INDICES = Object.freeze({
    unit_of_measures: 101,
    currencies: 102,
    manufacturers: 201,
    vendors: 202,
    materials: 203,
    manufacturer_materials: 204,
    vendor_price_lists: 205,
    purchase_orders: 301,
    purchase_order_items: 302,
    purchase_order_payments: 303,
    baskets: 311,
    basket_items: 312,
    quotations: 321,
    quotation_items: 322,
    projects: 251,
});

const _TABLE_DEFINITIONS = Object.freeze({
    unit_of_measures: Object.freeze({
        INDEX: _TABLE_INDICES.unit_of_measures,
        NAME: "unit_of_measures",
        TYPE: TABLE_TYPES.CONFIGURATION_DATA,
        IS_SYNC_DATA_TABLE: true,
        KEY_COLUMN: "name",
        COLUMNS: Object.freeze({
            name: DATA_TYPES.NAME,
            description: DATA_TYPES.DESCRIPTION,
            number_of_decimal_places: DATA_TYPES.INTEGER,
            is_default: DATA_TYPES.BOOLEAN,
            updated_at: DATA_TYPES.TIME_STAMP,
        }),
        LOOKUP_COLUMNS: Object.freeze({}),
        FOREIGN_KEY_RELATIONSHIPS: Object.freeze({}),
    }),
    currencies: Object.freeze({
        INDEX: _TABLE_INDICES.currencies,
        NAME: "currencies",
        TYPE: TABLE_TYPES.CONFIGURATION_DATA,
        IS_SYNC_DATA_TABLE: true,
        KEY_COLUMN: "name",
        COLUMNS: Object.freeze({
            name: DATA_TYPES.NAME,
            description: DATA_TYPES.DESCRIPTION,
            symbol: DATA_TYPES.STRING,
            number_of_decimal_places: DATA_TYPES.INTEGER,
            is_default: DATA_TYPES.BOOLEAN,
            updated_at: DATA_TYPES.TIME_STAMP,
        }),
        LOOKUP_COLUMNS: Object.freeze({}),
        FOREIGN_KEY_RELATIONSHIPS: Object.freeze({}),
    }),
    manufacturers: Object.freeze({
        INDEX: _TABLE_INDICES.manufacturers,
        NAME: "manufacturers",
        TYPE: TABLE_TYPES.MASTER_DATA,
        IS_SYNC_DATA_TABLE: true,
        KEY_COLUMN: "uuid",
        COLUMNS: Object.freeze({
            uuid: DATA_TYPES.UUID,
            id: DATA_TYPES.ID,
            name: DATA_TYPES.NAME,
            description: DATA_TYPES.DESCRIPTION,
            address: DATA_TYPES.ADDRESS,
            phone_number: DATA_TYPES.PHONE_NUMBER,
            email_address: DATA_TYPES.EMAIL_ADDRESS,
            website: DATA_TYPES.WEBSITE,
            updated_at: DATA_TYPES.TIME_STAMP,
            photo_uuid: DATA_TYPES.UUID,
        }),
        LOOKUP_COLUMNS: Object.freeze({}),
        FOREIGN_KEY_RELATIONSHIPS: Object.freeze({}),
    }),
    vendors: Object.freeze({
        INDEX: _TABLE_INDICES.vendors,
        NAME: "vendors",
        TYPE: TABLE_TYPES.MASTER_DATA,
        IS_SYNC_DATA_TABLE: true,
        KEY_COLUMN: "uuid",
        COLUMNS: Object.freeze({
            uuid: DATA_TYPES.UUID,
            id: DATA_TYPES.ID,
            name: DATA_TYPES.NAME,
            description: DATA_TYPES.DESCRIPTION,
            address: DATA_TYPES.ADDRESS,
            geo_location: DATA_TYPES.GEO_LOCATION,
            phone_number: DATA_TYPES.PHONE_NUMBER,
            email_address: DATA_TYPES.EMAIL_ADDRESS,
            website: DATA_TYPES.WEBSITE,
            updated_at: DATA_TYPES.TIME_STAMP,
            photo_uuid: DATA_TYPES.UUID,
        }),
        LOOKUP_COLUMNS: Object.freeze({}),
        FOREIGN_KEY_RELATIONSHIPS: Object.freeze({}),
    }),
    materials: Object.freeze({
        INDEX: _TABLE_INDICES.materials,
        NAME: "materials",
        TYPE: TABLE_TYPES.MASTER_DATA,
        IS_SYNC_DATA_TABLE: true,
        KEY_COLUMN: "uuid",
        COLUMNS: Object.freeze({
            uuid: DATA_TYPES.UUID,
            id: DATA_TYPES.ID,
            name: DATA_TYPES.NAME,
            description: DATA_TYPES.DESCRIPTION,
            unit_of_measure: DATA_TYPES.UNIT_OF_MEASURE,
            website: DATA_TYPES.WEBSITE,
            updated_at: DATA_TYPES.TIME_STAMP,
            photo_uuid: DATA_TYPES.UUID,
        }),
        LOOKUP_COLUMNS: Object.freeze({}),
        FOREIGN_KEY_RELATIONSHIPS: Object.freeze({
            unit_of_measure: Object.freeze({
                unit_of_measures: "name",
            }),
        }),
    }),
    manufacturer_materials: Object.freeze({
        INDEX: _TABLE_INDICES.manufacturer_materials,
        NAME: "manufacturer_materials",
        TYPE: TABLE_TYPES.MASTER_DATA,
        IS_SYNC_DATA_TABLE: true,
        KEY_COLUMN: "uuid",
        COLUMNS: Object.freeze({
            uuid: DATA_TYPES.UUID,
            manufacturer_uuid: DATA_TYPES.UUID,
            material_uuid: DATA_TYPES.UUID,
            model: DATA_TYPES.STRING,
            selling_lot_size: DATA_TYPES.QUANTITY,
            max_retail_price: DATA_TYPES.AMOUNT,
            currency: DATA_TYPES.CURRENCY,
            website: DATA_TYPES.WEBSITE,
            part_number: DATA_TYPES.STRING,
            updated_at: DATA_TYPES.TIME_STAMP,
            photo_uuid: DATA_TYPES.UUID,
        }),
        LOOKUP_COLUMNS: Object.freeze({
            manufacturer_uuid: Object.freeze({
                manufacturer_name: "name"
            }),
            material_uuid: Object.freeze({
                material_name: "name",
                unit_of_measure: "unit_of_measure"
            }),
        }),
        FOREIGN_KEY_RELATIONSHIPS: Object.freeze({
            currency: Object.freeze({
                currencies: "name",
            }),
            manufacturer_uuid: Object.freeze({
                manufacturers: "uuid"
            }),
            material_uuid: Object.freeze({
                materials: "uuid"
            }),
        }),
    }),
    vendor_price_lists: Object.freeze({
        INDEX: _TABLE_INDICES.vendor_price_lists,
        NAME: "vendor_price_lists",
        TYPE: TABLE_TYPES.MASTER_DATA,
        IS_SYNC_DATA_TABLE: true,
        KEY_COLUMN: "uuid",
        COLUMNS: Object.freeze({
            uuid: DATA_TYPES.UUID,
            manufacturer_material_uuid: DATA_TYPES.UUID,
            vendor_uuid: DATA_TYPES.UUID,
            rate: DATA_TYPES.AMOUNT,
            rate_before_tax: DATA_TYPES.AMOUNT,
            tax_amount: DATA_TYPES.DOUBLE,
            tax_percent: DATA_TYPES.PERCENT,
            currency: DATA_TYPES.CURRENCY,
            updated_at: DATA_TYPES.TIME_STAMP,
        }),
        LOOKUP_COLUMNS: Object.freeze({
            vendor_uuid: Object.freeze({
                vendor_name: "name"
            }),
            manufacturer_material_uuid: Object.freeze({
                manufacturer_name: "manufacturer_name",
                material_name: "material_name",
                model: "model",
                selling_lot_size: "selling_lot_size",
                max_retail_price: "max_retail_price",
                unit_of_measure: "unit_of_measure",
            }),
        }),
        FOREIGN_KEY_RELATIONSHIPS: Object.freeze({
            manufacturer_material_uuid: Object.freeze({
                manufacturer_materials: "uuid",
            }),
            vendor_uuid: Object.freeze({
                vendors: "uuid"
            }),
            currency: Object.freeze({
                currencies: "name",
            }),
        }),
    }),
    purchase_orders: Object.freeze({
        INDEX: _TABLE_INDICES.purchase_orders,
        NAME: "purchase_orders",
        TYPE: TABLE_TYPES.TRANSACTION_DATA,
        IS_SYNC_DATA_TABLE: true,
        KEY_COLUMN: "uuid",
        COLUMNS: Object.freeze({
            uuid: DATA_TYPES.UUID,
            id: DATA_TYPES.ID,
            vendor_uuid: DATA_TYPES.UUID,
            date: DATA_TYPES.TIME_STAMP,
            base_price: DATA_TYPES.AMOUNT,
            tax_amount: DATA_TYPES.AMOUNT,
            total_amount: DATA_TYPES.AMOUNT,
            currency: DATA_TYPES.CURRENCY,
            order_date: DATA_TYPES.TIME_STAMP,
            expected_delivery_date: DATA_TYPES.TIME_STAMP,
            amount_paid: DATA_TYPES.AMOUNT,
            amount_balance: DATA_TYPES.AMOUNT,
            completed: DATA_TYPES.BOOLEAN,
            basket_uuid: DATA_TYPES.UUID,
            quotation_uuid: DATA_TYPES.UUID,
            project_uuid: DATA_TYPES.UUID,
            description: DATA_TYPES.DESCRIPTION,
            delivery_address: DATA_TYPES.ADDRESS,
            phone_number: DATA_TYPES.PHONE_NUMBER,
            updated_at: DATA_TYPES.TIME_STAMP,
        }),
        LOOKUP_COLUMNS: Object.freeze({
            vendor_uuid: Object.freeze({
                vendor_name: "name"
            }),
        }),
        FOREIGN_KEY_RELATIONSHIPS: Object.freeze({
            vendor_uuid: Object.freeze({
                vendors: "uuid"
            }),
            basket_uuid: Object.freeze({
                baskets: "uuid"
            }),
            quotation_uuid: Object.freeze({
                quotations: "uuid"
            }),
            project_uuid: Object.freeze({
                projects: "uuid"
            }),
            currency: Object.freeze({
                currencies: "name",
            }),
        }),
    }),
    purchase_order_items: Object.freeze({
        INDEX: _TABLE_INDICES.purchase_order_items,
        NAME: "purchase_order_items",
        TYPE: TABLE_TYPES.TRANSACTION_DATA,
        IS_SYNC_DATA_TABLE: true,
        KEY_COLUMN: "uuid",
        COLUMNS: Object.freeze({
            uuid: DATA_TYPES.UUID,
            purchase_order_uuid: DATA_TYPES.UUID,
            manufacturer_material_uuid: DATA_TYPES.UUID,
            material_uuid: DATA_TYPES.UUID,
            model: DATA_TYPES.STRING,
            quantity: DATA_TYPES.QUANTITY,
            rate: DATA_TYPES.AMOUNT,
            rate_before_tax: DATA_TYPES.AMOUNT,
            base_price: DATA_TYPES.AMOUNT,
            tax_percent: DATA_TYPES.PERCENT,
            tax_amount: DATA_TYPES.AMOUNT,
            total_amount: DATA_TYPES.AMOUNT,
            currency: DATA_TYPES.CURRENCY,
            basket_item_uuid: DATA_TYPES.UUID,
            quotation_item_uuid: DATA_TYPES.UUID,
            unit_of_measure: DATA_TYPES.STRING,
            updated_at: DATA_TYPES.TIME_STAMP,
        }),
        LOOKUP_COLUMNS: Object.freeze({
            material_uuid: Object.freeze({
                material_name: "name"
            }),
            manufacturer_material_uuid: Object.freeze({
                manufacturer_name: "manufacturer_name",
                selling_lot_size: "selling_lot_size",
                max_retail_price: "max_retail_price",
            }),
        }),
        FOREIGN_KEY_RELATIONSHIPS: Object.freeze({
            purchase_order_uuid: Object.freeze({
                purchase_orders: "uuid"
            }),
            manufacturer_material_uuid: Object.freeze({
                manufacturer_materials: "uuid",
            }),
            material_uuid: Object.freeze({
                materials: "uuid"
            }),
            basket_item_uuid: Object.freeze({
                basket_items: "uuid"
            }),
            quotation_item_uuid: Object.freeze({
                quotation_items: "uuid"
            }),
            unit_of_measure: Object.freeze({
                unit_of_measures: "name",
            }),
            currency: Object.freeze({
                currencies: "name",
            }),
        }),
    }),
    purchase_order_payments: Object.freeze({
        INDEX: _TABLE_INDICES.purchase_order_payments,
        NAME: "purchase_order_payments",
        TYPE: TABLE_TYPES.TRANSACTION_DATA,
        IS_SYNC_DATA_TABLE: true,
        KEY_COLUMN: "uuid",
        COLUMNS: Object.freeze({
            uuid: DATA_TYPES.UUID,
            purchase_order_uuid: DATA_TYPES.UUID,
            date: DATA_TYPES.TIME_STAMP,
            amount: DATA_TYPES.AMOUNT,
            currency: DATA_TYPES.CURRENCY,
            upi_ref_number: DATA_TYPES.STRING,
            updated_at: DATA_TYPES.TIME_STAMP,
        }),
        LOOKUP_COLUMNS: Object.freeze({}),
        FOREIGN_KEY_RELATIONSHIPS: Object.freeze({
            purchase_order_uuid: Object.freeze({
                purchase_orders: "uuid"
            }),
            currency: Object.freeze({
                currencies: "name",
            }),
        }),
    }),
    baskets: Object.freeze({
        INDEX: _TABLE_INDICES.baskets,
        NAME: "baskets",
        TYPE: TABLE_TYPES.TRANSACTION_DATA,
        IS_SYNC_DATA_TABLE: true,
        KEY_COLUMN: "uuid",
        COLUMNS: Object.freeze({
            uuid: DATA_TYPES.UUID,
            id: DATA_TYPES.ID,
            date: DATA_TYPES.TIME_STAMP,
            description: DATA_TYPES.DESCRIPTION,
            expected_delivery_date: DATA_TYPES.TIME_STAMP,
            total_price: DATA_TYPES.AMOUNT,
            currency: DATA_TYPES.CURRENCY,
            number_of_items: DATA_TYPES.INTEGER,
            project_uuid: DATA_TYPES.UUID,
            delivery_address: DATA_TYPES.ADDRESS,
            phone_number: DATA_TYPES.PHONE_NUMBER,
            updated_at: DATA_TYPES.TIME_STAMP,
        }),
        LOOKUP_COLUMNS: Object.freeze({}),
        FOREIGN_KEY_RELATIONSHIPS: Object.freeze({
            project_uuid: Object.freeze({
                projects: "uuid"
            }),
            currency: Object.freeze({
                currencies: "name",
            }),
        }),
    }),
    basket_items: Object.freeze({
        INDEX: _TABLE_INDICES.basket_items,
        NAME: "basket_items",
        TYPE: TABLE_TYPES.TRANSACTION_DATA,
        IS_SYNC_DATA_TABLE: true,
        KEY_COLUMN: "uuid",
        COLUMNS: Object.freeze({
            uuid: DATA_TYPES.UUID,
            basket_uuid: DATA_TYPES.UUID,
            id: DATA_TYPES.ID,
            manufacturer_material_uuid: DATA_TYPES.UUID,
            material_uuid: DATA_TYPES.UUID,
            model: DATA_TYPES.STRING,
            manufacturer_uuid: DATA_TYPES.UUID,
            quantity: DATA_TYPES.QUANTITY,
            unit_of_measure: DATA_TYPES.STRING,
            max_retail_price: DATA_TYPES.AMOUNT,
            price: DATA_TYPES.AMOUNT,
            currency: DATA_TYPES.CURRENCY,
            updated_at: DATA_TYPES.TIME_STAMP,
        }),
        LOOKUP_COLUMNS: Object.freeze({
            manufacturer_uuid: Object.freeze({
                manufacturer_name: "name"
            }),
            material_uuid: Object.freeze({
                material_name: "name"
            }),
            manufacturer_material_uuid: Object.freeze({
                selling_lot_size: "selling_lot_size",
            }),
        }),
        FOREIGN_KEY_RELATIONSHIPS: Object.freeze({
            basket_uuid: Object.freeze({
                baskets: "uuid"
            }),
            manufacturer_material_uuid: Object.freeze({
                manufacturer_materials: "uuid",
            }),
            material_uuid: Object.freeze({
                materials: "uuid"
            }),
            manufacturer_uuid: Object.freeze({
                manufacturers: "uuid"
            }),
            unit_of_measure: Object.freeze({
                unit_of_measures: "name",
            }),
            currency: Object.freeze({
                currencies: "name",
            }),
        }),
    }),
    quotations: Object.freeze({
        INDEX: _TABLE_INDICES.quotations,
        NAME: "quotations",
        TYPE: TABLE_TYPES.TRANSACTION_DATA,
        IS_SYNC_DATA_TABLE: true,
        KEY_COLUMN: "uuid",
        COLUMNS: Object.freeze({
            uuid: DATA_TYPES.UUID,
            id: DATA_TYPES.ID,
            basket_uuid: DATA_TYPES.UUID,
            vendor_uuid: DATA_TYPES.UUID,
            date: DATA_TYPES.TIME_STAMP,
            expected_delivery_date: DATA_TYPES.TIME_STAMP,
            base_price: DATA_TYPES.AMOUNT,
            tax_amount: DATA_TYPES.AMOUNT,
            total_amount: DATA_TYPES.AMOUNT,
            currency: DATA_TYPES.CURRENCY,
            number_of_available_items: DATA_TYPES.INTEGER,
            number_of_unavailable_items: DATA_TYPES.INTEGER,
            project_uuid: DATA_TYPES.UUID,
            description: DATA_TYPES.DESCRIPTION,
            updated_at: DATA_TYPES.TIME_STAMP,
        }),
        LOOKUP_COLUMNS: Object.freeze({
            vendor_uuid: Object.freeze({
                vendor_name: "name"
            }),
        }),
        FOREIGN_KEY_RELATIONSHIPS: Object.freeze({
            basket_uuid: Object.freeze({
                baskets: "uuid"
            }),
            vendor_uuid: Object.freeze({
                vendors: "uuid"
            }),
            project_uuid: Object.freeze({
                projects: "uuid"
            }),
            currency: Object.freeze({
                currencies: "name",
            }),
        }),
    }),
    quotation_items: Object.freeze({
        INDEX: _TABLE_INDICES.quotation_items,
        NAME: "quotation_items",
        TYPE: TABLE_TYPES.TRANSACTION_DATA,
        IS_SYNC_DATA_TABLE: true,
        KEY_COLUMN: "uuid",
        COLUMNS: Object.freeze({
            uuid: DATA_TYPES.UUID,
            id: DATA_TYPES.ID,
            quotation_uuid: DATA_TYPES.UUID,
            basket_uuid: DATA_TYPES.UUID,
            basket_item_uuid: DATA_TYPES.UUID,
            vendor_price_list_uuid: DATA_TYPES.UUID,
            item_available_with_vendor: DATA_TYPES.BOOLEAN,
            manufacturer_material_uuid: DATA_TYPES.UUID,
            material_uuid: DATA_TYPES.UUID,
            model: DATA_TYPES.STRING,
            quantity: DATA_TYPES.QUANTITY,
            max_retail_price: DATA_TYPES.AMOUNT,
            rate: DATA_TYPES.AMOUNT,
            rate_before_tax: DATA_TYPES.AMOUNT,
            base_price: DATA_TYPES.AMOUNT,
            tax_percent: DATA_TYPES.PERCENT,
            tax_amount: DATA_TYPES.AMOUNT,
            total_amount: DATA_TYPES.AMOUNT,
            currency: DATA_TYPES.CURRENCY,
            unit_of_measure: DATA_TYPES.STRING,
            updated_at: DATA_TYPES.TIME_STAMP,
        }),
        LOOKUP_COLUMNS: Object.freeze({
            material_uuid: Object.freeze({
                material_name: "name"
            }),
            manufacturer_material_uuid: Object.freeze({
                selling_lot_size: "selling_lot_size",
                manufacturer_name: "manufacturer_name"
            }),
            vendor_price_list_uuid: Object.freeze({
                vendor_name: "vendor_name",
            }),
        }),
        FOREIGN_KEY_RELATIONSHIPS: Object.freeze({
            quotation_uuid: Object.freeze({
                quotations: "uuid"
            }),
            basket_uuid: Object.freeze({
                baskets: "uuid"
            }),
            basket_item_uuid: Object.freeze({
                basket_items: "uuid"
            }),
            vendor_price_list_uuid: Object.freeze({
                vendor_price_lists: "uuid"
            }),
            manufacturer_material_uuid: Object.freeze({
                manufacturer_materials: "uuid",
            }),
            material_uuid: Object.freeze({
                materials: "uuid"
            }),
            unit_of_measure: Object.freeze({
                unit_of_measures: "name",
            }),
            currency: Object.freeze({
                currencies: "name",
            }),
        }),
    }),
    projects: Object.freeze({
        INDEX: _TABLE_INDICES.projects,
        NAME: "projects",
        TYPE: TABLE_TYPES.MASTER_DATA,
        IS_SYNC_DATA_TABLE: true,
        KEY_COLUMN: "uuid",
        COLUMNS: Object.freeze({
            uuid: DATA_TYPES.UUID,
            name: DATA_TYPES.NAME,
            description: DATA_TYPES.DESCRIPTION,
            address: DATA_TYPES.STRING,
            phone_number: DATA_TYPES.STRING,
            geo_location: DATA_TYPES.STRING,
            start_date: DATA_TYPES.TIME_STAMP,
            end_date: DATA_TYPES.TIME_STAMP,
            completed: DATA_TYPES.BOOLEAN,
            updated_at: DATA_TYPES.TIME_STAMP,
        }),
        LOOKUP_COLUMNS: Object.freeze({}),
        FOREIGN_KEY_RELATIONSHIPS: Object.freeze({}),
    }),
    change_log: Object.freeze({
        INDEX: -1,
        NAME: "change_log",
        TYPE: TABLE_TYPES.LOG,
        IS_SYNC_DATA_TABLE: false,
        KEY_COLUMN: "uuid",
        COLUMNS: Object.freeze({
            uuid: DATA_TYPES.UUID,
            table_index: DATA_TYPES.TABLE_IDENTIFIER_INDEX,
            table_key: DATA_TYPES.STRING,
            change_mode: DATA_TYPES.CHANGE_MODE,
            updated_at: DATA_TYPES.TIME_STAMP,
        }),
        LOOKUP_COLUMNS: Object.freeze({}),
        FOREIGN_KEY_RELATIONSHIPS: Object.freeze({}),
    }),
    condensed_change_log: Object.freeze({
        INDEX: -2,
        NAME: "condensed_change_log",
        TYPE: TABLE_TYPES.LOG,
        IS_SYNC_DATA_TABLE: false,
        KEY_COLUMN: "uuid",
        COLUMNS: Object.freeze({
            uuid: DATA_TYPES.UUID,
            table_index: DATA_TYPES.TABLE_IDENTIFIER_INDEX,
            table_key: DATA_TYPES.STRING,
            change_mode: DATA_TYPES.CHANGE_MODE,
            updated_at: DATA_TYPES.TIME_STAMP,
        }),
        LOOKUP_COLUMNS: Object.freeze({}),
        FOREIGN_KEY_RELATIONSHIPS: Object.freeze({}),
    }),
});

class TableDefinition {
    constructor(definition) {
        this._definition = definition;
        this._index = definition.INDEX;
        let columnIndices = {};
        let colIndex = 0;
        let foreignKeyColumnNames = [];
        let foreignKeyRelations = {};
        let lookupColumnCount = 0
        const lookupColumns = {};
        for (const colName of Object.keys(definition.COLUMNS)) {
            columnIndices[colName] = colIndex;
            colIndex++;
        }
        for (const [sourceCol, foreignKeyTableColumn] of Object.entries(definition.FOREIGN_KEY_RELATIONSHIPS)) {
            foreignKeyColumnNames.push(sourceCol);
            for (const [foreignKeyTable, foreignKeyColumn] of Object.entries(foreignKeyTableColumn)) {
                let foreignKeyDef = Object.freeze({
                    table: foreignKeyTable,
                    column: foreignKeyColumn
                });
                if (foreignKeyRelations[sourceCol]) {
                    throw new Error(`Multiple foreign key relationships defined for source column '${sourceCol}' in table definition for table '${definition.NAME}'. Each foreign key column can reference only one table.column pair.`);
                }
                foreignKeyRelations[sourceCol] = foreignKeyDef;
            }
        }
        for (const [sourceCol, targetCols] of Object.entries(definition.LOOKUP_COLUMNS)) {
            for (const [lookupColumnName, targetColumnName] of Object.entries(targetCols)) {
                const lookupColumnDef = Object.freeze({
                    sourceForeignKeyColumn: sourceCol,
                    lookupColumnName: lookupColumnName,
                    targetColumn: targetColumnName,
                });
                if (lookupColumns[lookupColumnName]) {
                    throw new Error(`Duplicate lookup column name '${lookupColumnName}' found in table definition for table '${definition.NAME}'. Each lookup column name must be unique across all lookup columns.`);
                }
                lookupColumns[lookupColumnName] = lookupColumnDef;
                lookupColumnCount++;
            }
        }
        this._isSyncDataTable = Boolean(definition.IS_SYNC_DATA_TABLE);
        this._columnIndices = Object.freeze(columnIndices);
        this._columnNames = Object.freeze(Object.keys(this._definition.COLUMNS));
        this._columnIndices = Object.freeze(columnIndices);
        this._foreignKeyColumnNames = Object.freeze(foreignKeyColumnNames);
        this._foreignKeyRelations = Object.freeze(foreignKeyRelations);
        this._lookupColumnNames = Object.keys(Object.freeze(lookupColumns));
        this._lookupColumnDefinitions = Object.freeze(lookupColumns);
        this._totalColumnCount = this._columnNames.length + this._lookupColumnNames.length;
    }

    /**
     * @returns {number} 
     */
    get index() {
        return this._index;
    }

    /**
     * @returns {string} 
     */
    get name() {
        return this._definition.NAME;
    }

    /**
     * @returns {string} 
     */
    get type() {
        return this._definition.TYPE;
    }

    /**
     * @returns {boolean} 
     */
    get isSyncDataTable() {
        return this._isSyncDataTable;
    }

    /**
     * @returns {string} 
     */
    get keyColumn() {
        return this._definition.KEY_COLUMN;
    }

    /**
     * @returns {Object.<string, number>} 
     */
    get columnTypes() {
        return this._definition.COLUMNS;
    }

    /**
     * Gets the data type for a specific column
     * @param {string} columnName - The name of the column
     * @returns {string|number|Date|boolean|undefined} The data type value from DATA_TYPES, or undefined if column doesn't exist
     */
    getColumnType(columnName) {
        return this._definition.COLUMNS?.[columnName];
    }

    /**
     * Helper to identify if a column should be treated as a date
     * @param {string} columnName - The name of the column
     * @returns {boolean|undefined} 
     */
    isDateColumn(columnName) {
        return this.getColumnType(columnName) === DATA_TYPES.TIME_STAMP;
    }

    /**
     * @returns {ReadonlyArray<string>} 
     */
    get columnNames() {
        return this._columnNames;
    }

    /**
     * @returns {number} 
     */
    get columnCount() {
        return this._columnNames.length;
    }

    /**
     * @returns number 
     */
    get lookupColumnCount() {
        return this._lookupColumnNames.length;
    }

    /**
     * @returns number 
     */
    get totalColumnCount() {
        return this._totalColumnCount;
    }

    /**
     * @returns {Object.<string, number>} Object mapping column names to their indices (0-based)
     */
    get columnIndices() {
        return this._columnIndices;
    }

    /**
     * @returns {number|undefined} 
     */
    getColumnIndex(columnName) {
        return this._columnIndices?.[columnName];
    }

    /**
     * @returns {ReadonlyArray<string>} 
     */
    get foreignKeyColumnNames() {
        return this._foreignKeyColumnNames;
    }

    /**
     * @param {string} sourceForeignKeyColumnName
     * @returns {{table: string, column: string}|undefined}
     */
    getForeignKeyRelation(sourceForeignKeyColumnName) {
        return this._foreignKeyRelations?.[sourceForeignKeyColumnName];
    }

    /**
     * @returns {ReadonlyArray<string>} 
     */
    get lookupColumnNames() {
        return this._lookupColumnNames;
    }

    /**
     * Retrieves the definition of a lookup column by its name.
     * 
     * @param {string} lookupColumnName - The name of the lookup column to retrieve
     * @returns {{sourceForeignKeyColumn: string, lookupColumnName: string, targetColumn: string}|undefined} 
     * The lookup column definition object containing:
     * - sourceForeignKeyColumn: The foreign key column name in the current table that references another table
     * - lookupColumnName: The name of the computed lookup column
     * - targetColumn: The column name in the foreign table to retrieve the value from
     * Returns undefined if lookup column not found
     */
    getLookupColumnDefinition(lookupColumnName) {
        return this._lookupColumnDefinitions?.[lookupColumnName];
    }
}

class TableDefinitions {
    // _definitionsMap;
    // _definitionsByIndexMap;
    // _syncRelevantTableNames;

    /**
     * @param {Object} _INPUT_TABLE_DEFINITIONS_
     */
    constructor(_INPUT_TABLE_DEFINITIONS_) {
        let definitionsMap = {};
        let definitionsByIndexMap = {};
        let syncRelevantTableNames = [];
        let tableNames = [];
        for (const [tableName, def] of Object.entries(_INPUT_TABLE_DEFINITIONS_)) {
            let tableDef = new TableDefinition(def);
            definitionsMap[tableName] = tableDef;
            definitionsByIndexMap[def.INDEX] = tableDef;
            if (tableDef.isSyncDataTable) {
                syncRelevantTableNames.push(tableName);
            }
            tableNames.push(tableName);
        }
        this._definitionsMap = Object.freeze(definitionsMap);
        this._definitionsByIndexMap = Object.freeze(definitionsByIndexMap);
        this._syncRelevantTableNames = Object.freeze(syncRelevantTableNames);
        this._tableNames = Object.freeze(tableNames);
    }

    /**
     * @param {string} tableName
     * @returns {TableDefinition}
     */
    getByName(tableName) {
        return this._definitionsMap?.[tableName];
    }

    /**
     * @param {number} tableIndex
     * @returns {TableDefinition}
     */
    getByIndex(tableIndex) {
        return this._definitionsByIndexMap?.[tableIndex];
    }

    /**
     * @param {string} tableName
     * @returns {number}
     */
    getTableIndexByName(tableName) {
        const tableDef = this.getByName(tableName);
        return tableDef?.index;
    }

    /**
     * @param {number} tableIndex
     * @returns {string}
     */
    getTableNameByIndex(tableIndex) {
        const tableDef = this.getByIndex(tableIndex);
        return tableDef?.name;
    }

    /**
     * @returns {ReadonlyArray<string>} 
     */
    get syncRelevantTableNames() {
        return this._syncRelevantTableNames;
    }

    /**
     * @returns {ReadonlyArray<string>} 
     */
    get tableNames() {
        return this._tableNames;
    }
}

const tableDefinitions = Object.freeze(new TableDefinitions(_TABLE_DEFINITIONS));