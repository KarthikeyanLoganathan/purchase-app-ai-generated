In google sheet, through google apps script, behind a cell, can I attach additional (tagging) information that I can use it later

```javascript
// Add metadata to a cell
const cell = sheet.getRange('A1');
cell.addDeveloperMetadata('tag', 'important');
cell.addDeveloperMetadata('category', 'vendor');
cell.addDeveloperMetadata('id', '12345');

// Retrieve metadata later
const metadata = cell.getDeveloperMetadata();
metadata.forEach(m => {
  Logger.log(`${m.getKey()}: ${m.getValue()}`);
});

// Search for cells with specific metadata
const finder = sheet.createDeveloperMetadataFinder()
  .withKey('tag')
  .withValue('important')
  .find();


// Get developer metadata with a specific key from a range
const range = sheet.getRange('A1:B10');

// Get all metadata for the range and filter by key
const allMetadata = range.getDeveloperMetadata();
const specificMetadata = allMetadata.filter(m => m.getKey() === 'yourKey');

// Or use the finder to search by key
const metadataFinder = range.createDeveloperMetadataFinder()
  .withKey('yourKey')
  .find();

// Access the value
if (metadataFinder.length > 0) {
  const value = metadataFinder[0].getValue();
  Logger.log(value);
}

// Search by both key and value
const finder = range.createDeveloperMetadataFinder()
  .withKey('id')
  .withValue('12345')
  .find();

// Get specific metadata by key (simple helper)
function getMetadataValue(range, key) {
  const metadata = range.getDeveloperMetadata();
  const found = metadata.find(m => m.getKey() === key);
  return found ? found.getValue() : null;
}

// Usage
const id = getMetadataValue(sheet.getRange('A1'), 'id');
```

