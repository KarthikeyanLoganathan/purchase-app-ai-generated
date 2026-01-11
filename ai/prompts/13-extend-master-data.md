extend tables as follows
- manufacturers
  - address
  - phone_number
  - email_address
  - website
  - photo (clob - stored as base64 encoded text)
    - to be the last column in the list of columns
- vendors
  - address
  - phone_number
  - email_address
  - website
  - photo (clob - stored as base64 encoded text)
    - to be the last column in the list of columns
- materials
  - website
  - photo (clob - stored as base64 encoded text)
    - to be the last column in the list of columns
- manufacturer_materials
  - website
  - part_number(text)
  - photo (clob - stored as base64 encoded text)
    - to be the last column in the list of columns
- baskets
  - project (text)
  - delivery_address (text)
  - phone_number
- purchase_orders
  - project (text)
  - description (text)
  - delivery_address (text)
  - phone_number
- quotations
  - project (text)
  - description (text)

Respectively add these fields for input in the respective Flutter Detail Screens

Extend backend table definitions also in tableMetadata.js

