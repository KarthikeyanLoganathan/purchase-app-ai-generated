# Project Overview: Purchase Application

This is an **AI-Generated Flutter-based Purchase Management System** - a comprehensive mobile application for managing procurement workflows with offline-first capabilities and cloud synchronization.

## Core Concept

A complete procurement and vendor management solution that operates primarily offline using SQLite, with optional cloud sync via Google Sheets backend. The app enables users to manage the full purchasing lifecycle from vendor/material management to quotations and purchase orders.

## Key Features

### Master Data Management
- Vendors, Manufacturers, Materials
- Manufacturer-Material relationships
- Vendor Price Lists
- Projects, Currencies, Units of Measure

### Transaction Workflows
- Shopping Baskets (cart system)
- Request for Quotations (RFQ)
- Purchase Orders with line items
- Multi-currency and unit support

### Technical Highlights
- **Offline-First**: Full SQLite database with local CRUD operations
- **Delta Sync**: Incremental synchronization with Google Sheets backend using change logs
- **CSV Import/Export**: Bulk data management
- **PDF Generation**: Reports and purchase orders
- **Database Browser**: Built-in SQLite data viewer
- **Widget Previews**: Development tooling for UI components

## Architecture

- **Frontend**: Flutter with Material Design 3
- **Local Storage**: SQLite (sqflite)
- **Backend**: Google Apps Script serving as REST API over Google Sheets
- **Authentication**: Secret code-based system (APP_CODE)
- **Sync Strategy**: Bidirectional delta sync with conflict resolution

## Unique Aspects

### 1. AI-Generated Codebase
The `ai/` folder contains 22+ prompts documenting the iterative AI-assisted development process, showing how the app evolved from basic CRUD to a sophisticated system with sync, basket/quotation features, and preview capabilities.

### 2. No-Backend Deployment
Uses Google Sheets as a serverless database accessible via Google Apps Script, making deployment extremely simple without traditional server infrastructure.

### 3. Production-Ready
Includes APK builds, comprehensive documentation, architecture diagrams, and screenshots demonstrating a fully functional purchase management system.

## Conclusion

This is an impressive example of how AI can assist in building complete, production-grade mobile applications with complex business logic and data synchronization capabilities.
