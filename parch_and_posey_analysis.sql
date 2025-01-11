-- Parch & Posey Analysis SQL Queries

-- SECTION 1: Company Overview Metrics
-- Count of Enterprise Accounts
SELECT COUNT(DISTINCT id) as total_customers
FROM accounts;

-- List of All Regions
SELECT name as region
FROM region
ORDER BY region ASC;

-- Count of Sales Representatives
SELECT COUNT(*) as sales_rep_count
FROM sales_reps;

-- Marketing Channel Distribution
SELECT channel,
       COUNT(*) as event_count
FROM web_events
GROUP BY channel
ORDER BY event_count DESC;

-- SECTION 2: Product Performance Analysis
-- Product Quantities
SELECT 
    SUM(standard_qty) AS total_standard_qty,
    SUM(poster_qty) AS total_poster_qty,
    SUM(gloss_qty) AS total_gloss_qty,
    SUM(standard_qty + poster_qty + gloss_qty) AS total_quantity
FROM orders o
WHERE o.total > 0;

-- Revenue by Product
SELECT
    ROUND(SUM(standard_amt_usd), 0) AS total_standard_revenue,
    ROUND(SUM(poster_amt_usd), 0) AS total_poster_revenue,
    ROUND(SUM(gloss_amt_usd), 0) AS total_gloss_revenue,
    ROUND(SUM(standard_amt_usd + poster_amt_usd + gloss_amt_usd), 0) AS total_revenue
FROM orders o
WHERE o.total > 0;

-- Product Mix Percentages
SELECT
    ROUND(SUM(standard_qty) * 100.0 / SUM(standard_qty + poster_qty + gloss_qty), 1) AS standard_qty_pct,
    ROUND(SUM(gloss_qty) * 100.0 / SUM(standard_qty + poster_qty + gloss_qty), 1) AS gloss_qty_pct,
    ROUND(SUM(poster_qty) * 100.0 / SUM(standard_qty + poster_qty + gloss_qty), 1) AS poster_qty_pct,
    ROUND(SUM(standard_amt_usd) * 100.0 / SUM(standard_amt_usd + poster_amt_usd + gloss_amt_usd), 1) AS standard_rev_pct,
    ROUND(SUM(gloss_amt_usd) * 100.0 / SUM(standard_amt_usd + poster_amt_usd + gloss_amt_usd), 1) AS gloss_rev_pct,
    ROUND(SUM(poster_amt_usd) * 100.0 / SUM(standard_amt_usd + poster_amt_usd + gloss_amt_usd), 1) AS poster_rev_pct
FROM orders o
WHERE o.total > 0;

-- Average Unit Price per Paper Type
SELECT
    ROUND(SUM(standard_amt_usd) / NULLIF(SUM(standard_qty), 0), 0) AS avg_standard_unit_price,
    ROUND(SUM(poster_amt_usd) / NULLIF(SUM(poster_qty), 0), 0) AS avg_poster_unit_price,
    ROUND(SUM(gloss_amt_usd) / NULLIF(SUM(gloss_qty), 0), 0) AS avg_gloss_unit_price
FROM orders o
WHERE o.total > 0;

