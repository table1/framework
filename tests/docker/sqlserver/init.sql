-- SQL Server test database initialization
-- Creates test tables with various data types and patterns

-- Note: SQL Server initialization requires running via sqlcmd after startup
-- This script will be run by the helper script

CREATE DATABASE framework_test;
GO

USE framework_test;
GO

-- Test table with soft-delete pattern
CREATE TABLE users (
    id INT IDENTITY(1,1) PRIMARY KEY,
    email NVARCHAR(255) NOT NULL UNIQUE,
    name NVARCHAR(255),
    age INT,
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE(),
    deleted_at DATETIME2 NULL
);
GO

-- Test table without soft-delete
CREATE TABLE products (
    id INT IDENTITY(1,1) PRIMARY KEY,
    name NVARCHAR(255) NOT NULL,
    price DECIMAL(10, 2),
    in_stock BIT DEFAULT 1,
    created_at DATETIME2 DEFAULT GETDATE()
);
GO

-- Insert test data
INSERT INTO users (email, name, age) VALUES
    ('alice@example.com', 'Alice', 30),
    ('bob@example.com', 'Bob', 25),
    ('charlie@example.com', 'Charlie', 35);
GO

-- Soft-delete one user
UPDATE users SET deleted_at = GETDATE() WHERE email = 'charlie@example.com';
GO

INSERT INTO products (name, price, in_stock) VALUES
    ('Widget', 19.99, 1),
    ('Gadget', 29.99, 1),
    ('Doohickey', 9.99, 0);
GO
