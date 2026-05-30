------ Exercise 1: Team Velocity
SELECT
    t.name AS team_name,

    SUM(
        CASE
            WHEN task.status = 'completed' THEN 1
            ELSE 0
        END
    ) AS completed_tasks,

    COUNT(DISTINCT u.id) AS team_members,

    ROUND(
        SUM(
            CASE
                WHEN task.status = 'completed' THEN 1
                ELSE 0
            END
        ) / COUNT(DISTINCT u.id),
        2
    ) AS velocity,

    CASE
        WHEN ROUND(
            SUM(
                CASE
                    WHEN task.status = 'completed' THEN 1
                    ELSE 0
                END
            ) / COUNT(DISTINCT u.id),
            2
        ) < 1
        THEN 'Below Average'
        ELSE 'Average or Above'
    END AS velocity_flag

FROM teams t
LEFT JOIN users u
    ON t.id = u.team_id
LEFT JOIN tasks task
    ON u.id = task.assigned_to

GROUP BY t.name
ORDER BY velocity DESC;

----------------- Exercise 2: On-Time Delivery Rate
SELECT
    priority,

    COUNT(*) AS total_completed_tasks,

    SUM(
        CASE
            WHEN completed_at <= due_date
            THEN 1
            ELSE 0
        END
    ) AS on_time_tasks,

    ROUND(
        (
            SUM(
                CASE
                    WHEN completed_at <= due_date
                    THEN 1
                    ELSE 0
                END
            ) * 100
        ) / COUNT(*),
        2
    ) AS on_time_delivery_rate,

    ROUND(
        AVG(
            CASE
                WHEN completed_at > due_date
                THEN (CAST(completed_at AS DATE) - due_date) * 24
            END
        ),
        2
    ) AS avg_late_hours

FROM tasks

WHERE status = 'completed'
  AND due_date IS NOT NULL
  AND completed_at IS NOT NULL

GROUP BY priority

ORDER BY
    CASE priority
        WHEN 'critical' THEN 1
        WHEN 'high' THEN 2
        WHEN 'medium' THEN 3
        WHEN 'low' THEN 4
    END;

-------------- Exercise 3: Improve "Tasks per Team" (KPI 2 from class)
SELECT
    t.name AS team_name,

    -- Total tasks
    COUNT(ts.id) AS total_tasks,

    -- Active tasks
    SUM(
        CASE
            WHEN ts.status IN ('open', 'in_progress', 'blocked')
            THEN 1
            ELSE 0
        END
    ) AS active_tasks,

    -- Completion rate
    ROUND(
        SUM(
            CASE
                WHEN ts.status = 'completed'
                THEN 1
                ELSE 0
            END
        ) * 100 /
        CASE
            WHEN SUM(
                CASE
                    WHEN ts.status != 'cancelled'
                    THEN 1
                    ELSE 0
                END
            ) = 0
            THEN 1
            ELSE SUM(
                CASE
                    WHEN ts.status != 'cancelled'
                    THEN 1
                    ELSE 0
                END
            )
        END,
        2
    ) AS completion_rate,

    -- Health score
    CASE
        WHEN SUM(
            CASE
                WHEN ts.status IN ('open', 'in_progress', 'blocked')
                THEN 1
                ELSE 0
            END
        ) > 10
        THEN 'Overloaded'

        WHEN SUM(
            CASE
                WHEN ts.status IN ('open', 'in_progress', 'blocked')
                THEN 1
                ELSE 0
            END
        ) BETWEEN 5 AND 10
        THEN 'Healthy'

        ELSE 'Underutilized'
    END AS health_score

FROM teams t

LEFT JOIN users u
    ON u.team_id = t.id

LEFT JOIN tasks ts
    ON ts.assigned_to = u.id

GROUP BY t.id, t.name

ORDER BY active_tasks DESC;

