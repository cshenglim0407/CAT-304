-- Function to calculate weekly balances for a given month
CREATE OR REPLACE FUNCTION get_monthly_weekly_balances(
    p_user_id UUID,
    p_year INTEGER,
    p_month INTEGER,
    p_current_day INTEGER
)
RETURNS TABLE (
    week_number INTEGER,
    start_date DATE,
    end_date DATE,
    total_income NUMERIC,
    total_expense NUMERIC,
    balance NUMERIC,
    is_current_week BOOLEAN
) AS $$
DECLARE
    first_day DATE;
    last_day DATE;
    current_date_in_month DATE;
BEGIN
    -- Calculate first and last day of the month
    first_day := make_date(p_year, p_month, 1);
    last_day := (first_day + INTERVAL '1 month - 1 day')::DATE;
    current_date_in_month := make_date(p_year, p_month, p_current_day);

    RETURN QUERY
    WITH week_ranges AS (
        -- Generate week ranges for the month (4 weeks, 7 days each)
        SELECT 
            generate_series AS week_num,
            (first_day + ((generate_series - 1) * 7) * INTERVAL '1 day')::DATE AS week_start,
            LEAST(
                (first_day + ((generate_series - 1) * 7 + 6) * INTERVAL '1 day')::DATE,
                last_day
            ) AS week_end
        FROM generate_series(1, 4) AS generate_series
    ),
    income_summary AS (
        -- Calculate total income per week
        SELECT 
            wr.week_num,
            COALESCE(SUM(i.AMOUNT), 0) AS total_income
        FROM week_ranges wr
        LEFT JOIN TRANSACTION t ON t.CREATED_AT::DATE BETWEEN wr.week_start AND wr.week_end
        LEFT JOIN INCOME i ON i.TRANSACTION_ID = t.TRANSACTION_ID
        LEFT JOIN ACCOUNTS a ON t.ACCOUNT_ID = a.ACCOUNT_ID
        WHERE a.USER_ID = p_user_id OR a.USER_ID IS NULL
        GROUP BY wr.week_num
    ),
    expense_summary AS (
        -- Calculate total expenses per week
        SELECT 
            wr.week_num,
            COALESCE(SUM(e.AMOUNT), 0) AS total_expense
        FROM week_ranges wr
        LEFT JOIN TRANSACTION t ON t.CREATED_AT::DATE BETWEEN wr.week_start AND wr.week_end
        LEFT JOIN EXPENSES e ON e.TRANSACTION_ID = t.TRANSACTION_ID
        LEFT JOIN ACCOUNTS a ON t.ACCOUNT_ID = a.ACCOUNT_ID
        WHERE a.USER_ID = p_user_id OR a.USER_ID IS NULL
        GROUP BY wr.week_num
    )
    SELECT 
        wr.week_num::INTEGER AS week_number,
        wr.week_start AS start_date,
        wr.week_end AS end_date,
        COALESCE(i.total_income, 0) AS total_income,
        COALESCE(e.total_expense, 0) AS total_expense,
        COALESCE(i.total_income, 0) - COALESCE(e.total_expense, 0) AS balance,
        (current_date_in_month BETWEEN wr.week_start AND wr.week_end) AS is_current_week
    FROM week_ranges wr
    LEFT JOIN income_summary i ON i.week_num = wr.week_num
    LEFT JOIN expense_summary e ON e.week_num = wr.week_num
    -- Only return weeks that have started
    WHERE wr.week_start <= current_date_in_month
    ORDER BY wr.week_num;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate quarterly balances for a given year
CREATE OR REPLACE FUNCTION get_yearly_quarterly_balances(
    p_user_id UUID,
    p_year INTEGER,
    p_current_quarter INTEGER
)
RETURNS TABLE (
    quarter_number INTEGER,
    start_date DATE,
    end_date DATE,
    total_income NUMERIC,
    total_expense NUMERIC,
    balance NUMERIC,
    is_current_quarter BOOLEAN
) AS $$
DECLARE
    first_day_of_year DATE;
    last_day_of_year DATE;
BEGIN
    -- Calculate first and last day of the year
    first_day_of_year := make_date(p_year, 1, 1);
    last_day_of_year := make_date(p_year, 12, 31);

    RETURN QUERY
    WITH quarter_ranges AS (
        -- Generate quarter ranges for the year (Q1, Q2, Q3, Q4)
        SELECT 
            generate_series AS quarter_num,
            make_date(p_year, (generate_series - 1) * 3 + 1, 1) AS quarter_start,
            (make_date(p_year, (generate_series - 1) * 3 + 3, 1) + INTERVAL '1 month - 1 day')::DATE AS quarter_end
        FROM generate_series(1, 4) AS generate_series
    ),
    income_summary AS (
        -- Calculate total income per quarter
        SELECT 
            qr.quarter_num,
            COALESCE(SUM(i.AMOUNT), 0) AS total_income
        FROM quarter_ranges qr
        LEFT JOIN TRANSACTION t ON t.CREATED_AT::DATE BETWEEN qr.quarter_start AND qr.quarter_end
        LEFT JOIN INCOME i ON i.TRANSACTION_ID = t.TRANSACTION_ID
        LEFT JOIN ACCOUNTS a ON t.ACCOUNT_ID = a.ACCOUNT_ID
        WHERE a.USER_ID = p_user_id OR a.USER_ID IS NULL
        GROUP BY qr.quarter_num
    ),
    expense_summary AS (
        -- Calculate total expenses per quarter
        SELECT 
            qr.quarter_num,
            COALESCE(SUM(e.AMOUNT), 0) AS total_expense
        FROM quarter_ranges qr
        LEFT JOIN TRANSACTION t ON t.CREATED_AT::DATE BETWEEN qr.quarter_start AND qr.quarter_end
        LEFT JOIN EXPENSES e ON e.TRANSACTION_ID = t.TRANSACTION_ID
        LEFT JOIN ACCOUNTS a ON t.ACCOUNT_ID = a.ACCOUNT_ID
        WHERE a.USER_ID = p_user_id OR a.USER_ID IS NULL
        GROUP BY qr.quarter_num
    )
    SELECT 
        qr.quarter_num::INTEGER AS quarter_number,
        qr.quarter_start AS start_date,
        qr.quarter_end AS end_date,
        COALESCE(i.total_income, 0) AS total_income,
        COALESCE(e.total_expense, 0) AS total_expense,
        COALESCE(i.total_income, 0) - COALESCE(e.total_expense, 0) AS balance,
        (qr.quarter_num = p_current_quarter) AS is_current_quarter
    FROM quarter_ranges qr
    LEFT JOIN income_summary i ON i.quarter_num = qr.quarter_num
    LEFT JOIN expense_summary e ON e.quarter_num = qr.quarter_num
    -- Only return quarters that have started
    WHERE qr.quarter_num <= p_current_quarter
    ORDER BY qr.quarter_num;
END;
$$ LANGUAGE plpgsql;
