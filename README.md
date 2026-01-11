Budgetly – Finance Management Mobile Application (Data Management Project)
Higher National Diploma in Software Engineering | NIBM Sri Lanka

Budgetly is a mobile-based personal finance management system designed with an offline-first architecture and a robust client–server database synchronization model. The project focuses on reliable data handling, synchronization, and reporting using SQLite, Oracle Database, and ORDS REST APIs.

The system is divided into three layers:
• Client Side (Android) – Local SQLite database for offline access
• Server Side (Oracle) – Centralized data storage and reporting
• API Layer (ORDS) – Secure RESTful communication between client and server

Key features include expense tracking, budgeting, savings goals, and multi-device data consistency through a push–pull synchronization mechanism with conflict resolution using last-write-wins strategy.

🔧 Technical Contributions

• Designed logical and physical database schemas (ERD)
• Implemented SQLite CRUD operations and sync flags
• Developed Oracle PL/SQL triggers and stored procedures
• Built ORDS REST APIs for data synchronization
• Implemented soft deletes, timestamps, and conflict handling
• Generated financial reports using PL/SQL packages
