In Flutter App, please adopt the data model changes as given below

table manufacturer_materials - field names changed
- manufacturer_id to manufacturer_uuid
- material_id to material_uuid

table vendor_price_lists - field names changed
- manufacturer_material_id to manufacturer_material_uuid
- vendor_id to vendor_uuid

table purchase_orders - field names changed
- vendor_id to vendor_uuid

table purchase_order_items - field names changed
- purchase_order_id to purchase_order_uuid
- manufacturer_material_id to manufacturer_material_uuid
- material_id to material_uuid

table purchase_order_payments - field names changed
- purchase_order_id to purchase_order_uuid

table change_log to be recreated - field names changed including key field
- id changed to uuid
- key changed to table_key_uuid


You dont have to worry about SQLite database schema lifecycle.  Consider it a fresh start with database schema version 1.  

According to this data model change, adjust SQLite schema.  also adjust the flutter app.


Note the backend google sheet, backend google app script code base was alredy adjusted



one additional table to be adjusted change_log
field key to be renamed to table_key_uuid

Accordingly change flutter entity defintions also

Adjust all references.



In the Flutter app, folder lib/models has taken correct database field names.  However, the data entity classes use field names like manufacturerId for manufacturer_uuid, can we adjust the entity field names in line with SQLite database field names?