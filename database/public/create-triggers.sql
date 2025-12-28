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
$$ LANGUAGE plpgsql SET search_path = public;

CREATE TRIGGER trg_set_expense_item_id
BEFORE INSERT ON EXPENSE_ITEMS
FOR EACH ROW
EXECUTE FUNCTION set_expense_item_id();

---
-- Trigger to sync current balance before insert or update on ACCOUNTS
---
DROP TRIGGER IF EXISTS trigger_init_account_current_balance ON ACCOUNTS;
DROP FUNCTION IF EXISTS init_account_current_balance();

CREATE OR REPLACE FUNCTION init_account_current_balance()
RETURNS TRIGGER AS $$
BEGIN
    -- If client didn't provide CURRENT_BALANCE, or it's 0 while INITIAL_BALANCE is non-zero,
    -- initialize it from INITIAL_BALANCE. This avoids overwriting legitimate zeros later.
    IF (NEW.CURRENT_BALANCE IS NULL) OR (NEW.CURRENT_BALANCE = 0 AND NEW.INITIAL_BALANCE <> 0) THEN
        NEW.CURRENT_BALANCE := NEW.INITIAL_BALANCE;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = public;

CREATE TRIGGER trigger_init_account_current_balance
    BEFORE INSERT ON ACCOUNTS
    FOR EACH ROW
    EXECUTE FUNCTION init_account_current_balance();

---
-- Updates the UPDATED_AT column to the current timestamp before any update operation. 
---

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
$$ LANGUAGE plpgsql SET search_path = public;

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
$$ LANGUAGE plpgsql SET search_path = public;

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

---
-- Revert account balances when transactions are deleted
---

DROP TRIGGER IF EXISTS trg_delete_income_balance ON INCOME;
DROP TRIGGER IF EXISTS trg_delete_expense_balance ON EXPENSES;
DROP TRIGGER IF EXISTS trg_delete_transfer_balance ON TRANSFER;
DROP FUNCTION IF EXISTS revert_account_balance();

CREATE OR REPLACE FUNCTION revert_account_balance()
RETURNS TRIGGER AS $$
BEGIN
    -- 1. Handle INCOME deletion (subtract the amount back)
    IF (TG_TABLE_NAME = 'income') THEN
        UPDATE ACCOUNTS 
        SET CURRENT_BALANCE = CURRENT_BALANCE - OLD.AMOUNT
        WHERE ACCOUNT_ID = (SELECT ACCOUNT_ID FROM TRANSACTION WHERE TRANSACTION_ID = OLD.TRANSACTION_ID);

    -- 2. Handle EXPENSES deletion (add the amount back)
    ELSIF (TG_TABLE_NAME = 'expenses') THEN
        UPDATE ACCOUNTS 
        SET CURRENT_BALANCE = CURRENT_BALANCE + OLD.AMOUNT
        WHERE ACCOUNT_ID = (SELECT ACCOUNT_ID FROM TRANSACTION WHERE TRANSACTION_ID = OLD.TRANSACTION_ID);

    -- 3. Handle TRANSFER deletion (reverse both operations)
    ELSIF (TG_TABLE_NAME = 'transfer') THEN
        -- Add back to the "From" account
        UPDATE ACCOUNTS 
        SET CURRENT_BALANCE = CURRENT_BALANCE + OLD.AMOUNT
        WHERE ACCOUNT_ID = OLD.FROM_ACCOUNT_ID;
        
        -- Subtract from the "To" account
        UPDATE ACCOUNTS 
        SET CURRENT_BALANCE = CURRENT_BALANCE - OLD.AMOUNT
        WHERE ACCOUNT_ID = OLD.TO_ACCOUNT_ID;
    END IF;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql SET search_path = public;

CREATE TRIGGER trg_delete_income_balance
AFTER DELETE ON INCOME
FOR EACH ROW EXECUTE FUNCTION revert_account_balance();

CREATE TRIGGER trg_delete_expense_balance
AFTER DELETE ON EXPENSES
FOR EACH ROW EXECUTE FUNCTION revert_account_balance();

CREATE TRIGGER trg_delete_transfer_balance
AFTER DELETE ON TRANSFER
FOR EACH ROW EXECUTE FUNCTION revert_account_balance();

---
-- Update account balances when transaction amounts are modified
---

DROP TRIGGER IF EXISTS trg_modify_income_balance ON INCOME;
DROP TRIGGER IF EXISTS trg_modify_expense_balance ON EXPENSES;
DROP TRIGGER IF EXISTS trg_modify_transfer_balance ON TRANSFER;
DROP FUNCTION IF EXISTS adjust_account_balance();

CREATE OR REPLACE FUNCTION adjust_account_balance()
RETURNS TRIGGER AS $$
DECLARE
    amount_diff NUMERIC(15, 2);
