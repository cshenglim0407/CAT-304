-- Enable RLS on all tables
ALTER TABLE public.APP_USERS ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ACCOUNTS ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.TRANSACTION ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.TRANSFER ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.INCOME ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.EXPENSE_CATEGORY ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.EXPENSES ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.EXPENSE_ITEMS ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.RECEIPT ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.BUDGET ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.USER_BUDGET ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ACCOUNT_BUDGET ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.CATEGORY_BUDGET ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.DETAILED ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.AI_REPORT ENABLE ROW LEVEL SECURITY;

-- ==============================================
-- APP_USERS Policies
-- ==============================================
CREATE POLICY "Users can view own profile" ON public.APP_USERS
    FOR SELECT USING (auth.uid() = USER_ID);

CREATE POLICY "Users can insert own profile" ON public.APP_USERS
    FOR INSERT WITH CHECK (auth.uid() = USER_ID);

CREATE POLICY "Users can update own profile" ON public.APP_USERS
    FOR UPDATE USING (auth.uid() = USER_ID);

CREATE POLICY "Users can delete own profile" ON public.APP_USERS
    FOR DELETE USING (auth.uid() = USER_ID);

-- ==============================================
-- ACCOUNTS Policies
-- ==============================================
CREATE POLICY "Users can view own accounts" ON public.ACCOUNTS
    FOR SELECT USING (auth.uid() = USER_ID);

CREATE POLICY "Users can insert own accounts" ON public.ACCOUNTS
    FOR INSERT WITH CHECK (auth.uid() = USER_ID);

CREATE POLICY "Users can update own accounts" ON public.ACCOUNTS
    FOR UPDATE USING (auth.uid() = USER_ID);

CREATE POLICY "Users can delete own accounts" ON public.ACCOUNTS
    FOR DELETE USING (auth.uid() = USER_ID);

-- ==============================================
-- TRANSACTION Policies (via ACCOUNTS)
-- ==============================================
CREATE POLICY "Users can view own transactions" ON public.TRANSACTION
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.ACCOUNTS
            WHERE ACCOUNTS.ACCOUNT_ID = TRANSACTION.ACCOUNT_ID
            AND ACCOUNTS.USER_ID = auth.uid()
        )
    );

CREATE POLICY "Users can insert own transactions" ON public.TRANSACTION
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.ACCOUNTS
            WHERE ACCOUNTS.ACCOUNT_ID = TRANSACTION.ACCOUNT_ID
            AND ACCOUNTS.USER_ID = auth.uid()
        )
    );

CREATE POLICY "Users can update own transactions" ON public.TRANSACTION
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.ACCOUNTS
            WHERE ACCOUNTS.ACCOUNT_ID = TRANSACTION.ACCOUNT_ID
            AND ACCOUNTS.USER_ID = auth.uid()
        )
    );

CREATE POLICY "Users can delete own transactions" ON public.TRANSACTION
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM public.ACCOUNTS
            WHERE ACCOUNTS.ACCOUNT_ID = TRANSACTION.ACCOUNT_ID
            AND ACCOUNTS.USER_ID = auth.uid()
        )
    );

-- ==============================================
-- TRANSFER Policies (via FROM_ACCOUNT and TO_ACCOUNT)
-- ==============================================
CREATE POLICY "Users can view own transfers" ON public.TRANSFER
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.ACCOUNTS
            WHERE (ACCOUNTS.ACCOUNT_ID = TRANSFER.FROM_ACCOUNT_ID
                OR ACCOUNTS.ACCOUNT_ID = TRANSFER.TO_ACCOUNT_ID)
            AND ACCOUNTS.USER_ID = auth.uid()
        )
    );

CREATE POLICY "Users can insert own transfers" ON public.TRANSFER
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.ACCOUNTS
            WHERE ACCOUNTS.ACCOUNT_ID = TRANSFER.FROM_ACCOUNT_ID
            AND ACCOUNTS.USER_ID = auth.uid()
        )
        AND EXISTS (
            SELECT 1 FROM public.ACCOUNTS
            WHERE ACCOUNTS.ACCOUNT_ID = TRANSFER.TO_ACCOUNT_ID
            AND ACCOUNTS.USER_ID = auth.uid()
        )
    );

CREATE POLICY "Users can update own transfers" ON public.TRANSFER
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.ACCOUNTS
            WHERE (ACCOUNTS.ACCOUNT_ID = TRANSFER.FROM_ACCOUNT_ID
                OR ACCOUNTS.ACCOUNT_ID = TRANSFER.TO_ACCOUNT_ID)
            AND ACCOUNTS.USER_ID = auth.uid()
        )
    );

