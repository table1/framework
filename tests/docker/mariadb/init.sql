-- MariaDB test database initialization
-- Creates test tables with various data types and patterns

USE framework_test;

-- Test table with soft-delete pattern
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    name VARCHAR(255),
    age INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Test table without soft-delete
CREATE TABLE products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    price DECIMAL(10, 2),
    in_stock BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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

-- Grant privileges
GRANT ALL PRIVILEGES ON framework_test.* TO 'framework'@'%';
FLUSH PRIVILEGES;
