### Class Example

```sql
CREATE TABLE tasks (
    id          NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title       VARCHAR2(200)  NOT NULL,
    status      VARCHAR2(20)   DEFAULT 'open' NOT NULL,
    assigned_to VARCHAR2(100),
    created_at  TIMESTAMP      DEFAULT SYSTIMESTAMP,
    updated_at  TIMESTAMP      DEFAULT SYSTIMESTAMP,
    CONSTRAINT chk_task_status CHECK (
        status IN ('open', 'assigned', 'in_progress', 'blocked', 'closed')
    )
)

CREATE TABLE task_logs (
    id          NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    task_id     NUMBER         NOT NULL REFERENCES tasks(id),
    old_status  VARCHAR2(20),
    new_status  VARCHAR2(20)   NOT NULL,
    changed_at  TIMESTAMP      DEFAULT SYSTIMESTAMP,
    changed_by  VARCHAR2(100)  DEFAULT USER
)

CREATE TABLE task_analytics (
    status      VARCHAR2(20) PRIMARY KEY,
    total       NUMBER DEFAULT 0
)

INSERT INTO task_analytics (status) VALUES ('open')

INSERT INTO task_analytics (status) VALUES ('assigned')

INSERT INTO task_analytics (status) VALUES ('in_progress')

INSERT INTO task_analytics (status) VALUES ('blocked')

INSERT INTO task_analytics (status) VALUES ('closed')

COMMIT

CREATE OR REPLACE TRIGGER trg_tasks_set_updated_at
BEFORE UPDATE ON tasks
FOR EACH ROW
BEGIN
    :NEW.updated_at := SYSTIMESTAMP;
END;

CREATE OR REPLACE TRIGGER trg_tasks_require_assignee
BEFORE INSERT OR UPDATE ON tasks
FOR EACH ROW
BEGIN
    IF :NEW.status = 'assigned' AND (:NEW.assigned_to IS NULL OR TRIM(:NEW.assigned_to) = '') THEN
        RAISE_APPLICATION_ERROR(
            -20002,
            'assigned_to must be set when status is ''assigned'''
        );
    END IF;
END;

CREATE OR REPLACE TRIGGER trg_tasks_log_status_change
AFTER UPDATE OF status ON tasks
FOR EACH ROW
BEGIN
    -- Only log if the status actually changed
    IF :OLD.status != :NEW.status THEN
        INSERT INTO task_logs (task_id, old_status, new_status, changed_by)
        VALUES (:NEW.id, :OLD.status, :NEW.status, USER);
    END IF;
END;

CREATE OR REPLACE TRIGGER trg_tasks_log_insert
AFTER INSERT ON tasks
FOR EACH ROW
BEGIN
    INSERT INTO task_logs (task_id, old_status, new_status, changed_by)
    VALUES (:NEW.id, NULL, :NEW.status, USER);
END;

CREATE OR REPLACE TRIGGER trg_tasks_update_analytics
AFTER INSERT OR UPDATE OF status OR DELETE ON tasks
FOR EACH ROW
BEGIN
    -- On INSERT: increment the new status counter
    IF INSERTING THEN
        UPDATE task_analytics SET total = total + 1 WHERE status = :NEW.status;

    -- On UPDATE: decrement old, increment new
    ELSIF UPDATING AND :OLD.status != :NEW.status THEN
        UPDATE task_analytics SET total = total - 1 WHERE status = :OLD.status;
        UPDATE task_analytics SET total = total + 1 WHERE status = :NEW.status;

    -- On DELETE: decrement the deleted task's status
    ELSIF DELETING THEN
        UPDATE task_analytics SET total = total - 1 WHERE status = :OLD.status;
    END IF;
END;

INSERT INTO tasks (title) VALUES ('Build login page')

INSERT INTO tasks (title) VALUES ('Write unit tests')

INSERT INTO tasks (title, status, assigned_to) VALUES ('Deploy to staging', 'assigned', 'alice')

COMMIT

UPDATE tasks SET title = 'Build login page (revised)' WHERE id = 1
```
