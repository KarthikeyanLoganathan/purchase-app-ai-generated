// Configuration
const SPREADSHEET_ID =
    PropertiesService.getScriptProperties().getProperty("SPREADSHEET_ID");

const EPOCH_TIME_LOWEST_MILLISECONDS = -8640000000000000; // Earliest date in JavaScript
const EPOCH_TIME_1900_01_01_00_00_00_UTC_MILLISECONDS = -2208988800000; // 1900-01-01T00:00:00Z
//const EPOCH_TIME_LOWEST = new Date(EPOCH_TIME_LOWEST_MILLISECONDS);

// Change modes
const CHANGE_MODE_INSERT = "I";
const CHANGE_MODE_UPDATE = "U";
const CHANGE_MODE_DELETE = "D";

const CHANGE_MODE_TEMPORARY_FIELD = "___change___mode___";
const UPDATED_AT_TEMPORARY_FIELD = "___updated___at___";

const DEFAULT_CURRENCY_NAMED_RANGE = "DEFAULT_CURRENCY";
