USE master;
GO

IF DB_ID('BookingDWH') IS NOT NULL
BEGIN
    ALTER DATABASE BookingDWH SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE BookingDWH;
END
GO

CREATE DATABASE BookingDWH;
GO

USE BookingDWH;
GO

/* =======================================================================================
   DIMENSION TABLES
======================================================================================= */


-------------------------------------------------------------------------------
CREATE TABLE DimUser (
    user_key         INT IDENTITY(1,1) PRIMARY KEY,
    original_user_id INT NOT NULL,
    full_name        NVARCHAR(200) NOT NULL,
    role             NVARCHAR(20) NOT NULL
);


-------------------------------------------------------------------------------
CREATE TABLE DimProperty (
    property_key         INT IDENTITY(1,1) PRIMARY KEY,
    original_property_id INT NOT NULL,
    name                 NVARCHAR(200) NOT NULL,
    capacity             INT NOT NULL,
    base_price           DECIMAL(10,2) NOT NULL,
    cleaning_fee         DECIMAL(10,2) NOT NULL
);


-------------------------------------------------------------------------------
CREATE TABLE DimLocation (
    location_key INT IDENTITY(1,1) PRIMARY KEY,
    city         NVARCHAR(100) NOT NULL,
    country      NVARCHAR(100) NOT NULL
);


-------------------------------------------------------------------------------
CREATE TABLE DimDate (
    date_key INT PRIMARY KEY,
    [date]   DATE NOT NULL,
    [year]   INT NOT NULL,
    [quarter] TINYINT NOT NULL,
    [month]  TINYINT NOT NULL,
    [day]    TINYINT NOT NULL
);


-------------------------------------------------------------------------------
CREATE TABLE DimStatus (
    status_key   INT IDENTITY(1,1) PRIMARY KEY,
    status_type  NVARCHAR(20) NOT NULL,   -- Reservation / Payment
    status_value NVARCHAR(20) NOT NULL
);


-------------------------------------------------------------------------------
CREATE TABLE DimAmenity (
    amenity_key         INT IDENTITY(1,1) PRIMARY KEY,
    original_amenity_id INT NOT NULL,
    name                NVARCHAR(100) NOT NULL,
    description         NVARCHAR(255)
);

/* =======================================================================================
   FACT TABLES
======================================================================================= */


-------------------------------------------------------------------------------
CREATE TABLE FactReservation (
    reservation_key    INT IDENTITY(1,1) PRIMARY KEY,
    user_key           INT NOT NULL,
    property_key       INT NOT NULL,
    location_key       INT NOT NULL,
    checkin_date_key   INT NOT NULL,
    checkout_date_key  INT NOT NULL,
    status_key         INT NOT NULL,
    nights             INT NOT NULL,
    total_price        DECIMAL(10,2) NOT NULL
);


-------------------------------------------------------------------------------
CREATE TABLE FactPayment (
    payment_key      INT IDENTITY(1,1) PRIMARY KEY,
    reservation_key  INT NOT NULL,
    payment_date_key INT NOT NULL,
    status_key       INT NOT NULL,
    amount           DECIMAL(10,2) NOT NULL
);


-------------------------------------------------------------------------------
CREATE TABLE FactReview (
    review_key      INT IDENTITY(1,1) PRIMARY KEY,
    user_key        INT NOT NULL,
    property_key    INT NOT NULL,
    location_key    INT NOT NULL,
    review_date_key INT NOT NULL,
    rating          TINYINT NOT NULL
);


-------------------------------------------------------------------------------
ALTER TABLE FactReservation
    ADD FOREIGN KEY (user_key) REFERENCES DimUser(user_key);
ALTER TABLE FactReservation
    ADD FOREIGN KEY (property_key) REFERENCES DimProperty(property_key);
ALTER TABLE FactReservation
    ADD FOREIGN KEY (location_key) REFERENCES DimLocation(location_key);
ALTER TABLE FactReservation
    ADD FOREIGN KEY (checkin_date_key) REFERENCES DimDate(date_key);
ALTER TABLE FactReservation
    ADD FOREIGN KEY (checkout_date_key) REFERENCES DimDate(date_key);
ALTER TABLE FactReservation
    ADD FOREIGN KEY (status_key) REFERENCES DimStatus(status_key);

ALTER TABLE FactPayment
    ADD FOREIGN KEY (reservation_key) REFERENCES FactReservation(reservation_key);
ALTER TABLE FactPayment
    ADD FOREIGN KEY (payment_date_key) REFERENCES DimDate(date_key);
ALTER TABLE FactPayment
    ADD FOREIGN KEY (status_key) REFERENCES DimStatus(status_key);

ALTER TABLE FactReview
    ADD FOREIGN KEY (user_key) REFERENCES DimUser(user_key);
ALTER TABLE FactReview
    ADD FOREIGN KEY (property_key) REFERENCES DimProperty(property_key);
ALTER TABLE FactReview
    ADD FOREIGN KEY (location_key) REFERENCES DimLocation(location_key);
ALTER TABLE FactReview
    ADD FOREIGN KEY (review_date_key) REFERENCES DimDate(date_key);


DECLARE @startDate DATE = '2020-01-01';
DECLARE @endDate DATE   = '2030-12-31';

;WITH n AS (
    SELECT TOP (DATEDIFF(DAY, @startDate, @endDate) + 1)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS n
    FROM master..spt_values
)
INSERT INTO DimDate (date_key, [date], [year], [quarter], [month], [day])
SELECT 
    CONVERT(INT, FORMAT(DATEADD(DAY, n, @startDate), 'yyyyMMdd')),
    DATEADD(DAY, n, @startDate),
    YEAR(DATEADD(DAY, n, @startDate)),
    DATEPART(QUARTER, DATEADD(DAY, n, @startDate)),
    MONTH(DATEADD(DAY, n, @startDate)),
    DAY(DATEADD(DAY, n, @startDate))
FROM n;


INSERT INTO DimUser (original_user_id, full_name, role)
SELECT 
    u.user_id,
    u.first_name + ' ' + u.last_name,
    u.role
FROM BookingDB.dbo.[User] u;

INSERT INTO DimProperty (original_property_id, name, capacity, base_price, cleaning_fee)
SELECT 
    p.property_id,
    p.name,
    p.capacity,
    p.base_price,
    p.cleaning_fee
FROM BookingDB.dbo.Property p;

INSERT INTO DimLocation (city, country)
SELECT DISTINCT
    p.city,
    p.country
FROM BookingDB.dbo.Property p;

INSERT INTO DimAmenity (original_amenity_id, name, description)
SELECT
    a.amenity_id,
    a.name,
    a.description
FROM BookingDB.dbo.Amenity a;

INSERT INTO DimStatus (status_type, status_value)
SELECT DISTINCT 'Reservation', r.status
FROM BookingDB.dbo.Reservation r
UNION
SELECT DISTINCT 'Payment', p.status
FROM BookingDB.dbo.Payment p;