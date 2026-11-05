-- Kart Direct Courier
-- =========================================================
-- PHASE 1: DATABASE IDENTIFICATION AND SETUP
-- Report reference: Section 1 – Case Study
-- Purpose: Identify the project and confirm the PostgreSQL
-- environment in which the database work is being performed.
-- =========================================================

SELECT
    'Kart Direct Courier' AS company_name,
    CURRENT_DATE AS setup_date,
    version() AS postgresql_version;
-- Return the case study name, current date, and PostgreSQL version

-- =========================================================
-- PHASE 2: TABLE CREATION AND RELATIONAL SCHEMA
-- Report reference: Section 2 – Relational Schema
-- Purpose: Create the ten related tables and define their
-- attributes, primary keys, foreign keys and constraints.
-- =========================================================

-- TABLE 1: CUSTOMERS
-- Stores customer identity and contact information.

CREATE TABLE customers (
    customer_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name VARCHAR(60) NOT NULL,
    last_name VARCHAR(60) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    phone VARCHAR(20),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- TABLE 2: CUSTOMER_ADDRESSES
-- Stores delivery addresses linked to individual customers.

CREATE TABLE customer_addresses (
    address_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id INTEGER NOT NULL
        REFERENCES customers(customer_id),
    address_line VARCHAR(200) NOT NULL,
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100) NOT NULL,
    postal_code VARCHAR(20),
    is_default BOOLEAN NOT NULL DEFAULT FALSE
);


-- TABLE 3: CATEGORIES
-- Stores product categories to avoid repeating category names across multiple product records.

CREATE TABLE categories (
    category_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL UNIQUE
);

-- TABLE 4: PRODUCTS
-- Stores product descriptions, prices, stock and category links.

