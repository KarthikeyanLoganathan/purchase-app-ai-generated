Let us rename Basket Vendor to Quotation

let us rename the tables
- basket_vendors to quotations
- basket_vendor_items to quotation_items

Fields to be renamed
- basket_vendor_uuid to quotation_uuid
- basket_vendor_item_uuid to quotation_uuid

Rename the frontend and backend artifacts

Even local variable names to be renamed properly to reflect this change

Don't bother about DDL history.  Assume it is a fresh start. No need of version 2 for the DDL changes.