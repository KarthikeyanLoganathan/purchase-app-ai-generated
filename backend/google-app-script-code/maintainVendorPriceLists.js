/**
 * Vendor Price List Maintenance Functions
 */
const maintainVendorPriceLists = {
    LAYOUT: Object.freeze({
        SHEET: "MaintainVendorPrices",
        TITLE_ROW: 1,

        INPUT_VENDOR_ROW: 2,
        INPUT_VENDOR_LABEL_COLUMN: 1,
        INPUT_VENDOR_COLUMN: 2,

        INPUT_MANUFACTURER_ROW: 3,
        INPUT_MANUFACTURER_LABEL_COLUMN: 1,
        INPUT_MANUFACTURER_COLUMN: 2,

        INPUT_MATERIAL_ROW: 4,
        INPUT_MATERIAL_LABEL_COLUMN: 1,
        INPUT_MATERIAL_COLUMN: 2,

        BUTTONS_ROW: 5,
        PREPARE_LABEL_COLUMN: 1,
        PREPARE_CHECKBOX_COLUMN: 2,
        SAVE_LABEL_COLUMN: 3,
        SAVE_CHECKBOX_COLUMN: 4,
        CLEAR_LABEL_COLUMN: 5,
        CLEAR_CHECKBOX_COLUMN: 6,
        BUTTONS_ROW_LAST_COLLUMN: 6,

        HEADER_ROW: 6,
        DATA_START_ROW: 7,
        LAST_DATA_INPUT_COLLUMN: 4,
        MAX_COLUMNS: 12,
        //Data Collumn Indexes
        RATE_COLUMN: 1,
        TAX_PERCENT_COLUMN: 2,
        RATE_BEFORE_TAX_COLUMN: 3,
        TAX_COLUMN: 4,
        MRP_COLUMN: 5,
        LOT_SIZE_COLUMN: 6,
        VENDOR_COLUMN: 7,
        MATERIAL_COLUMN: 8,
        MANIUFACTURER_COLUMN: 9,
        MODEL_COLUMN: 10,
        UNIT_COLUMN: 11,
        CURRENCY_COLUMN: 12
    }),

    /**
     * Setup Manufacturer Material Models Input Sheet
     * Creates a utility sheet for maintaining manufacturer materials in a matrix format
     */
    setupSheet() {
        const layout = this.LAYOUT;
        const ss = SpreadsheetApp.getActiveSpreadsheet();

        // Delete existing sheet if it exists
        let sheet = ss.getSheetByName(layout.SHEET);
        if (sheet) {
            sheet.getDataRange().clearContent().clearFormat().clearDataValidations();
            this.clearData();
        } else {
            // Create new sheet
            sheet = ss.insertSheet(layout.SHEET);
        }

        // Delete columns beyond column 6 if they exist
        const maxCols = sheet.getMaxColumns();
        if (maxCols > layout.MAX_COLUMNS) {
            sheet.deleteColumns(
                layout.MAX_COLUMNS + 1,
                maxCols - layout.MAX_COLUMNS);
        }

        // Set up title row (merged cells)
        sheet.getRange(layout.TITLE_ROW, 1, 1, 5).merge();
        sheet.getRange(layout.TITLE_ROW, 1)
            .setValue("Maintain Manufacturer Materials Model Data")
            .setFontSize(12)
            .setFontWeight("bold")
            .setHorizontalAlignment("center")
            .setBackground("#4285F4")
            .setFontColor("#FFFFFF");

        sheet.getRange(layout.TITLE_ROW, 6).setValue("Create Buttons manually if you regenerated this sheet")

        // Row: Vendor label and dropdown
        sheet.getRange(layout.INPUT_VENDOR_ROW,
            layout.INPUT_VENDOR_LABEL_COLUMN)
            .setValue("Vendor")
            .setFontSize(10)
            .setFontWeight("bold");

        // Set up data validation for vendor dropdown
        utils.createDataValidationForGivenRange(
            sheet.getRange(layout.INPUT_VENDOR_ROW,
                layout.INPUT_VENDOR_COLUMN),
            TABLES.vendors,
            "name",
            2);

        // Row: Manufacturer label and dropdown
        sheet.getRange(layout.INPUT_MANUFACTURER_ROW,
            layout.INPUT_MANUFACTURER_LABEL_COLUMN)
            .setValue("Manufacturer")
            .setFontSize(10)
            .setFontWeight("bold");

        // Set up data validation for manufacturer dropdown
        utils.createDataValidationForGivenRange(
            sheet.getRange(layout.INPUT_MANUFACTURER_ROW,
                layout.INPUT_MANUFACTURER_COLUMN),
            TABLES.manufacturers,
            "name",
            2);

        // Row: Materials label and dropdown
        sheet.getRange(layout.INPUT_MATERIAL_ROW,
            layout.INPUT_MATERIAL_LABEL_COLUMN)
            .setValue("Material")
            .setFontSize(10)
            .setFontWeight("bold");

        // Set up data validation for manufacturer dropdown
        utils.createDataValidationForGivenRange(
            sheet.getRange(layout.INPUT_MATERIAL_ROW,
                layout.INPUT_MATERIAL_COLUMN),
            TABLES.materials,
            "name",
            2);

        // Row: Create clickable checkbox buttons
        // Clear any existing buttons in row
        sheet.getRange(layout.BUTTONS_ROW, 1, 1, 6).clearContent().clearFormat();

        // Create "Prepare" button using checkbox (cell 3,1)
        sheet.getRange(layout.BUTTONS_ROW,
            layout.PREPARE_LABEL_COLUMN)
            .setValue("⚡ Prepare")
            .setFontWeight("bold")
            .setFontSize(10)
            .setBackground("#34A853")
            .setFontColor("#FFFFFF")
            .setHorizontalAlignment("center")
            .setVerticalAlignment("middle")
            .setBorder(true, true, true, true, false, false, "#2D7D3E", SpreadsheetApp.BorderStyle.SOLID_MEDIUM);

        // Insert checkbox in Prepare
        const prepareCheckbox = sheet.getRange(layout.BUTTONS_ROW,
            layout.PREPARE_CHECKBOX_COLUMN);
        prepareCheckbox
            .insertCheckboxes()
            .setBackground("#34A853")
            .setHorizontalAlignment("center")
            .setVerticalAlignment("middle")
            .setBorder(true, true, true, true, false, false, "#2D7D3E", SpreadsheetApp.BorderStyle.SOLID_MEDIUM);
        prepareCheckbox.setNote("Check this box to prepare data");

        // Create "Save" button using checkbox (cell 3,3)
        sheet.getRange(layout.BUTTONS_ROW,
            layout.SAVE_LABEL_COLUMN)
            .setValue("💾 Save")
            .setFontWeight("bold")
            .setFontSize(10)
            .setBackground("#EA4335")
            .setFontColor("#FFFFFF")
            .setHorizontalAlignment("center")
            .setVerticalAlignment("middle")
            .setBorder(true, true, true, true, false, false, "#C5341F", SpreadsheetApp.BorderStyle.SOLID_MEDIUM);

        // Insert checkbox in cell 3,4 for Save
        const saveCheckbox = sheet.getRange(layout.BUTTONS_ROW,
            layout.SAVE_CHECKBOX_COLUMN);
        saveCheckbox
            .insertCheckboxes()
            .setBackground("#EA4335")
            .setHorizontalAlignment("center")
            .setVerticalAlignment("middle")
            .setBorder(true, true, true, true, false, false, "#C5341F", SpreadsheetApp.BorderStyle.SOLID_MEDIUM);
        saveCheckbox.setNote("Check this box to save changes");

        // Create "Clear" button using checkbox (cell 3,5)
        sheet.getRange(layout.BUTTONS_ROW,
            layout.CLEAR_LABEL_COLUMN)
            .setValue("🗑️ Clear")
            .setFontWeight("bold")
            .setFontSize(10)
            .setBackground("#FBBC04")
            .setFontColor("#000000")
            .setHorizontalAlignment("center")
            .setVerticalAlignment("middle")
            .setBorder(true, true, true, true, false, false, "#F9AB00", SpreadsheetApp.BorderStyle.SOLID_MEDIUM);

        // Insert checkbox in cell 3,6 for Clear
        const clearCheckbox = sheet.getRange(layout.BUTTONS_ROW,
            layout.CLEAR_CHECKBOX_COLUMN);
        clearCheckbox.insertCheckboxes();
        clearCheckbox
            .setBackground("#FBBC04")
            .setHorizontalAlignment("center")
            .setVerticalAlignment("middle")
            .setBorder(true, true, true, true, false, false, "#F9AB00", SpreadsheetApp.BorderStyle.SOLID_MEDIUM);
        clearCheckbox.setNote("Check this box to clear all data below row 4");

        // Set row height for better button appearance
        sheet.setRowHeight(layout.BUTTONS_ROW, 35);

        sheet.getRange(layout.HEADER_ROW,
            layout.RATE_COLUMN)
            .setValue("Rate")
            .setFontSize(10)
            .setFontWeight("bold")
            .setBackground("#4285F4")
            .setFontColor("#FFFFFF");
        sheet.getRange(layout.HEADER_ROW,
            layout.TAX_PERCENT_COLUMN)
            .setValue("Tax %")
            .setFontSize(10)
            .setFontWeight("bold")
            .setBackground("#4285F4")
            .setFontColor("#FFFFFF");
        sheet.getRange(layout.HEADER_ROW,
            layout.RATE_BEFORE_TAX_COLUMN)
            .setValue("RateBeforeTax")
            .setFontSize(10)
            .setFontWeight("bold")
            .setBackground("#4285F4")
            .setFontColor("#FFFFFF");
        sheet.getRange(layout.HEADER_ROW,
            layout.TAX_COLUMN)
            .setValue("Tax")
            .setFontSize(10)
            .setFontWeight("bold")
            .setBackground("#4285F4")
            .setFontColor("#FFFFFF");
        sheet.getRange(layout.HEADER_ROW,
            layout.MRP_COLUMN)
            .setValue("MRP")
            .setFontSize(10)
            .setFontWeight("bold")
            .setBackground("#4285F4")
            .setFontColor("#FFFFFF");
        sheet.getRange(layout.HEADER_ROW,
            layout.LOT_SIZE_COLUMN)
            .setValue("Lot Size")
            .setFontSize(10)
            .setFontWeight("bold")
            .setBackground("#4285F4")
            .setFontColor("#FFFFFF");
        sheet.getRange(layout.HEADER_ROW,
            layout.VENDOR_COLUMN)
            .setValue("Vendor")
            .setFontSize(10)
            .setFontWeight("bold")
            .setBackground("#4285F4")
            .setFontColor("#FFFFFF");
        sheet.getRange(layout.HEADER_ROW,
            layout.MATERIAL_COLUMN)
            .setValue("Material")
            .setFontSize(10)
            .setFontWeight("bold")
            .setBackground("#4285F4")
            .setFontColor("#FFFFFF");
        sheet.getRange(layout.HEADER_ROW,
            layout.MANIUFACTURER_COLUMN)
            .setValue("Manufacturer")
            .setFontSize(10)
            .setFontWeight("bold")
            .setBackground("#4285F4")
            .setFontColor("#FFFFFF");
        sheet.getRange(layout.HEADER_ROW,
            layout.MODEL_COLUMN)
            .setValue("Model")
            .setFontSize(10)
            .setFontWeight("bold")
            .setBackground("#4285F4")
            .setFontColor("#FFFFFF");
        sheet.getRange(layout.HEADER_ROW,
            layout.UNIT_COLUMN)
            .setValue("Unit")
            .setFontSize(10)
            .setFontWeight("bold")
            .setBackground("#4285F4")
            .setFontColor("#FFFFFF");
        sheet.getRange(layout.HEADER_ROW,
            layout.CURRENCY_COLUMN)
            .setValue("Currency")
            .setFontSize(10)
            .setFontWeight("bold")
            .setBackground("#4285F4")
            .setFontColor("#FFFFFF");

        // Freeze rows and set column  widths
        sheet.setFrozenRows(layout.HEADER_ROW);
        sheet.setColumnWidth(1, 100);

        Logger.log("Vendor Price List Input Sheet created successfully");
        const execContext = utils.getExecutionContext();
        if (execContext.canShowToast) {
            SpreadsheetApp.getActiveSpreadsheet().toast("Sheet created! Select a vendor and check the '⚡ Prepare Data' checkbox.");
        }

        return "Vendor Price List Input Sheet created";
    },

    /**
     * Clear vendor price list data
     * Clears data from the maintenance sheet
     */
    clearData() {
        const layout = this.LAYOUT;
        const ss = SpreadsheetApp.getActiveSpreadsheet();
        const sheet = ss.getSheetByName(layout.SHEET);

        if (!sheet) {
            throw new Error(`${layout.SHEET} sheet not found.`);
        }

        utils.removeProtectionsFromSheet(sheet);
        const deletedRows = utils.deleteRowsFromSheetGivenStartRow(sheet, layout.DATA_START_ROW);

        const execContext = utils.getExecutionContext();
        if (execContext.canShowToast) {
            if (deletedRows !== undefined) {
                ss.toast(`Cleared ${deletedRows} row(s)`, 'Data Cleared', 3);
            } else {
                ss.toast('No data to clear', 'Clear', 2);
            }
        }
    },

    protectSheet() {
        const layout = this.LAYOUT;
        const ss = SpreadsheetApp.getActiveSpreadsheet();
        const sheet = ss.getSheetByName(layout.SHEET);

        if (!sheet) {
            throw new Error(`${layout.SHEET} sheet not found.`);
        }

        const maxRows = sheet.getMaxRows();
        const maxCols = sheet.getMaxColumns();

        // Remove any existing protections first
        utils.removeProtectionsFromSheet(sheet);

        // Protect specific ranges that should be READ-ONLY
        const protectedRanges = [];

        // Title row (entire row)
        protectedRanges.push(sheet.getRange(layout.TITLE_ROW, 1, 1, maxCols));

        protectedRanges.push(sheet.getRange(layout.INPUT_MANUFACTURER_ROW,
            layout.INPUT_MANUFACTURER_LABEL_COLUMN, 1, 1));
        protectedRanges.push(sheet.getRange(layout.INPUT_VENDOR_ROW,
            layout.INPUT_VENDOR_LABEL_COLUMN, 1, 1));
        protectedRanges.push(sheet.getRange(layout.INPUT_MATERIAL_ROW,
            layout.INPUT_MATERIAL_LABEL_COLUMN, 1, 1));
        if (maxCols >= (layout.INPUT_MANUFACTURER_COLUMN + 1)) {
            protectedRanges.push(
                sheet.getRange(layout.INPUT_MANUFACTURER_ROW,
                    (layout.INPUT_MANUFACTURER_COLUMN + 1), 1,
                    maxCols - layout.INPUT_MANUFACTURER_COLUMN));
            protectedRanges.push(
                sheet.getRange(layout.INPUT_VENDOR_ROW,
                    (layout.INPUT_VENDOR_COLUMN + 1), 1,
                    maxCols - layout.INPUT_VENDOR_COLUMN));
            protectedRanges.push(
                sheet.getRange(layout.INPUT_MATERIAL_ROW,
                    (layout.INPUT_MATERIAL_COLUMN + 1), 1,
                    maxCols - layout.INPUT_MATERIAL_COLUMN));
        }

        protectedRanges.push(sheet.getRange(layout.BUTTONS_ROW,
            layout.PREPARE_LABEL_COLUMN, 1, 1));
        protectedRanges.push(sheet.getRange(layout.BUTTONS_ROW,
            layout.SAVE_LABEL_COLUMN, 1, 1));
        protectedRanges.push(sheet.getRange(layout.BUTTONS_ROW,
            layout.CLEAR_LABEL_COLUMN, 1, 1));
        if (maxCols >= (layout.BUTTONS_ROW_LAST_COLLUMN + 1)) {
            protectedRanges.push(sheet.getRange(layout.BUTTONS_ROW,
                (layout.BUTTONS_ROW_LAST_COLLUMN + 1), 1,
                maxCols - layout.BUTTONS_ROW_LAST_COLLUMN));
        }

        // Row - Header row (entire row)
        protectedRanges.push(sheet.getRange(layout.HEADER_ROW, 1, 1, maxCols));

        // Data onwards, Columns C onwards - Material, Model, Unit, Currency (read-only)
        if (maxRows >= layout.DATA_START_ROW &&
            maxCols >= layout.LAST_DATA_INPUT_COLLUMN) {
            protectedRanges.push(sheet.getRange(
                layout.DATA_START_ROW,
                layout.LAST_DATA_INPUT_COLLUMN + 1,
                maxRows - layout.DATA_START_ROW + 1,
                maxCols - layout.LAST_DATA_INPUT_COLLUMN));
        }

        // Apply protection to each range
        protectedRanges.forEach((range, index) => {
            const protection = range.protect().setDescription(`Protected area ${index + 1} (read-only)`);
            protection.setWarningOnly(true); // Show warning instead of blocking (for owner compatibility)
        });
    },

    /**
     * Prepare vendor price list data
     * Populates the sheet with existing vendor price data
     */
    prepareInputData() {
        const layout = this.LAYOUT;
        const ss = SpreadsheetApp.getActiveSpreadsheet();
        const sheet = ss.getSheetByName(layout.SHEET);
        const execContext = utils.getExecutionContext();

        if (!sheet) {
            throw new Error(`${layout.SHEET} sheet not found. Run setupManufacturerMaterialModelsInputSheet() first.`);
        }
        this.clearData();

        const vendorName = sheet.getRange(layout.INPUT_VENDOR_ROW, layout.INPUT_VENDOR_COLUMN).getValue();
        const manufacturerName = sheet.getRange(layout.INPUT_MANUFACTURER_ROW, layout.INPUT_MANUFACTURER_COLUMN).getValue();
        const materialName = sheet.getRange(layout.INPUT_MATERIAL_ROW, layout.INPUT_MATERIAL_COLUMN).getValue();
        if (!(vendorName || manufacturerName || materialName)) {
            if (execContext.canShowToast) {
                SpreadsheetApp.getActiveSpreadsheet().toast("Please select a vendor / material / manufacturer first!");
            }
            return;
        }

        const manufacturers = dataReaders.readManufacturers({
            name: manufacturerName
        });
        const manufacturerUuid = manufacturers.nameMap[manufacturerName]?.uuid;
        const vendors = dataReaders.readVendors({
            name: vendorName
        });
        const vendorUuid = vendors.nameMap[vendorName]?.uuid;
        const materials = dataReaders.readMaterials({
            name: materialName
        });
        const materialUuid = materials.nameMap[materialName]?.uuid;
        if (!(vendorUuid || manufacturerUuid || materialUuid)) {
            if (execContext.canShowToast) {
                SpreadsheetApp.getActiveSpreadsheet().toast("Please select a vendor / material / manufacturer first!");
            }
            return;
        }
        const manufacturerMaterials = dataReaders.readManufacturerMaterials(
            manufacturers,
            materials,
            {
                manufacturer_uuid: manufacturerUuid,
                material_uuid: materialUuid
            }
        );
        const vendorPriceList = dataReaders.readVendorPriceList(
            manufacturers,
            materials,
            vendors,
            manufacturerMaterials,
            {
                vendor_uuid: vendorUuid,
                manufacturer_uuid: manufacturerUuid,
                material_uuid: materialUuid
            }
        );
        const defaultCurrency = ss.getRangeByName(DEFAULT_CURRENCY_NAMED_RANGE).getValue() || "INR";

        // Populate the matrix - build 2D array first for efficient batch write
        const matrixData = [];
        for (let i = 0; i < manufacturerMaterials.list.length; i++) {
            const mm = manufacturerMaterials.list[i];
            for (let j = 0; j < vendors.list.length; j++) {
                let vp = null;
                const v = vendors.list[j];
                const vEntry = vendorPriceList.map?.[v.uuid];
                if (vEntry) {
                    const manEntry = vEntry?.[mm.manufacturer.uuid];
                    if (manEntry) {
                        const matEntry = manEntry?.[mm.material.uuid];
                        if (matEntry) {
                            vp = matEntry[mm.model];
                        }
                    }
                }
                if (!vp) {
                    vp = {
                        uuid: '11111111-1111-1111-1111-111111111111',
                        manufacturer_material_uuid: mm.uuid,
                        vendor_uuid: v.uuid,
                        rate: 0,
                        rate_before_tax: 0,
                        currency: defaultCurrency,
                        tax_percent: 0,
                        tax_amount: 0,
                        updated_at: null,

                        manufacturer_material: mm,
                        vendor: v,
                        material: mm.material,
                        manufacturer: mm.manufacturer,
                    };
                }
                // RATE_COLUMN: 1,
                // TAX_PERCENT_COLUMN: 2,
                // RATE_BEFORE_TAX_COLUMN: 3,
                // TAX_COLUMN: 4,
                // MRP_COLUMN: 5,
                // LOT_SIZE_COLUMN: 6,
                // VENDOR_COLUMN: 7,
                // MATERIAL_COLUMN: 8,
                // MANIUFACTURER_COLUMN: 9,
                // MODEL_COLUMN: 10,
                // UNIT_COLUMN: 11,
                // CURRENCY_COLUMN: 12        
                const row = new Array(layout.MAX_COLUMNS).fill("");
                row[layout.RATE_COLUMN - 1] = vp.rate || 1.0;
                row[layout.TAX_PERCENT_COLUMN - 1] = vp.tax_percent || 0;
                row[layout.RATE_BEFORE_TAX_COLUMN - 1] = vp.rate_before_tax || 0;
                row[layout.TAX_COLUMN - 1] = vp.tax_amount || 0;
                row[layout.MRP_COLUMN - 1] = vp.manufacturer_material.max_retail_price || 0;
                row[layout.LOT_SIZE_COLUMN - 1] = vp.manufacturer_material.selling_lot_size || 0;
                row[layout.VENDOR_COLUMN - 1] = vp.vendor?.name || "";
                row[layout.MATERIAL_COLUMN - 1] = vp.material?.name || "";
                row[layout.MANIUFACTURER_COLUMN - 1] = vp.manufacturer_material.manufacturer?.name || "";
                row[layout.MODEL_COLUMN - 1] = vp.manufacturer_material.model || "";
                row[layout.UNIT_COLUMN - 1] = vp.material?.unit_of_measure || "";
                row[layout.CURRENCY_COLUMN - 1] = vp.currency || defaultCurrency;
                matrixData.push(row);
            }
        }

        // Write all data in one operation
        if (matrixData.length > 0) {
            sheet.getRange(layout.DATA_START_ROW, 1, matrixData.length, layout.MAX_COLUMNS)
                .setValues(matrixData);
        }

        this.protectSheet();
        Logger.log("Vendor Price List data prepared successfully");
        if (execContext.canShowToast) {
            SpreadsheetApp.getActiveSpreadsheet().toast("Data prepared! Edit models as needed, then check the '💾 Save Data' checkbox.");
        }
    },
    /**
     * Maintain vendor price list data
     * Processes the sheet and updates the vendor_price_lists table
     */
    saveData() {
        const layout = this.LAYOUT;
        const ss = SpreadsheetApp.getActiveSpreadsheet();
        const sheet = ss.getSheetByName(layout.SHEET);
        const execContext = utils.getExecutionContext();

        if (!sheet) {
            throw new Error(`${layout.SHEET} sheet not found. Run setupManufacturerMaterialModelsInputSheet() first.`);
        }
        const vendorName = sheet.getRange(layout.INPUT_VENDOR_ROW, layout.INPUT_VENDOR_COLUMN).getValue();
        const manufacturerName = sheet.getRange(layout.INPUT_MANUFACTURER_ROW, layout.INPUT_MANUFACTURER_COLUMN).getValue();
        const materialName = sheet.getRange(layout.INPUT_MATERIAL_ROW, layout.INPUT_MATERIAL_COLUMN).getValue();
        if (!(vendorName || manufacturerName || materialName)) {
            if (execContext.canShowToast) {
                SpreadsheetApp.getActiveSpreadsheet().toast("Please select a vendor / material / manufacturer first!");
            }
            return;
        }

        const manufacturers = dataReaders.readManufacturers({
            name: manufacturerName
        });
        const manufacturerUuid = manufacturers.nameMap[manufacturerName]?.uuid;
        const vendors = dataReaders.readVendors({
            name: vendorName
        });
        const vendorUuid = vendors.nameMap[vendorName]?.uuid;
        const materials = dataReaders.readMaterials({
            name: materialName
        });
        const materialUuid = materials.nameMap[materialName]?.uuid;
        if (!(vendorUuid || manufacturerUuid || materialUuid)) {
            if (execContext.canShowToast) {
                SpreadsheetApp.getActiveSpreadsheet().toast("Please select a vendor / material / manufacturer first!");
            }
            return;
        }
        const manufacturerMaterials = dataReaders.readManufacturerMaterials(
            manufacturers,
            materials,
            {
                manufacturer_uuid: manufacturerUuid,
                material_uuid: materialUuid
            }
        );
        const vendorPriceList = dataReaders.readVendorPriceList(
            manufacturers,
            materials,
            vendors,
            manufacturerMaterials,
            {
                vendor_uuid: vendorUuid,
                manufacturer_uuid: manufacturerUuid,
                material_uuid: materialUuid
            }
        );
        const defaultCurrency = ss.getRangeByName(DEFAULT_CURRENCY_NAMED_RANGE).getValue() || "INR";

        // Process sheet data - read all data in one batch for performance
        const newEntries = [];
        const updatedEntries = [];
        let invalidEntriesCount = 0;
        const lastRow = sheet.getLastRow();
        const currentTime = new Date();

        // Read all data at once instead of cell by cell
        if (lastRow >= layout.DATA_START_ROW) {
            const numRows = lastRow - layout.DATA_START_ROW + 1;
            const sheetData = sheet.getRange(layout.DATA_START_ROW, 1, numRows, layout.MAX_COLUMNS).getValues();

            for (let i = 0; i < sheetData.length; i++) {
                const row = sheetData[i];
                const materialName = row[layout.MATERIAL_COLUMN - 1];
                const manufacturerName = row[layout.MANIUFACTURER_COLUMN - 1];
                const modelName = row[layout.MODEL_COLUMN - 1];
                const vendorName = row[layout.VENDOR_COLUMN - 1];
                const materialId = materials.nameMap?.[materialName]?.uuid;
                const manufacturerId = manufacturers.nameMap?.[manufacturerName]?.uuid;
                const vendorId = vendors.nameMap?.[vendorName]?.uuid;
                const mm = manufacturerMaterials.map?.[manufacturerId]?.[materialId]?.[modelName];
                const oldRec = vendorPriceList.map?.[vendorId]?.[manufacturerId]?.[materialId]?.[modelName];

                if (!(vendorId && manufacturerId && materialId && modelName && mm)) {
                    invalidEntriesCount++;
                    continue;
                }

                const rec = {
                    uuid: oldRec?.uuid,
                    manufacturer_material_uuid: mm.uuid,
                    vendor_uuid: vendorId,
                    rate: Number(row[layout.RATE_COLUMN - 1] || 0),
                    rate_before_tax: Number(row[layout.RATE_BEFORE_TAX_COLUMN - 1] || 0),
                    currency: row[layout.CURRENCY_COLUMN - 1] || defaultCurrency,
                    tax_percent: Number(row[layout.TAX_PERCENT_COLUMN - 1] || 0),
                    tax_amount: Number(row[layout.TAX_COLUMN - 1] || 0),
                    updated_at: null,
                };
                if (oldRec.rate === rec.rate
                    && oldRec.rate_before_tax === rec.rate_before_tax
                    && oldRec.tax_percent === rec.tax_percent
                    && oldRec.tax_amount === rec.tax_amount
                    && oldRec.currency === rec.currency
                ) {
                    continue;
                }
                if (rec.uuid) {
                    rec.updated_at = currentTime;
                    updatedEntries.push(rec);
                } else {
                    rec.uuid = utils.UUID();
                    newEntries.push(rec);
                    rec.updated_at = currentTime;
                }
            }
        }

        if (updatedEntries.length > 0) {
            Logger.log(`Upserting ${updatedEntries.length} records to ${TABLES.vendor_price_lists}`);
            const upserted = deltaSync.upsertRecords(TABLES.vendor_price_lists, updatedEntries);
            // Log changes
            changeLog.logChanges(TABLES.vendor_price_lists, updatedEntries.map(rec => rec.uuid), CHANGE_MODE_UPDATE, currentTime);
        }
        if (newEntries.length > 0) {
            Logger.log(`Upserting ${newEntries.length} records to ${TABLES.vendor_price_lists}`);
            const upserted = deltaSync.upsertRecords(TABLES.vendor_price_lists, newEntries);
            // Log changes
            changeLog.logChanges(TABLES.vendor_price_lists, newEntries.map(rec => rec.uuid), CHANGE_MODE_INSERT, currentTime);
        }

        // Apply formatting and resize
        setup.setupDataTableSheet(TABLES.vendor_price_lists, false);

        if (execContext.canShowToast) {
            SpreadsheetApp.getActiveSpreadsheet().toast(
                `Maintenance complete!\nInserted: ${newEntries.length}\nUpdated: ${updatedEntries.length}\nInvalid: ${invalidEntriesCount}`
            );
        }

        return `Inserted: ${newEntries.length}, Updated: ${updatedEntries.length}, Invalid: ${invalidEntriesCount}`;
    },
    onEdit(range) {
        const row = range.getRow();
        const col = range.getColumn();

        // Check if "Prepare" checkbox (row 3, col 2) was checked
        if (row === maintainVendorPriceLists.LAYOUT.BUTTONS_ROW && col === maintainVendorPriceLists.LAYOUT.PREPARE_CHECKBOX_COLUMN) {
            const value = range.getValue();
            if (value === true) {
                // Uncheck immediately
                range.setValue(false);
                // Call prepare function
                this.prepareInputData();
            }
        }
        // Check if "Save" checkbox (row 3, col 4) was checked
        else if (row === maintainVendorPriceLists.LAYOUT.BUTTONS_ROW && col === maintainVendorPriceLists.LAYOUT.SAVE_CHECKBOX_COLUMN) {
            const value = range.getValue();
            if (value === true) {
                // Uncheck immediately
                range.setValue(false);
                // Call save function
                this.saveData();
            }
        }
        // Check if "Clear" checkbox (row 3, col 6) was checked
        else if (row === maintainVendorPriceLists.LAYOUT.BUTTONS_ROW && col === maintainVendorPriceLists.LAYOUT.CLEAR_CHECKBOX_COLUMN) {
            const value = range.getValue();
            if (value === true) {
                // Uncheck immediately
                range.setValue(false);
                // Call clear function
                this.clearData();
            }
        } else if (row >= maintainVendorPriceLists.LAYOUT.DATA_START_ROW) {
            // If edit is in data area, trigger recalculation of dependent fields
            this.calculateTaxes(range);
        }
    },
    calculateTaxes(range) {
        const row = range.getRow();
        if (row < maintainVendorPriceLists.LAYOUT.DATA_START_ROW) return;

        const layout = this.LAYOUT;
        const col = range.getColumn();
        const sheet = range.getSheet();

        // If Rate Before Tax (B) was edited
        if (col === layout.RATE_BEFORE_TAX_COLUMN) {
            const rateBeforeTax = sheet.getRange(row, layout.RATE_BEFORE_TAX_COLUMN).getValue();
            const taxPercent = sheet.getRange(row, layout.TAX_PERCENT_COLUMN).getValue();

            const tax = utils.roundToDigits(rateBeforeTax * taxPercent / 100.0, 2);
            const rate = utils.roundToDigits(rateBeforeTax + tax, 2);

            sheet.getRange(row, layout.TAX_COLUMN).setValue(tax);
            sheet.getRange(row, layout.RATE_COLUMN).setValue(rate);
        } else if (col === layout.RATE_COLUMN) {
            const rate = sheet.getRange(row, layout.RATE_COLUMN).getValue();
            const taxPercent = sheet.getRange(row, layout.TAX_PERCENT_COLUMN).getValue();

            const rateBeforeTax = utils.roundToDigits(rate / (1 + taxPercent / 100.0), 2);
            const tax = utils.roundToDigits(rateBeforeTax * taxPercent / 100.0, 2);

            sheet.getRange(row, layout.RATE_BEFORE_TAX_COLUMN).setValue(rateBeforeTax);
            sheet.getRange(row, layout.TAX_COLUMN).setValue(tax);
        } else if (col === layout.TAX_PERCENT_COLUMN) {
            const rateBeforeTax = sheet.getRange(row, layout.RATE_BEFORE_TAX_COLUMN).getValue();
            const taxPercent = sheet.getRange(row, layout.TAX_PERCENT_COLUMN).getValue();

            const tax = utils.roundToDigits(rateBeforeTax * taxPercent / 100.0, 2);
            const rate = utils.roundToDigits(rateBeforeTax + tax, 2);

            sheet.getRange(row, layout.TAX_COLUMN).setValue(tax);
            sheet.getRange(row, layout.RATE_COLUMN).setValue(rate);
        }
    }
};

function maintainVendorPriceListsPrepareInputData() {
    return maintainVendorPriceLists.prepareInputData();
}
function maintainVendorPriceListsClearData() {
    return maintainVendorPriceLists.clearData();
}
function maintainVendorPriceListsSaveData() {
    return maintainVendorPriceLists.saveData();
}
