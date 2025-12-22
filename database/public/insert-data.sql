-- INSERT INTO
--     APP_USERS (DISPLAY_NAME, DATE_OF_BIRTH, GENDER, EMAIL)
-- VALUES
-- ('John Doe', '1990-01-15', 'MALE', 'johndoe@example.com'),
-- ('Jane Doe', '1992-05-22', 'FEMALE', 'janedoe@example.com'),
-- ('Bob Smith', '1988-11-30', 'MALE', 'bobsmith@example.com');

UPDATE APP_USERS
SET
    DISPLAY_NAME = 'John Doe',
    DATE_OF_BIRTH = '1990-01-15',
    GENDER = 'MALE'
WHERE EMAIL = 'johndoe@example.com';

UPDATE APP_USERS
SET
    DISPLAY_NAME = 'Jane Doe',
    DATE_OF_BIRTH = '1992-05-22',
    GENDER = 'FEMALE'
WHERE EMAIL = 'janedoe@example.com';

UPDATE APP_USERS
SET
    DISPLAY_NAME = 'Bob Smith',
    DATE_OF_BIRTH = '1988-11-30',
    GENDER = 'MALE'
WHERE EMAIL = 'bobsmith@example.com';


INSERT INTO
    BIOMETRICS (TEMPLATE_DATA, ALGO_VERSION, DEVICE_ID, DEVICE_NAME, TYPE, USER_ID)
VALUES
('template_fingerprint_johndoe_device_001', 'v1.0', 'device_001', 'Fingerprint Scanner A', 'fingerprint',
    (SELECT USER_ID FROM APP_USERS WHERE EMAIL = 'johndoe@example.com')),
('template_face_johndoe_device_001', 'v1.0', 'device_001', 'Face Detector A', 'face',
    (SELECT USER_ID FROM APP_USERS WHERE EMAIL = 'johndoe@example.com')),
('template_fingerprint_janedoe_device_002', 'v1.0', 'device_002', 'Fingerprint Scanner B', 'fingerprint',
    (SELECT USER_ID FROM APP_USERS WHERE EMAIL = 'janedoe@example.com')),
('template_face_bobsmith_device_003', 'v1.0', 'device_003', 'Face Detector C', 'face',
    (SELECT USER_ID FROM APP_USERS WHERE EMAIL = 'bobsmith@example.com'));

INSERT INTO
    ACCOUNTS (NAME, TYPE, INITIAL_BALANCE, DESCRIPTION, USER_ID)
VALUES
('Cash Wallet', 'CASH', 1000.00, 'Personal cash wallet', 
    (SELECT USER_ID FROM APP_USERS WHERE EMAIL = 'cashlytics123@gmail.com')),
('Maybank', 'BANK', 5000.00, 'Main bank account',
    (SELECT USER_ID FROM APP_USERS WHERE EMAIL = 'cashlytics123@gmail.com')),
('MaE Credit', 'CREDIT CARD', 0.00, 'Maybank credit card',
    (SELECT USER_ID FROM APP_USERS WHERE EMAIL = 'cashlytics123@gmail.com')),
('TnG eWallet', 'E-WALLET', 300.00, 'Touch ''n Go eWallet',
    (SELECT USER_ID FROM APP_USERS WHERE EMAIL = 'cashlytics123@gmail.com')),
('Jane''s Savings', 'BANK', 8000.00, 'Jane''s personal savings account',
    (SELECT USER_ID FROM APP_USERS WHERE EMAIL = 'janedoe@example.com')),
('Bob''s Cash', 'CASH', 500.00, 'Bob''s cash on hand',
    (SELECT USER_ID FROM APP_USERS WHERE EMAIL = 'bobsmith@example.com'));

-- CALL add_transfer
DO $$
DECLARE
    v_user_id UUID;
    v_from_account_id UUID;
    v_to_account_id UUID;
BEGIN
    SELECT USER_ID INTO v_user_id FROM APP_USERS WHERE EMAIL = 'cashlytics123@gmail.com';
    SELECT ACCOUNT_ID INTO v_from_account_id FROM ACCOUNTS WHERE NAME = 'Maybank' AND USER_ID = v_user_id;
    SELECT ACCOUNT_ID INTO v_to_account_id FROM ACCOUNTS WHERE NAME = 'Cash Wallet' AND USER_ID = v_user_id;
    CALL add_transfer(v_user_id, v_from_account_id, v_to_account_id, 'ATM Withdrawal', 200.00, 'Cash for weekly expenses', 'MYR');
