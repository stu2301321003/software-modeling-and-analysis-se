USE BookingDB;
GO

---------------------------------------------------------
-- USERS
---------------------------------------------------------
INSERT INTO [User] (first_name, last_name, email, phone, role)
VALUES
('Ivan', 'Petrov', 'ivan.petrov@example.com', '0888123456', 'guest'),
('Maria', 'Georgieva', 'maria.georgieva@example.com', '0888765432', 'guest'),
('Georgi', 'Dimitrov', 'georgi.dimitrov@example.com', '0888111222', 'host'),
('Elena', 'Stoyanova', 'elena.stoyanova@example.com', '0899776655', 'host'),
('Admin', 'User', 'admin@example.com', NULL, 'admin');
GO


---------------------------------------------------------
-- PROPERTIES
---------------------------------------------------------
INSERT INTO Property (name, description, address, city, country, capacity, base_price, cleaning_fee)
VALUES
('Cozy Studio Downtown', 'Small studio in the center of Sofia.', 'Vitosha 15', 'Sofia', 'Bulgaria', 2, 60.00, 15.00),
('Sea View Apartment', 'Beautiful view of the Black Sea.', 'Primorska 22', 'Varna', 'Bulgaria', 4, 120.00, 25.00),
('Mountain House', 'Quiet cabin near the ski slopes.', 'Borovets 3', 'Samokov', 'Bulgaria', 6, 180.00, 30.00);
GO


---------------------------------------------------------
-- AMENITIES
---------------------------------------------------------
INSERT INTO Amenity (name, description)
VALUES
('WiFi', 'High-speed internet'),
('Parking', 'Private parking spot'),
('Air Conditioning', 'AC in all rooms'),
('Kitchen', 'Fully equipped kitchen'),
('Balcony', 'Outdoor balcony area');
GO


---------------------------------------------------------
-- PROPERTY-AMENITY (M:N)
---------------------------------------------------------
INSERT INTO PropertyAmenity (property_id, amenity_id)
VALUES
(1, 1), -- Studio + WiFi
(1, 3), -- Studio + AC
(2, 1), -- Sea View Apt + WiFi
(2, 5), -- Sea View Apt + Balcony
(2, 4), -- Sea View Apt + Kitchen
(3, 2), -- Mountain House + Parking
(3, 4), -- Mountain House + Kitchen
(3, 5); -- Mountain House + Balcony
GO


---------------------------------------------------------
-- RESERVATIONS
---------------------------------------------------------
INSERT INTO Reservation (user_id, property_id, check_in, check_out, guests_count, status)
VALUES
(1, 1, '2025-07-01', '2025-07-05', 2, 'confirmed'),
(2, 2, '2025-08-10', '2025-08-15', 3, 'confirmed'),
(1, 3, '2025-12-20', '2025-12-27', 4, 'pending'),
(2, 1, '2025-09-01', '2025-09-03', 1, 'completed');
GO


---------------------------------------------------------
-- PAYMENTS
---------------------------------------------------------
INSERT INTO Payment (reservation_id, amount, currency, method, status)
VALUES
(1, 255.00, 'EUR', 'card', 'paid'),
(2, 625.00, 'EUR', 'bank', 'paid'),
(3, 1290.00, 'EUR', 'card', 'pending'),
(4, 135.00, 'EUR', 'cash', 'paid');
GO


---------------------------------------------------------
-- REVIEWS
---------------------------------------------------------
INSERT INTO Review (user_id, property_id, rating, comment)
VALUES
(1, 1, 5, 'Amazing stay, very cozy and clean.'),
(2, 2, 4, 'Beautiful view and great location.'),
(1, 3, 5, 'Perfect winter vacation place.');
GO


---------------------------------------------------------
-- MESSAGES
---------------------------------------------------------
INSERT INTO Message (user_id, property_id, content)
VALUES
(1, 1, 'Hello, is early check-in possible?'),
(2, 2, 'Do you provide airport pickup?'),
(1, 3, 'Can we bring pets?'),
(3, 1, 'Your reservation is confirmed.'),
(4, 2, 'Thank you for your booking!');
GO
---------

DECLARE @newRes INT;  -- outer param

EXEC CreateReservation
    @user_id = 1,
    @property_id = 2,
    @check_in = '2025-11-01',
    @check_out = '2025-11-05',
    @guests_count = 2,
    @reservation_id = @newRes OUTPUT;

SELECT @newRes AS New_Reservation_ID;


SELECT * from Reservation;

SELECT 
    r.reservation_id,
    r.user_id,
    r.property_id,
    r.check_in,
    r.check_out,
    dbo.fn_TotalPrice(r.reservation_id) AS TotalPrice
FROM Reservation r;
