## Multi-table queries with JOINs
```sql 
SELECT column, another_table_column, …
FROM mytable
INNER JOIN another_table 
    ON mytable.id = another_table.id
WHERE condition(s)
ORDER BY column, … ASC/DESC
LIMIT num_limit OFFSET num_offset;
```

![alt text](image.png)
![alt text](image-1.png)
![alt text](image-2.png)

## OUTER JOINS

```sql 
SELECT column, another_column, …
FROM mytable
INNER/LEFT/RIGHT/FULL JOIN another_table 
    ON mytable.id = another_table.matching_id
WHERE condition(s)
ORDER BY column, … ASC/DESC
LIMIT num_limit OFFSET num_offset;
```

![alt text](image-3.png)
![alt text](image-4.png)
![alt text](image-5.png)

