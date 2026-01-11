extend table purchase_orders with fields basket_uuid, basket_vendor_uuid fields

extend table purchase_order_items with fields basket_item_uuid, basket_vendor_item_uuid

Update backend models in tableMetadata.js

Update SQLite models



In BasketVendorDetailScreen provide button generate purchase Order.  The following logic shal logic executed.
- Insert purchase_orders record.
  - Copy values from basket_vendors record
    - vendor_uuid, base_price, tax_amount, total_amount, currency, expected_delivery_date
  - Initialize values
    - order_date = current date
    - completed = false
    - amount_paid = 0
    - amount_balance = total_amount
    - basket_vendor_uuid = basket_vendors.uuid
    - basket_uuid = basket_vendors.basket_uuid
    - updated_at current timestamp
- if there is already a purchase order with basket_vendor_uuid = basket_vendors.uuid, update the values in purchase_orders
  - Copy values from basket_vendors record
    - vendor_uuid, base_price, tax_amount, total_amount, currency, expected_delivery_date
  - Initialize values
    - uuid = new UUID
    - order_date = current date
    - completed = false
    - amount_paid = 0
    - amount_balance = total_amount
    - basket_vendor_uuid = basket_vendors.uuid
    - basket_uuid = basket_vendors.basket_uuid
    - updated_at current timestamp
- for every basket_vendor_items of the current basket_vendor record
  - Insert purchase_order_items record.
    - Copy values from basket_vendor_items record
      - manufacturer_material_uuid, material_uuid, model, quantity, rate, rate_before_tax, base_price, tax_percent, tax_amount, total_amount
    - Initialize values
      - uuid = new UUID
      - purchase_order_uuid = generated/updated purchase_oders.uuid
      - basket_vendor_item_uuid = basket_vendor_items.uuid
      - basket_item_uuid = basket_vendor_items.basket_item_uuid
      - updated_at current timestamp
  - if there is alredy a purchase order item with basket_vendor_item_uuid = basket_vendor_items.uuid, update the purchase_order_items record
    - Copy values from basket_vendor_items record
      - manufacturer_material_uuid, material_uuid, model, quantity, rate, rate_before_tax, base_price, tax_percent, tax_amount, total_amount
    - Initialize values
      - uuid = new UUID
      - purchase_order_uuid = generated/updated purchase_oders.uuid
      - basket_vendor_item_uuid = basket_vendor_items.uuid
      - basket_item_uuid = basket_vendor_items.basket_item_uuid
      - updated_at current timestamp
- if there are more items in purchase order than in basket_vendor_items for given basket_vendors record, delete redundant purchase order items
- do purchase order item level calculations
- rollup values to purchase order header as per existing logic

- Log changes to purchase_orders, purchase_order_items in change_log
- Once purchase order is generated or changed, navigate to the newly generated purchase order

In BasketVendorDetailScreen provide button Go to purchase Order. Navigate to PurchaseOrderDetailScreen.
In BasketDetailScreen provide button Go to purchase Order. Navigate to PurchaseOrderDetailScreen.