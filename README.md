# My Purchase Application
My Purchase - Complete offline-first purchase management system with basket management, vendor quotations, and Google Sheets sync

The app aim to leverge compute capabilities of mobile device to give simple purchase experience. For backup it uses Google Sheets

* Manage Vendors
* Manage Manufactors
* Manage Materials
* Manage Manufactor Materials
* Manage Vendor Price Lists
* Manage Purchase Orders
* Manage Shopping Baskets & Quotations
* Login and Sync with Google Sheets
  * [Google Sheets equivalent excel - Purchase App](./backend/Purchase%20App%20Google%20Sheet%20equivalent%20Excel.xlsx)
  * [Google Sheet Apps Script](./backend/google-app-script-code/)


## Example Backend Google Sheet
- [Purchase App Demo](https://docs.google.com/spreadsheets/d/1CaOdGMX22fHNe83yY0Ib8h6pBSO9mfq5OPlTuoZdhqw/edit?usp=sharing)
  - Application URL & App Code found in config sheet

## Android Binary
 - [APK](https://drive.google.com/file/d/1cdhXZbb6wO8N9ZPZp1GkVNlOEgnS6TDT/view?usp=sharing)
 - [GitHub v1.0.0 Release build](https://github.com/KarthikeyanLoganathan/purchase-app-ai-generated/releases/download/v1.0.0/app-release.apk)

## Build
- Android Transfer of API by USB, Cloud Storage Email / Messaging Aps
  - `flutter build apk --release`
- Build App Bundle (recommended for Play Store)
  - `flutter build appbundle --release`

## Screenshots
<img src="./docu/000-android-home-screen.png" width="45%"/>
<img src="./docu/001-login-screen.png" width="45%"/>
<img src="./docu/002-home-screen-2.png" width="45%"/>
<img src="./docu/003-home-screen-3.png" width="45%"/>
<img src="./docu/011-manufacturers.png" width="45%"/>
<img src="./docu/021-vendors.png" width="45%"/>
<img src="./docu/031-materials-1.png" width="45%"/>
<img src="./docu/032-materials-2.png" width="45%"/>
<img src="./docu/041-manufacturer-materials-1.png" width="45%"/>
<img src="./docu/042-manufacturer-materials-2.png" width="45%"/>
<img src="./docu/043-manufacturer-materials-3.png" width="45%"/>
<img src="./docu/051-vendor-price-list-1.png" width="45%"/>
<img src="./docu/052-vendor-price-list-2.png" width="45%"/>
<img src="./docu/061-purchase-orders-1.png" width="45%"/>
<img src="./docu/062-purchase-orders-2.png" width="45%"/>
<img src="./docu/063-purchase-orders-3.png" width="45%"/>
<img src="./docu/064-purchase-orders-4.png" width="45%"/>
<img src="./docu/065-purchase-orders-5.png" width="45%"/>
<img src="./docu/066-purchase-orders-6.png" width="45%"/>
<img src="./docu/067-purchase-orders-7.png" width="45%"/>
<img src="./docu/081-sync-with-google-sheet-1.png" width="45%"/>
<img src="./docu/082-sync-with-google-sheet-2.png" width="45%"/>
<img src="./docu/091-data-in-google-sheets.png" width="45%"/>
<img src="./docu/092-data-in-google-sheets.png" width="45%"/>
<img src="./docu/101-import-sample-data.png" width="45%"/>
<img src="./docu/102-import-sample-data.png" width="45%"/>
<img src="./docu/201-clear-all-data.png" width="45%"/>