END $$;

DO $$
DECLARE
    v_user_id UUID;
    v_from_account_id UUID;
    v_to_account_id UUID;
BEGIN
    SELECT USER_ID INTO v_user_id FROM APP_USERS WHERE EMAIL = 'cashlytics123@gmail.com';
    SELECT ACCOUNT_ID INTO v_from_account_id FROM ACCOUNTS WHERE NAME = 'Maybank' AND USER_ID = v_user_id;
    SELECT ACCOUNT_ID INTO v_to_account_id FROM ACCOUNTS WHERE NAME = 'TnG eWallet' AND USER_ID = v_user_id;
    CALL add_transfer(v_user_id, v_from_account_id, v_to_account_id, 'Reload eWallet', 50.00, 'Monthly reload for TnG', 'MYR');
END $$;

-- CALL add_income
DO $$
DECLARE
    v_user_id UUID;
    v_account_id UUID;
BEGIN
    SELECT USER_ID INTO v_user_id FROM APP_USERS WHERE EMAIL = 'cashlytics123@gmail.com';
    SELECT ACCOUNT_ID INTO v_account_id FROM ACCOUNTS WHERE NAME = 'Maybank' AND USER_ID = v_user_id;
    CALL add_income(v_user_id, v_account_id, 'Salary August', 3000.00, 'SALARY', 'Monthly salary for August', 'MYR', TRUE);
END $$;

DO $$
DECLARE
    v_user_id UUID;
    v_account_id UUID;
BEGIN
    SELECT USER_ID INTO v_user_id FROM APP_USERS WHERE EMAIL = 'janedoe@example.com';
    SELECT ACCOUNT_ID INTO v_account_id FROM ACCOUNTS WHERE NAME = 'Jane''s Savings' AND USER_ID = v_user_id;
    CALL add_income(v_user_id, v_account_id, 'Freelance Project', 1200.00, 'BUSINESS', 'Payment for freelance web development project', 'MYR', FALSE);
END $$;

DO $$
DECLARE
    v_user_id UUID;
    v_account_id UUID;
BEGIN
    SELECT USER_ID INTO v_user_id FROM APP_USERS WHERE EMAIL = 'bobsmith@example.com';
    SELECT ACCOUNT_ID INTO v_account_id FROM ACCOUNTS WHERE NAME = 'Bob''s Cash' AND USER_ID = v_user_id;
    CALL add_income(v_user_id, v_account_id, 'Sold Old Bike', 150.00, 'OTHER', 'Income from selling old bicycle', 'MYR', FALSE);
END $$;

INSERT INTO
    EXPENSE_CATEGORY (NAME, DESCRIPTION)
VALUES
('FOOD', 'Food and dining expenses'),
('TRANSPORT', 'Transportation costs'),
('ENTERTAINMENT', 'Entertainment and leisure activities'),
('UTILITIES', 'Utility bills such as electricity, water, and gas'),
('HEALTHCARE', 'Healthcare and medical expenses'),
('SHOPPING', 'Shopping and personal items'),
('TRAVEL', 'Travel and vacation expenses'),
('EDUCATION', 'Education and learning expenses'),
('RENT', 'Housing rent and related expenses'),
('OTHER', 'Other miscellaneous expenses');

-- CALL add_expense
DO $$
DECLARE
    v_user_id UUID;
    v_account_id UUID;
BEGIN
    SELECT USER_ID INTO v_user_id FROM APP_USERS WHERE EMAIL = 'cashlytics123@gmail.com';
    SELECT ACCOUNT_ID INTO v_account_id FROM ACCOUNTS WHERE NAME = 'Cash Wallet' AND USER_ID = v_user_id;
    CALL add_expense(
        v_user_id,
        v_account_id,
        'FOOD',
        'Grocery Shopping',
        'Weekly groceries from supermarket',
        '[
            {"name": "Milk", "qty": 1, "unit_price": 7.50},
            {"name": "Bread", "qty": 1, "unit_price": 4.20},
            {"name": "Eggs", "qty": 2, "unit_price": 8.00}
        ]',
        'MYR'
    );
END $$;

-- CALL add_expense_with_receipt
DO $$
DECLARE
    v_user_id UUID;
    v_account_id UUID;
