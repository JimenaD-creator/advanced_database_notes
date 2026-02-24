-- SQL Lesson 1: Select Queries -------------
SELECT Title FROM Movies;
SELECT Director FROM Movies;
SELECT Title, Director FROM Movies;
SELECT Title, Year FROM movies;
SELECT * FROM movies;

-- SQL Lesson 2: Queries with constraints Pt.1 ------------
SELECT Title FROM movies WHERE id = 6;
SELECT Title FROM movies WHERE year BETWEEN 2000 AND 2010;
SELECT Title FROM movies WHERE year NOT BETWEEN 2000 AND 2010;
SELECT Title, Year FROM movies WHERE id <= 5;

-- SQL Lesson 3: Queries with constraints Pt.2 -------------
SELECT Title FROM movies WHERE Title LIKE '%Toy Story%';
SELECT Title FROM movies WHERE Director = "John Lasseter";
SELECT Title, Director FROM movies WHERE Director NOT LIKE "John Lasseter";
SELECT Title FROM movies WHERE Title LIKE '%WALL-%';

--SQL Lesson 4: Filtering and sorting query results -----------
SELECT DISTINCT Director FROM movies ORDER BY Director ASC;
SELECT Title FROM movies ORDER BY Year DESC LIMIT 4;
SELECT Title FROM movies ORDER BY Title ASC LIMIT 5;
SELECT Title FROM movies ORDER BY Title ASC LIMIT 5 OFFSET 5;

-- Review: Simple Select Queries ------------------
SELECT * FROM north_american_cities WHERE Country="Canada";
SELECT * FROM north_american_cities WHERE Country="United States" ORDER BY Latitude DESC;
SELECT City FROM north_american_cities WHERE Longitude < -87.629798 ORDER BY Longitude ASC
SELECT City FROM north_american_cities WHERE Country = "Mexico" ORDER BY Population DESC LIMIT 2;
SELECT City FROM north_american_cities WHERE Country = "United States" ORDER BY Population DESC LIMIT 2 OFFSET 2;