BEGIN
    -- 1. Handle INCOME update
    IF (TG_TABLE_NAME = 'income') THEN
        amount_diff := NEW.AMOUNT - OLD.AMOUNT;
        UPDATE ACCOUNTS 
        SET CURRENT_BALANCE = CURRENT_BALANCE + amount_diff
        WHERE ACCOUNT_ID = (SELECT ACCOUNT_ID FROM TRANSACTION WHERE TRANSACTION_ID = NEW.TRANSACTION_ID);

    -- 2. Handle EXPENSES update
    ELSIF (TG_TABLE_NAME = 'expenses') THEN
        amount_diff := NEW.AMOUNT - OLD.AMOUNT;
        UPDATE ACCOUNTS 
        SET CURRENT_BALANCE = CURRENT_BALANCE - amount_diff
        WHERE ACCOUNT_ID = (SELECT ACCOUNT_ID FROM TRANSACTION WHERE TRANSACTION_ID = NEW.TRANSACTION_ID);

    -- 3. Handle TRANSFER update (more complex: amount change + potential account change)
    ELSIF (TG_TABLE_NAME = 'transfer') THEN
        -- Revert the old transfer
        UPDATE ACCOUNTS 
        SET CURRENT_BALANCE = CURRENT_BALANCE + OLD.AMOUNT
        WHERE ACCOUNT_ID = OLD.FROM_ACCOUNT_ID;
        
        UPDATE ACCOUNTS 
        SET CURRENT_BALANCE = CURRENT_BALANCE - OLD.AMOUNT
        WHERE ACCOUNT_ID = OLD.TO_ACCOUNT_ID;
        
        -- Apply the new transfer
        UPDATE ACCOUNTS 
        SET CURRENT_BALANCE = CURRENT_BALANCE - NEW.AMOUNT
        WHERE ACCOUNT_ID = NEW.FROM_ACCOUNT_ID;
        
        UPDATE ACCOUNTS 
        SET CURRENT_BALANCE = CURRENT_BALANCE + NEW.AMOUNT
        WHERE ACCOUNT_ID = NEW.TO_ACCOUNT_ID;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = public;

CREATE TRIGGER trg_modify_income_balance
AFTER UPDATE ON INCOME
FOR EACH ROW EXECUTE FUNCTION adjust_account_balance();

CREATE TRIGGER trg_modify_expense_balance
AFTER UPDATE ON EXPENSES
FOR EACH ROW EXECUTE FUNCTION adjust_account_balance();

CREATE TRIGGER trg_modify_transfer_balance
AFTER UPDATE ON TRANSFER
FOR EACH ROW EXECUTE FUNCTION adjust_account_balance();

---
-- Ensure balances update when deleting from TRANSACTION (handles cascade deletes)
---

DROP TRIGGER IF EXISTS trg_delete_transaction_balance ON TRANSACTION;
DROP FUNCTION IF EXISTS adjust_balance_on_transaction_delete();

CREATE OR REPLACE FUNCTION adjust_balance_on_transaction_delete()
RETURNS TRIGGER AS $$
DECLARE
    amt NUMERIC(15, 2);
    from_acc UUID;
    to_acc UUID;
BEGIN
    -- Reverse balance effects based on transaction type before the child rows are cascaded
    IF (OLD.TYPE = 'I') THEN
        SELECT AMOUNT INTO amt FROM INCOME WHERE TRANSACTION_ID = OLD.TRANSACTION_ID;
        IF amt IS NOT NULL THEN
            UPDATE ACCOUNTS
            SET CURRENT_BALANCE = CURRENT_BALANCE - amt
            WHERE ACCOUNT_ID = OLD.ACCOUNT_ID;
        END IF;
    ELSIF (OLD.TYPE = 'E') THEN
        SELECT AMOUNT INTO amt FROM EXPENSES WHERE TRANSACTION_ID = OLD.TRANSACTION_ID;
        IF amt IS NOT NULL THEN
            UPDATE ACCOUNTS
            SET CURRENT_BALANCE = CURRENT_BALANCE + amt
            WHERE ACCOUNT_ID = OLD.ACCOUNT_ID;
        END IF;
    ELSIF (OLD.TYPE = 'T') THEN
        SELECT AMOUNT, FROM_ACCOUNT_ID, TO_ACCOUNT_ID
        INTO amt, from_acc, to_acc
        FROM TRANSFER WHERE TRANSACTION_ID = OLD.TRANSACTION_ID;
        IF amt IS NOT NULL THEN
            -- Add back to FROM, subtract from TO
            UPDATE ACCOUNTS
            SET CURRENT_BALANCE = CURRENT_BALANCE + amt
            WHERE ACCOUNT_ID = from_acc;

            UPDATE ACCOUNTS
            SET CURRENT_BALANCE = CURRENT_BALANCE - amt
            WHERE ACCOUNT_ID = to_acc;
        END IF;
    END IF;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql SET search_path = public;

CREATE TRIGGER trg_delete_transaction_balance
BEFORE DELETE ON TRANSACTION
FOR EACH ROW EXECUTE FUNCTION adjust_balance_on_transaction_delete();