CREATE TABLE products (
    product_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    category_id INTEGER NOT NULL
        REFERENCES categories(category_id),
    product_name VARCHAR(150) NOT NULL,
    description TEXT,
    unit_price NUMERIC(12, 2) NOT NULL
        CHECK (unit_price >= 0),
    stock_quantity INTEGER NOT NULL DEFAULT 0
        CHECK (stock_quantity >= 0),
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

-- TABLE 5: ORDERS
-- Stores customer orders and their current processing status.

CREATE TABLE orders (
    order_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id INTEGER NOT NULL
        REFERENCES customers(customer_id),
    order_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    order_status VARCHAR(20) NOT NULL DEFAULT 'Pending'
        CHECK (order_status IN (
            'Pending', 'Confirmed', 'Processing',
            'Shipped', 'Delivered', 'Cancelled'
        ))
);

-- TABLE 6: ORDER_ITEMS
-- Stores the products and quantities belonging to each order.

CREATE TABLE order_items (
    order_item_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id INTEGER NOT NULL
        REFERENCES orders(order_id),
    product_id INTEGER NOT NULL
        REFERENCES products(product_id),
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(12, 2) NOT NULL
        CHECK (unit_price >= 0),
    UNIQUE (order_id, product_id)
);

-- TABLE 7: PAYMENTS
-- Stores payment amounts, methods, statuses and references.

CREATE TABLE payments (
    payment_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id INTEGER NOT NULL
        REFERENCES orders(order_id),
    amount NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
    payment_method VARCHAR(30) NOT NULL
        CHECK (payment_method IN (
            'Card', 'Bank Transfer', 'USSD', 'Cash'
        )),
    payment_status VARCHAR(20) NOT NULL DEFAULT 'Pending'
        CHECK (payment_status IN (
            'Pending', 'Successful', 'Failed', 'Refunded'
        )),
    transaction_reference VARCHAR(100) UNIQUE,
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- TABLE 8: COURIERS
-- Stores courier identity, contact details and active status.

CREATE TABLE couriers (
    courier_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name VARCHAR(60) NOT NULL,
    last_name VARCHAR(60) NOT NULL,
    phone VARCHAR(20) NOT NULL UNIQUE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

-- TABLE 9: DELIVERIES
-- Stores delivery assignments, destinations, tracking details and delivery progress.

CREATE TABLE deliveries (
    delivery_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id INTEGER NOT NULL UNIQUE
        REFERENCES orders(order_id),
    address_id INTEGER NOT NULL
        REFERENCES customer_addresses(address_id),
    courier_id INTEGER
        REFERENCES couriers(courier_id),
    delivery_status VARCHAR(20) NOT NULL DEFAULT 'Pending'
        CHECK (delivery_status IN (
            'Pending', 'Assigned', 'In Transit',
            'Delivered', 'Failed', 'Returned'
        )),
    tracking_number VARCHAR(100) NOT NULL UNIQUE,
    dispatched_at TIMESTAMP,
    delivered_at TIMESTAMP
);

-- TABLE 10: DELIVERY_STATUS_HISTORY
-- Records individual delivery-status events over time.

CREATE TABLE delivery_status_history (
    history_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    delivery_id INTEGER NOT NULL
        REFERENCES deliveries(delivery_id),
    status VARCHAR(20) NOT NULL
        CHECK (status IN (
            'Pending', 'Assigned', 'In Transit',
            'Delivered', 'Failed', 'Returned'
        )),
    status_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    notes TEXT
);

-- =========================================================
-- PHASE 3: DATABASE AND TABLE VERIFICATION
-- Report reference: Section 6.1 – Database and Table Creation
-- Purpose: Confirm the connected database and list its
-- user-created tables in the public schema.
-- =========================================================

SELECT
    current_database() AS connected_database,
    table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE'
ORDER BY table_name;


-- =========================================================
-- PHASE 4: SAMPLE DATA INSERTION
-- Report reference: Section 6.2 – Sample Data Verification
-- Purpose: Populate all ten tables with test records.
-- BEGIN and COMMIT group the insertions into one transaction.
-- =========================================================

BEGIN;

-- 1. Customers
INSERT INTO customers (first_name, last_name, email, phone)
VALUES
('Ada', 'Okafor', 'ada.okafor@example.com', '08030000001'),
('Chidi', 'Bello', 'chidi.bello@example.com', '08030000002'),
('Amara', 'Eze', 'amara.eze@example.com', '08030000003'),
('Tunde', 'Adebayo', 'tunde.adebayo@example.com', '08030000004'),
('Zainab', 'Musa', 'zainab.musa@example.com', '08030000005');

-- 2. Customer addresses
INSERT INTO customer_addresses
(customer_id, address_line, city, state, postal_code, is_default)
SELECT customer_id, '12 Garden Avenue', 'Port Harcourt',
       'Rivers', '500001', TRUE
FROM customers WHERE email = 'ada.okafor@example.com'
UNION ALL
SELECT customer_id, '8 Unity Road', 'Lagos',
       'Lagos', '100001', TRUE
FROM customers WHERE email = 'chidi.bello@example.com'
UNION ALL
SELECT customer_id, '21 Independence Layout', 'Enugu',
       'Enugu', '400001', TRUE
FROM customers WHERE email = 'amara.eze@example.com'
UNION ALL
SELECT customer_id, '5 Ring Road', 'Ibadan',
       'Oyo', '200001', TRUE
FROM customers WHERE email = 'tunde.adebayo@example.com'
UNION ALL
SELECT customer_id, '14 Ahmadu Bello Way', 'Abuja',
       'FCT', '900001', TRUE
FROM customers WHERE email = 'zainab.musa@example.com';

-- 3. Product categories
INSERT INTO categories (category_name)
VALUES
('Electronics'),
('Fashion'),
('Home and Living');

-- 4. Products
INSERT INTO products
(category_id, product_name, description, unit_price, stock_quantity)
SELECT category_id, 'Wireless Headphones',
       'Bluetooth headphones', 45000.00, 25
FROM categories WHERE category_name = 'Electronics'
UNION ALL
SELECT category_id, 'Smart Watch',
       'Digital smart watch', 65000.00, 18
FROM categories WHERE category_name = 'Electronics'
UNION ALL
SELECT category_id, 'Running Shoes',
       'Casual running shoes', 38000.00, 30
FROM categories WHERE category_name = 'Fashion'
UNION ALL
SELECT category_id, 'Travel Backpack',
       'Everyday travel backpack', 22000.00, 40
FROM categories WHERE category_name = 'Fashion'
UNION ALL
SELECT category_id, 'Table Lamp',
       'LED bedside lamp', 18000.00, 15
FROM categories WHERE category_name = 'Home and Living';

-- 5. Couriers
INSERT INTO couriers (first_name, last_name, phone)
VALUES
('Emeka', 'Nwosu', '08040000001'),
('Fatima', 'Yusuf', '08040000002'),
('Samuel', 'James', '08040000003');

-- 6. Orders
INSERT INTO orders (customer_id, order_status)
SELECT customer_id, 'Delivered'
FROM customers WHERE email = 'ada.okafor@example.com'
UNION ALL
SELECT customer_id, 'Shipped'
FROM customers WHERE email = 'chidi.bello@example.com'
UNION ALL
SELECT customer_id, 'Processing'
FROM customers WHERE email = 'amara.eze@example.com'
UNION ALL
SELECT customer_id, 'Confirmed'
FROM customers WHERE email = 'tunde.adebayo@example.com'
UNION ALL
SELECT customer_id, 'Pending'
FROM customers WHERE email = 'zainab.musa@example.com';

-- 7. Order items
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT o.order_id, p.product_id, 1, p.unit_price
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
JOIN products p ON p.product_name = 'Wireless Headphones'
WHERE c.email = 'ada.okafor@example.com'
UNION ALL
SELECT o.order_id, p.product_id, 1, p.unit_price
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
JOIN products p ON p.product_name = 'Smart Watch'
WHERE c.email = 'chidi.bello@example.com'
UNION ALL
SELECT o.order_id, p.product_id, 2, p.unit_price
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
JOIN products p ON p.product_name = 'Running Shoes'
WHERE c.email = 'amara.eze@example.com'
UNION ALL
SELECT o.order_id, p.product_id, 1, p.unit_price
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
JOIN products p ON p.product_name = 'Travel Backpack'
WHERE c.email = 'tunde.adebayo@example.com'
UNION ALL
SELECT o.order_id, p.product_id, 1, p.unit_price
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
JOIN products p ON p.product_name = 'Table Lamp'
WHERE c.email = 'zainab.musa@example.com';

-- 8. Payments
INSERT INTO payments
(order_id, amount, payment_method, payment_status, transaction_reference)
SELECT o.order_id, 45000.00, 'Card', 'Successful', 'KDC-PAY-001'
FROM orders o JOIN customers c ON c.customer_id = o.customer_id
WHERE c.email = 'ada.okafor@example.com'
UNION ALL
SELECT o.order_id, 65000.00, 'Bank Transfer', 'Successful', 'KDC-PAY-002'
FROM orders o JOIN customers c ON c.customer_id = o.customer_id
WHERE c.email = 'chidi.bello@example.com'
UNION ALL
SELECT o.order_id, 76000.00, 'USSD', 'Successful', 'KDC-PAY-003'
FROM orders o JOIN customers c ON c.customer_id = o.customer_id
WHERE c.email = 'amara.eze@example.com'
UNION ALL
SELECT o.order_id, 22000.00, 'Card', 'Pending', 'KDC-PAY-004'
FROM orders o JOIN customers c ON c.customer_id = o.customer_id
WHERE c.email = 'tunde.adebayo@example.com'
UNION ALL
SELECT o.order_id, 18000.00, 'Bank Transfer', 'Pending', 'KDC-PAY-005'
FROM orders o JOIN customers c ON c.customer_id = o.customer_id
WHERE c.email = 'zainab.musa@example.com';

-- 9. Deliveries
INSERT INTO deliveries
(order_id, address_id, courier_id, delivery_status, tracking_number,
 dispatched_at, delivered_at)
SELECT o.order_id, a.address_id, cr.courier_id, 'Delivered',
       'KDC-TRK-001', CURRENT_TIMESTAMP - INTERVAL '3 days',
       CURRENT_TIMESTAMP - INTERVAL '2 days'
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
JOIN customer_addresses a ON a.customer_id = c.customer_id
JOIN couriers cr ON cr.phone = '08040000001'
WHERE c.email = 'ada.okafor@example.com'
UNION ALL
SELECT o.order_id, a.address_id, cr.courier_id, 'In Transit',
       'KDC-TRK-002', CURRENT_TIMESTAMP - INTERVAL '1 day', NULL
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
JOIN customer_addresses a ON a.customer_id = c.customer_id
JOIN couriers cr ON cr.phone = '08040000002'
WHERE c.email = 'chidi.bello@example.com';

-- 10. Delivery status history
INSERT INTO delivery_status_history (delivery_id, status, notes)
SELECT delivery_id, 'Assigned', 'Courier assigned to the order'
FROM deliveries WHERE tracking_number = 'KDC-TRK-001'
UNION ALL
SELECT delivery_id, 'In Transit', 'Parcel dispatched for delivery'
FROM deliveries WHERE tracking_number = 'KDC-TRK-001'
UNION ALL
SELECT delivery_id, 'Delivered', 'Parcel delivered successfully'
FROM deliveries WHERE tracking_number = 'KDC-TRK-001'
UNION ALL
SELECT delivery_id, 'Assigned', 'Courier assigned to the order'
FROM deliveries WHERE tracking_number = 'KDC-TRK-002'
UNION ALL
SELECT delivery_id, 'In Transit', 'Parcel is on its way'
FROM deliveries WHERE tracking_number = 'KDC-TRK-002';

COMMIT;

-- =========================================================
-- PHASE 5: RECORD COUNT VERIFICATION
-- Report reference: Section 6.2 – Sample Data Verification
-- Purpose: Count the records in each of the ten tables
-- to verify the sample data insertion.
-- =========================================================

SELECT 'customers' AS table_name, COUNT(*) AS records FROM customers
UNION ALL SELECT 'customer_addresses', COUNT(*) FROM customer_addresses
UNION ALL SELECT 'categories', COUNT(*) FROM categories
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'orders', COUNT(*) FROM orders
UNION ALL SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL SELECT 'payments', COUNT(*) FROM payments
UNION ALL SELECT 'couriers', COUNT(*) FROM couriers
UNION ALL SELECT 'deliveries', COUNT(*) FROM deliveries
UNION ALL SELECT 'delivery_status_history', COUNT(*) FROM delivery_status_history
ORDER BY table_name;

-- =========================================================
-- PHASE 6: RELATIONAL JOIN QUERY
-- Report reference: Section 6.3 – Relational JOIN Query
-- Purpose: Retrieve customer, order, product and payment
-- information by joining related tables.
-- =========================================================

SELECT
    c.first_name || ' ' || c.last_name AS customer_name,
    o.order_id,
    p.product_name,
    oi.quantity,
    oi.unit_price,
    oi.quantity * oi.unit_price AS item_total,
    pay.payment_status
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
JOIN payments pay
    ON o.order_id = pay.order_id
ORDER BY o.order_id;

-- =========================================================
-- ADDITIONAL VERIFICATION: DELIVERY ORDER CONSTRAINTS
-- Report reference: Section 4 – Keys and Constraints
-- Purpose: Check the constraints defined on deliveries.order_id.
-- =========================================================

SELECT
    tc.constraint_type,
    kcu.column_name,
    tc.constraint_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name
   AND tc.table_schema = kcu.table_schema
   AND tc.table_name = kcu.table_name
WHERE tc.table_schema = 'public'
  AND tc.table_name = 'deliveries'
  AND kcu.column_name = 'order_id'
ORDER BY tc.constraint_type;









-- =========================================================
-- PORTFOLIO 2: QUERY PROCESSING AND OPTIMISATION
-- Purpose: Retrieve order information, analyse query
-- execution plans and investigate indexing in PostgreSQL.
-- =========================================================

-- PHASE 1: BASIC ORDER RETRIEVAL
-- Purpose: Retrieve all orders and display the newest orders first.

SELECT
    order_id,
    order_date,
    order_status,
    customer_id
FROM orders
ORDER BY order_date DESC;

-- PHASE 2: ORDER TOTAL CALCULATION USING JOINS
-- Purpose: Calculate the total value of each order and
-- identify the customer who placed it.
-- JOIN connects related records across the three tables.
-- SUM calculates the total value of the items in each order.
-- GROUP BY groups the records belonging to each order.
-- ORDER BY ranks orders from the highest total to the lowest.

SELECT
    o.order_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    SUM(oi.quantity * oi.unit_price) AS order_total
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY
    o.order_id,
    c.first_name,
    c.last_name
ORDER BY order_total DESC;

-- PHASE 3: QUERY EXECUTION PLAN ANALYSIS
-- Purpose: Examine how PostgreSQL executes the order-total query.
-- EXPLAIN ANALYZE executes the query and reports the actual
-- execution plan and timing information.

EXPLAIN ANALYZE
SELECT
    o.order_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    SUM(oi.quantity * oi.unit_price) AS order_total
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY
    o.order_id,
    c.first_name,
    c.last_name
ORDER BY order_total DESC;

-- PHASE 4: INDEX CREATION
-- Purpose: Create an index on the order_date column.
-- The index may help PostgreSQL retrieve orders by date
-- more efficiently as the table grows.

CREATE INDEX idx_orders_order_date
ON orders (order_date);

-- PHASE 5: QUERY PERFORMANCE TEST WITH INDEX AVAILABLE
-- Purpose: Examine the execution plan for retrieving orders
-- from a specified date onwards while the date index exists.
-- EXPLAIN ANALYZE shows the actual execution plan and timing.
-- PostgreSQL may still choose a sequential scan for a small table.

EXPLAIN ANALYZE
SELECT
    order_id,
    order_date,
    order_status,
    customer_id
FROM orders
WHERE order_date >= TIMESTAMP '2026-10-01 00:00:00'
ORDER BY order_date DESC;

-- PHASE 6: BASELINE PERFORMANCE TEST WITHOUT THE INDEX
-- Purpose: Observe how PostgreSQL executes the date-filtered
-- query when the order_date index is absent.
-- Dropping the index allows a comparison with the indexed test.
-- EXPLAIN ANALYZE reports the actual execution plan and timing.

DROP INDEX IF EXISTS idx_orders_order_date;

EXPLAIN ANALYZE
SELECT
    order_id,
    order_date,
    order_status,
    customer_id
FROM orders
WHERE order_date >= TIMESTAMP '2026-10-01 00:00:00'
ORDER BY order_date DESC;

-- PHASE 7: INDEX VERIFICATION
-- Purpose: Inspect the indexes defined on the orders table.
-- The PostgreSQL system view pg_indexes provides index names
-- and their SQL definitions.

SELECT
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename = 'orders';

-- PHASE 8: INDEX RECREATION AND FINAL PERFORMANCE TEST
-- Purpose: Ensure the date index exists and inspect the
-- execution plan for the date-filtered order retrieval query.
-- IF NOT EXISTS prevents an error if the index already exists.
  
CREATE INDEX IF NOT EXISTS idx_orders_order_date
ON orders (order_date);

-- FINAL TEST: EXAMINE QUERY EXECUTION WITH THE INDEX AVAILABLE

EXPLAIN ANALYZE
SELECT
    order_id,
    order_date,
    order_status,
    customer_id
FROM orders
WHERE order_date >= TIMESTAMP '2026-10-01 00:00:00'
ORDER BY order_date DESC;




-- =========================================================
-- PORTFOLIO 3: TRANSACTIONS AND CONCURRENCY
-- PHASE 1: ROLLBACK TEST
-- Purpose: Demonstrate how uncommitted changes can be undone.
-- =========================================================

BEGIN;

UPDATE orders
SET order_status = 'Confirmed'
WHERE order_id = 5;

SELECT order_id, order_status
FROM orders
WHERE order_id = 5;

ROLLBACK;

SELECT order_id, order_status-- =========================================================
-- PHASE 2: COMMIT TEST
-- Purpose: Demonstrate how COMMIT saves a transaction.
-- =========================================================

BEGIN;

-- Change Order 5 status from Pending to Confirmed.
UPDATE orders
SET order_status = 'Confirmed'
WHERE order_id = 5;

-- Verify the change before committing.
SELECT order_id, order_status
FROM orders
WHERE order_id = 5;


COMMIT;

-- Verify the saved status after committing.
SELECT order_id, order_status
FROM orders
WHERE order_id = 5;
FROM orders
WHERE order_id = 5;

-- =========================================================
-- PHASE 2: COMMIT TEST
-- Purpose: Demonstrate how COMMIT saves a transaction.
-- =========================================================

BEGIN;

UPDATE orders
SET order_status = 'Confirmed'
WHERE order_id = 5;

SELECT order_id, order_status
FROM orders
WHERE order_id = 5;

COMMIT;

SELECT order_id, order_status
FROM orders
WHERE order_id = 5;
