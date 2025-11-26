CREATE DATABASE BookingDB;
GO


USE BookingDB;
GO


CREATE TABLE [User] (
    user_id           INT IDENTITY(1,1) CONSTRAINT PK_User PRIMARY KEY,
    first_name        NVARCHAR(50)  NOT NULL,
    last_name         NVARCHAR(50)  NOT NULL,
    email             NVARCHAR(255) NOT NULL,
    phone             NVARCHAR(20)  NULL,
    role              NVARCHAR(20)  NOT NULL
        CONSTRAINT CHK_User_Role CHECK (role IN ('guest','host','admin')),
    registration_date DATETIME2(0)  NOT NULL
        CONSTRAINT DF_User_RegistrationDate DEFAULT (SYSDATETIME())
);

-- Unique email
CREATE UNIQUE INDEX UX_User_Email ON [User](email);
GO


-------------------------------------------------------------------------------
CREATE TABLE Property (
    property_id  INT IDENTITY(1,1) CONSTRAINT PK_Property PRIMARY KEY,
    name         NVARCHAR(200) NOT NULL,
    description  NVARCHAR(MAX) NULL,
    address      NVARCHAR(255) NOT NULL,
    city         NVARCHAR(100) NOT NULL,
    country      NVARCHAR(100) NOT NULL,
    capacity     INT           NOT NULL
        CONSTRAINT CHK_Property_Capacity CHECK (capacity > 0),
    base_price   DECIMAL(10,2) NOT NULL
        CONSTRAINT CHK_Property_BasePrice CHECK (base_price >= 0),
    cleaning_fee DECIMAL(10,2) NOT NULL
        CONSTRAINT CHK_Property_CleaningFee CHECK (cleaning_fee >= 0)
);
GO

-- Index for location search
CREATE INDEX IX_Property_Location ON Property(country, city);
GO

-------------------------------------------------------------------------------
CREATE TABLE Reservation (
    reservation_id INT IDENTITY(1,1) CONSTRAINT PK_Reservation PRIMARY KEY,
    user_id        INT          NOT NULL,
    property_id    INT          NOT NULL,
    check_in       DATE         NOT NULL,
    check_out      DATE         NOT NULL,
    guests_count   INT          NOT NULL
        CONSTRAINT CHK_Reservation_Guests CHECK (guests_count > 0),
    status         NVARCHAR(20) NOT NULL
        CONSTRAINT CHK_Reservation_Status
            CHECK (status IN ('pending','confirmed','cancelled','completed')),
    created_at     DATETIME2(0) NOT NULL
        CONSTRAINT DF_Reservation_CreatedAt DEFAULT (SYSDATETIME())
);

ALTER TABLE Reservation
    ADD CONSTRAINT FK_Reservation_User
        FOREIGN KEY (user_id) REFERENCES [User](user_id);

ALTER TABLE Reservation
    ADD CONSTRAINT FK_Reservation_Property
        FOREIGN KEY (property_id) REFERENCES Property(property_id);
GO

-- Индекс за проверки на заетост / търсене
CREATE INDEX IX_Reservation_Property_Dates
    ON Reservation(property_id, check_in, check_out);
GO


-------------------------------------------------------------------------------
CREATE TABLE Payment (
    payment_id     INT IDENTITY(1,1) CONSTRAINT PK_Payment PRIMARY KEY,
    reservation_id INT           NOT NULL,
    amount         DECIMAL(10,2) NOT NULL
        CONSTRAINT CHK_Payment_Amount CHECK (amount >= 0),
    currency       CHAR(3)       NOT NULL
        CONSTRAINT DF_Payment_Currency DEFAULT ('EUR'),
    method         NVARCHAR(50)  NOT NULL
        CONSTRAINT CHK_Payment_Method
            CHECK (method IN ('card','cash','bank','apple_pay','google_pay')),
    payment_date   DATETIME2(0)  NOT NULL
        CONSTRAINT DF_Payment_PaymentDate DEFAULT (SYSDATETIME()),
    status         NVARCHAR(20)  NOT NULL
        CONSTRAINT CHK_Payment_Status
            CHECK (status IN ('pending','paid','failed','refunded'))
);

ALTER TABLE Payment
    ADD CONSTRAINT FK_Payment_Reservation
        FOREIGN KEY (reservation_id) REFERENCES Reservation(reservation_id);
GO

CREATE INDEX IX_Payment_Reservation ON Payment(reservation_id);
GO

-------------------------------------------------------------------------------
CREATE TABLE Review (
    review_id    INT IDENTITY(1,1) CONSTRAINT PK_Review PRIMARY KEY,
    user_id      INT           NOT NULL,
    property_id  INT           NOT NULL,
    rating       TINYINT       NOT NULL
        CONSTRAINT CHK_Review_Rating CHECK (rating BETWEEN 1 AND 5),
    comment      NVARCHAR(1000) NULL,
    created_at   DATETIME2(0)  NOT NULL
        CONSTRAINT DF_Review_CreatedAt DEFAULT (SYSDATETIME())
);

ALTER TABLE Review
    ADD CONSTRAINT FK_Review_User
        FOREIGN KEY (user_id) REFERENCES [User](user_id);

ALTER TABLE Review
    ADD CONSTRAINT FK_Review_Property
        FOREIGN KEY (property_id) REFERENCES Property(property_id);
GO

