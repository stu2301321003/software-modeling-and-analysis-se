# Booking Platform – OLTP, DWH & Power BI Project
**Student Faculty Number:** 2301321003  
**Discipline:** Software modeling and analysis  
**Project Theme:** Booking.com  

## Overview
This project implements a full data solution inspired by Booking.com, including:
- Conceptual Model (Chen notation)
- Logical Model (Crow’s Foot)
- OLTP Database in MS SQL Server
- Stored Procedure, Function, Trigger
- Data Warehouse (Star Schema)
- Power BI report with analytical dashboards

## Project Structure
```
diagrams -> contains the .jpeg and .drawio files
sql -> contains sql scripts
powerbi-> contains the powerbi file and png
README.md -> the default readme
Problems.md -> the problems which i faced
```

---

## Installation Instructions

### 1. Start SQL Server (Docker recommended)
Run:
```
docker run -e "ACCEPT_EULA=Y" -e "SA_PASSWORD=Password!1"   -p 1433:1433 --name sql2022   -d mcr.microsoft.com/mssql/server:2022-latest
```

### 2. Execute OLTP scripts (in order)
- DB_CREATION.sql 
- DB_INSERT.sql

### 3. Execute DWH scripts
- BookingDWH.sql
- BookingDWH_INSERT.sql

### 4. Open Power BI report
- Open BookingDWH_Report.pbix  
- Refresh connection to SQL Server  
- View the 3 required visualizations  

---

## IF THE UPPER ONE DOESN'T WORK 🔧 Windows ODBC Configuration (Required for Power BI & SSMS Connection)

When using SQL Server through Docker on Windows, additional ODBC configuration may be needed so that Power BI and other applications can connect properly.

### 1️ Open ODBC Data Source Administrator
- Press **Windows key**
- Type: **ODBC**
- Choose:
  - **ODBC Data Sources (32-bit)** → for some apps
  - **ODBC Data Sources (64-bit)** → for Power BI

### 2️ Add a new SQL Server ODBC connection
1. Go to the **System DSN** tab  
2. Click **Add…**
3. Select:
   - **ODBC Driver 17 for SQL Server**  
   *(or ODBC Driver 18 if 17 is not available but sometimes 18 causes problems)*
4. Click **Finish**

### 3️ Configure the DSN
Fill the fields as follows:

- **Name:** `BookingDB_Docker`
- **Server:** `localhost,1433`

Click **Next**

### 4️ Authentication settings
Choose:
- **With SQL Server authentication**
- **Login:** `sa`
- **Password:** `Password!1`

Click **Next**

### 5️ ODBC TLS / Certificate Fix (VERY IMPORTANT)
Because Docker SQL Server uses a self-signed certificate, you MUST enable:

✔ **Trust server certificate**

To do that:
- Check: **"Trust server certificate"**

### 6️ Complete the setup
1. Leave defaults
2. Click **Test Connection**
3. You should see: **TESTS COMPLETED SUCCESSFULLY!**

---

## 🔌 Connecting Power BI to SQL Server using ODBC

When SQL Server runs in Docker or when SSL trust errors appear, connecting via ODBC is the most reliable method.  
Follow these steps:

### 1️ Open Power BI
Launch **Power BI Desktop**.

### 2️ Go to Get Data
- Click **Home**
- Click **Get Data**
- Choose **More…**

### 3️ Select ODBC as data source
- Enter the credentials

---

## Visualizations Included
1. Total Revenue by Month & Year  
2. Number of Reservations per Property  
3. Average Rating per Property  