-------------- Exercise 4: Improve "Average Resolution Time" (KPI 5 from class)
SELECT
    priority,

    COUNT(*) AS completed_task_count,

    -- Average resolution time
    ROUND(
        AVG(
            (CAST(completed_at AS DATE) - CAST(created_at AS DATE)) * 24
        ),
        2
    ) AS avg_resolution_hours,

    -- Median resolution time
    ROUND(
        PERCENTILE_CONT(0.5)
        WITHIN GROUP (
            ORDER BY
            (CAST(completed_at AS DATE) - CAST(created_at AS DATE)) * 24
        ),
        2
    ) AS median_resolution_hours,

    -- Fastest resolution time
    ROUND(
        MIN(
            (CAST(completed_at AS DATE) - CAST(created_at AS DATE)) * 24
        ),
        2
    ) AS fastest_resolution_hours,

    -- Slowest resolution time
    ROUND(
        MAX(
            (CAST(completed_at AS DATE) - CAST(created_at AS DATE)) * 24
        ),
        2
    ) AS slowest_resolution_hours,

    -- SLA Target Check
    CASE
        WHEN priority = 'critical'
             AND AVG(
                 (CAST(completed_at AS DATE) - CAST(created_at AS DATE)) * 24
             ) <= 24
        THEN 'Target Met'

        WHEN priority = 'high'
             AND AVG(
                 (CAST(completed_at AS DATE) - CAST(created_at AS DATE)) * 24
             ) <= 72
        THEN 'Target Met'

        WHEN priority = 'medium'
             AND AVG(
                 (CAST(completed_at AS DATE) - CAST(created_at AS DATE)) * 24
             ) <= 168
        THEN 'Target Met'

        WHEN priority = 'low'
             AND AVG(
                 (CAST(completed_at AS DATE) - CAST(created_at AS DATE)) * 24
             ) <= 336
        THEN 'Target Met'

        ELSE 'Target Missed'
    END AS target_met

FROM tasks

WHERE status = 'completed'
  AND completed_at IS NOT NULL

GROUP BY priority

ORDER BY
    CASE priority
        WHEN 'critical' THEN 1
        WHEN 'high' THEN 2
        WHEN 'medium' THEN 3
        WHEN 'low' THEN 4
    END;

--------------- Exercise 5: Improve "Overdue Tasks"
-- DETAILED OVERDUE TASK REPORT

SELECT
    ts.title AS task_title,
    u.full_name AS assignee,
    t.name AS team_name,
    ts.priority,
    ts.due_date,

    TRUNC(SYSDATE) - TRUNC(ts.due_date) AS days_overdue,

    CASE
        WHEN ts.priority = 'critical'
             AND (TRUNC(SYSDATE) - TRUNC(ts.due_date)) > 0
        THEN 'CRITICAL'

        WHEN ts.priority = 'high'
             AND (TRUNC(SYSDATE) - TRUNC(ts.due_date)) > 2
        THEN 'HIGH'

        WHEN ts.priority = 'medium'
             AND (TRUNC(SYSDATE) - TRUNC(ts.due_date)) > 5
        THEN 'MEDIUM'

        ELSE 'LOW'
    END AS severity

FROM tasks ts

LEFT JOIN users u
    ON ts.assigned_to = u.id

LEFT JOIN teams t
    ON u.team_id = t.id

WHERE ts.due_date < TRUNC(SYSDATE)
  AND ts.status NOT IN ('completed', 'cancelled')
  AND ts.due_date IS NOT NULL

ORDER BY
    CASE
        WHEN ts.priority = 'critical' THEN 1
        WHEN ts.priority = 'high' THEN 2
        WHEN ts.priority = 'medium' THEN 3
        ELSE 4
    END,
    days_overdue DESC;


-- SUMMARY REPORT BY SEVERITY

SELECT
    CASE
        WHEN ts.priority = 'critical'
             AND (TRUNC(SYSDATE) - TRUNC(ts.due_date)) > 0
        THEN 'CRITICAL'

        WHEN ts.priority = 'high'
             AND (TRUNC(SYSDATE) - TRUNC(ts.due_date)) > 2
        THEN 'HIGH'

        WHEN ts.priority = 'medium'
             AND (TRUNC(SYSDATE) - TRUNC(ts.due_date)) > 5
        THEN 'MEDIUM'

        ELSE 'LOW'
    END AS severity,

    COUNT(*) AS overdue_task_count,

    ROUND(
        AVG(TRUNC(SYSDATE) - TRUNC(ts.due_date)),
        2
    ) AS avg_days_overdue

FROM tasks ts

WHERE ts.due_date < TRUNC(SYSDATE)
  AND ts.status NOT IN ('completed', 'cancelled')
  AND ts.due_date IS NOT NULL

GROUP BY
    CASE
        WHEN ts.priority = 'critical'
             AND (TRUNC(SYSDATE) - TRUNC(ts.due_date)) > 0
        THEN 'CRITICAL'

        WHEN ts.priority = 'high'
             AND (TRUNC(SYSDATE) - TRUNC(ts.due_date)) > 2
        THEN 'HIGH'

        WHEN ts.priority = 'medium'
             AND (TRUNC(SYSDATE) - TRUNC(ts.due_date)) > 5
        THEN 'MEDIUM'

        ELSE 'LOW'
    END

ORDER BY
    CASE
        WHEN severity = 'CRITICAL' THEN 1
        WHEN severity = 'HIGH' THEN 2
        WHEN severity = 'MEDIUM' THEN 3
        ELSE 4
    END;