BEGIN
    SELECT USER_ID INTO v_user_id FROM APP_USERS WHERE EMAIL = 'cashlytics123@gmail.com';
    SELECT ACCOUNT_ID INTO v_account_id FROM ACCOUNTS WHERE NAME = 'Maybank' AND USER_ID = v_user_id;
    CALL add_expense_with_receipt(
        v_user_id,
        v_account_id,
        'TRANSPORT',
        'Taxi Ride',
        'Taxi ride to airport',
        '[
            {"name": "Taxi Fare", "qty": 1, "unit_price": 45.00}
        ]',
        '/receipts/receipt_002.png',
        'MYR',
        'City Taxi Services',
        92.00,
        'City Taxi Services\nDate: 2024-09-12\nTaxi Fare x1 - $45.00\nTotal: $45.00'
    );
END $$;

-- CALL add_user_budget
DO $$
DECLARE
    v_user_id UUID;
BEGIN
    SELECT USER_ID INTO v_user_id FROM APP_USERS WHERE EMAIL = 'cashlytics123@gmail.com';
    CALL add_user_budget(
        v_user_id,
        1000.00,
        '2024-09-01',
        '2024-09-30'
    );
END $$;

---
-- CALL add_account_budget
DO $$
DECLARE
    v_user_id UUID;
    v_account_id UUID;
BEGIN
    SELECT USER_ID INTO v_user_id FROM APP_USERS WHERE EMAIL = 'cashlytics123@gmail.com';
    SELECT ACCOUNT_ID INTO v_account_id FROM ACCOUNTS WHERE NAME = 'Maybank' AND USER_ID = v_user_id;
    CALL add_account_budget(
        v_user_id,
        v_account_id,
        800.00,
        '2024-09-01',
        '2024-09-30'
    );
END $$;

--- CALL add_category_budget
DO $$
DECLARE
    v_user_id UUID;
    v_category_id UUID;
BEGIN
    SELECT USER_ID INTO v_user_id FROM APP_USERS WHERE EMAIL = 'cashlytics123@gmail.com';
    SELECT EXPENSE_CAT_ID INTO v_category_id FROM EXPENSE_CATEGORY WHERE NAME = 'FOOD';
    CALL add_category_budget(
        v_user_id,
        v_category_id,
        400.00,
        '2024-09-01',
        '2024-09-30'
    );
END $$;

INSERT INTO DETAILED (EDU_LVL, EMPLOYMENT_STAT, MARITAL_STAT, DEPENDENT_NUM, ESTIMATED_LOAN, USER_ID)
VALUES
('BACHELORS', 'EMPLOYED', 'SINGLE', 2, 15000.00,
    (SELECT USER_ID FROM APP_USERS WHERE EMAIL = 'johndoe@example.com')),
('MASTERS', 'SELF-EMPLOYED', 'MARRIED', 0, 5000.00,
    (SELECT USER_ID FROM APP_USERS WHERE EMAIL = 'janedoe@example.com')),
('DIPLOMA', 'UNEMPLOYED', 'DIVORCED', 1, 2000.00,
    (SELECT USER_ID FROM APP_USERS WHERE EMAIL = 'bobsmith@example.com'));
INSERT INTO AI_REPORT (TITLE, DESCRIPTION, BODY, MONTH, HEALTH_SCORE, USER_ID)
VALUES
('September 2024 Financial Health Report', 'An overview of your financial health for September 2024.',
 'Your financial health score for September 2024 is 85 out of 100. You have managed your expenses well and stayed within your budget limits. Keep up the good work!',
 '09-2024', 85,
    (SELECT USER_ID FROM APP_USERS WHERE EMAIL = 'cashlytics123@gmail.com')),
('August 2024 Financial Health Report', 'An overview of your financial health for August 2024.',
 'Your financial health score for August 2024 is 78 out of 100. While you did a good job managing your income, there were some overspending instances in the entertainment category. Consider reviewing your budget allocations.',
 '08-2024', 78,
    (SELECT USER_ID FROM APP_USERS WHERE EMAIL = 'janedoe@example.com')),
('July 2024 Financial Health Report', 'An overview of your financial health for July 2024.',
 'Your financial health score for July 2024 is 90 out of 100. Excellent job on maintaining a balanced budget and saving a portion of your income. Continue to monitor your spending habits to sustain this positive trend.',
 '07-2024', 90,
    (SELECT USER_ID FROM APP_USERS WHERE EMAIL = 'bobsmith@example.com'));