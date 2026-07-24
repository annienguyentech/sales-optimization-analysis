/*
============================================================
PROJECT: Sales Optimization Analysis
AUTHOR: Annie Nguyen
DATABASE: MySQL
============================================================

PURPOSE:
Analyze airline promotional campaigns, customer membership
revenue, booking demand, and remaining seat capacity.

MAIN TABLES:
- passenger
- membership
- booking
- ticket
- promotion
- flight
- flightlog
============================================================
*/

USE alaskaairlines;


/*
============================================================
QUESTION 1:
Which promotional campaigns were used most frequently?
============================================================
*/

SELECT
    b.CampaignID,
    p.DiscountPercentage,
    p.TargetCustomerSegment,
    COUNT(DISTINCT b.BookingID) AS TimesUsed
FROM booking AS b
INNER JOIN promotion AS p
    ON b.CampaignID = p.CampaignID
WHERE b.CampaignID IS NOT NULL
    AND TRIM(b.CampaignID) <> ''
GROUP BY
    b.CampaignID,
    p.DiscountPercentage,
    p.TargetCustomerSegment
ORDER BY
    TimesUsed DESC;


/*
Expected ranking from the analysis:

C002: 45 uses
C001: 43 uses
C004: 40 uses
C003: 39 uses
*/


/*
============================================================
QUESTION 2:
Which membership level generated the most revenue?
============================================================
*/

SELECT
    m.StatusLevel,
    ROUND(SUM(b.FinalPricePaid), 2) AS TotalRevenue,
    COUNT(DISTINCT p.PassengerID) AS UniquePassengers
FROM membership AS m
INNER JOIN passenger AS p
    ON p.MemberID = m.MemberID
INNER JOIN ticket AS t
    ON t.PassengerID = p.PassengerID
INNER JOIN booking AS b
    ON b.BookingID = t.BookingID
GROUP BY
    m.StatusLevel
ORDER BY
    TotalRevenue DESC;


/*
Expected ranking from the analysis:

MVP Gold:       $54,587.30
Member:         $51,091.74
MVP:            $51,061.72
MVP Gold 75K:   $50,076.89
MVP Gold 100K:  $43,533.57
*/


/*
============================================================
QUESTION 3:
Which campaign reached the most unique customers?
============================================================
*/

SELECT
    b.CampaignID,
    COUNT(DISTINCT t.PassengerID) AS UniqueCustomers,
    COUNT(DISTINCT b.BookingID) AS TotalBookings
FROM booking AS b
INNER JOIN ticket AS t
    ON b.BookingID = t.BookingID
WHERE b.CampaignID IS NOT NULL
    AND TRIM(b.CampaignID) <> ''
GROUP BY
    b.CampaignID
ORDER BY
    UniqueCustomers DESC;


/*
The screenshot used:

COUNT(b.BookingID) AS TotalBookings

However, joining booking to ticket can create multiple rows for the
same booking. COUNT(DISTINCT b.BookingID) prevents duplicate bookings.

Use the query below only when you need to reproduce the exact
calculation shown in the original screenshot.
*/

SELECT
    b.CampaignID,
    COUNT(DISTINCT t.PassengerID) AS UniqueCustomers,
    COUNT(b.BookingID) AS TotalBookingRecords
FROM booking AS b
INNER JOIN ticket AS t
    ON b.BookingID = t.BookingID
WHERE b.CampaignID IS NOT NULL
    AND TRIM(b.CampaignID) <> ''
GROUP BY
    b.CampaignID
ORDER BY
    UniqueCustomers DESC;


/*
Expected screenshot results:

C002: 113 unique customers, 131 booking records
C001: 106 unique customers, 124 booking records
C004: 101 unique customers, 120 booking records
C003:  93 unique customers, 107 booking records
*/


/*
============================================================
QUESTION 4:
Which flights received the most bookings?
============================================================
*/

SELECT
    b.FlightID,
    COUNT(DISTINCT b.BookingID) AS TotalBookings
FROM booking AS b
WHERE b.FlightID IS NOT NULL
GROUP BY
    b.FlightID
ORDER BY
    TotalBookings DESC,
    b.FlightID ASC;


/*
Expected top results from the analysis:

F275: 5 bookings
F343: 5 bookings
F162: 4 bookings
F291: 4 bookings
F110: 4 bookings
F297: 4 bookings
F417: 4 bookings
F144: 4 bookings
*/


/*
============================================================
QUESTION 5:
Which destinations have available seat capacity?

Assumption:
Each destination has a capacity of 150 seats.
============================================================
*/

SELECT
    f.ArrivalAirport AS Destination,
    COUNT(b.BookingID) AS TotalBookings,
    150 - COUNT(b.BookingID) AS RemainingSeats
FROM flight AS f
INNER JOIN booking AS b
    ON f.FlightID = b.FlightID
GROUP BY
    f.ArrivalAirport
HAVING
    COUNT(b.BookingID) < 150
    AND COUNT(b.BookingID) > 20
ORDER BY
    TotalBookings DESC;


/*
Expected results:

SEA: 57 bookings,  93 remaining seats
LAX: 50 bookings, 100 remaining seats
DFW: 44 bookings, 106 remaining seats
DEN: 44 bookings, 106 remaining seats
SFO: 43 bookings, 107 remaining seats
ORD: 41 bookings, 109 remaining seats
JFK: 41 bookings, 109 remaining seats
PDX: 39 bookings, 111 remaining seats
LAS: 38 bookings, 112 remaining seats
PHX: 33 bookings, 117 remaining seats
*/


