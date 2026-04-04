----- Creation of the tables ------
create table PRODUCT (
    PRODUCT_ID int not null primary key,
    PRODUCT_NAME VARCHAR2(30),
    PACKAGE_ID NUMBER(10),
    CURRENT_INVENTORY_COUNT NUMBER(5),
    STORE_COST NUMBER(10, 2),
    SALE_PRICE NUMBER(10, 2),
    LAST_UPDATE_DATE DATE,
    UPDATED_BY_USER VARCHAR2(30),
    PET_FLAG VARCHAR2(1)
)

create table CUSTOMER (
    CUST_ID int not null primary key,
    FIRSTNAME VARCHAR2(20),
    LASTNAME VARCHAR2(25),
    ADDRESS VARCHAR2(32),
    CITY VARCHAR2(20),
    STATE VARCHAR2(2),
    ZIP VARCHAR2(9)
)

create table CUSTOMER_SALE (
    SALES_ID int not null primary key,
    CUST_ID NUMBER(10),
    TOTAL_ITEM_AMOUNT NUMBER(10, 2),
    TAX_AMOUNT NUMBER(10, 2),
    TOTAL_SALE_AMOUNT NUMBER(10, 2),
    SALES_DATE DATE,
    SHIPPING_HANDLING_FEE NUMBER(5, 2)
)

create table SALES_ITEM (
    SALES_ID int not null primary key,
    SALE_AMOUNT NUMBER(10, 2)
)

create table PET_CARE_LOG (
    PRODUCT_ID int not null primary key,
    CREATED_BY_USER VARCHAR2(30),
    LOG_TEXT VARCHAR2(500),
    LAST_UPDATE_DATETIME DATE
)

----- Triggers ---------
1. CREATE OR REPLACE TRIGGER fire_before_inserting
BEFORE INSERT ON PET_CARE_LOG
FOR EACH ROW
BEGIN
    :NEW.UPDATE_DATE :=SYSDATE;
    :NEW.UPDATED_BY_USER :=USER;
EXCEPTION
    WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR(-20001, 'An error occurred while updating audit columns: ' || SQLERRM);
END;

2. CREATE OR REPLACE TRIGGER fire_before_updating
BEFORE UPDATE ON PET_CARE_LOG
FOR EACH ROW
BEGIN
    IF :OLD.UPDATED_BY_USER != USER THEN
        RAISE_APPLICATION_ERROR(-20002, 'Access Denied: Only ' || :OLD.UPDATED_BY_USER || ' can modify this record.');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
    IF SQLCODE = -20002 THEN
        RAISE;
    ELSE
        RAISE_APPLICATION_ERROR(-20001, 'An error occurred during update validation: ' || SQLERRM);
    END IF;
END;

3. CREATE OR REPLACE TRIGGER fire_before_deleting
BEFORE DELETE ON PET_CARE_LOG
FOR EACH ROW
BEGIN
    IF USER != 'JOEMANAGER' THEN
        RAISE_APPLICATION_ERROR(-20003, 'Unauthorized: Only JOEMANAGER has permission to delete logs.');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
    IF SQLCODE = -20003 THEN
        RAISE;
    ELSE
        RAISE_APPLICATION_ERROR(-20001, 'An error occurred during the delete operation: ' || SQLERRM);
    END IF;
END;