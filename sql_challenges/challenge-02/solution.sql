------- SQL Lesson 6: Multi-table queries with JOINS -----------------
SELECT Domestic_sales, International_sales, Title FROM Boxoffice INNER JOIN Movies ON Movie_id = id;
SELECT Domestic_sales, International_sales, Title FROM Boxoffice INNER JOIN Movies ON Movie_id = id WHERE International_sales > Domestic_sales;
SELECT Title FROM Boxoffice INNER JOIN Movies ON Movie_id = id ORDER BY Rating DESC;

------- SQL Lesson 7: OUTER JOIN's -----------------------
SELECT DISTINCT Building FROM employees LEFT JOIN buildings ON Building_name = Building;
SELECT Building_name, Capacity FROM Buildings;
SELECT DISTINCT Building_name, Role FROM Buildings LEFT JOIN Employees ON Building_name = Building;

------- Interview Question ------------------
SELECT pages.page_id FROM pages LEFT JOIN page_likes ON pages.page_id = page_likes.page_id WHERE page_likes.liked_date IS NULL;