CREATE POLICY "Users can delete own transfers" ON public.TRANSFER
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM public.ACCOUNTS
            WHERE (ACCOUNTS.ACCOUNT_ID = TRANSFER.FROM_ACCOUNT_ID
                OR ACCOUNTS.ACCOUNT_ID = TRANSFER.TO_ACCOUNT_ID)
            AND ACCOUNTS.USER_ID = auth.uid()
        )
    );

-- ==============================================
-- INCOME Policies (via TRANSACTION -> ACCOUNTS)
-- ==============================================
CREATE POLICY "Users can view own income" ON public.INCOME
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.TRANSACTION
            JOIN public.ACCOUNTS ON ACCOUNTS.ACCOUNT_ID = TRANSACTION.ACCOUNT_ID
            WHERE TRANSACTION.TRANSACTION_ID = INCOME.TRANSACTION_ID
            AND ACCOUNTS.USER_ID = auth.uid()
        )
    );

CREATE POLICY "Users can insert own income" ON public.INCOME
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.TRANSACTION
            JOIN public.ACCOUNTS ON ACCOUNTS.ACCOUNT_ID = TRANSACTION.ACCOUNT_ID
            WHERE TRANSACTION.TRANSACTION_ID = INCOME.TRANSACTION_ID
            AND ACCOUNTS.USER_ID = auth.uid()
        )
    );

CREATE POLICY "Users can update own income" ON public.INCOME
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.TRANSACTION
            JOIN public.ACCOUNTS ON ACCOUNTS.ACCOUNT_ID = TRANSACTION.ACCOUNT_ID
            WHERE TRANSACTION.TRANSACTION_ID = INCOME.TRANSACTION_ID
            AND ACCOUNTS.USER_ID = auth.uid()
        )
    );

CREATE POLICY "Users can delete own income" ON public.INCOME
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM public.TRANSACTION
            JOIN public.ACCOUNTS ON ACCOUNTS.ACCOUNT_ID = TRANSACTION.ACCOUNT_ID
            WHERE TRANSACTION.TRANSACTION_ID = INCOME.TRANSACTION_ID
            AND ACCOUNTS.USER_ID = auth.uid()
        )
    );

-- ==============================================
-- EXPENSE_CATEGORY Policies (Public read, admin write)
-- ==============================================
CREATE POLICY "Anyone can view expense categories" ON public.EXPENSE_CATEGORY
    FOR SELECT USING (true);

-- Note: Only admins should insert/update/delete categories
-- You may want to add admin-specific policies here

-- ==============================================
-- EXPENSES Policies (via TRANSACTION -> ACCOUNTS)
-- ==============================================
CREATE POLICY "Users can view own expenses" ON public.EXPENSES
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.TRANSACTION
            JOIN public.ACCOUNTS ON ACCOUNTS.ACCOUNT_ID = TRANSACTION.ACCOUNT_ID
            WHERE TRANSACTION.TRANSACTION_ID = EXPENSES.TRANSACTION_ID
            AND ACCOUNTS.USER_ID = auth.uid()
        )
    );

CREATE POLICY "Users can insert own expenses" ON public.EXPENSES
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.TRANSACTION
            JOIN public.ACCOUNTS ON ACCOUNTS.ACCOUNT_ID = TRANSACTION.ACCOUNT_ID
            WHERE TRANSACTION.TRANSACTION_ID = EXPENSES.TRANSACTION_ID
            AND ACCOUNTS.USER_ID = auth.uid()
        )
    );

CREATE POLICY "Users can update own expenses" ON public.EXPENSES
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.TRANSACTION
            JOIN public.ACCOUNTS ON ACCOUNTS.ACCOUNT_ID = TRANSACTION.ACCOUNT_ID
            WHERE TRANSACTION.TRANSACTION_ID = EXPENSES.TRANSACTION_ID
            AND ACCOUNTS.USER_ID = auth.uid()
        )
    );

CREATE POLICY "Users can delete own expenses" ON public.EXPENSES
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM public.TRANSACTION
            JOIN public.ACCOUNTS ON ACCOUNTS.ACCOUNT_ID = TRANSACTION.ACCOUNT_ID
            WHERE TRANSACTION.TRANSACTION_ID = EXPENSES.TRANSACTION_ID
            AND ACCOUNTS.USER_ID = auth.uid()
        )
    );

-- ==============================================
-- EXPENSE_ITEMS Policies (via EXPENSES -> TRANSACTION -> ACCOUNTS)
-- ==============================================
CREATE POLICY "Users can view own expense items" ON public.EXPENSE_ITEMS
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.EXPENSES
            JOIN public.TRANSACTION ON TRANSACTION.TRANSACTION_ID = EXPENSES.TRANSACTION_ID
            JOIN public.ACCOUNTS ON ACCOUNTS.ACCOUNT_ID = TRANSACTION.ACCOUNT_ID
            WHERE EXPENSES.TRANSACTION_ID = EXPENSE_ITEMS.TRANSACTION_ID
            AND ACCOUNTS.USER_ID = auth.uid()
        )
    );

