----------------Create the database-------------------------------

CREATE DATABASE FoodserviceDB;

USE FoodserviceDB; 
GO


------ script to drop all tables if they exist---------
IF OBJECT_ID('Restaurants', 'U') IS NOT NULL
    DROP TABLE Restaurants;

IF OBJECT_ID('Consumers', 'U') IS NOT NULL
    DROP TABLE Consumers;

IF OBJECT_ID('Ratings', 'U') IS NOT NULL
    DROP TABLE Ratings;

IF OBJECT_ID('Restaurant_Cuisines', 'U') IS NOT NULL
    DROP TABLE Restaurant_Cuisines;


------------------alter the Ratings table to add the Primary Key-------------------------------
ALTER TABLE Ratings
ADD  Rating_ID INT IDENTITY(1, 1) PRIMARY KEY;


------------------alter the Ratings table to make Consumer_ID the Foreign key constraint---------------------------------
ALTER TABLE Ratings
ADD CONSTRAINT fk_ratings_consumer
FOREIGN KEY (Consumer_ID) REFERENCES Consumers(Consumer_ID);


-------------------alter the Ratings table to make Restaurant_ID the Foreign key constraint---------------------
ALTER TABLE Ratings
ADD CONSTRAINT fk_ratings_restaurant
FOREIGN KEY (Restaurant_ID) REFERENCES Restaurants(Restaurant_ID);


--------------------alter the Restaurant_Cuisines table to add the Primary key-------------------------
ALTER TABLE Restaurant_Cuisines
ADD  Restaurant_Cuisine_ID INT IDENTITY(1, 1) PRIMARY KEY;


-------------alter the Restaurant_Cuisines table to make Restaurant_ID the Foreign key constraint---------------------
ALTER TABLE Restaurant_Cuisines
ADD CONSTRAINT fk_restaurant_cuisines_restaurant
FOREIGN KEY (Restaurant_id) REFERENCES Restaurants(Restaurant_id);


-------------------------Question 1----------------------------
---------Restaurants with a Medium range price with open area, serving Mexican food-----------
SELECT r.Name
FROM Restaurants r
JOIN Restaurant_Cuisines rc ON r.Restaurant_id = rc.Restaurant_id
WHERE r.Price = 'Medium' AND r.Area = 'Open' AND rc.Cuisine = 'Mexican';



----------Question 2------------------
---------------Comparison of Restaurants with Overall Rating 1 for Mexican and Italian Food-------------
SELECT 
    COUNT(DISTINCT CASE WHEN rc.Cuisine = 'Mexican' THEN r.Restaurant_ID END) AS Mexican_Restaurants,
    COUNT(DISTINCT CASE WHEN rc.Cuisine = 'Italian' THEN r.Restaurant_ID END) AS Italian_Restaurants
FROM  Restaurants r
JOIN Restaurant_Cuisines rc ON r.Restaurant_ID = rc.Restaurant_ID
JOIN Ratings ra ON r.Restaurant_ID = ra.Restaurant_ID
WHERE ra.Overall_Rating = 1 AND (rc.Cuisine = 'Mexican' OR rc.Cuisine = 'Italian');



------------------------QUESTION 3-----------------------------
---------Average age of consumers who have given a 0 Service rating------------------

SELECT ROUND(AVG(c.Age), 0) AS Average_Age
FROM Consumers c
JOIN Ratings r ON c.Consumer_ID = r.Consumer_ID
WHERE r.Service_Rating = 0;



-----------------QUESTION 4--------------------------
--------Restaurants Ranked by the Youngest Consumer's Food Rating:-----------------
  SELECT r.Name RestaurantName, ra.Food_Rating
FROM Ratings ra
JOIN Restaurants r ON ra.Restaurant_ID = r.Restaurant_ID
JOIN 
    (SELECT Restaurant_ID, MIN(Age) AS YoungestAge
     FROM Consumers c
     JOIN Ratings ra ON c.Consumer_ID = ra.Consumer_ID
     GROUP BY Restaurant_ID) AS y ON ra.Restaurant_ID = y.Restaurant_ID
