const maintainManufacturerModelData = {
    LAYOUT: Object.freeze({
        SHEET: "MaintainManufacturerMaterialModelData",
        TITLE_ROW: 1,

        INPUT_MANUFACTURER_ROW: 2,
        INPUT_MANUFACTURER_LABEL_COLUMN: 1,
        INPUT_MANUFACTURER_COLUMN: 2,

        BUTTONS_ROW: 3,
        PREPARE_LABEL_COLUMN: 1,
        PREPARE_CHECKBOX_COLUMN: 2,
        SAVE_LABEL_COLUMN: 3,
        SAVE_CHECKBOX_COLUMN: 4,
        CLEAR_LABEL_COLUMN: 5,
        CLEAR_CHECKBOX_COLUMN: 6,
        BUTTONS_ROW_LAST_COLLUMN: 6,

        HEADER_ROW: 4,
        DATA_START_ROW: 5,
        LAST_DATA_INPUT_COLLUMN: 2,
        MAX_COLUMNS: 6,
        //Data Collumn Indexes
        MRP_COLUMN: 1,
        LOT_SIZE_COLUMN: 2,
        MATERIAL_COLUMN: 3,
        MODEL_COLUMN: 4,
        UNIT_COLUMN: 5,
        CURRENCY_COLUMN: 6
    }),

    /**
     * Setup Manufacturer Material Models Sheet
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

        // Row 2: Manufacturer label and dropdown
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

        // Row 3: Create clickable checkbox buttons
        // Clear any existing buttons in row 3
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

        // Insert checkbox in cell 3,2 for Prepare
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

        // Row 4: Column headers
        sheet.getRange(layout.HEADER_ROW,
            layout.MRP_COLUMN)
            .setValue("MRP")
            .setFontSize(10)
            .setFontWeight("bold")
            .setBackground("#4285F4")
            .setFontColor("#FFFFFF");

        // Row 4: Column headers
        sheet.getRange(layout.HEADER_ROW,
            layout.LOT_SIZE_COLUMN)
            .setValue("Lot Size")
            .setFontSize(10)
            .setFontWeight("bold")
            .setBackground("#4285F4")
            .setFontColor("#FFFFFF");

        // Row 4: Column headers
        sheet.getRange(layout.HEADER_ROW,
            layout.MATERIAL_COLUMN)
            .setValue("Material")
            .setFontSize(10)
            .setFontWeight("bold")
            .setBackground("#4285F4")
            .setFontColor("#FFFFFF");

        // Row 4: Column headers
        sheet.getRange(layout.HEADER_ROW,
            layout.MODEL_COLUMN)
            .setValue("Model")
            .setFontSize(10)
            .setFontWeight("bold")
            .setBackground("#4285F4")
            .setFontColor("#FFFFFF");

        // Row 4: Column headers
        sheet.getRange(layout.HEADER_ROW,
            layout.UNIT_COLUMN)
            .setValue("Unit")
            .setFontSize(10)
            .setFontWeight("bold")
            .setBackground("#4285F4")
            .setFontColor("#FFFFFF");

        // Row 4: Column headers
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

        Logger.log("Manufacturer Material Data Input Sheet created successfully");
        const execContext = utils.getExecutionContext();
        if (execContext.canShowToast) {
            SpreadsheetApp.getActiveSpreadsheet().toast("Sheet created! Select a manufacturer and check the '⚡ Prepare Data' checkbox.");
        }

        return "Manufacturer Material Data Input Sheet created";
    },

    /**
     * Clear data from row 5 onwards in the Manufacturer Material Model Data Input Sheet
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

    /**
     * Prepare manufacturer material model data input data
     * Populates the matrix with existing materials and models
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
        // Get selected manufacturer
        const manufacturerName = sheet.getRange(layout.INPUT_MANUFACTURER_ROW, layout.INPUT_MANUFACTURER_COLUMN).getValue();
        if (!manufacturerName) {
            if (execContext.canShowToast) {
                SpreadsheetApp.getActiveSpreadsheet().toast("Please select a manufacturer first!");
            }
            return;
        }

        const manufacturers = dataReaders.readManufacturers({
            name: manufacturerName
        });
        const manufacturerUuid = manufacturers.nameMap[manufacturerName]?.uuid;
        if (!manufacturerUuid) {
            if (execContext.canShowToast) {
                SpreadsheetApp.getActiveSpreadsheet().toast("Manufacturer not found!");
            }
            return;
        }

        const materials = dataReaders.readMaterials();

        const manufacturerMaterials = dataReaders.readManufacturerMaterials(
            manufacturers,
            materials,
            {
                manufacturer_uuid: manufacturerUuid
            }
        );

        const defaultCurrency = ss.getRangeByName(DEFAULT_CURRENCY_NAMED_RANGE).getValue() || "INR";

        // Populate the matrix - build 2D array first for efficient batch write
        const matrixData = [];
        for (let i = 0; i < manufacturerMaterials.list.length; i++) {
            const mm = manufacturerMaterials.list[i];
            const row = new Array(layout.MAX_COLUMNS).fill("");
            row[layout.MRP_COLUMN - 1] = mm.max_retail_price || 1.0;
            row[layout.LOT_SIZE_COLUMN - 1] = mm.selling_lot_size || 1;
            row[layout.MATERIAL_COLUMN - 1] = mm.material?.name || "";
            row[layout.MODEL_COLUMN - 1] = mm.model || "";
            row[layout.UNIT_COLUMN - 1] = mm.material?.unit_of_measure || "";
            row[layout.CURRENCY_COLUMN - 1] = mm.currency || defaultCurrency;
            matrixData.push(row);
        }

        // Write all data in one operation
        if (matrixData.length > 0) {
            sheet.getRange(layout.DATA_START_ROW, 1, matrixData.length, layout.MAX_COLUMNS)
                .setValues(matrixData);
        }

        this.protectSheet();
        Logger.log("Manufacturer material input data prepared successfully");
        if (execContext.canShowToast) {
            SpreadsheetApp.getActiveSpreadsheet().toast("Data prepared! Edit models as needed, then check the '💾 Save Data' checkbox.");
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

        // Column 1 - Manufacturer label
        protectedRanges.push(sheet.getRange(layout.INPUT_MANUFACTURER_ROW,
            layout.INPUT_MANUFACTURER_LABEL_COLUMN, 1, 1));
        // Row 2, Columns 3+ - Extra columns
        if (maxCols >= (layout.INPUT_MANUFACTURER_COLUMN + 1)) {
            protectedRanges.push(
                sheet.getRange(layout.INPUT_MANUFACTURER_ROW,
                    (layout.INPUT_MANUFACTURER_COLUMN + 1), 1,
                    maxCols - layout.INPUT_MANUFACTURER_COLUMN));
        }

        // Row 3, Columns 1, 3, 5 - Button labels (not checkboxes)
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

        // Row 4 - Header row (entire row)
        protectedRanges.push(sheet.getRange(layout.HEADER_ROW, 1, 1, maxCols));

        // Rows 5 onwards, Columns C onwards - Material, Model, Unit, Currency (read-only)
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
     * Maintain manufacturer material models
     * Processes the matrix and updates the manufacturer_materials sheet
     */
    saveData() {
        const layout = this.LAYOUT;
        const ss = SpreadsheetApp.getActiveSpreadsheet();
        const inputSheet = ss.getSheetByName(layout.SHEET);
        const mmSheet = ss.getSheetByName(TABLES.manufacturer_materials);
        const execContext = utils.getExecutionContext();

        if (!inputSheet) {
            throw new Error(`${layout.SHEET} sheet not found.`);
        }

        // Get selected manufacturer
        const manufacturerName = inputSheet.getRange(2, 2).getValue();
        if (!manufacturerName) {
            if (execContext.canShowToast) {
                SpreadsheetApp.getActiveSpreadsheet().toast("Please select a manufacturer first!");
            }
            return;
        }

        const manufacturers = dataReaders.readManufacturers({
            name: manufacturerName
        });
        const manufacturerUuid = manufacturers.nameMap[manufacturerName]?.uuid;
        if (!manufacturerUuid) {
            if (execContext.canShowToast) {
                SpreadsheetApp.getActiveSpreadsheet().toast("Manufacturer not found!");
            }
            return;
        }

        const materials = dataReaders.readMaterials();

        const manufacturerMaterials = dataReaders.readManufacturerMaterials(
            manufacturers,
            materials,
            {
                manufacturer_uuid: manufacturerUuid
            }
        );

        const defaultCurrency = ss.getRangeByName(DEFAULT_CURRENCY_NAMED_RANGE).getValue() || "INR";

        // Process sheet data - read all data in one batch for performance
        const entries = [];
        let invalidEntriesCount = 0;
        const lastRow = inputSheet.getLastRow();
        const currentTime = new Date();

        // Read all data at once instead of cell by cell
        if (lastRow >= layout.DATA_START_ROW) {
            const numRows = lastRow - layout.DATA_START_ROW + 1;
            const sheetData = inputSheet.getRange(layout.DATA_START_ROW, 1, numRows, layout.MAX_COLUMNS).getValues();

            for (let i = 0; i < sheetData.length; i++) {
                const row = sheetData[i];
                const materialName = row[layout.MATERIAL_COLUMN - 1];
                const modelName = row[layout.MODEL_COLUMN - 1];
                const materialUuid = materials.nameMap?.[materialName]?.uuid;
                const oldRec = manufacturerMaterials.map?.[manufacturerUuid]?.[materialUuid]?.[modelName];

                if (!(materialName && modelName && materialUuid && oldRec)) {
                    invalidEntriesCount++;
                    continue;
                }

                const rec = {
                    max_retail_price: Number(row[layout.MRP_COLUMN - 1]),
                    selling_lot_size: Number(row[layout.LOT_SIZE_COLUMN - 1]),
                    currency: row[layout.CURRENCY_COLUMN - 1] || defaultCurrency,
                    uuid: oldRec.uuid,
                    updated_at: currentTime,

                    manufacturer_uuid: manufacturerUuid,
                    material_uuid: materialUuid,
                    model: modelName,

                    material_name: materialName,
                    manufacturer_name: manufacturerName
                };

                if (oldRec.max_retail_price === rec.max_retail_price
                    && oldRec.selling_lot_size === rec.selling_lot_size) {
                    continue;
                }
                entries.push(rec);
            }
        }

        if (entries.length > 0) {
            Logger.log(`Upserting ${entries.length} records to ${TABLES.manufacturer_materials}`);
            const upserted = deltaSync.upsertRecords(TABLES.manufacturer_materials, entries);
            // Log changes
            changeLog.logChanges(TABLES.manufacturer_materials, entries.map(rec => rec.uuid), CHANGE_MODE_UPDATE, currentTime);
        }

        // Apply formatting and resize
        setup.setupDataTableSheet(TABLES.manufacturer_materials, false);

        if (execContext.canShowToast) {
            SpreadsheetApp.getActiveSpreadsheet().toast(
                `Maintenance complete!\nUpdated: ${entries.length}\nInvalid: ${invalidEntriesCount}`
            );
        }

        return `Updated: ${entries.length}, Invalid: ${invalidEntriesCount}`;
    },
    onEdit(range) {
        const row = range.getRow();
        const col = range.getColumn();

        // Check if "Prepare" checkbox (row 3, col 2) was checked
        if (row === maintainManufacturerModelData.LAYOUT.BUTTONS_ROW && col === maintainManufacturerModelData.LAYOUT.PREPARE_CHECKBOX_COLUMN) {
            const value = range.getValue();
            if (value === true) {
                // Uncheck immediately
                range.setValue(false);
                // Call prepare function
                this.prepareInputData();
            }
        }
        // Check if "Save" checkbox (row 3, col 4) was checked
        else if (row === maintainManufacturerModelData.LAYOUT.BUTTONS_ROW && col === maintainManufacturerModelData.LAYOUT.SAVE_CHECKBOX_COLUMN) {
            const value = range.getValue();
            if (value === true) {
                // Uncheck immediately
                range.setValue(false);
                // Call save function
                this.saveData();
            }
        }
        // Check if "Clear" checkbox (row 3, col 6) was checked
        else if (row === maintainManufacturerModelData.LAYOUT.BUTTONS_ROW && col === maintainManufacturerModelData.LAYOUT.CLEAR_CHECKBOX_COLUMN) {
            const value = range.getValue();
            if (value === true) {
                // Uncheck immediately
                range.setValue(false);
                // Call clear function
                this.clearData();
            }
        }
    }
};

function maintainManufacturerModelDataPrepareInputData() {
    return maintainManufacturerModelData.prepareInputData();
}
function maintainManufacturerModelDataClearData() {
    return maintainManufacturerModelData.clearData();
}
function maintainManufacturerModelDataSaveData() {
    return maintainManufacturerModelData.saveData();
}
