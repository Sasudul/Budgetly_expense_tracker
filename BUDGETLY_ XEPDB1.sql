CREATE USER budgetly IDENTIFIED BY 1234
DEFAULT TABLESPACE users
QUOTA UNLIMITED ON users;

GRANT CREATE SESSION TO budgetly;
GRANT CREATE TABLE TO budgetly;
GRANT CREATE PROCEDURE TO budgetly;
GRANT CREATE SEQUENCE TO budgetly;
GRANT CREATE TRIGGER TO budgetly;

-- Connect as budgetly user, then run:

-- 1. Users Table
CREATE TABLE users (
    id VARCHAR2(36) PRIMARY KEY,
    name VARCHAR2(255) NOT NULL,
    email VARCHAR2(255) NOT NULL UNIQUE,
    password VARCHAR2(255) NOT NULL,
    sync_status NUMBER(1,0) DEFAULT 0 NOT NULL,
    is_deleted NUMBER(1,0) DEFAULT 0 NOT NULL,
    created_at TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    last_modified TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    CONSTRAINT chk_user_email CHECK (email LIKE '%_@_%._%')
);

-- 2. Expenses Table
CREATE TABLE expenses (
    id VARCHAR2(36) PRIMARY KEY,
    user_id VARCHAR2(36) NOT NULL,
    expense_date DATE NOT NULL,
    category VARCHAR2(100) NOT NULL,
    amount NUMBER(18, 2) NOT NULL,
    notes VARCHAR2(1000),
    sync_status NUMBER(1,0) DEFAULT 0 NOT NULL,
    is_deleted NUMBER(1,0) DEFAULT 0 NOT NULL,
    created_at TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    last_modified TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    CONSTRAINT chk_expense_amount CHECK (amount > 0),
    CONSTRAINT fk_expense_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 3. Budgets Table
CREATE TABLE budgets (
    id VARCHAR2(36) PRIMARY KEY,
    user_id VARCHAR2(36) NOT NULL,
    month VARCHAR2(7) NOT NULL,
    limit_amount NUMBER(18, 2) NOT NULL,
    sync_status NUMBER(1,0) DEFAULT 0 NOT NULL,
    is_deleted NUMBER(1,0) DEFAULT 0 NOT NULL,
    created_at TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    last_modified TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    CONSTRAINT chk_budget_limit CHECK (limit_amount >= 0),
    CONSTRAINT uq_user_month UNIQUE (user_id, month),
    CONSTRAINT fk_budget_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 4. Savings Table
CREATE TABLE savings (
    id VARCHAR2(36) PRIMARY KEY,
    user_id VARCHAR2(36) NOT NULL,
    goal_name VARCHAR2(255) NOT NULL,
    target_amount NUMBER(18, 2) NOT NULL,
    current_amount NUMBER(18, 2) NOT NULL,
    sync_status NUMBER(1,0) DEFAULT 0 NOT NULL,
    is_deleted NUMBER(1,0) DEFAULT 0 NOT NULL,
    created_at TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    last_modified TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    CONSTRAINT chk_saving_target CHECK (target_amount > 0),
    CONSTRAINT chk_saving_current CHECK (current_amount >= 0 AND current_amount <= target_amount),
    CONSTRAINT uq_user_goal UNIQUE (user_id, goal_name),
    CONSTRAINT fk_saving_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Create triggers for last_modified
CREATE OR REPLACE TRIGGER trg_users_last_modified
BEFORE UPDATE ON users FOR EACH ROW
BEGIN :new.last_modified := SYSTIMESTAMP; END;
/

CREATE OR REPLACE TRIGGER trg_expenses_last_modified
BEFORE UPDATE ON expenses FOR EACH ROW
BEGIN :new.last_modified := SYSTIMESTAMP; END;
/

CREATE OR REPLACE TRIGGER trg_budgets_last_modified
BEFORE UPDATE ON budgets FOR EACH ROW
BEGIN :new.last_modified := SYSTIMESTAMP; END;
/

CREATE OR REPLACE TRIGGER trg_savings_last_modified
BEFORE UPDATE ON savings FOR EACH ROW
BEGIN :new.last_modified := SYSTIMESTAMP; END;
/

BEGIN
  ORDS.ENABLE_SCHEMA(
    p_enabled => TRUE,
    p_schema => 'BUDGETLY',
    p_url_mapping_type => 'BASE_PATH',
    p_url_mapping_pattern => 'budgetly',
    p_auto_rest_auth => FALSE
  );
  COMMIT;
END;
/

BEGIN
  ORDS.ENABLE_OBJECT(p_enabled=>TRUE, p_schema=>'BUDGETLY', p_object=>'USERS', p_object_type=>'TABLE', p_object_alias=>'users', p_auto_rest_auth=>FALSE);
  ORDS.ENABLE_OBJECT(p_enabled=>TRUE, p_schema=>'BUDGETLY', p_object=>'EXPENSES', p_object_type=>'TABLE', p_object_alias=>'expenses', p_auto_rest_auth=>FALSE);
  ORDS.ENABLE_OBJECT(p_enabled=>TRUE, p_schema=>'BUDGETLY', p_object=>'BUDGETS', p_object_type=>'TABLE', p_object_alias=>'budgets', p_auto_rest_auth=>FALSE);
  ORDS.ENABLE_OBJECT(p_enabled=>TRUE, p_schema=>'BUDGETLY', p_object=>'SAVINGS', p_object_type=>'TABLE', p_object_alias=>'savings', p_auto_rest_auth=>FALSE);
  COMMIT;
END;
/

INSERT INTO users (id, name, email, password)
VALUES ('user-67890', 'Sasa', 'sasa@gmail.com', 'Cool2006#');
COMMIT;

-- ============================================
-- USERS API
-- ============================================
BEGIN
  ORDS.DEFINE_MODULE(
    p_module_name    => 'users_api',
    p_base_path      => '/api/users/',
    p_items_per_page => 25,
    p_status         => 'PUBLISHED'
  );
  
  -- POST /users/create
  ORDS.DEFINE_TEMPLATE(
    p_module_name => 'users_api',
    p_pattern     => 'create'
  );
  
  ORDS.DEFINE_HANDLER(
    p_module_name => 'users_api',
    p_pattern     => 'create',
    p_method      => 'POST',
    p_source_type => 'plsql/block',
    p_source      => 
'BEGIN
  INSERT INTO users (id, name, email, password, sync_status, is_deleted, last_modified)
  VALUES (:id, :name, :email, :password, 1, 0, SYSTIMESTAMP);
  COMMIT;
END;'
  );
  
  -- GET /users/list
  ORDS.DEFINE_TEMPLATE(
    p_module_name => 'users_api',
    p_pattern     => 'list'
  );
  
  ORDS.DEFINE_HANDLER(
    p_module_name => 'users_api',
    p_pattern     => 'list',
    p_method      => 'GET',
    p_source_type => 'json/collection',
    p_source      => 'SELECT * FROM users WHERE is_deleted = 0'
  );
  
  COMMIT;
END;
/

-- ============================================
-- EXPENSES API
-- ============================================
BEGIN
  ORDS.DEFINE_MODULE(
    p_module_name    => 'expenses_api',
    p_base_path      => '/api/expenses/',
    p_items_per_page => 25,
    p_status         => 'PUBLISHED'
  );
  
  -- POST /expenses/create
  ORDS.DEFINE_TEMPLATE(
    p_module_name => 'expenses_api',
    p_pattern     => 'create'
  );
  
  ORDS.DEFINE_HANDLER(
    p_module_name => 'expenses_api',
    p_pattern     => 'create',
    p_method      => 'POST',
    p_source_type => 'plsql/block',
    p_source      => 
'BEGIN
  INSERT INTO expenses (id, user_id, expense_date, category, amount, notes, sync_status, is_deleted, last_modified)
  VALUES (:id, :user_id, TO_DATE(:expense_date, ''YYYY-MM-DD''), :category, :amount, :notes, 1, 0, SYSTIMESTAMP);
  COMMIT;
END;'
  );
  
  -- GET /expenses/list
  ORDS.DEFINE_TEMPLATE(
    p_module_name => 'expenses_api',
    p_pattern     => 'list'
  );
  
  ORDS.DEFINE_HANDLER(
    p_module_name => 'expenses_api',
    p_pattern     => 'list',
    p_method      => 'GET',
    p_source_type => 'json/collection',
    p_source      => 'SELECT * FROM expenses WHERE is_deleted = 0'
  );
  
  COMMIT;
END;
/

-- ============================================
-- BUDGETS API
-- ============================================
BEGIN
  ORDS.DEFINE_MODULE(
    p_module_name    => 'budgets_api',
    p_base_path      => '/api/budgets/',
    p_items_per_page => 25,
    p_status         => 'PUBLISHED'
  );
  
  -- POST /budgets/create
  ORDS.DEFINE_TEMPLATE(
    p_module_name => 'budgets_api',
    p_pattern     => 'create'
  );
  
  ORDS.DEFINE_HANDLER(
    p_module_name => 'budgets_api',
    p_pattern     => 'create',
    p_method      => 'POST',
    p_source_type => 'plsql/block',
    p_source      => 
'BEGIN
  INSERT INTO budgets (id, user_id, month, limit_amount, sync_status, is_deleted, last_modified)
  VALUES (:id, :user_id, :month, :limit_amount, 1, 0, SYSTIMESTAMP);
  COMMIT;
END;'
  );
  
  -- GET /budgets/list
  ORDS.DEFINE_TEMPLATE(
    p_module_name => 'budgets_api',
    p_pattern     => 'list'
  );
  
  ORDS.DEFINE_HANDLER(
    p_module_name => 'budgets_api',
    p_pattern     => 'list',
    p_method      => 'GET',
    p_source_type => 'json/collection',
    p_source      => 'SELECT * FROM budgets WHERE is_deleted = 0'
  );
  
  COMMIT;
END;
/

-- ============================================
-- SAVINGS API
-- ============================================
BEGIN
  ORDS.DEFINE_MODULE(
    p_module_name    => 'savings_api',
    p_base_path      => '/api/savings/',
    p_items_per_page => 25,
    p_status         => 'PUBLISHED'
  );
  
  -- POST /savings/create
  ORDS.DEFINE_TEMPLATE(
    p_module_name => 'savings_api',
    p_pattern     => 'create'
  );
  
  ORDS.DEFINE_HANDLER(
    p_module_name => 'savings_api',
    p_pattern     => 'create',
    p_method      => 'POST',
    p_source_type => 'plsql/block',
    p_source      => 
'BEGIN
  INSERT INTO savings (id, user_id, goal_name, target_amount, current_amount, sync_status, is_deleted, last_modified)
  VALUES (:id, :user_id, :goal_name, :target_amount, :current_amount, 1, 0, SYSTIMESTAMP);
  COMMIT;
END;'
  );
  
  -- GET /savings/list
  ORDS.DEFINE_TEMPLATE(
    p_module_name => 'savings_api',
    p_pattern     => 'list'
  );
  
  ORDS.DEFINE_HANDLER(
    p_module_name => 'savings_api',
    p_pattern     => 'list',
    p_method      => 'GET',
    p_source_type => 'json/collection',
    p_source      => 'SELECT * FROM savings WHERE is_deleted = 0'
  );
  
  COMMIT;
END;
/

BEGIN
  -- Create login module
  ORDS.DEFINE_MODULE(
    p_module_name    => 'auth_api',
    p_base_path      => '/api/auth/',
    p_items_per_page => 25,
    p_status         => 'PUBLISHED'
  );
  
  -- POST /auth/login
  ORDS.DEFINE_TEMPLATE(
    p_module_name => 'auth_api',
    p_pattern     => 'login'
  );
  
  ORDS.DEFINE_HANDLER(
    p_module_name => 'auth_api',
    p_pattern     => 'login',
    p_method      => 'POST',
    p_source_type => 'json/collection',
    p_source      => 
'SELECT id, name, email
FROM users
WHERE email = :email 
  AND password = :password 
  AND is_deleted = 0'
  );
  
  COMMIT;
END;
/

BEGIN
  -- Create login module
  ORDS.DEFINE_MODULE(
    p_module_name    => 'auth_api',
    p_base_path      => '/api/auth/',
    p_items_per_page => 25,
    p_status         => 'PUBLISHED'
  );
  
  -- POST /auth/login
  ORDS.DEFINE_TEMPLATE(
    p_module_name => 'auth_api',
    p_pattern     => 'login'
  );
  
  ORDS.DEFINE_HANDLER(
    p_module_name => 'auth_api',
    p_pattern     => 'login',
    p_method      => 'POST',
    p_source_type => 'json/collection',
    p_source      => 
'SELECT id, name, email
FROM users
WHERE email = :email 
  AND password = :password 
  AND is_deleted = 0'
  );
  
  COMMIT;
END;
/

-- Connect as BUDGETLY user
CREATE OR REPLACE PACKAGE financial_reports AS
  -- Report 1: Monthly Expenditure Analysis
  PROCEDURE monthly_expenditure_analysis(p_user_id VARCHAR2);
  
  -- Report 2: Budget Adherence Tracking
  PROCEDURE budget_adherence_tracking(p_user_id VARCHAR2);
  
  -- Report 3: Savings Goal Progress
  PROCEDURE savings_goal_progress(p_user_id VARCHAR2);
  
  -- Report 4: Category-wise Expense Distribution
  PROCEDURE category_expense_distribution(p_user_id VARCHAR2);
  
  -- Report 5: Forecasted Savings Trends
  PROCEDURE forecasted_savings_trends(p_user_id VARCHAR2);
END financial_reports;
/

CREATE OR REPLACE PACKAGE BODY financial_reports AS

  -- =====================================================
  -- REPORT 1: Monthly Expenditure Analysis
  -- =====================================================
  PROCEDURE monthly_expenditure_analysis(p_user_id VARCHAR2) IS
    CURSOR expense_cursor IS
      SELECT 
        TO_CHAR(expense_date, 'YYYY-MM') as expense_month,
        SUM(amount) as total_spent,
        COUNT(*) as transaction_count,
        AVG(amount) as avg_transaction,
        MIN(amount) as min_expense,
        MAX(amount) as max_expense
      FROM expenses
      WHERE user_id = p_user_id 
        AND is_deleted = 0
      GROUP BY TO_CHAR(expense_date, 'YYYY-MM')
      ORDER BY expense_month DESC;
      
    v_month VARCHAR2(7);
    v_total NUMBER;
    v_count NUMBER;
    v_avg NUMBER;
    v_min NUMBER;
    v_max NUMBER;
  BEGIN
    DBMS_OUTPUT.PUT_LINE('   MONTHLY EXPENDITURE ANALYSIS');
    DBMS_OUTPUT.PUT_LINE('----------------------------------------');
    DBMS_OUTPUT.PUT_LINE('');
    
    FOR rec IN expense_cursor LOOP
      DBMS_OUTPUT.PUT_LINE('Month: ' || rec.expense_month);
      DBMS_OUTPUT.PUT_LINE('  Total Spent: $' || TO_CHAR(rec.total_spent, '999,999.99'));
      DBMS_OUTPUT.PUT_LINE('  Transactions: ' || rec.transaction_count);
      DBMS_OUTPUT.PUT_LINE('  Avg/Transaction: $' || TO_CHAR(rec.avg_transaction, '999,999.99'));
      DBMS_OUTPUT.PUT_LINE('  Min Expense: $' || TO_CHAR(rec.min_expense, '999,999.99'));
      DBMS_OUTPUT.PUT_LINE('  Max Expense: $' || TO_CHAR(rec.max_expense, '999,999.99'));
      DBMS_OUTPUT.PUT_LINE('----------------------------------------');
    END LOOP;
    
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      DBMS_OUTPUT.PUT_LINE('No expense data found for this user.');
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
  END monthly_expenditure_analysis;

  -- =====================================================
  -- REPORT 2: Budget Adherence Tracking
  -- =====================================================
  PROCEDURE budget_adherence_tracking(p_user_id VARCHAR2) IS
    CURSOR budget_cursor IS
      SELECT 
        b.month,
        b.limit_amount as budget_limit,
        NVL(SUM(e.amount), 0) as actual_spent,
        b.limit_amount - NVL(SUM(e.amount), 0) as remaining,
        CASE 
          WHEN b.limit_amount > 0 THEN 
            ROUND((NVL(SUM(e.amount), 0) / b.limit_amount) * 100, 2)
          ELSE 0
        END as utilization_percentage,
        CASE 
          WHEN NVL(SUM(e.amount), 0) > b.limit_amount THEN 'OVER BUDGET'
          WHEN NVL(SUM(e.amount), 0) > (b.limit_amount * 0.9) THEN 'WARNING'
          ELSE 'ON TRACK'
        END as status
      FROM budgets b
      LEFT JOIN expenses e ON b.user_id = e.user_id 
        AND b.month = TO_CHAR(e.expense_date, 'YYYY-MM')
        AND e.is_deleted = 0
      WHERE b.user_id = p_user_id 
        AND b.is_deleted = 0
      GROUP BY b.month, b.limit_amount
      ORDER BY b.month DESC;
  BEGIN
    DBMS_OUTPUT.PUT_LINE('   BUDGET ADHERENCE TRACKING');
    DBMS_OUTPUT.PUT_LINE('-----------------------------------');
    DBMS_OUTPUT.PUT_LINE('');
    
    FOR rec IN budget_cursor LOOP
      DBMS_OUTPUT.PUT_LINE('Month: ' || rec.month);
      DBMS_OUTPUT.PUT_LINE('  Budget Limit: $' || TO_CHAR(rec.budget_limit, '999,999.99'));
      DBMS_OUTPUT.PUT_LINE('  Actual Spent: $' || TO_CHAR(rec.actual_spent, '999,999.99'));
      DBMS_OUTPUT.PUT_LINE('  Remaining: $' || TO_CHAR(rec.remaining, '999,999.99'));
      DBMS_OUTPUT.PUT_LINE('  Utilization: ' || rec.utilization_percentage || '%');
      DBMS_OUTPUT.PUT_LINE('  Status: ' || rec.status);
      DBMS_OUTPUT.PUT_LINE('----------------------------------------');
    END LOOP;
    
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
  END budget_adherence_tracking;

  -- =====================================================
  -- REPORT 3: Savings Goal Progress
  -- =====================================================
  PROCEDURE savings_goal_progress(p_user_id VARCHAR2) IS
    CURSOR savings_cursor IS
      SELECT 
        goal_name,
        target_amount,
        current_amount,
        target_amount - current_amount as remaining_amount,
        ROUND((current_amount / target_amount) * 100, 2) as progress_percentage,
        CASE 
          WHEN current_amount >= target_amount THEN 'GOAL ACHIEVED!'
          WHEN current_amount >= (target_amount * 0.75) THEN 'ALMOST THERE'
          WHEN current_amount >= (target_amount * 0.5) THEN 'GOOD PROGRESS'
          ELSE 'KEEP GOING'
        END as status
      FROM savings
      WHERE user_id = p_user_id 
        AND is_deleted = 0
      ORDER BY progress_percentage DESC;
  BEGIN
    DBMS_OUTPUT.PUT_LINE('   SAVINGS GOAL PROGRESS');
    DBMS_OUTPUT.PUT_LINE('-----------------------------------');
    DBMS_OUTPUT.PUT_LINE('');
    
    FOR rec IN savings_cursor LOOP
      DBMS_OUTPUT.PUT_LINE('Goal: ' || rec.goal_name);
      DBMS_OUTPUT.PUT_LINE('  Target: $' || TO_CHAR(rec.target_amount, '999,999.99'));
      DBMS_OUTPUT.PUT_LINE('  Current: $' || TO_CHAR(rec.current_amount, '999,999.99'));
      DBMS_OUTPUT.PUT_LINE('  Remaining: $' || TO_CHAR(rec.remaining_amount, '999,999.99'));
      DBMS_OUTPUT.PUT_LINE('  Progress: ' || rec.progress_percentage || '%');
      DBMS_OUTPUT.PUT_LINE('  Status: ' || rec.status);
      DBMS_OUTPUT.PUT_LINE('----------------------------------------');
    END LOOP;
    
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
  END savings_goal_progress;

  -- =====================================================
  -- REPORT 4: Category-wise Expense Distribution
  -- =====================================================
  PROCEDURE category_expense_distribution(p_user_id VARCHAR2) IS
    v_total_expenses NUMBER;
    
    CURSOR category_cursor IS
      SELECT 
        category,
        SUM(amount) as category_total,
        COUNT(*) as transaction_count,
        AVG(amount) as avg_amount,
        ROUND((SUM(amount) / v_total_expenses) * 100, 2) as percentage
      FROM expenses
      WHERE user_id = p_user_id 
        AND is_deleted = 0
      GROUP BY category
      ORDER BY category_total DESC;
  BEGIN
    -- Calculate total expenses first
    SELECT NVL(SUM(amount), 0) 
    INTO v_total_expenses
    FROM expenses
    WHERE user_id = p_user_id AND is_deleted = 0;
    
    DBMS_OUTPUT.PUT_LINE('   CATEGORY-WISE EXPENSE DISTRIBUTION');
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('Total Expenses: $' || TO_CHAR(v_total_expenses, '999,999.99'));
    DBMS_OUTPUT.PUT_LINE('');
    
    FOR rec IN category_cursor LOOP
      DBMS_OUTPUT.PUT_LINE('Category: ' || rec.category);
      DBMS_OUTPUT.PUT_LINE('  Total: $' || TO_CHAR(rec.category_total, '999,999.99'));
      DBMS_OUTPUT.PUT_LINE('  Transactions: ' || rec.transaction_count);
      DBMS_OUTPUT.PUT_LINE('  Average: $' || TO_CHAR(rec.avg_amount, '999,999.99'));
      DBMS_OUTPUT.PUT_LINE('  Percentage: ' || rec.percentage || '% of total');
      DBMS_OUTPUT.PUT_LINE('----------------------------------------');
    END LOOP;
    
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
  END category_expense_distribution;

  -- =====================================================
  -- REPORT 5: Forecasted Savings Trends
  -- =====================================================
  PROCEDURE forecasted_savings_trends(p_user_id VARCHAR2) IS
    v_monthly_avg_expense NUMBER;
    v_monthly_avg_income NUMBER := 0; 
    
    CURSOR forecast_cursor IS
      SELECT 
        s.goal_name,
        s.target_amount,
        s.current_amount,
        s.target_amount - s.current_amount as remaining,
        CASE 
          WHEN v_monthly_avg_expense > 0 THEN
            ROUND((s.target_amount - s.current_amount) / v_monthly_avg_expense, 1)
          ELSE NULL
        END as estimated_months_to_goal,
        ROUND(s.current_amount / NULLIF(s.target_amount, 0) * 100, 2) as completion_percentage
      FROM savings s
      WHERE s.user_id = p_user_id 
        AND s.is_deleted = 0
      ORDER BY completion_percentage DESC;
  BEGIN
    -- Calculate average monthly savings (simplified: using expenses as proxy)
    SELECT AVG(monthly_total)
    INTO v_monthly_avg_expense
    FROM (
      SELECT 
        TO_CHAR(expense_date, 'YYYY-MM') as month,
        SUM(amount) as monthly_total
      FROM expenses
      WHERE user_id = p_user_id 
        AND is_deleted = 0
      GROUP BY TO_CHAR(expense_date, 'YYYY-MM')
    );
    
    DBMS_OUTPUT.PUT_LINE('   FORECASTED SAVINGS TRENDS');
    DBMS_OUTPUT.PUT_LINE('-----------------------------------');
    DBMS_OUTPUT.PUT_LINE('Avg Monthly Expense: $' || TO_CHAR(NVL(v_monthly_avg_expense, 0), '999,999.99'));
    DBMS_OUTPUT.PUT_LINE('');
    
    FOR rec IN forecast_cursor LOOP
      DBMS_OUTPUT.PUT_LINE('Goal: ' || rec.goal_name);
      DBMS_OUTPUT.PUT_LINE('  Target: $' || TO_CHAR(rec.target_amount, '999,999.99'));
      DBMS_OUTPUT.PUT_LINE('  Current: $' || TO_CHAR(rec.current_amount, '999,999.99'));
      DBMS_OUTPUT.PUT_LINE('  Remaining: $' || TO_CHAR(rec.remaining, '999,999.99'));
      DBMS_OUTPUT.PUT_LINE('  Completion: ' || rec.completion_percentage || '%');
      
      IF rec.estimated_months_to_goal IS NOT NULL THEN
        DBMS_OUTPUT.PUT_LINE('  Est. Time to Goal: ' || rec.estimated_months_to_goal || ' months');
      ELSE
        DBMS_OUTPUT.PUT_LINE('  Est. Time to Goal: Cannot calculate');
      END IF;
      
      DBMS_OUTPUT.PUT_LINE('----------------------------------------');
    END LOOP;
    
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
  END forecasted_savings_trends;

END financial_reports;
/

SET SERVEROUTPUT ON;

BEGIN
  financial_reports.monthly_expenditure_analysis('user-67890');
END;
/

BEGIN
  financial_reports.savings_goal_progress('2df6bfa3-e862-4658-82e5-fb60d12a72e0');
END;
/

BEGIN
  financial_reports.category_expense_distribution('user-67890');
END;
/

BEGIN
  financial_reports.forecasted_savings_trends('user-67890');
END;
/

SELECT * FROM expenses;
SELECT * FROM budgets;
