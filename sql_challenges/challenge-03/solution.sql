------ SQL Lesson 10: Queries with aggregates Pt.1 -----------
SELECT MAX(Years_employed) FROM employees;
SELECT AVG(Years_employed), Role FROM employees GROUP BY Role;
SELECT SUM(Years_employed), Building FROM employees GROUP BY Building;

------ SQL Lesson 11: Queries with aggregates Pt.2 ----------
SELECT COUNT(Role) FROM employees WHERE Role = "Artist";
SELECT COUNT(Name), Role FROM employees GROUP BY Role;
SELECT SUM(Years_employed), Role FROM employees GROUP BY Role HAVING Role="Engineer";

------ Aggregating Rows: Databases for Developers -----------
select count ( distinct shape) number_of_shapes,
       stddev (distinct weight) distinct_weight_stddev
from  bricks;

select shape, sum (weight) shape_weight
from   bricks
group by shape;

select shape, sum ( weight )
from   bricks
group  by shape
having sum (weight) < 4;

