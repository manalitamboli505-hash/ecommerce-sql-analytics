PRAGMA foreign_keys = ON;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS customers;
CREATE TABLE customers (
 customer_id INTEGER PRIMARY KEY, customer_name TEXT NOT NULL, city TEXT NOT NULL,
 region TEXT NOT NULL, signup_date DATE NOT NULL,
 segment TEXT NOT NULL CHECK(segment IN ('Consumer','Corporate','Small Business'))
);
CREATE TABLE products (
 product_id INTEGER PRIMARY KEY, product_name TEXT NOT NULL UNIQUE, category TEXT NOT NULL,
 unit_price REAL NOT NULL CHECK(unit_price >= 0), unit_cost REAL NOT NULL CHECK(unit_cost >= 0)
);
CREATE TABLE orders (
 order_id INTEGER PRIMARY KEY, customer_id INTEGER NOT NULL, order_date DATE NOT NULL,
 order_status TEXT NOT NULL CHECK(order_status IN ('Delivered','Shipped','Cancelled','Returned')),
 payment_method TEXT NOT NULL, FOREIGN KEY(customer_id) REFERENCES customers(customer_id)
);
CREATE TABLE order_items (
 order_item_id INTEGER PRIMARY KEY, order_id INTEGER NOT NULL, product_id INTEGER NOT NULL,
 quantity INTEGER NOT NULL CHECK(quantity > 0), unit_price REAL NOT NULL CHECK(unit_price >= 0),
 discount_pct REAL NOT NULL DEFAULT 0 CHECK(discount_pct >= 0 AND discount_pct <= 1),
 FOREIGN KEY(order_id) REFERENCES orders(order_id), FOREIGN KEY(product_id) REFERENCES products(product_id)
);
CREATE INDEX idx_orders_date ON orders(order_date);
CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_items_order ON order_items(order_id);
CREATE INDEX idx_items_product ON order_items(product_id);
