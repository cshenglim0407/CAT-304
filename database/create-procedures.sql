-- Handle income, expense, and transfer entries

CREATE OR REPLACE PROCEDURE add_transfer(
    p_user_id UUID,
    p_from_account_id UUID,
    p_to_account_id UUID,
    p_name TEXT,
    p_amount NUMERIC,
    p_description TEXT DEFAULT NULL,
    p_currency TEXT DEFAULT 'MYR'
)
LANGUAGE plpgsql AS $$
DECLARE
    v_tx_id UUID;
BEGIN
    -- 1. Verify account ownership
    IF NOT EXISTS (SELECT 1 FROM ACCOUNTS WHERE ACCOUNT_ID = p_from_account_id AND USER_ID = p_user_id) THEN
        RAISE EXCEPTION 'From account % does not exist or does not belong to user %', p_from_account_id, p_user_id;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM ACCOUNTS WHERE ACCOUNT_ID = p_to_account_id AND USER_ID = p_user_id) THEN
        RAISE EXCEPTION 'To account % does not exist or does not belong to user %', p_to_account_id, p_user_id;
    END IF;

    -- 2. Insert into TRANSACTION (Primary log)
    INSERT INTO TRANSACTION (NAME, TYPE, DESCRIPTION, CURRENCY, ACCOUNT_ID)
    VALUES (p_name, 'T', p_description, p_currency, p_from_account_id)
    RETURNING TRANSACTION_ID INTO v_tx_id;

    -- 3. Insert into TRANSFER
    INSERT INTO TRANSFER (TRANSACTION_ID, AMOUNT, FROM_ACCOUNT_ID, TO_ACCOUNT_ID)
    VALUES (v_tx_id, p_amount, p_from_account_id, p_to_account_id);
END;
$$;

CREATE OR REPLACE PROCEDURE add_income(
    p_user_id UUID,
    p_account_id UUID,
    p_name TEXT,
    p_amount NUMERIC,
    p_category TEXT, -- 'SALARY', 'BUSINESS', etc.
    p_description TEXT DEFAULT NULL,
    p_currency TEXT DEFAULT 'MYR',
    p_is_recurrent BOOLEAN DEFAULT FALSE
)
LANGUAGE plpgsql AS $$
DECLARE
    v_tx_id UUID;
BEGIN
    -- Verify that the account belongs to the user
    IF NOT EXISTS (SELECT 1 FROM ACCOUNTS WHERE ACCOUNT_ID = p_account_id AND USER_ID = p_user_id) THEN
        RAISE EXCEPTION 'Account % does not exist or does not belong to user %', p_account_id, p_user_id;
    END IF;

    -- Insert into Parent Transaction
    INSERT INTO TRANSACTION (NAME, TYPE, DESCRIPTION, CURRENCY, ACCOUNT_ID)
    VALUES (p_name, 'I', p_description, p_currency, p_account_id)
    RETURNING TRANSACTION_ID INTO v_tx_id;

    -- Insert into Income child table
    INSERT INTO INCOME (TRANSACTION_ID, AMOUNT, CATEGORY, IS_RECURRENT)
    VALUES (v_tx_id, p_amount, p_category, p_is_recurrent);
END;
$$;

CREATE OR REPLACE PROCEDURE add_expense(
    p_user_id UUID,
    p_account_id UUID,
    p_category_name TEXT,
    p_expense_name TEXT,
    p_description TEXT,
    p_items JSONB, -- Format: '[{"name": "Milk", "qty": 2, "unit_price": 5.50}, ...]'
    p_currency TEXT DEFAULT 'MYR'
)
LANGUAGE plpgsql AS $$
DECLARE
    v_cat_id UUID;
    v_tx_id UUID;
    v_total_amount NUMERIC(15, 2) := 0;
    v_item RECORD;