----------- Exercise 6: Fix the Productivity Score
-- PROBLEM:
--
-- This metric is misleading because it only counts how many
-- tasks are assigned to each user.
--
-- Problems with this KPI:
--
-- 1. It does NOT distinguish between completed and incomplete tasks.
--    A user with many unfinished tasks may appear highly productive.
--
-- 2. It treats all tasks equally.
--    A critical production issue counts the same as a simple task.
--
-- 3. It ignores task priority and complexity.
--
-- 4. It ignores time.
--    Completing 20 tasks in one month is different from
--    completing 20 tasks in one year.
--
-- 5. It encourages quantity over quality.
--
-- 6. Unassigned tasks are ignored entirely.
--
-- Because of these issues, the metric does not accurately
-- represent real productivity.
--
-- Better KPI:
-- "Completed tasks per day, weighted by priority"
--
-- Rules:
-- - Only completed tasks are counted.
-- - Tasks are weighted by priority:
--      critical = 4 points
--      high     = 3 points
--      medium   = 2 points
--      low      = 1 point
-- - Productivity is normalized by active work days.
--
-- Formula:
-- weighted completed task points / active days
SELECT
    u.full_name,

    COUNT(ts.id) AS completed_tasks,

    SUM(
        CASE
            WHEN ts.priority = 'critical' THEN 4
            WHEN ts.priority = 'high' THEN 3
            WHEN ts.priority = 'medium' THEN 2
            WHEN ts.priority = 'low' THEN 1
            ELSE 0
        END
    ) AS weighted_productivity_score

FROM users u

LEFT JOIN tasks ts
    ON ts.assigned_to = u.id

WHERE ts.status = 'completed'

GROUP BY u.id, u.full_name

ORDER BY weighted_productivity_score DESC;

------------- Exercise 7: Fix the "Team Efficiency"
-- PROBLEM:
--
-- The metric is mathematically meaningless because task IDs are
-- identifiers, not measurable business values.
--
-- Problems with the KPI:
--
-- 1. Task IDs are arbitrary numbers generated by the database.
--    Averaging them does not measure efficiency, productivity,
--    speed, or quality.
--
-- 2. Higher task IDs only indicate newer records, not better performance.
--
-- 3. The metric cannot be explained in business terms.
--    "Average task ID" has no operational meaning.
--
-- 4. The query ignores task status.
--    Completed, cancelled, and open tasks are treated equally.
--
-- 5. It provides no insight into whether teams actually finish work.
--
-- Better KPI:
--
-- "Team efficiency = completed tasks / total non-cancelled tasks"
--
-- This measures how effectively teams finish assigned work.

SELECT
    t.name AS team_name,

    COUNT(ts.id) AS total_tasks,

    SUM(
        CASE
            WHEN ts.status = 'completed'
            THEN 1
            ELSE 0
        END
    ) AS completed_tasks,

    AVG(
        CASE
            WHEN ts.status = 'completed'
            THEN 100
            ELSE 0
        END
    ) AS efficiency_rate

FROM teams t

LEFT JOIN users u
    ON u.team_id = t.id

LEFT JOIN tasks ts
    ON ts.assigned_to = u.id

GROUP BY t.id, t.name

ORDER BY efficiency_rate DESC;

------------ Exercise 8: Fix the "Urgency Index"
-- PROBLEM:
--
-- The original query is mathematically and logically incorrect.
--
-- Problems:
--
-- 1. priority is a VARCHAR, not a number.
--    You cannot multiply text values like:
--    'high' * 10
--
-- 2. due_date is a DATE value.
--    Adding a number directly to a DATE does not create a
--    meaningful urgency metric.
--
-- 3. The query mixes incompatible data types:
--    - VARCHAR
--    - NUMBER
--    - DATE
--
-- 4. The metric has no business meaning.
--    "priority * 10 + due_date" cannot be explained
--    to stakeholders.
--
-- Better KPI:
--
-- Create a real urgency score based on:
-- - task priority
-- - due date proximity
-- - overdue status
--
-- Higher score = more urgent task.

SELECT
    title,
    priority,
    due_date,

    -- Days until due
    TRUNC(due_date) - TRUNC(SYSDATE) AS days_until_due,

    -- Priority weight
    CASE
        WHEN priority = 'critical' THEN 4
        WHEN priority = 'high' THEN 3
        WHEN priority = 'medium' THEN 2
        WHEN priority = 'low' THEN 1
        ELSE 0
    END AS priority_weight,

    -- Urgency score
    (
        CASE
            WHEN priority = 'critical' THEN 40
            WHEN priority = 'high' THEN 30
            WHEN priority = 'medium' THEN 20
            WHEN priority = 'low' THEN 10
            ELSE 0
        END
        -
        (TRUNC(due_date) - TRUNC(SYSDATE))
    ) AS urgency_score

FROM tasks

WHERE status NOT IN ('completed', 'cancelled')
  AND due_date IS NOT NULL

ORDER BY urgency_score DESC;
