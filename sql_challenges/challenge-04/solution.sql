-------- Analytic Functions: Database for Developers -----------------
1. select b.*,
       count(*) over (
         partition by shape
       ) bricks_per_shape,
       median ( weight ) over (
         partition by shape
       ) median_weight_per_shape
from   bricks b
order  by shape, weight, brick_id;

2. select b.brick_id, b.weight,
       round ( avg ( weight ) over (
         order by brick_id
       ), 2 ) running_average_weight
from   bricks b
order  by brick_id;

3. select b.*,
       min(colour) over (
         order by brick_id
         rows between 2 preceding and 1 preceding
       ) as min_colour_prev_two,
       count(*) over (
         order by weight
         range between current row and 1 following
       ) as count_same_and_plus_one
from   bricks b
order  by weight;

4. with totals as (
  select b.*,
         sum ( weight ) over (
           partition by b.shape
         ) weight_per_shape,
         sum ( weight ) over (
           order by b.brick_id
           rows between unbounded preceding and current row
         ) running_weight_by_id
  from   bricks b
)
select * from   totals
where  weight_per_shape > 4 
  and  running_weight_by_id > 4
order  by brick_id;

---------- Top Three Salaries --------------
SELECT 
    d.department_name,
    e.name,
    e.salary
FROM (
    SELECT 
        employee_id,
        name,
        salary,
        department_id,
        DENSE_RANK() OVER (
            PARTITION BY department_id
            ORDER BY salary DESC
        ) AS salary_rank
    FROM employee
) e
JOIN department d
    ON e.department_id = d.department_id
WHERE e.salary_rank <= 3
ORDER BY 
    d.department_name ASC,
    e.salary DESC,
    e.name ASC;