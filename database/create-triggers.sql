---
-- Trigger to auto-increment ITEM_ID for each TRANSACTION_ID in EXPENSE_ITEMS
---

DROP TRIGGER IF EXISTS trg_set_expense_item_id ON EXPENSE_ITEMS;
DROP FUNCTION IF EXISTS set_expense_item_id();

CREATE OR REPLACE FUNCTION set_expense_item_id()
RETURNS TRIGGER AS $$
BEGIN
    NEW.ITEM_ID := (SELECT COALESCE(MAX(ITEM_ID), 0) + 1 FROM EXPENSE_ITEMS WHERE TRANSACTION_ID = NEW.TRANSACTION_ID);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_set_expense_item_id
BEFORE INSERT ON EXPENSE_ITEMS
FOR EACH ROW
EXECUTE FUNCTION set_expense_item_id();


---
-- Updates the UPDATED_AT column to the current timestamp before any update operation. 
---

DROP TRIGGER IF EXISTS trg_update_users_timestamp ON USERS;
DROP TRIGGER IF EXISTS trg_update_biometrics_timestamp ON BIOMETRICS;
DROP TRIGGER IF EXISTS trg_update_accounts_timestamp ON ACCOUNTS;
DROP TRIGGER IF EXISTS trg_update_transaction_timestamp ON TRANSACTION;
DROP TRIGGER IF EXISTS trg_update_detailed_timestamp ON DETAILED;
DROP FUNCTION IF EXISTS update_timestamp();

CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.UPDATED_AT = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_users_timestamp
BEFORE UPDATE ON USERS
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER trg_update_biometrics_timestamp
BEFORE UPDATE ON BIOMETRICS
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER trg_update_accounts_timestamp
BEFORE UPDATE ON ACCOUNTS
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER trg_update_transaction_timestamp
BEFORE UPDATE ON TRANSACTION
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER trg_update_detailed_timestamp
BEFORE UPDATE ON DETAILED
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

---
-- Update account balances after income, expenses, or transfer operations
---

DROP TRIGGER IF EXISTS trg_update_income_balance ON INCOME;
DROP TRIGGER IF EXISTS trg_update_expense_balance ON EXPENSES;
DROP TRIGGER IF EXISTS trg_update_transfer_balance ON TRANSFER;
DROP FUNCTION IF EXISTS update_account_balance();

CREATE OR REPLACE FUNCTION update_account_balance()
RETURNS TRIGGER AS $$
BEGIN
    -- 1. Handle INCOME
    IF (TG_TABLE_NAME = 'income') THEN
        UPDATE ACCOUNTS 
        SET CURRENT_BALANCE = CURRENT_BALANCE + NEW.AMOUNT
        WHERE ACCOUNT_ID = (SELECT ACCOUNT_ID FROM TRANSACTION WHERE TRANSACTION_ID = NEW.TRANSACTION_ID);

    -- 2. Handle EXPENSES
    ELSIF (TG_TABLE_NAME = 'expenses') THEN
        UPDATE ACCOUNTS 
        SET CURRENT_BALANCE = CURRENT_BALANCE - NEW.AMOUNT
        WHERE ACCOUNT_ID = (SELECT ACCOUNT_ID FROM TRANSACTION WHERE TRANSACTION_ID = NEW.TRANSACTION_ID);

    -- 3. Handle TRANSFERS (Deduct from Source, Add to Destination)
    ELSIF (TG_TABLE_NAME = 'transfer') THEN
        -- Deduct from the "From" account
        UPDATE ACCOUNTS 
        SET CURRENT_BALANCE = CURRENT_BALANCE - NEW.AMOUNT
        WHERE ACCOUNT_ID = NEW.FROM_ACCOUNT_ID;
        
        -- Add to the "To" account
        UPDATE ACCOUNTS 
        SET CURRENT_BALANCE = CURRENT_BALANCE + NEW.AMOUNT
        WHERE ACCOUNT_ID = NEW.TO_ACCOUNT_ID;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

---
-- Update triggers for account balance management
---

CREATE TRIGGER trg_update_income_balance
AFTER INSERT ON INCOME
FOR EACH ROW EXECUTE FUNCTION update_account_balance();

CREATE TRIGGER trg_update_expense_balance
AFTER INSERT ON EXPENSES
FOR EACH ROW EXECUTE FUNCTION update_account_balance();

CREATE TRIGGER trg_update_transfer_balance
AFTER INSERT ON TRANSFER
FOR EACH ROW EXECUTE FUNCTION update_account_balance();