CREATE POLICY "Users can insert own expense items" ON public.EXPENSE_ITEMS
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.EXPENSES
            JOIN public.TRANSACTION ON TRANSACTION.TRANSACTION_ID = EXPENSES.TRANSACTION_ID
            JOIN public.ACCOUNTS ON ACCOUNTS.ACCOUNT_ID = TRANSACTION.ACCOUNT_ID
            WHERE EXPENSES.TRANSACTION_ID = EXPENSE_ITEMS.TRANSACTION_ID
            AND ACCOUNTS.USER_ID = auth.uid()
        )
    );

CREATE POLICY "Users can update own expense items" ON public.EXPENSE_ITEMS
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.EXPENSES
            JOIN public.TRANSACTION ON TRANSACTION.TRANSACTION_ID = EXPENSES.TRANSACTION_ID
            JOIN public.ACCOUNTS ON ACCOUNTS.ACCOUNT_ID = TRANSACTION.ACCOUNT_ID
            WHERE EXPENSES.TRANSACTION_ID = EXPENSE_ITEMS.TRANSACTION_ID
            AND ACCOUNTS.USER_ID = auth.uid()
        )
    );

CREATE POLICY "Users can delete own expense items" ON public.EXPENSE_ITEMS
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM public.EXPENSES
            JOIN public.TRANSACTION ON TRANSACTION.TRANSACTION_ID = EXPENSES.TRANSACTION_ID
            JOIN public.ACCOUNTS ON ACCOUNTS.ACCOUNT_ID = TRANSACTION.ACCOUNT_ID
            WHERE EXPENSES.TRANSACTION_ID = EXPENSE_ITEMS.TRANSACTION_ID
            AND ACCOUNTS.USER_ID = auth.uid()
        )
    );

-- ==============================================
-- RECEIPT Policies (via TRANSACTION -> ACCOUNTS)
-- ==============================================
CREATE POLICY "Users can view own receipts" ON public.RECEIPT
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.TRANSACTION
            JOIN public.ACCOUNTS ON ACCOUNTS.ACCOUNT_ID = TRANSACTION.ACCOUNT_ID
            WHERE TRANSACTION.TRANSACTION_ID = RECEIPT.TRANSACTION_ID
            AND ACCOUNTS.USER_ID = auth.uid()
        )
    );

CREATE POLICY "Users can insert own receipts" ON public.RECEIPT
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.TRANSACTION
            JOIN public.ACCOUNTS ON ACCOUNTS.ACCOUNT_ID = TRANSACTION.ACCOUNT_ID
            WHERE TRANSACTION.TRANSACTION_ID = RECEIPT.TRANSACTION_ID
            AND ACCOUNTS.USER_ID = auth.uid()
        )
    );

CREATE POLICY "Users can update own receipts" ON public.RECEIPT
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.TRANSACTION
            JOIN public.ACCOUNTS ON ACCOUNTS.ACCOUNT_ID = TRANSACTION.ACCOUNT_ID
            WHERE TRANSACTION.TRANSACTION_ID = RECEIPT.TRANSACTION_ID
            AND ACCOUNTS.USER_ID = auth.uid()
        )
    );

CREATE POLICY "Users can delete own receipts" ON public.RECEIPT
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM public.TRANSACTION
            JOIN public.ACCOUNTS ON ACCOUNTS.ACCOUNT_ID = TRANSACTION.ACCOUNT_ID
            WHERE TRANSACTION.TRANSACTION_ID = RECEIPT.TRANSACTION_ID
            AND ACCOUNTS.USER_ID = auth.uid()
        )
    );

-- ==============================================
-- BUDGET Policies
-- ==============================================
CREATE POLICY "Users can view own budgets" ON public.BUDGET
    FOR SELECT USING (auth.uid() = USER_ID);

CREATE POLICY "Users can insert own budgets" ON public.BUDGET
    FOR INSERT WITH CHECK (auth.uid() = USER_ID);

CREATE POLICY "Users can update own budgets" ON public.BUDGET
    FOR UPDATE USING (auth.uid() = USER_ID);

CREATE POLICY "Users can delete own budgets" ON public.BUDGET
    FOR DELETE USING (auth.uid() = USER_ID);

-- ==============================================
-- USER_BUDGET Policies (via BUDGET)
-- ==============================================
CREATE POLICY "Users can view own user budgets" ON public.USER_BUDGET
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.BUDGET
            WHERE BUDGET.BUDGET_ID = USER_BUDGET.BUDGET_ID
            AND BUDGET.USER_ID = auth.uid()
        )
    );

CREATE POLICY "Users can insert own user budgets" ON public.USER_BUDGET
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.BUDGET
            WHERE BUDGET.BUDGET_ID = USER_BUDGET.BUDGET_ID
            AND BUDGET.USER_ID = auth.uid()
        )
    );

