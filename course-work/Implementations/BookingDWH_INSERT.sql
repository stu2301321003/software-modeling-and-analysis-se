
USE BookingDWH;
GO

INSERT INTO DimUser (original_user_id, full_name, role)
VALUES
(1, 'John Smith', 'customer'),
(2, 'Alice Brown', 'customer'),
(3, 'Mark Johnson', 'host'),
(4, 'Emily Carter', 'customer');


INSERT INTO DimProperty (original_property_id, name, capacity, base_price, cleaning_fee)
VALUES
(101, 'Cozy Apartment City Center', 3, 80, 20),
(102, 'Beachside Villa', 6, 150, 40),
(103, 'Mountain Cabin', 4, 120, 25);



INSERT INTO DimProperty (original_property_id, name, capacity, base_price, cleaning_fee)
VALUES
(101, 'Cozy Apartment City Center', 3, 80, 20),
(102, 'Beachside Villa', 6, 150, 40),
(103, 'Mountain Cabin', 4, 120, 25);

INSERT INTO DimLocation (city, country)
VALUES
('Sofia', 'Bulgaria'),
('Varna', 'Bulgaria'),
('Plovdiv', 'Bulgaria');


INSERT INTO DimStatus (status_type, status_value)
VALUES
('reservation', 'confirmed'),
('reservation', 'canceled'),
('payment', 'paid'),
('payment', 'pending');



INSERT INTO FactReservation
(user_key, property_key, location_key, checkin_date_key, checkout_date_key, status_key, nights, total_price)
VALUES
(1, 1, 1, 20240101, 20240105, 1, 4, 4 * 80 + 20),

(2, 2, 2, 20240210, 20240215, 1, 5, 5 * 150 + 40),

(3, 3, 3, 20240305, 20240307, 2, 2, 2 * 120 + 25),

(4, 1, 1, 20240410, 20240412, 1, 2, 2 * 80 + 20);


INSERT INTO FactPayment (reservation_key, payment_date_key, status_key, amount)
VALUES
(1, 20240101, 3, 100),
(1, 20240103, 3, 220),

(2, 20240210, 3, 150),
(2, 20240212, 3, 190),
(2, 20240214, 3, 200),

(3, 20240306, 4, 50),

(4, 20240410, 3, 160);



INSERT INTO FactReview (user_key, property_key, location_key, review_date_key, rating)
VALUES
(1, 1, 1, 20240106, 5),
(2, 2, 2, 20240216, 4),
(4, 1, 1, 20240413, 5);