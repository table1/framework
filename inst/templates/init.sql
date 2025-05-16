CREATE TABLE results (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT UNIQUE,
  type TEXT,
  public BOOLEAN,
  blind BOOLEAN,
  comment TEXT,
  hash TEXT,
  last_read_at DATETIME,
  created_at DATETIME,
  updated_at DATETIME,
  deleted_at DATETIME
);

CREATE TABLE data (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT UNIQUE,
  path TEXT,
  type TEXT,
  delimiter TEXT,
  locked BOOLEAN,
  encrypted BOOLEAN,
  hash TEXT,
  last_read_at DATETIME,
  created_at DATETIME,
  updated_at DATETIME,
  deleted_at DATETIME
);

CREATE TABLE cache (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT UNIQUE,
  hash TEXT,
  last_read_at DATETIME,
  created_at DATETIME,
  updated_at DATETIME,
  deleted_at DATETIME
);

CREATE TABLE connections (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT UNIQUE,
  driver TEXT,
  host TEXT,
  port INTEGER,
  database TEXT,
  schema TEXT,
  user TEXT,
  password TEXT,
  last_used_at DATETIME,
  created_at DATETIME,
  updated_at DATETIME,
  deleted_at DATETIME
); 