-- SECTION 3: Business Growth Analysis (2014-2016)
-- Year-over-Year Metrics
WITH yearly_metrics AS (
    SELECT '2014' as year,
        COUNT(*) as number_of_orders,
        COUNT(DISTINCT account_id) as number_of_customers,
        ROUND(SUM(total_amt_usd)) as total_revenue,
        ROUND(SUM(total_amt_usd)/COUNT(*)) as avg_order_value,
        SUM(total) as total_quantity,
        (SELECT COUNT(*) FROM web_events WHERE occurred_at >= '2014-01-01' AND occurred_at <= '2014-12-31') as web_events
    FROM orders o
    WHERE occurred_at >= '2014-01-01'
        AND occurred_at <= '2014-12-31'
        AND o.total > 0
    
    UNION
    
    SELECT '2015' as year,
        COUNT(*) as number_of_orders,
        COUNT(DISTINCT account_id) as number_of_customers,
        ROUND(SUM(total_amt_usd)) as total_revenue,
        ROUND(SUM(total_amt_usd)/COUNT(*)) as avg_order_value,
        SUM(total) as total_quantity,
        (SELECT COUNT(*) FROM web_events WHERE occurred_at >= '2015-01-01' AND occurred_at <= '2015-12-31') as web_events
    FROM orders o
    WHERE occurred_at >= '2015-01-01'
        AND occurred_at <= '2015-12-31'
        AND o.total > 0
    
    UNION
    
    SELECT '2016' as year,
        COUNT(*) as number_of_orders,
        COUNT(DISTINCT account_id) as number_of_customers,
        ROUND(SUM(total_amt_usd)) as total_revenue,
        ROUND(SUM(total_amt_usd)/COUNT(*)) as avg_order_value,
        SUM(total) as total_quantity,
        (SELECT COUNT(*) FROM web_events WHERE occurred_at >= '2016-01-01' AND occurred_at <= '2016-12-31') as web_events
    FROM orders o
    WHERE occurred_at >= '2016-01-01'
        AND occurred_at <= '2016-12-31'
        AND o.total > 0
)
SELECT * FROM yearly_metrics
ORDER BY year;

-- SECTION 4: Sales Representative Analysis
-- Sales Rep Distribution by Region
SELECT
    COALESCE(region_id, r.id) new_id,
    r.name region_name,
    COUNT(sr.id) reps_per_region,
    ROUND(100*COUNT(sr.id) / 52.0,1) reps_per_region_pct
FROM sales_reps sr
FULL JOIN region r
    ON sr.region_id = r.id
GROUP BY new_id, r.name
ORDER BY new_id;

-- Order Distribution by Region
SELECT
    region_id,
    r.name region_name,
    COUNT(o.id) num_orders,
    ROUND(100*COUNT(o.id) / 3773.0,1) orders_pct
FROM accounts a
JOIN sales_reps sr
    ON a.sales_rep_id = sr.id
JOIN orders o
    ON a.id = o.account_id
FULL JOIN region r
    ON sr.region_id = r.id
WHERE o.total > 0 
    AND o.occurred_at >= '2016-01-01'
GROUP BY region_id, r.name
ORDER BY region_id, r.name;

-- Account Distribution per Sales Rep
SELECT
    region_id, 
    name,
    ROUND(AVG(num_accounts), 1) avg_num_accounts
FROM (
    SELECT
        sales_rep_id,
        region_id,
        r.name,
        COUNT(a.id) num_accounts
    FROM accounts a
    FULL JOIN sales_reps sr
        ON a.sales_rep_id = sr.id
    FULL JOIN region r
        ON sr.region_id = r.id
    GROUP BY sales_rep_id, region_id, r.name
    ORDER BY region_id
) reps_region
WHERE num_accounts > 0
GROUP BY region_id, name
ORDER BY avg_num_accounts ASC;

