-------- EXERCISE 1 -------
SELECT object_type, COUNT(*) AS cnt
FROM user_objects
GROUP BY object_type
ORDER BY object_type;

------ Objects Type:
--- 1. Index
--- 2. Lob
--- 3. Procedure
--- 4. Sequence
--- 5. Table
--- 6. Trigger

---------- EXERCISE 2 --------------
SELECT DBMS_METADATA.GET_DDL('TABLE', 'PRODUCTS') FROM DUAL;

--------- EXERCISE 3 -------------
---- With schema
BEGIN
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'DEFAULT', TRUE);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'EMIT_SCHEMA', TRUE);
END;

---- Without schema
SELECT REPLACE(
         DBMS_METADATA.GET_DDL('TABLE', 'ACCOUNTS'),
         '"' || USER || '".',
         ''
       ) AS portable_ddl
FROM dual;

---------- EXERCISE 4 --------------
SELECT DBMS_METADATA.GET_DDL('TABLE', table_name)
FROM user_tables
WHERE table_name = 'EMPLOYEES';

SELECT DISTINCT table_name
FROM user_constraints
WHERE constraint_type = 'R'
ORDER BY table_name;

---- 1. Find all foreign keys
SELECT constraint_name,
       table_name,
       r_constraint_name
FROM user_constraints
WHERE constraint_type = 'R'
ORDER BY table_name;
-- 2. Find which table that referenced constraint belongs to
SELECT owner,
       table_name,
       constraint_name
FROM all_constraints
WHERE constraint_name = 'SYS_C003860469';

-- 3. Extract the actual DDL
SELECT DBMS_METADATA.GET_DDL('TABLE', 'EMPLOYEES')
FROM dual;

-- Export with EMIT_SCHEMA = FALSE
-- Review FK references
-- Change old schema names
-- Load:
-- Tables
-- Constraints
-- Indexes
-- Views
-- Procedures

-------- EXERCISE 5 --------
SELECT referenced_name,
       name AS referencing_name,
       type AS referencing_type
FROM user_dependencies
ORDER BY referenced_name;

SELECT name AS referencing_name,
       type AS referencing_type
FROM user_dependencies
WHERE referenced_name IN (
    SELECT table_name
    FROM user_tables
)
ORDER BY type, name;

SELECT referenced_name,
       referenced_type
FROM user_dependencies
WHERE name = 'DEPOSIT_FUNDS';

SELECT name AS referencing_name,
       type AS referencing_type,
       LISTAGG(referenced_name, ', ')
         WITHIN GROUP (ORDER BY referenced_name) AS dependencies
FROM user_dependencies
WHERE type IN ('PACKAGE', 'PROCEDURE', 'FUNCTION')
GROUP BY name, type
ORDER BY type, name;

------- EXERCISE 6 ----------
-- Extract sequences
SELECT DBMS_METADATA.GET_DDL('SEQUENCE', sequence_name)
FROM user_sequences
WHERE sequence_name NOT LIKE 'ISEQ$$_%'
ORDER BY sequence_name;
-- Extract constraints
SELECT DBMS_METADATA.GET_DDL('CONSTRAINT', constraint_name)
FROM user_constraints
WHERE constraint_name NOT LIKE 'BIN$%'
ORDER BY table_name, constraint_name;

-- 1. Create tables
CREATE TABLE departments (
    department_id NUMBER PRIMARY KEY,
    department_name VARCHAR2(100)
);

CREATE TABLE employees (
    employee_id NUMBER PRIMARY KEY,
    employee_name VARCHAR2(100),
    department_id NUMBER
);
-- 2. Create sequences
CREATE SEQUENCE emp_seq
START WITH 1
INCREMENT BY 1
NOCACHE;
-- 3. Create indexes
CREATE INDEX idx_emp_department
ON employees(department_id);

-- 4. Add constraints (enable FKs)
ALTER TABLE employees
ADD CONSTRAINT fk_emp_department
FOREIGN KEY (department_id)
REFERENCES departments(department_id);

-- 5. Create views
CREATE OR REPLACE VIEW employee_details AS
SELECT e.employee_id,
       e.employee_name,
       d.department_name
FROM employees e
JOIN departments d
ON e.department_id = d.department_id;

-- 6. Create procedures/functions/packages
CREATE OR REPLACE PROCEDURE show_employee_count AS
    total_employees NUMBER;
BEGIN
    SELECT COUNT(*) INTO total_employees
    FROM employees;

    DBMS_OUTPUT.PUT_LINE('Total Employees: ' || total_employees);
END;
/

CREATE OR REPLACE FUNCTION get_department_count
RETURN NUMBER AS
    dept_total NUMBER;
BEGIN
    SELECT COUNT(*) INTO dept_total
    FROM departments;
    RETURN dept_total;
END;
/

CREATE OR REPLACE PACKAGE BODY emp_pkg AS
    PROCEDURE list_employees IS
    BEGIN
        FOR rec IN (SELECT employee_name FROM employees) LOOP
            DBMS_OUTPUT.PUT_LINE(rec.employee_name);
        END LOOP;
    END;
END emp_pkg;
/

-- 7. Create triggers
CREATE OR REPLACE TRIGGER trg_emp_id
BEFORE INSERT ON employees
FOR EACH ROW
BEGIN
    IF :NEW.employee_id IS NULL THEN
        SELECT emp_seq.NEXTVAL
        INTO :NEW.employee_id
        FROM dual;
    END IF;
END;
/



