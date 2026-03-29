# Budgetly Expense Tracker

Budgetly is a mobile-based personal finance management system designed to help users track expenses, manage budgets, and monitor savings goals efficiently.  
It follows an offline-first architecture with client–server synchronization, making it reliable even when network connectivity is limited.

## Overview

Budgetly is built as a data management project for the Higher National Diploma in Software Engineering at NIBM Sri Lanka.  
The application uses:

- **Android + SQLite** for offline local storage
- **Oracle Database** for centralized server-side storage and reporting
- **ORDS REST APIs** for secure communication and synchronization between client and server

## Features

- Expense tracking
- Budget management
- Savings goal monitoring
- Offline-first data access
- Push–pull synchronization
- Conflict resolution using last-write-wins strategy
- Soft delete support
- Timestamp-based record tracking
- Financial reporting

## Architecture

The system is divided into three main layers:

### 1. Client Side (Android)
- Local SQLite database
- Offline access to user data
- CRUD operations on finance records

### 2. Server Side (Oracle)
- Centralized data storage
- PL/SQL triggers and stored procedures
- Reporting and data consistency handling

### 3. API Layer (ORDS)
- RESTful communication between Android client and Oracle database
- Data synchronization endpoints
- Secure data exchange

## Technical Highlights

- Logical and physical database design
- SQLite CRUD operations
- Sync flags for offline data handling
- Oracle PL/SQL triggers and procedures
- ORDS REST API integration
- Conflict handling and data consistency
- Financial reports generated using PL/SQL packages

## Contributors

Contributors of this project are:

1. **Sasudul** (`sasudul`)
2. **Sanugi** (`sanugi06`)
3. **Ishara** (`IsharaLakshan2002`)
4. **Branjana** (`sureshbranjana`)
5. **Harsha** (`Harsha20020703`)

## Technologies Used

- Android
- SQLite
- Oracle Database
- PL/SQL
- ORDS REST APIs
- Gradle

## Getting Started

If you want to run or extend this project:

1. Clone the repository
2. Open the Android project in Android Studio
3. Configure the Oracle database connection
4. Import and run the SQL script
5. Build and run the Android app