BEGIN
    -- 1. Resolve IDs and calculate total amount first
    IF NOT EXISTS (SELECT 1 FROM ACCOUNTS WHERE ACCOUNT_ID = p_account_id AND USER_ID = p_user_id) THEN
        RAISE EXCEPTION 'Account % does not exist or does not belong to user %', p_account_id, p_user_id;
    END IF;
    
    SELECT EXPENSE_CAT_ID INTO v_cat_id FROM EXPENSE_CATEGORY 
    WHERE NAME = p_category_name;

    -- Pre-calculate the total amount from items
    FOR v_item IN SELECT * FROM jsonb_to_recordset(p_items) 
        AS x(name TEXT, qty INTEGER, unit_price NUMERIC)
    LOOP
        v_total_amount := v_total_amount + (v_item.qty * v_item.unit_price);
    END LOOP;

    -- Raise an exception if the total amount is not positive
    IF v_total_amount <= 0 THEN
        RAISE EXCEPTION 'Total expense amount must be positive.';
    END IF;

    -- 2. Create the Parent Transaction
    INSERT INTO TRANSACTION (NAME, TYPE, DESCRIPTION, CURRENCY, ACCOUNT_ID)
    VALUES (p_expense_name, 'E', p_description, p_currency, p_account_id)
    RETURNING TRANSACTION_ID INTO v_tx_id;

    -- 3. Create the Expense Record with the correct total amount
    INSERT INTO EXPENSES (TRANSACTION_ID, AMOUNT, EXPENSE_CAT_ID)
    VALUES (v_tx_id, v_total_amount, v_cat_id);

    -- 4. Loop through the JSON items and insert into EXPENSE_ITEMS
    FOR v_item IN SELECT * FROM jsonb_to_recordset(p_items) 
        AS x(name TEXT, qty INTEGER, unit_price NUMERIC)
    LOOP
        INSERT INTO EXPENSE_ITEMS (TRANSACTION_ID, ITEM_NAME, QTY, UNIT_PRICE, PRICE)
        VALUES (
            v_tx_id,
            v_item.name, 
            v_item.qty, 
            v_item.unit_price, 
            (v_item.qty * v_item.unit_price)
        );
    END LOOP;

END;
$$;

CREATE OR REPLACE PROCEDURE add_expense_with_receipt(
    p_user_id UUID,
    p_account_id UUID,
    p_category_name TEXT,
    p_expense_name TEXT,
    p_description TEXT,
    p_items JSONB,
    p_receipt_path TEXT,
    p_currency TEXT DEFAULT 'MYR',
    p_receipt_merchant_name TEXT DEFAULT NULL,
    p_receipt_confidence_score NUMERIC DEFAULT NULL,
    p_receipt_ocr_raw_text TEXT DEFAULT NULL
)
LANGUAGE plpgsql AS $$
DECLARE
    v_cat_id UUID;
    v_tx_id UUID;
    v_total_amount NUMERIC(15, 2) := 0;
    v_item RECORD;
BEGIN
    -- This section is the same as add_expense
    IF NOT EXISTS (SELECT 1 FROM ACCOUNTS WHERE ACCOUNT_ID = p_account_id AND USER_ID = p_user_id) THEN
        RAISE EXCEPTION 'Account % does not exist or does not belong to user %', p_account_id, p_user_id;
    END IF;
    
    SELECT EXPENSE_CAT_ID INTO v_cat_id FROM EXPENSE_CATEGORY 
    WHERE NAME = p_category_name;

    FOR v_item IN SELECT * FROM jsonb_to_recordset(p_items) 
        AS x(name TEXT, qty INTEGER, unit_price NUMERIC)
    LOOP
        v_total_amount := v_total_amount + (v_item.qty * v_item.unit_price);
    END LOOP;

    IF v_total_amount <= 0 THEN
        RAISE EXCEPTION 'Total expense amount must be positive.';
    END IF;

    INSERT INTO TRANSACTION (NAME, TYPE, DESCRIPTION, CURRENCY, ACCOUNT_ID)
    VALUES (p_expense_name, 'E', p_description, p_currency, p_account_id)
    RETURNING TRANSACTION_ID INTO v_tx_id;

    INSERT INTO EXPENSES (TRANSACTION_ID, AMOUNT, EXPENSE_CAT_ID)
    VALUES (v_tx_id, v_total_amount, v_cat_id);

    FOR v_item IN SELECT * FROM jsonb_to_recordset(p_items) 
        AS x(name TEXT, qty INTEGER, unit_price NUMERIC)
    LOOP
        INSERT INTO EXPENSE_ITEMS (TRANSACTION_ID, ITEM_NAME, QTY, UNIT_PRICE, PRICE)
        VALUES (
            v_tx_id,
            v_item.name, 
            v_item.qty, 
            v_item.unit_price, 
            (v_item.qty * v_item.unit_price)
        );
    END LOOP;

    -- Insert into RECEIPT table
    INSERT INTO RECEIPT (TRANSACTION_ID, PATH, MERCHANT_NAME, CONFIDENCE_SCORE, OCR_RAW_TEXT)
    VALUES (
        v_tx_id,
        p_receipt_path,
        p_receipt_merchant_name,
        p_receipt_confidence_score,
        p_receipt_ocr_raw_text
    );
END;
$$;