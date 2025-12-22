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
