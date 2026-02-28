## SQL Lesson 10: Queries with aggregates Pt.1

```sql
SELECT AGG_FUNC(column_or_expression) AS aggregate_description, …
FROM mytable
WHERE constraint_expression;
```

![alt text](image.png)

```sql
SELECT AGG_FUNC(column_or_expression) AS aggregate_description, …
FROM mytable
WHERE constraint_expression
GROUP BY column;
```
### Examples:

![alt text](image-1.png)
![alt text](image-2.png)
![alt text](image-3.png)

## SQL Lesson 11: Queries with aggregates Pt.2

```sql
SELECT group_by_column, AGG_FUNC(column_expression) AS aggregate_result_alias, …
FROM mytable
WHERE condition
GROUP BY column
HAVING group_condition;
```
### Examples:

![alt text](image-4.png)
![alt text](image-5.png)
![alt text](image-6.png)