JOIN Consumers c ON ra.Consumer_ID = c.Consumer_ID AND c.Age = y.YoungestAge
ORDER BY ra.Food_Rating DESC;



-----------------Question 5--------------------------
----------------Stored Procedure to Update Service Rating---------------------
GO
CREATE OR ALTER PROCEDURE UpdateServiceRatingWithParking
AS
BEGIN
    UPDATE ra
    SET ra.Service_Rating = 2
    FROM Ratings ra
    INNER JOIN Restaurants r ON ra.Restaurant_ID = r.Restaurant_ID
    WHERE r.Parking IN ('Yes', 'Public');
END;
GO


-------------Run the procedure-----------------
EXEC UpdateServiceRatingWithParking;

---------------Verify the update----------------
SELECT * FROM Ratings;



--------------------Question 6a Consumers� Ratings on Mexican Cuisine  Using EXISTS AND HAVING----------------------
SELECT  TOP (5) c.Consumer_ID, c.City, c.Age, COUNT(ra.Restaurant_ID) AS TotalHighRatings
FROM consumers c
INNER JOIN ratings ra ON c.Consumer_ID = ra.Consumer_ID
INNER JOIN restaurant_cuisines rc ON ra.Restaurant_ID = rc.Restaurant_ID
WHERE ra.Overall_Rating = 2 
 AND rc.Cuisine = 'Mexican'  AND c.City IN ('San Luis Potosi', 'Ciudad Victoria') AND EXISTS ( 
        SELECT 1
        FROM ratings ra2
        INNER JOIN restaurant_cuisines rc2 ON ra2.Restaurant_ID = rc2.Restaurant_ID
        WHERE  ra2.Consumer_ID = c.Consumer_ID AND ra2.Overall_Rating = 2 AND rc2.Cuisine = 'Mexican'
    )
GROUP BY c.Consumer_ID, c.City, c.Age
HAVING c.Age > 25 
ORDER BY TotalHighRatings DESC, c.Age DESC;



--------------------Question 6b Consumer Preferences by Age Group (21 to 30) Using IN----------------------
SELECT r.Alcohol_Service, COUNT(*) AS PreferenceCount
FROM Ratings ra
JOIN Consumers c ON ra.Consumer_ID = c.Consumer_ID
JOIN Restaurants r ON ra.Restaurant_ID = r.Restaurant_ID
WHERE c.Age IN (
    SELECT Age 
    FROM Consumers 
    WHERE Age BETWEEN 21 AND 30
)
GROUP BY r.Alcohol_Service
ORDER BY PreferenceCount DESC;



--------------------Question 6c  Capitalize RestausrantName and Rounding Up Using System Functions----------------------
SELECT 
    UPPER(Name) AS RestaurantName, 
    CAST(ROUND(Latitude, 0) AS INT) AS RoundedLatitude, 
    CAST(ROUND(Longitude, 0) AS INT) AS RoundedLongitude,
	State
FROM restaurants
WHERE Price = 'Low'
ORDER BY Name;



-------------Question 6d Budget level of Student and Cusines with Food rating (Using GROUP BY, HAVING)------
SELECT r.Name AS RestaurantName, c.Occupation, c.Budget,rc.Cuisine,
AVG(ra.Food_Rating) AS AvgFoodRating
FROM Restaurants r
JOIN Restaurant_Cuisines rc ON r.Restaurant_ID = rc.Restaurant_ID
JOIN Ratings ra ON r.Restaurant_ID = ra.Restaurant_ID
JOIN Consumers c ON ra.Consumer_ID = c.Consumer_ID
WHERE c.Occupation = 'Student' 
GROUP BY r.Name, c.Occupation, c.Budget, rc.Cuisine
HAVING AVG(ra.Food_Rating) > 1;