-- SECTION 5: Industry Analysis and Channel Performance
-- Overall Industry-Level Analysis
SELECT
    CASE 
        WHEN a.name ILIKE ANY(ARRAY['%tech%', '%computer%', '%digital%', '%systems%', 
                                    '%intel%', '%microsoft%', '%cisco%', '%electronics%']) THEN 'Technology'
        WHEN a.name ILIKE ANY(ARRAY['%financial%', '%bank%', '%capital%', 
                                    '%insurance%', '%invest%', '%credit%']) THEN 'Finance'
        WHEN a.name ILIKE ANY(ARRAY['%health%', '%hospital%', '%medical%', 
                                    '%pharma%', '%drug%', '%care%']) THEN 'Healthcare'
        WHEN a.name ILIKE ANY(ARRAY['%energy%', '%power%', '%electric%', 
                                    '%utility%', '%oil%', '%gas%']) THEN 'Energy'
        WHEN a.name ILIKE ANY(ARRAY['%food%', '%beverage%', '%restaurant%', '%sysco%']) THEN 'Food & Beverage'
        ELSE 'Other'
    END AS industry,
    COUNT(DISTINCT a.name) AS num_companies,
    COUNT(*) AS num_orders,
    SUM(o.total) AS total_qty,
    ROUND(SUM(o.total_amt_usd), 2) AS total_order_value,
    ROUND(SUM(o.standard_qty) * 100.0 / NULLIF(SUM(o.total), 0), 1) AS overall_standard_pct,
    ROUND(SUM(o.gloss_qty) * 100.0 / NULLIF(SUM(o.total), 0), 1) AS overall_gloss_pct,
    ROUND(SUM(o.poster_qty) * 100.0 / NULLIF(SUM(o.total), 0), 1) AS overall_poster_pct
FROM accounts a
JOIN orders o ON a.id = o.account_id
WHERE o.total > 0
GROUP BY industry
ORDER BY total_order_value DESC;

-- Company-Level Analysis
SELECT
    CASE 
        WHEN a.name ILIKE ANY(ARRAY['%tech%', '%computer%', '%digital%', '%systems%', 
                                    '%intel%', '%microsoft%', '%cisco%', '%electronics%']) THEN 'Technology'
        WHEN a.name ILIKE ANY(ARRAY['%financial%', '%bank%', '%capital%', 
                                    '%insurance%', '%invest%', '%credit%']) THEN 'Finance'
        WHEN a.name ILIKE ANY(ARRAY['%health%', '%hospital%', '%medical%', 
                                    '%pharma%', '%drug%', '%care%']) THEN 'Healthcare'
        WHEN a.name ILIKE ANY(ARRAY['%energy%', '%power%', '%electric%', 
                                    '%utility%', '%oil%', '%gas%']) THEN 'Energy'
        WHEN a.name ILIKE ANY(ARRAY['%food%', '%beverage%', '%restaurant%', '%sysco%']) THEN 'Food & Beverage'
        ELSE 'Other'
    END AS industry,
    a.name AS company_name,
    COUNT(*) AS num_orders,
    SUM(o.total) AS total_qty,
    ROUND(SUM(o.total_amt_usd), 2) AS total_order_value,
    ROUND(SUM(o.standard_qty) * 100.0 / NULLIF(SUM(o.total), 0), 1) AS standard_pct,
    ROUND(SUM(o.gloss_qty) * 100.0 / NULLIF(SUM(o.total), 0), 1) AS gloss_pct,
    ROUND(SUM(o.poster_qty) * 100.0 / NULLIF(SUM(o.total), 0), 1) AS poster_pct
FROM accounts a
JOIN orders o ON a.id = o.account_id
WHERE o.total > 0
GROUP BY industry, company_name
ORDER BY industry, total_order_value DESC;

-- Channel Performance by Region
WITH region_totals AS (
    SELECT 
        r.name AS region_name,
        COUNT(*) AS total_events
    FROM web_events we
    JOIN accounts a ON we.account_id = a.id
    JOIN sales_reps sr ON a.sales_rep_id = sr.id
    JOIN region r ON sr.region_id = r.id
    GROUP BY r.name
)
SELECT
    r.name AS region_name,
    we.channel AS channel_name,
    COUNT(we.channel) AS number_used,
    ROUND(100.0 * COUNT(we.channel) / rt.total_events, 1) AS channel_pct
FROM web_events we
JOIN accounts a ON we.account_id = a.id
JOIN sales_reps sr ON a.sales_rep_id = sr.id
JOIN region r ON sr.region_id = r.id
JOIN region_totals rt ON r.name = rt.region_name
GROUP BY we.channel, r.name, rt.total_events
ORDER BY region_name, number_used DESC;
