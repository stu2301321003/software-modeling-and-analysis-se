# Problems Encountered During the Project

## 1. MS SQL Server Installation Failure
Multiple attempts to install Microsoft SQL Server locally resulted in errors such as:
- "Cannot generate SSPI context"
- "The target principal name is incorrect"
- SPN registration failures
- Database Engine recovery handle crash

### Cause
Windows authentication + SPN misconfiguration + unreliable certificate chain.

### Resolution
SQL Server was run successfully inside Docker:
```
docker run -e "ACCEPT_EULA=Y" -e "SA_PASSWORD=Password!1"   -p 1433:1433 --name sql2022   -d mcr.microsoft.com/mssql/server:2022-latest
```

This provided a stable environment for OLTP and DWH development.

## 2. Power BI Ambiguous Relationship Errors
Issues arose due to:
- Incorrect relationship direction (One-to-Many flipped)
- Multiple active date relationships
- Fact tables connected incorrectly to dimensions

### Fix
- Rebuild Star Schema with correct 1:* directions  
- Make only one active Date relationship  
- Remove cross-filter ambiguity  

## 3. Data Warehouse Loading Cancellations
Errors such as:
"Load was cancelled by an error in loading a previous table."

### Cause
One relationship error in FactReview or FactReservation blocked all tables.

### Fix
Correct all FK directions and ensure dimensions are on the ‘1’ side.

---

All issues were resolved and the final model works correctly.
