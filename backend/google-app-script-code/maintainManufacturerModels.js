const maintainManufacturerModelNames = {
    LAYOUT: Object.freeze({
        SHEET: "MaintainManufacturerMaterialModels",
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
        LAST_DATA_INPUT_COLLUMN: 12,
        MAX_COLUMNS: 12,
        //Data Collumn Indexes
        MATERIAL_COLUMN: 1,
        UNIT_COLUMN: 2,
        FIRST_MODEL_COLUMN: 3,
        NUMBER_OF_MODELS: 10
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

        // Delete columns beyond column 12 if they exist
        const maxCols = sheet.getMaxColumns();
        if (maxCols > layout.MAX_COLUMNS) {
            sheet.deleteColumns(layout.MAX_COLUMNS + 1, maxCols - layout.MAX_COLUMNS);
        }

        // Set up title row (merged cells)
        sheet.getRange(layout.TITLE_ROW, 1, 1, 5).merge();
        sheet.getRange(layout.TITLE_ROW, 1)
            .setValue("Maintain Manufacturer Materials Models")
            .setFontSize(12)
            .setFontWeight("bold")
            .setHorizontalAlignment("center")
            .setBackground("#4285F4")
            .setFontColor("#FFFFFF");

        sheet.getRange(layout.TITLE_ROW, 6).setValue("Create Buttons manually if you regenerated this sheet")

        // Row 2: Manufacturer label and dropdown
        sheet.getRange(layout.INPUT_MANUFACTURER_ROW, layout.INPUT_MANUFACTURER_LABEL_COLUMN)
            .setValue("Manufacturer")
            .setFontSize(10)
            .setFontWeight("bold");

        // Set up data validation for manufacturer dropdown
        utils.createDataValidationForGivenRange(
            sheet.getRange(layout.INPUT_MANUFACTURER_ROW, layout.INPUT_MANUFACTURER_COLUMN),
            TABLES.manufacturers,
            "name",
            2);

        // Row 3: Create clickable checkbox buttons
        // Clear any existing buttons in row 3
        sheet.getRange(layout.BUTTONS_ROW, 1, 1, layout.MAX_COLUMNS).clearContent().clearFormat();

        // Create "Prepare" button using checkbox (cell 3,1)
        sheet.getRange(layout.BUTTONS_ROW, layout.PREPARE_LABEL_COLUMN)
            .setValue("⚡ Prepare")
            .setFontWeight("bold")
            .setFontSize(10)
            .setBackground("#34A853")
            .setFontColor("#FFFFFF")
            .setHorizontalAlignment("center")
            .setVerticalAlignment("middle")
            .setBorder(true, true, true, true, false, false, "#2D7D3E", SpreadsheetApp.BorderStyle.SOLID_MEDIUM);

        // Insert checkbox in cell 3,2 for Prepare
        const prepareCheckbox = sheet.getRange(layout.BUTTONS_ROW, layout.PREPARE_CHECKBOX_COLUMN);
        prepareCheckbox
            .insertCheckboxes()
            .setBackground("#34A853")
            .setHorizontalAlignment("center")
            .setVerticalAlignment("middle")
            .setBorder(true, true, true, true, false, false, "#2D7D3E", SpreadsheetApp.BorderStyle.SOLID_MEDIUM);
        prepareCheckbox.setNote("Check this box to prepare data");

        // Create "Save" button using checkbox (cell 3,3)
        sheet.getRange(layout.BUTTONS_ROW, layout.SAVE_LABEL_COLUMN)
            .setValue("💾 Save")
            .setFontWeight("bold")
            .setFontSize(10)
            .setBackground("#EA4335")
            .setFontColor("#FFFFFF")
            .setHorizontalAlignment("center")
            .setVerticalAlignment("middle")
            .setBorder(true, true, true, true, false, false, "#C5341F", SpreadsheetApp.BorderStyle.SOLID_MEDIUM);

        // Insert checkbox in cell 3,4 for Save
        const saveCheckbox = sheet.getRange(layout.BUTTONS_ROW, layout.SAVE_CHECKBOX_COLUMN);
        saveCheckbox
            .insertCheckboxes()
            .setBackground("#EA4335")
            .setHorizontalAlignment("center")
            .setVerticalAlignment("middle")
            .setBorder(true, true, true, true, false, false, "#C5341F", SpreadsheetApp.BorderStyle.SOLID_MEDIUM);
        saveCheckbox.setNote("Check this box to save changes");

        // Create "Clear" button using checkbox (cell 3,5)
        sheet.getRange(layout.BUTTONS_ROW, layout.CLEAR_LABEL_COLUMN)
            .setValue("🗑️ Clear")
            .setFontWeight("bold")
            .setFontSize(10)
            .setBackground("#FBBC04")
            .setFontColor("#000000")
            .setHorizontalAlignment("center")
            .setVerticalAlignment("middle")
            .setBorder(true, true, true, true, false, false, "#F9AB00", SpreadsheetApp.BorderStyle.SOLID_MEDIUM);

        // Insert checkbox in cell 3,6 for Clear
        const clearCheckbox = sheet.getRange(layout.BUTTONS_ROW, layout.CLEAR_CHECKBOX_COLUMN);
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
        sheet.getRange(layout.HEADER_ROW, layout.MATERIAL_COLUMN)
            .setValue("Material")
            .setFontSize(10)
            .setFontWeight("bold")
            .setBackground("#4285F4")
            .setFontColor("#FFFFFF");

        // Row 4: Column headers
        sheet.getRange(layout.HEADER_ROW, layout.UNIT_COLUMN)
            .setValue("Unit")
            .setFontSize(10)
            .setFontWeight("bold")
            .setBackground("#4285F4")
            .setFontColor("#FFFFFF");

        for (let i = 1; i <= layout.NUMBER_OF_MODELS; i++) {
            sheet.getRange(layout.HEADER_ROW, layout.FIRST_MODEL_COLUMN + i - 1)
                .setValue(`Model ${i}`)
                .setFontSize(10)
                .setFontWeight("bold")
                .setBackground("#4285F4")
                .setFontColor("#FFFFFF");
        }

        // Freeze rows and set column widths
        sheet.setFrozenRows(layout.HEADER_ROW);
        sheet.setColumnWidth(layout.MATERIAL_COLUMN, 150);
        for (let i = layout.FIRST_MODEL_COLUMN; i <= layout.MAX_COLUMNS; i++) {
            sheet.setColumnWidth(i, 70);
        }

        Logger.log("Manufacturer Material Input Sheet created successfully");
        const execContext = utils.getExecutionContext();
        if (execContext.canShowToast) {
            SpreadsheetApp.getActiveSpreadsheet().toast("Sheet created! Select a manufacturer and check the '⚡ Prepare Data' checkbox.");
        }

        return "Manufacturer Material Input Sheet created";
    },

    /**
     * Prepare manufacturer material models input data
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
            SpreadsheetApp.getActiveSpreadsheet().toast("Manufacturer not found!");
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

        // Populate the matrix - build 2D array first for efficient batch write
        const matrixData = [];
        for (let i = 0; i < materials.list.length; i++) {
            const m = materials.list[i];
            const row = new Array(layout.MAX_COLUMNS).fill("");
            row[layout.MATERIAL_COLUMN - 1] = m.name;
            row[layout.UNIT_COLUMN - 1] = m.unit_of_measure;

            let c = layout.UNIT_COLUMN; // Start from column 3 for models
            for (let j = 0; j < manufacturerMaterials.list.length; j++) {
                const mm = manufacturerMaterials.list[j];
                if (mm.material_uuid === m.uuid
                    && mm.manufacturer_uuid === manufacturerUuid
                    && c < layout.FIRST_MODEL_COLUMN + layout.NUMBER_OF_MODELS) {
                    c++;
                    row[c - 1] = mm.model;
                }
            }
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

        // Manufacturer label
        protectedRanges.push(sheet.getRange(layout.INPUT_MANUFACTURER_ROW, layout.INPUT_MANUFACTURER_LABEL_COLUMN, 1, 1));

        // Row 2, Columns 3+ - Extra columns
        if (maxCols >= (layout.INPUT_MANUFACTURER_COLUMN + 1)) {
            protectedRanges.push(sheet.getRange(layout.INPUT_MANUFACTURER_ROW, layout.INPUT_MANUFACTURER_COLUMN + 1, 1, maxCols - layout.INPUT_MANUFACTURER_COLUMN));
        }

        // Row 3, Columns 1, 3, 5 - Button labels (not checkboxes)
        protectedRanges.push(sheet.getRange(layout.BUTTONS_ROW, layout.PREPARE_LABEL_COLUMN, 1, 1));
        protectedRanges.push(sheet.getRange(layout.BUTTONS_ROW, layout.SAVE_LABEL_COLUMN, 1, 1));
        protectedRanges.push(sheet.getRange(layout.BUTTONS_ROW, layout.CLEAR_LABEL_COLUMN, 1, 1));
        if (maxCols >= (layout.BUTTONS_ROW_LAST_COLLUMN + 1)) {
            protectedRanges.push(sheet.getRange(layout.BUTTONS_ROW, layout.BUTTONS_ROW_LAST_COLLUMN + 1, 1, maxCols - layout.BUTTONS_ROW_LAST_COLLUMN));
        }

        // Header row (entire row)
        protectedRanges.push(sheet.getRange(layout.HEADER_ROW, 1, 1, maxCols));

        // Rows 5 onwards, Columns A and B - Material and Unit columns
        if (maxRows >= layout.DATA_START_ROW) {
            protectedRanges.push(sheet.getRange(layout.DATA_START_ROW, layout.MATERIAL_COLUMN, maxRows - layout.HEADER_ROW, layout.UNIT_COLUMN));
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
        const manufacturerName = inputSheet.getRange(layout.INPUT_MANUFACTURER_ROW, layout.INPUT_MANUFACTURER_COLUMN).getValue();
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

        // Process sheet data
        const newEntries = [];
        const deleteEntries = [];
        const currentEntriesMap = {};

        const currentTime = new Date();
        const lastRow = inputSheet.getLastRow();
        for (let r = layout.DATA_START_ROW; r <= lastRow; r++) {
            const materialName = inputSheet.getRange(r, layout.MATERIAL_COLUMN).getValue();
            if (!materialName) continue;

            let c = layout.UNIT_COLUMN; // Start from column 3 for models
            for (let j = 1; j <= layout.NUMBER_OF_MODELS; j++) {
                c++;
                const modelValue = inputSheet.getRange(r, c).getValue();
                if (modelValue) {
                    const rec = {
                        manufacturer_name: manufacturerName,
                        manufacturer_uuid: manufacturerUuid,
                        material_name: materialName,
                        material_uuid: materials.nameMap[materialName]?.uuid,
                        model: modelValue,
                        uuid: null,
                        updated_at: currentTime,
                        newEntry: false
                    };

                    // Check if this model already exists
                    let manuMap = manufacturerMaterials.map[manufacturerUuid];
                    if (!manuMap) {
                        manuMap = manufacturerMaterials.map[manufacturerUuid] = {};
                    }
                    let matMap = manuMap[rec.material_uuid];
                    if (!matMap) {
                        matMap = manuMap[rec.material_uuid] = {};
                    }
                    if (matMap[rec.model]) {
                        rec.uuid = matMap[rec.model].uuid;
                        currentEntriesMap[rec.uuid] = rec;
                    } else {
                        matMap[rec.model] = rec;
                        rec.uuid = utils.UUID();
                        rec.newEntry = true;
                        currentEntriesMap[rec.uuid] = rec;
                        newEntries.push(rec);
                    }
                }
            }
        }

        // Find records to delete
        for (const manUuid in manufacturerMaterials.map) {
            const manuMap = manufacturerMaterials.map[manUuid];
            for (const matUuid in manuMap) {
                const matMap = manuMap[matUuid];
                for (const model in matMap) {
                    const uuid = matMap[model].uuid;
                    if (!currentEntriesMap[uuid]) {
                        deleteEntries.push({
                            uuid: uuid,
                            manufacturer_uuid: manUuid,
                            material_uuid: matUuid,
                            model: model,
                            updated_at: currentTime
                        });
                    }
                }
            }
        }

        const tableDef = tableDefinitions.getByName(TABLES.manufacturer_materials);

        // Get column map from actual sheet headers
        const columnMap = setup.getSheetColumnMap(mmSheet, TABLES.manufacturer_materials);
        const keyColumnIndex = columnMap[tableDef.keyColumn];

        // Delete records from manufacturer_materials sheet
        if (deleteEntries.length > 0) {
            const deleteUuids = deleteEntries.map(rec => rec.uuid);
            const sheetData = mmSheet.getDataRange().getValues();

            // Find rows to delete (in reverse order to avoid index shifts)
            const rowsToDelete = [];
            for (let i = sheetData.length - 1; i >= 1; i--) {
                const uuid = sheetData[i][keyColumnIndex];
                if (deleteUuids.includes(uuid)) {
                    rowsToDelete.push(i + 1); // +1 for 1-based indexing
                }
            }
            changeLog.logChanges(TABLES.manufacturer_materials,
                deleteUuids, CHANGE_MODE_DELETE, currentTime);

            // Delete rows
            for (const rowIndex of rowsToDelete) {
                mmSheet.deleteRows(rowIndex, 1);
            }

            Logger.log(`Deleted ${rowsToDelete.length} records`);
        }

        // Insert new records
        if (newEntries.length > 0) {
            const insertData = newEntries.map(rec => {
                return utils.buildRowDataFromRecord(rec, tableDef.columnNames, columnMap, TABLES.manufacturer_materials);
            });

            const numCols = Math.max(...Object.values(columnMap)) + 1;
            const startRow = mmSheet.getLastRow() + 1;
            mmSheet.getRange(startRow, 1, insertData.length, numCols)
                .setValues(insertData);

            Logger.log(`Inserted ${insertData.length} new records`);
            // Log changes
            changeLog.logChanges(TABLES.manufacturer_materials,
                newEntries.map(rec => rec.uuid), CHANGE_MODE_INSERT, currentTime);
        }

        // Apply formatting and resize
        setup.setupDataTableSheet(TABLES.manufacturer_materials, false);

        if (execContext.canShowToast) {
            SpreadsheetApp.getActiveSpreadsheet().toast(
                `Maintenance complete!\nInserted: ${newEntries.length}\nDeleted: ${deleteEntries.length}`
            );
        }

        return `Inserted: ${newEntries.length}, Deleted: ${deleteEntries.length}`;
    },

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

    onEdit(range) {
        const row = range.getRow();
        const col = range.getColumn();

        // Check if "Prepare" checkbox (row 3, col 2) was checked
        if (row === maintainManufacturerModelNames.LAYOUT.BUTTONS_ROW && col === maintainManufacturerModelNames.LAYOUT.PREPARE_CHECKBOX_COLUMN) {
            const value = range.getValue();
            if (value === true) {
                // Uncheck immediately
                range.setValue(false);
                // Call prepare function
                this.prepareInputData();
            }
        }
        // Check if "Save" checkbox (row 3, col 4) was checked
        else if (row === maintainManufacturerModelNames.LAYOUT.BUTTONS_ROW && col === maintainManufacturerModelNames.LAYOUT.SAVE_CHECKBOX_COLUMN) {
            const value = range.getValue();
            if (value === true) {
                // Uncheck immediately
                range.setValue(false);
                // Call save function
                this.saveData();
            }
        }
        // Check if "Clear" checkbox (row 3, col 6) was checked
        else if (row === maintainManufacturerModelNames.LAYOUT.BUTTONS_ROW && col === maintainManufacturerModelNames.LAYOUT.CLEAR_CHECKBOX_COLUMN) {
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

function maintainManufacturerModelNamesPrepareInputData() {
    return maintainManufacturerModelNames.prepareInputData();
}
function maintainManufacturerModelNamesClearData() {
    return maintainManufacturerModelNames.clearData();
}
function maintainManufacturerModelNamesSaveData() {
    return maintainManufacturerModelNames.saveData();
}
