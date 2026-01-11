const config = {
    setConfigValue(key, value) {
        const ss = SpreadsheetApp.getActiveSpreadsheet();
        let configSheet = ss.getSheetByName(setup.SHEET_NAMES.CONFIG);
        if (!configSheet) {
            throw new Error(`Config sheet "${setup.SHEET_NAMES.CONFIG}" does not exist. Please run setup first.`);
        }

        const data = configSheet.getDataRange().getValues();
        let found = false;

        for (let i = 1; i < data.length; i++) {
            if (data[i][0] === key) {
                configSheet.getRange(i + 1, 2).setValue(value);
                found = true;
                Logger.log(`Updated config key "${key}" with new value.`);
                break;
            }
        }

        if (!found) {
            configSheet.appendRow([key, value]);
            Logger.log(`Added new config key "${key}" with value.`);
        }
    },
    /**
     * Get configuration value by name
     */
    getConfigValue(name) {
        const ss = SpreadsheetApp.getActiveSpreadsheet();
        const configSheet = ss.getSheetByName(setup.SHEET_NAMES.CONFIG);

        if (!configSheet) {
            throw new Error("Config sheet not found. Run setup() first.");
        }

        const data = configSheet.getDataRange().getValues();
        for (let i = 1; i < data.length; i++) {
            if (data[i][0] === name) {
                return data[i][1];
            }
        }

        return null;
    }
};