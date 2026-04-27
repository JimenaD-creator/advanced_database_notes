-- Exercise 1 — Find the slow query
--
-- Run this query. Look at the execution plan.
-- Is Oracle using an index? Should it?
-- ============================================================

SELECT * FROM patient_visits WHERE site_id = 3;

-- Questions:
-- a) What scan type do you see? Why? A Full Table Scan. Because currently, there is 
-- no index on the site_id column. Even if there were, Oracle would likely still choose a Full Table Scan. 
-- Because site_id only has 5 possible values (1–5) distributed across 100,000 rows, a query for site_id = 3 
-- expects to return roughly 20% of the entire table (20,000 rows). It is more efficient for the database 
-- to read the blocks sequentially than to jump back and forth between an index and the table (random I/O) 
-- for such a large portion of the data.

-- b) site_id has values 1–5. Is this high or low cardinality? It is low cardinality. 
-- With only 5 unique values in a 100,000-row table, the "selectivity" is very poor.

-- c) Would adding an index on site_id help? Why or why not? In general, no, because
-- Because the data is distributed evenly, searching for one site_id grabs too many rows. 
-- The overhead of reading the index plus the table blocks would likely be slower than just reading the 
-- table once.

-- ============================================================
-- Exercise 2 — Create an index and see if it helps
--
-- Create an index on visit_date.
-- Then run the range query below and check the plan.
-- ============================================================
-- Step 1: Create it
CREATE INDEX idx_visit_date ON patient_visits(visit_date);

-- Step 3: Run the range query and check the plan
SELECT * FROM patient_visits
WHERE visit_date BETWEEN SYSDATE - 30 AND SYSDATE;

-- Questions:
-- a) Does Oracle use the index for this range? Yes. A 30-day range out of 730
-- days represents roughly aprox 4,000$ rows. Oracle typically considers this 
-- selective enough to use an INDEX RANGE SCAN. It finds the starting ROWID in the
-- index and follows the "leaf block" chain to the end date.

-- b) Change the range to the last 7 days. Does the plan change?
-- The scan type remains the same, but the "Cost" decreases. 
-- The plan will still show an INDEX RANGE SCAN. However, since 7 days is 
-- only about 1% of the data, the number of "Consistent Gets" (blocks read) will drop 
-- significantly. Oracle stays with the index because the overhead of fetching table rows via 
-- ROWIDs is very low for such a small result set.

-- c) Change to the last 700 days. What happens?
-- Oracle will likely switch back to a TABLE ACCESS FULL.
-- When we ask for 700 out of 730 days, you are asking for 95%+ of the table.
-- Oracle realizes that reading the index and then jumping to the table for 95,000 rows
-- is much slower than just reading the table sequentially from start to finish.
-- Sequential I/O (Multi-block reads) used in a full scan is faster than the random I/O 
-- required to bounce between an index and a table for nearly every row.

-- d) Why does the range size affect whether Oracle uses the index?
-- Because Oracle performs two steps: finds the addresses (ROWIDs) of the rows, and 
-- goes to the blocks  to fetch the actual data (SELECT *).
-- If the range is small, the table lookups are few and fast. If the range is large, 
-- the "Table Lookup" step becomes a bottleneck. The Optimizer calculates that it is 
-- cheaper to ignore the index entirely and read the whole table into memory in large chunks 
-- rather than looking up thousands of rows one-by-one.

-- ============================================================
-- Exercise 3 — Composite index
--
-- You often query by both patient_id AND visit_date together:
--   WHERE patient_id = 1234 AND visit_date > SYSDATE - 90
--
-- Two options:
--   Option A: Two separate indexes (one per column)
--   Option B: One composite index (patient_id, visit_date)
--
-- Create the composite index and test the query.
-- ============================================================

-- ============================================================
-- Exercise 3 — Composite index
--
-- You often query by both patient_id AND visit_date together:
--   WHERE patient_id = 1234 AND visit_date > SYSDATE - 90
--
-- Two options:
--   Option A: Two separate indexes (one per column)
--   Option B: One composite index (patient_id, visit_date)
--
-- Create the composite index and test the query.
-- ============================================================

CREATE INDEX idx_pv_patient_date ON patient_visits(patient_id, visit_date);

BEGIN
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'PATIENT_VISITS', cascade => TRUE);
END;
/

SELECT * FROM patient_visits
WHERE patient_id = 1234
  AND visit_date > SYSDATE - 90;

-- Questions:
-- a) Does the plan use the composite index? Yes. 
-- Oracle performs and INDEX RANGE SCAN on idx_pv_patient_date. Because the both 
-- columns in the WHERE clause match the columns in the index, Oracle can narrow 
-- down the search very fast. It uses the first part of the index to find all entries
-- for patient_id = 1234, and because the visit_date is the second part of that same 
-- index entry, it can immediately filter the dates without ever looking at the table yet.

