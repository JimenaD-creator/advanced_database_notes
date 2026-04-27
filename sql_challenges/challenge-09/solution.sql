------------ EXERCISE 1 -------------
UPDATE accounts 
SET balance = balance - 50 
WHERE account_id = 3;

UPDATE accounts 
SET balance = balance + 50 
WHERE account_id = 1;

COMMIT;

---------- EXERCISE 2 ----------
UPDATE accounts 
SET balance = balance - 10000 
WHERE account_id = 2;

UPDATE accounts 
SET balance = balance + 10000 
WHERE account_id = 3;

SELECT account_id, owner_name, balance 
FROM accounts 
WHERE account_id IN (2, 3);

ROLLBACK;

----------- EXERCISE 3 --------------
-- 1. Add $25 to Alice
UPDATE accounts SET balance = balance + 25 WHERE account_id = 1;

-- 2. Set the savepoint
SAVEPOINT alice_update_done;

-- 3. Deduct $25 from Charlie (The Mistake)
UPDATE accounts SET balance = balance - 25 WHERE account_id = 3;

-- 4. Rollback to the savepoint 
-- This keeps Alice's +$25 but erases Charlie's -$25
ROLLBACK TO SAVEPOINT alice_update_done;


SELECT account_id, owner_name, balance 
FROM accounts 
ORDER BY account_id;

------------- EXERCISE 4 ------------
CREATE OR REPLACE PROCEDURE deposit_funds (
    p_account_id IN NUMBER,
    p_amount     IN NUMBER
) AS
    -- Custom error for invalid amounts
    e_invalid_amount EXCEPTION;
BEGIN
    -- 1. Validate that p_amount > 0
    IF p_amount <= 0 THEN
        RAISE e_invalid_amount;
    END IF;

    -- 2. Add p_amount to the account balance
    UPDATE accounts 
    SET balance = balance + p_amount 
    WHERE account_id = p_account_id;

    -- Check if the account actually exists
    IF SQL%NOTFOUND THEN
        RAISE_APPLICATION_ERROR(-20001, 'Account ID ' || p_account_id || ' not found.');
    END IF;

    -- 3. COMMIT on success
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Deposit successful for Account ' || p_account_id);

EXCEPTION
    -- 4. ROLLBACK + re-raise on any error
    WHEN e_invalid_amount THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20002, 'Deposit amount must be greater than zero.');
        
    WHEN OTHERS THEN
        ROLLBACK;
        -- Re-raises the actual system error (like a connection drop or constraint)
        RAISE;
END;

------------ TEST -------------
-- Test with a valid deposit
EXEC deposit_funds(3, 75);

SELECT * FROM accounts WHERE account_id = 3;

-- Test with an invalid deposit (Should trigger an error)
EXEC deposit_funds(3, -10);

-------------- EXERCISE 5 -------------
---- Q1: The Booking System
-- Inside the Transaction: (a) Reserve the time slot and (b) Create the appointment record.
-- Outside the Transaction: (c) Send a confirmation notification.
-- Because a transaction should only include database-level changes that must succeed or fail together (Atomicity). You don't want to create an appointment without a slot, or vice-versa.
-- However, sending a notification is an external action (like an API call or email server). 
-- If the email succeeds but the database crashes before the COMMIT, you’ve told the patient they 
-- have a slot that doesn't exist. Conversely, if the database transaction fails because of a notification error, 
-- you’ve unnecessarily blocked a patient from booking. You should commit the data first, then trigger the notification logic.

----- Q2: The "Nested" Commit Problem
-- The Problem: It breaks Encapsulation and Atomicity for the caller.
-- When the procedure calls COMMIT, it saves everything currently pending in that session, not just its own work. If a developer starts a transaction,
-- performs three important updates, and then calls their procedure, their COMMIT will finalize their three updates prematurely.
-- The developer can no longer ROLLBACK their work if something goes wrong later in their script because your procedure already
-- "pushed the save button" for the entire session. In professional environments, procedures usually leave the COMMIT to the final caller.

------- Q3: Functions vs. Procedures in SELECT --------
-- Can they use the Function? Yes.
-- Can they use the Procedure? No.
-- Because functions are designed to return a value based on input. As long as the function is 'pure'
-- (meaning it doesn't try to change data or perform INSERT/UPDATE statements), it can't be used in a SELECT
-- statement to calculate values on the fly for every row.
-- On the other side, procedures are designed to perform actions (side effects) and do not have return value in the same way.
-- SQL select are meant to be read-only operations. Allowing a procedure inside a SELECT would mean that 
-- simply "viewing" data could change the database state (like accidentally posting 1,000 payments just by running a report), 
-- which violates the fundamental principles of SQL.

