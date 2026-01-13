const dataReaders = {
    readManufacturers(filter) {
        const result = {
            list: [],
            uuidMap: {},
            nameMap: {},
            count: 0
        };
        const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName(TABLES.manufacturers);
        const columnMap = setup.getSheetColumnMap(sheet, TABLES.manufacturers);
        const sheetData = sheet.getDataRange().getValues();

        for (let i = 1; i < sheetData.length; i++) {
            //uuid	id	name	description	updated_at
            const sheetRec = sheetData[i];
            const rec = {
                uuid: sheetRec[columnMap?.uuid],
                id: sheetRec[columnMap?.id],
                name: sheetRec[columnMap?.name],
                description: sheetRec[columnMap?.description],
                updated_at: sheetRec[columnMap?.updated_at],
            };
            if (!filter ||
                ((!filter.uuid || filter.uuid === rec.uuid) &&
                    (!filter.name || filter.name === rec.name))
            ) {
                result.list.push(rec);
                result.uuidMap[rec.uuid] = rec;
                result.nameMap[rec.name] = rec;
                result.count++;
            }
        }
        result.list.sort((a, b) => {
            if (a.name < b.name) return -1;
            if (a.name > b.name) return 1;
            return 0;
        });
        return result;
    },

    readVendors(filter) {
        const result = {
            list: [],
            uuidMap: {},
            nameMap: {},
            count: 0
        };
        const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName(TABLES.vendors);
        const columnMap = setup.getSheetColumnMap(sheet, TABLES.vendors);
        const sheetData = sheet.getDataRange().getValues();

        for (let i = 1; i < sheetData.length; i++) {
            //uuid	id	name	description	address	geo_location	updated_at
            const sheetRec = sheetData[i];
            const rec = {
                uuid: sheetRec[columnMap?.uuid],
                id: sheetRec[columnMap?.id],
                name: sheetRec[columnMap?.name],
                description: sheetRec[columnMap?.description],
                address: sheetRec[columnMap?.address],
                geo_location: sheetRec[columnMap?.geo_location],
                updated_at: sheetRec[columnMap?.updated_at],
            };
            if (!filter ||
                ((!filter.uuid || filter.uuid === rec.uuid) &&
                    (!filter.name || filter.name === rec.name))
            ) {
                result.list.push(rec);
                result.uuidMap[rec.uuid] = rec;
                result.nameMap[rec.name] = rec;
                result.count++;
            }
        }
        result.list.sort((a, b) => {
            if (a.name < b.name) return -1;
            if (a.name > b.name) return 1;
            return 0;
        });
        return result;
    },

    readMaterials(filter) {
        const result = {
            list: [],
            uuidMap: {},
            nameMap: {},
            count: 0
        };
        const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName(TABLES.materials);
        const columnMap = setup.getSheetColumnMap(sheet, TABLES.materials);
        const sheetData = sheet.getDataRange().getValues();

        for (let i = 1; i < sheetData.length; i++) {
            //uuid	id	name	description	unit_of_measure	updated_at
            const sheetRec = sheetData[i];
            const rec = {
                uuid: sheetRec[columnMap?.uuid],
                id: sheetRec[columnMap?.id],
                name: sheetRec[columnMap?.name],
                description: sheetRec[columnMap?.description],
                unit_of_measure: sheetRec[columnMap?.unit_of_measure],
                updated_at: sheetRec[columnMap?.updated_at]
            };
            if (!filter ||
                ((!filter.uuid || filter.uuid === rec.uuid) &&
                    (!filter.name || filter.name === rec.name))
            ) {
                result.list.push(rec);
                result.uuidMap[rec.uuid] = rec;
                result.nameMap[rec.name] = rec;
                result.count++;
            }
        }
        result.list.sort((a, b) => {
            if (a.name < b.name) return -1;
            if (a.name > b.name) return 1;
            return 0;
        });
        return result;
    },

    readManufacturerMaterials(manufacturers, materials, filter) {
        const result = {
            list: [],
            uuidMap: {},
            map: {},
            count: 0
        };
        const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName(TABLES.manufacturer_materials);
        const columnMap = setup.getSheetColumnMap(sheet, TABLES.manufacturer_materials);
        const sheetData = sheet.getDataRange().getValues();

        for (let i = 1; i < sheetData.length; i++) {
            //uuid	manufacturer_uuid	material_uuid	model	
            // selling_lot_size	max_retail_price	currency	updated_at	
            // manufacturer_name	material_name	unit_of_measure
            const sheetRec = sheetData[i];
            const rec = {
                uuid: sheetRec[columnMap?.uuid],
                manufacturer_uuid: sheetRec[columnMap?.manufacturer_uuid],
                material_uuid: sheetRec[columnMap?.material_uuid],
                model: sheetRec[columnMap?.model],
                selling_lot_size: sheetRec[columnMap?.selling_lot_size],
                max_retail_price: sheetRec[columnMap?.max_retail_price],
                currency: sheetRec[columnMap?.currency],
                updated_at: sheetRec[columnMap?.updated_at],
                manufacturer: null,
                material: null
                // manufacturer_name: sheetRec[columns?.manufacturer_name],
                // material_name: sheetRec[columns?.material_name],
                // unit_of_measure: sheetRec[columns?.unit_of_measure]
            };
            rec.manufacturer = manufacturers.uuidMap?.[rec?.manufacturer_uuid] || null;
            rec.material = materials.uuidMap?.[rec?.material_uuid] || null;
            if (!(rec.manufacturer && rec.material && rec.model)) {
                continue;
            }
            if (!filter ||
                ((!filter.uuid || filter.uuid === rec.uuid) &&
                    (!filter.manufacturer_uuid || filter.manufacturer_uuid === rec.manufacturer_uuid) &&
                    (!filter.material_uuid || filter.material_uuid === rec.material_uuid) &&
                    (!filter.model || filter.model === rec.model))
            ) {
                result.list.push(rec);
                result.uuidMap[rec.uuid] = rec;
                let manuMap = result.map[rec.manufacturer_uuid];
                if (!manuMap) {
                    manuMap = result.map[rec.manufacturer_uuid] = {};
                }
                let matMap = manuMap[rec.material_uuid];
                if (!matMap) {
                    matMap = manuMap[rec.material_uuid] = {};
                }
                let modelMap = matMap[rec.model];
                if (!modelMap) {
                    modelMap = matMap[rec.model] = rec;
                }
                result.count++;
            }
        }
        result.list.sort((a, b) => {
            if (a.manufacturer?.name < b.manufacturer?.name) return -1;
            if (a.manufacturer?.name > b.manufacturer?.name) return 1;
            if (a.material?.name < b.material?.name) return -1;
            if (a.material?.name > b.material?.name) return 1;
            if (a.model < b.model) return -1;
            if (a.model > b.model) return 1;
            return 0;
        });

        return result;
    },

    readVendorPriceList(manufacturers, materials, vendors, manufacturerMaterials, filter) {
        const result = {
            list: [],
            uuidMap: {},
            map: {},
            count: 0
        };
        const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName(TABLES.vendor_price_lists);
        const columnMap = setup.getSheetColumnMap(sheet, TABLES.vendor_price_lists);
        const sheetData = sheet.getDataRange().getValues();

        for (let i = 1; i < sheetData.length; i++) {
            // uuid	manufacturer_material_uuid	vendor_uuid	
            // rate	rate_before_tax	currency	tax_percent	tax_amount	updated_at
            const sheetRec = sheetData[i];
            const rec = {
                uuid: sheetRec[columnMap?.uuid],
                manufacturer_material_uuid: sheetRec[columnMap?.manufacturer_material_uuid],
                vendor_uuid: sheetRec[columnMap?.vendor_uuid],
                rate: sheetRec[columnMap?.rate],
                rate_before_tax: sheetRec[columnMap?.rate_before_tax],
                currency: sheetRec[columnMap?.currency],
                tax_percent: sheetRec[columnMap?.tax_percent],
                tax_amount: sheetRec[columnMap?.tax_amount],
                updated_at: sheetRec[columnMap?.updated_at],

                manufacturer_material: null,
                vendor: null,
                material: null,
                manufacturer: null,
            };
            rec.vendor = vendors?.uuidMap?.[rec?.vendor_uuid] || null;
            rec.manufacturer_material = manufacturerMaterials?.uuidMap?.[rec.manufacturer_material_uuid] || null;
            if (!(rec.vendor && rec.manufacturer_material)) {
                continue;
            }
            rec.manufacturer = manufacturers?.uuidMap?.[rec.manufacturer_material?.manufacturer_uuid] || null;
            rec.material = materials?.uuidMap?.[rec.manufacturer_material?.material_uuid] || null;
            if (!(rec.manufacturer && rec.material)) {
                continue;
            }
            if (!filter ||
                ((!filter.uuid || filter.uuid === rec.uuid) &&
                    (!filter.vendor_uuid || filter.vendor_uuid === rec.vendor_uuid) &&
                    (!filter.manufacturer_uuid || filter.manufacturer_uuid === rec.manufacturer_material.manufacturer_uuid) &&
                    (!filter.material_uuid || filter.material_uuid === rec.manufacturer_material.material_uuid) &&
                    (!filter.model || filter.model === rec.manufacturer_material.model))
            ) {
                result.list.push(rec);
                result.uuidMap[rec.uuid] = rec;
                let vendMap = result.map[rec.vendor_uuid];
                if (!vendMap) {
                    vendMap = result.map[rec.vendor_uuid] = {};
                }
                let manuMap = vendMap[rec.manufacturer.uuid];
                if (!manuMap) {
                    manuMap = vendMap[rec.manufacturer.uuid] = {};
                }
                let matMap = manuMap[rec.material.uuid];
                if (!matMap) {
                    matMap = manuMap[rec.material.uuid] = {};
                }
                let modelMap = matMap[rec.manufacturer_material.model];
                if (!modelMap) {
                    modelMap = matMap[rec.manufacturer_material.model] = rec;
                }
                result.count++;
            }
        }
        result.list.sort((a, b) => {
            if (a.manufacturer?.name < b.manufacturer?.name) return -1;
            if (a.manufacturer?.name > b.manufacturer?.name) return 1;
            if (a.material?.name < b.material?.name) return -1;
            if (a.material?.name > b.material?.name) return 1;
            if (a.model < b.model) return -1;
            if (a.model > b.model) return 1;
            if (a.vendor?.name < b.vendor?.name) return -1;
            if (a.vendor?.name > b.vendor?.name) return 1;
            return 0;
        });

        return result;
    }
};