CREATE POLICY "Users can update own user budgets" ON public.USER_BUDGET
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.BUDGET
            WHERE BUDGET.BUDGET_ID = USER_BUDGET.BUDGET_ID
            AND BUDGET.USER_ID = auth.uid()
        )
    );

CREATE POLICY "Users can delete own user budgets" ON public.USER_BUDGET
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM public.BUDGET
            WHERE BUDGET.BUDGET_ID = USER_BUDGET.BUDGET_ID
            AND BUDGET.USER_ID = auth.uid()
        )
    );

-- ==============================================
-- ACCOUNT_BUDGET Policies (via BUDGET and ACCOUNTS)
-- ==============================================
CREATE POLICY "Users can view own account budgets" ON public.ACCOUNT_BUDGET
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.BUDGET
            WHERE BUDGET.BUDGET_ID = ACCOUNT_BUDGET.BUDGET_ID
            AND BUDGET.USER_ID = auth.uid()
        )
    );

CREATE POLICY "Users can insert own account budgets" ON public.ACCOUNT_BUDGET
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.BUDGET
            WHERE BUDGET.BUDGET_ID = ACCOUNT_BUDGET.BUDGET_ID
            AND BUDGET.USER_ID = auth.uid()
        )
        AND EXISTS (
            SELECT 1 FROM public.ACCOUNTS
            WHERE ACCOUNTS.ACCOUNT_ID = ACCOUNT_BUDGET.ACCOUNT_ID
            AND ACCOUNTS.USER_ID = auth.uid()
        )
    );

CREATE POLICY "Users can update own account budgets" ON public.ACCOUNT_BUDGET
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.BUDGET
            WHERE BUDGET.BUDGET_ID = ACCOUNT_BUDGET.BUDGET_ID
            AND BUDGET.USER_ID = auth.uid()
        )
    );

CREATE POLICY "Users can delete own account budgets" ON public.ACCOUNT_BUDGET
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM public.BUDGET
            WHERE BUDGET.BUDGET_ID = ACCOUNT_BUDGET.BUDGET_ID
            AND BUDGET.USER_ID = auth.uid()
        )
    );

-- ==============================================
-- CATEGORY_BUDGET Policies (via BUDGET)
-- ==============================================
CREATE POLICY "Users can view own category budgets" ON public.CATEGORY_BUDGET
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.BUDGET
            WHERE BUDGET.BUDGET_ID = CATEGORY_BUDGET.BUDGET_ID
            AND BUDGET.USER_ID = auth.uid()
        )
    );

CREATE POLICY "Users can insert own category budgets" ON public.CATEGORY_BUDGET
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.BUDGET
            WHERE BUDGET.BUDGET_ID = CATEGORY_BUDGET.BUDGET_ID
            AND BUDGET.USER_ID = auth.uid()
        )
    );

CREATE POLICY "Users can update own category budgets" ON public.CATEGORY_BUDGET
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.BUDGET
            WHERE BUDGET.BUDGET_ID = CATEGORY_BUDGET.BUDGET_ID
            AND BUDGET.USER_ID = auth.uid()
        )
    );

CREATE POLICY "Users can delete own category budgets" ON public.CATEGORY_BUDGET
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM public.BUDGET
            WHERE BUDGET.BUDGET_ID = CATEGORY_BUDGET.BUDGET_ID
            AND BUDGET.USER_ID = auth.uid()
        )
    );

-- ==============================================
-- DETAILED Policies
-- ==============================================
CREATE POLICY "Users can view own detailed info" ON public.DETAILED
    FOR SELECT USING (auth.uid() = USER_ID);

CREATE POLICY "Users can insert own detailed info" ON public.DETAILED
    FOR INSERT WITH CHECK (auth.uid() = USER_ID);

CREATE POLICY "Users can update own detailed info" ON public.DETAILED
    FOR UPDATE USING (auth.uid() = USER_ID);

CREATE POLICY "Users can delete own detailed info" ON public.DETAILED
    FOR DELETE USING (auth.uid() = USER_ID);

-- ==============================================
-- AI_REPORT Policies
-- ==============================================
CREATE POLICY "Users can view own AI reports" ON public.AI_REPORT
    FOR SELECT USING (auth.uid() = USER_ID);

CREATE POLICY "Users can insert own AI reports" ON public.AI_REPORT
    FOR INSERT WITH CHECK (auth.uid() = USER_ID);

CREATE POLICY "Users can update own AI reports" ON public.AI_REPORT
    FOR UPDATE USING (auth.uid() = USER_ID);

CREATE POLICY "Users can delete own AI reports" ON public.AI_REPORT
    FOR DELETE USING (auth.uid() = USER_ID);