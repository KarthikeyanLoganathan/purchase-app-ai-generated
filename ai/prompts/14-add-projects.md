add tables
- projects
  - uuid (key)
  - name
  - description
  - address
  - phone_number
  - geo_location
  - start_date (timestamp)
  - end_date (timestamp)
  - completed
  - updated_at

extend tables
- purchase_order_items 
  - unit_of_measure (text)
- quotation_items
  - unit_of_measure (text)

During maintenance of purchase order, materials.unit_of_measure has to be copied to this field.

During maintenance of quotation, materials.unit_of_measure has to be copied to this field.

extend both backend and frontend