/*
============================================================
ADDITIONAL ANALYSIS 1:
Calculate the average revenue per passenger for each
membership level.
============================================================
*/

SELECT
    m.StatusLevel,
    COUNT(DISTINCT p.PassengerID) AS UniquePassengers,
    ROUND(SUM(b.FinalPricePaid), 2) AS TotalRevenue,
    ROUND(
        SUM(b.FinalPricePaid)
        / NULLIF(COUNT(DISTINCT p.PassengerID), 0),
        2
    ) AS AverageRevenuePerPassenger
FROM membership AS m
INNER JOIN passenger AS p
    ON p.MemberID = m.MemberID
INNER JOIN ticket AS t
    ON t.PassengerID = p.PassengerID
INNER JOIN booking AS b
    ON b.BookingID = t.BookingID
GROUP BY
    m.StatusLevel
ORDER BY
    AverageRevenuePerPassenger DESC;


/*
============================================================
ADDITIONAL ANALYSIS 2:
Compare campaign usage, customers, and revenue.
============================================================
*/

SELECT
    p.CampaignID,
    p.DiscountPercentage,
    p.TargetCustomerSegment,
    COUNT(DISTINCT b.BookingID) AS TotalBookings,
    COUNT(DISTINCT t.PassengerID) AS UniqueCustomers,
    ROUND(SUM(b.FinalPricePaid), 2) AS TotalRevenue
FROM promotion AS p
INNER JOIN booking AS b
    ON p.CampaignID = b.CampaignID
LEFT JOIN ticket AS t
    ON b.BookingID = t.BookingID
GROUP BY
    p.CampaignID,
    p.DiscountPercentage,
    p.TargetCustomerSegment
ORDER BY
    TotalRevenue DESC;


/*
============================================================
ADDITIONAL ANALYSIS 3:
Calculate the average final price paid by campaign.
============================================================
*/

SELECT
    p.CampaignID,
    p.DiscountPercentage,
    p.TargetCustomerSegment,
    COUNT(DISTINCT b.BookingID) AS TotalBookings,
    ROUND(AVG(b.FinalPricePaid), 2) AS AverageFinalPrice,
    ROUND(SUM(b.FinalPricePaid), 2) AS TotalCampaignRevenue
FROM promotion AS p
INNER JOIN booking AS b
    ON p.CampaignID = b.CampaignID
GROUP BY
    p.CampaignID,
    p.DiscountPercentage,
    p.TargetCustomerSegment
ORDER BY
    TotalCampaignRevenue DESC;


/*
============================================================
ADDITIONAL ANALYSIS 4:
Analyze booking demand by route.
============================================================
*/

SELECT
    f.DepartureAirport,
    f.ArrivalAirport,
    COUNT(DISTINCT b.BookingID) AS TotalBookings,
    SUM(b.NumberOfPassengers) AS TotalPassengers,
    ROUND(SUM(b.FinalPricePaid), 2) AS TotalRevenue
FROM flight AS f
INNER JOIN booking AS b
    ON f.FlightID = b.FlightID
GROUP BY
    f.DepartureAirport,
    f.ArrivalAirport
ORDER BY
    TotalPassengers DESC;


/*
============================================================
ADDITIONAL ANALYSIS 5:
Identify flights with the highest passenger demand.
============================================================
*/

SELECT
    f.FlightID,
    f.DepartureAirport,
    f.ArrivalAirport,
    f.DepartureTime,
    f.ArrivalTime,
    COUNT(DISTINCT b.BookingID) AS TotalBookings,
    SUM(b.NumberOfPassengers) AS TotalPassengers,
    ROUND(SUM(b.FinalPricePaid), 2) AS TotalRevenue
FROM flight AS f
INNER JOIN booking AS b
    ON f.FlightID = b.FlightID
GROUP BY
    f.FlightID,
    f.DepartureAirport,
    f.ArrivalAirport,
    f.DepartureTime,
    f.ArrivalTime
ORDER BY
    TotalPassengers DESC;


/*
============================================================
ADDITIONAL ANALYSIS 6:
Analyze flight delays and weather conditions.
============================================================
*/

SELECT
    f.FlightID,
    f.DepartureAirport,
    f.ArrivalAirport,
    fl.ActualDepartureTime,
    fl.ActualArrivalTime,
    fl.DelayMinutes,
    fl.WeatherConditions
FROM flight AS f
INNER JOIN flightlog AS fl
    ON f.FlightID = fl.FlightID
ORDER BY
    fl.DelayMinutes DESC;


/*
============================================================
ADDITIONAL ANALYSIS 7:
Calculate average delays by weather condition.
============================================================
*/

SELECT
    fl.WeatherConditions,
    COUNT(*) AS TotalFlights,
    ROUND(AVG(fl.DelayMinutes), 2) AS AverageDelayMinutes,
    MAX(fl.DelayMinutes) AS MaximumDelayMinutes
FROM flightlog AS fl
GROUP BY
    fl.WeatherConditions
ORDER BY
    AverageDelayMinutes DESC;


/*
============================================================
END OF SALES OPTIMIZATION ANALYSIS
============================================================
*/