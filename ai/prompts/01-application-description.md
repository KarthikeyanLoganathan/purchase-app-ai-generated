I would like to develop a Purchasing Application.

I need a mobile application with SQLite database that stores data on the mobile device providing offline capabilties.

Database Tables required.

Manufacturers - uuid (key), id(number, auto-generated), name, description, updated at timestamp
Vendors - uuid (key), id(number, auto-generated), name, description, address, geo-location, updated at timestamp
Materials - uuid (key), id(number, auto-generated), name, description, unit of measure, updated at timestamp
Manufacturer Material - uuid (key), manufacturer id, material id, model, updated at timestamp, selling lot size, max retail price, currency, updated at timestamp
Vendor Price List - uuid (key), manufacturer material id, vendor id, rate, currency, tax percent, tax amount, updated at timestamp
Purchase Order - uuid (key), id(number, auto-generated), vendor id, date, base price, tax amount, total amount, currency, order date, expected delivery date, updated at timestamp
Purcahse Order Items - uuid (key), purchase order id, manufacturer material id, quantity, rate, base price, tax percent, tax amount, total amount, currency, updated at timestamp


Develop a Flutter Android Frontend Application for the functionalities given below.

1. Login Screen to accept user credentials.
2. Maintain Manufactures screen
3. Maintain Vendors screen
4. Maintain Materials screen - In details screen, it shall be possible to maintain models.  If a model is in use in vendor price list or quotation or purchase order, it shall not be possible to delete the model.
5. Maintain Manufacturer Material screen. Need search filter manufacturer and material. - In details screen, it shall be possible to maintain vendor price list for the the given manufacturer model, the vendor shall be searchable.
6. Maintain Vendor Price List screen.  Need search filter for vendor, manufacturer, material.
8. Maintain Purchase Order screens. Header screen and item screen.  In header vendor shall be searchable.  In item screen, manufacturer material shall be searchable.  Item tax percent shall be inherited from vendor price list.  Item base price shall be calculated based on rate and quantity. Item tax amount shall be calculated based on tax percent and base price. Item total amount shall be calculated based on base price and tax amount. Header base price shall be the sum of item base prices.  Header tax amount shall be the sum of item tax amounts. Header total amount shall be the sum of item total amounts.  Order date shall be the current date.  Expected delivery date shall be an input from user.  Since vendor is fixed on the purchase order header, item level manufacturer material shall be searchable restricted by vendor price list.


