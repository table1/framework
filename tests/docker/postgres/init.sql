-- PostgreSQL test database initialization
-- Creates test tables with various data types and patterns

-- Test table with soft-delete pattern
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    name VARCHAR(255),
    age INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL
);

-- Test table without soft-delete
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    price DECIMAL(10, 2),
    in_stock BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert test data
INSERT INTO users (email, name, age) VALUES
    ('alice@example.com', 'Alice', 30),
    ('bob@example.com', 'Bob', 25),
    ('charlie@example.com', 'Charlie', 35);

-- Soft-delete one user
UPDATE users SET deleted_at = CURRENT_TIMESTAMP WHERE email = 'charlie@example.com';

INSERT INTO products (name, price, in_stock) VALUES
    ('Widget', 19.99, TRUE),
    ('Gadget', 29.99, TRUE),
    ('Doohickey', 9.99, FALSE);

-- Create a test schema for multi-schema testing
CREATE SCHEMA IF NOT EXISTS test_schema;

CREATE TABLE test_schema.items (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255)
);

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO framework;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO framework;
GRANT ALL PRIVILEGES ON SCHEMA test_schema TO framework;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA test_schema TO framework;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA test_schema TO framework;