-- По едно ревю на потребител за даден имот
CREATE UNIQUE INDEX UX_Review_User_Property
    ON Review(user_id, property_id);
GO

CREATE INDEX IX_Review_Property ON Review(property_id);
GO




-------------------------------------------------------------------------------
CREATE TABLE Amenity (
    amenity_id  INT IDENTITY(1,1) CONSTRAINT PK_Amenity PRIMARY KEY,
    name        NVARCHAR(100) NOT NULL,
    description NVARCHAR(255) NULL
);

CREATE UNIQUE INDEX UX_Amenity_Name ON Amenity(name);
GO

-------------------------------------------------------------------------------
CREATE TABLE PropertyAmenity (
    property_id INT NOT NULL,
    amenity_id  INT NOT NULL,
    CONSTRAINT PK_PropertyAmenity PRIMARY KEY (property_id, amenity_id)
);

ALTER TABLE PropertyAmenity
    ADD CONSTRAINT FK_PropertyAmenity_Property
        FOREIGN KEY (property_id) REFERENCES Property(property_id);

ALTER TABLE PropertyAmenity
    ADD CONSTRAINT FK_PropertyAmenity_Amenity
        FOREIGN KEY (amenity_id) REFERENCES Amenity(amenity_id);
GO

-------------------------------------------------------------------------------
CREATE TABLE Message (
    message_id  INT IDENTITY(1,1) CONSTRAINT PK_Message PRIMARY KEY,
    user_id     INT           NOT NULL, -- изпращач
    property_id INT           NOT NULL,
    sent_at     DATETIME2(0)  NOT NULL
        CONSTRAINT DF_Message_SentAt DEFAULT (SYSDATETIME()),
    content     NVARCHAR(MAX) NOT NULL
);

ALTER TABLE Message
    ADD CONSTRAINT FK_Message_User
        FOREIGN KEY (user_id) REFERENCES [User](user_id);

ALTER TABLE Message
    ADD CONSTRAINT FK_Message_Property
        FOREIGN KEY (property_id) REFERENCES Property(property_id);
GO

CREATE INDEX IX_Message_Property ON Message(property_id);
GO


--***********************
--FUNCTION--
CREATE OR ALTER FUNCTION fn_TotalPrice (@reservation_id INT)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @result DECIMAL(10,2);

    SELECT @result =
        CASE
            WHEN DATEDIFF(DAY, r.check_in, r.check_out) <= 0 THEN NULL
            ELSE DATEDIFF(DAY, r.check_in, r.check_out) * p.base_price + p.cleaning_fee
        END
    FROM Reservation r
    JOIN Property p ON r.property_id = p.property_id
    WHERE r.reservation_id = @reservation_id;

    RETURN @result;
END;
GO



--***********************
--STORED PROCEDURE--
CREATE OR ALTER PROCEDURE CreateReservation
    @user_id      INT,
    @property_id  INT,
    @check_in     DATE,
    @check_out    DATE,
    @guests_count INT,
    @reservation_id INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- 1) Date validation
    IF (@check_in >= @check_out)
    BEGIN
        RAISERROR('check_in трябва да е преди check_out.', 16, 1);
        RETURN;
    END;

    -- 2) User check
    IF NOT EXISTS (SELECT 1 FROM [User] WHERE user_id = @user_id)
    BEGIN
        RAISERROR('Потребителят не съществува.', 16, 1);
        RETURN;
    END;

    -- 3) Property check
    IF NOT EXISTS (SELECT 1 FROM Property WHERE property_id = @property_id)
    BEGIN
        RAISERROR('Имотът не съществува.', 16, 1);
        RETURN;
    END;

    -- 4) Availability check
    IF EXISTS (
        SELECT 1
        FROM Reservation r
        WHERE r.property_id = @property_id
          AND r.status IN ('pending','confirmed')
          AND NOT (
                @check_out  <= r.check_in
            OR  @check_in   >= r.check_out
          )
    )
    BEGIN
        RAISERROR('Имотът е зает в избрания период.', 16, 1);
        RETURN;
    END;

    -- 5) Creation
    INSERT INTO Reservation (user_id, property_id, check_in, check_out,
                             guests_count, status, created_at)
    VALUES (@user_id, @property_id, @check_in, @check_out,
            @guests_count, 'confirmed', SYSDATETIME());

    SET @reservation_id = SCOPE_IDENTITY();
END;
GO



--***********************
--TRIGGER--
CREATE OR ALTER TRIGGER TR_Reservation_PreventOverlap
ON Reservation
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Проверяваме за всяка нова/обновена резервация
    IF EXISTS (
        SELECT 1
        FROM Reservation r
        JOIN inserted i
          ON r.property_id = i.property_id
         AND r.reservation_id <> i.reservation_id
         AND r.status IN ('pending','confirmed')
         AND i.status IN ('pending','confirmed')
         AND NOT (
                i.check_out <= r.check_in
             OR i.check_in  >= r.check_out
         )
    )
    BEGIN
        RAISERROR('Имотът вече е резервиран в този период (trigger).', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;
END;
GO


--************
--DECLARE--
DECLARE @newRes INT;
EXEC CreateReservation
    @user_id = 1,
    @property_id = 1,
    @check_in = '2025-07-01',
    @check_out = '2025-07-05',
    @guests_count = 2,
    @reservation_id = @newRes OUTPUT;

SELECT @newRes AS NewReservationId;