-- b) Now try querying ONLY on visit_date (no patient_id). 
--    Does the composite index get used? Why not?
-- Likely No (or it will be very inefficient).
-- If the query only by visit_date (the second column), Oracle usually cannot use the index
-- effectively. This is because the index is sorted primarily by patient_id.

-- c) What's the rule about column order in composite indexes?
-- Leading columns matter.
-- Generally, place the column that filters the data most effectively (high cardinality) at the beginning.
-- For an index to be used efficiently, the query should include the leading column (the first column defined in the index).
-- An index on (A, B) can support:
-- Queries on A and B together.
-- Queries on A alone.
-- It cannot (efficiently) support queries on B alone.

SELECT * FROM patient_visits WHERE patient_id = 1234;

-- Trailing column only (index cannot be used from the middle):
SELECT * FROM patient_visits WHERE visit_date > SYSDATE - 90;

-- ============================================================
-- Exercise 4 — Function that breaks an index
--
-- There IS an index on patient_id (from lesson 03).
-- Predict what happens when you wrap the column in a function.
-- ============================================================

-- This query CAN use the index:
SELECT * FROM patient_visits WHERE patient_id = 5432;
-- This one cannot — why?
SELECT * FROM patient_visits WHERE TO_CHAR(patient_id) = '5432';

-- Questions:
-- a) What scan type did the second query use? The second query use a TABLE ACCESS FULL.
-- Even though patient_id has a B-Tree index, Oracle will ignore it ans scan every
-- row in the table because of the TO_CHAR() function

-- b) Why does wrapping a column in a function break index use?
-- Becuase an index stores the original values of the column in a sorted tree structure. 
-- When we apply a function like TO_CHAR(), UPPER(), or TRUNC() to the column in the WHERE clause, 
-- we are no longer searching for the value stored in the index; we are searching for a transformed
-- version of it.

-- c) How would you rewrite the second query to allow index use?
SELECT * FROM patient_visits WHERE patient_id = TO_NUMBER('5432');

-- ============================================================
-- Exercise 5 — Discussion: real-world scenarios
--
-- For each scenario below, decide:
--   a) Would you add an index?
--   b) On which column(s)?
--   c) Any concerns?
-- ============================================================

-- Scenario A:
-- A reporting table gets loaded once per night (batch ETL).
-- During the day, analysts run SELECT queries by date range.
-- The table has 50 million rows.
-- → Index on date? Yes/No, why? Yes, I would add an index in the date_column,
-- because with 50 million rows, a Full Table Scan (FTS) would be extremely 
-- expensive in terms of I/O and time. Since the data is loaded in a batch at night,
-- we don't have to worry about the index slowing down individual "inserts" throughout the day.
-- Concerns: 
--    *Index Build Time: Adding an index to 50M rows takes time and temp space. It's often
--    *best to drop the index before the nightly load and rebuild it after (to make the load faster).
--    *Selectivity: If an analyst queries a date range covering 5 years, the index might be ignored. 
--    * If they query "last week," it will be a lifesaver.

-- Scenario B:
-- An OLTP orders table gets 10,000 inserts per minute.
-- Support staff look up orders by customer_id or order_status.
-- order_status has 4 values: pending, processing, shipped, cancelled.
-- → What indexes would you add? 
-- I would add a selective indexing only in customer_id.
-- Index on customer_id because Customers and support need to find specific orders quickly.
-- Since customer_id is high-cardinality, the index will be very efficient.
-- No Index on order_status: Do not put a standard B-Tree index on status. With only 4 values, it is low-cardinality.
-- Concerns: 
--    * Insert Overhead: Every index you add slows down those 10,000 inserts per minute because Oracle has to update the table and every related index for every single row.
--    * Locking/Contention: High-volume indexes can lead to "buffer busy waits" or "index contention" at the leaf blocks.

-- Scenario C:
-- A patient table has an email column (unique per patient).
-- There are 5 million patients.
-- The app frequently does: WHERE email = 'user@example.com'
-- → What kind of index would be best here? Unique B-Tree Index
-- I would add a unique index, email, since the app frequently searches for a single, unique value, a Unique B-Tree Index is the "gold standard." 
-- It provides the fastest possible access (usually only 3–4 I/O operations to find the exact row).
-- Concerns: 
--    * Case Sensitivity: In Oracle, 'User@Example.com' is not the same as 'user@example.com'. If the app doesn't enforce lowercase, 
--    we might actually need a Function-Based Index on UPPER(email) to ensure searches work correctly.
--    * Storage: Emails are strings and can be long. This index will take up more space than a numeric index, but for 5M rows, it is easily manageable.

