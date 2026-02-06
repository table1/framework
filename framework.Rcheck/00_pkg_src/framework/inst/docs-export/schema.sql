-- Framework Documentation Export Schema
-- Designed to capture all roxygen2 output for GUI and public site

-- Core function documentation
CREATE TABLE IF NOT EXISTS functions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    title TEXT,
    description TEXT,
    details TEXT,
    usage TEXT,
    value TEXT,              -- Return value description
    note TEXT,               -- Additional notes
    source_file TEXT,        -- R source file (from roxygen comment)
    keywords TEXT,           -- Comma-separated keywords
    is_exported INTEGER DEFAULT 1,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- Function aliases (many-to-one with functions)
CREATE TABLE IF NOT EXISTS aliases (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    function_id INTEGER NOT NULL,
    alias TEXT NOT NULL,
    FOREIGN KEY (function_id) REFERENCES functions(id) ON DELETE CASCADE,
    UNIQUE(function_id, alias)
);

-- Function parameters/arguments
CREATE TABLE IF NOT EXISTS parameters (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    function_id INTEGER NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    position INTEGER,        -- Order in function signature
    FOREIGN KEY (function_id) REFERENCES functions(id) ON DELETE CASCADE
);

-- Examples (can have multiple per function)
CREATE TABLE IF NOT EXISTS examples (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    function_id INTEGER NOT NULL,
    code TEXT NOT NULL,
    is_dontrun INTEGER DEFAULT 0,  -- Wrapped in \dontrun{}
    position INTEGER,
    FOREIGN KEY (function_id) REFERENCES functions(id) ON DELETE CASCADE
);

-- See Also references
CREATE TABLE IF NOT EXISTS seealso (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    function_id INTEGER NOT NULL,
    reference TEXT NOT NULL,       -- Function name or link text
    link_type TEXT DEFAULT 'function',  -- 'function', 'url', 'package'
    url TEXT,                      -- For external links
    FOREIGN KEY (function_id) REFERENCES functions(id) ON DELETE CASCADE
);

-- Custom sections (from @section tag)
CREATE TABLE IF NOT EXISTS sections (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    function_id INTEGER NOT NULL,
    title TEXT NOT NULL,
    content TEXT,
    position INTEGER,
    FOREIGN KEY (function_id) REFERENCES functions(id) ON DELETE CASCADE
);

-- Subsections (nested under sections or details)
CREATE TABLE IF NOT EXISTS subsections (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    function_id INTEGER NOT NULL,
    section_id INTEGER,            -- NULL if under details
    title TEXT NOT NULL,
    content TEXT,
    position INTEGER,
    FOREIGN KEY (function_id) REFERENCES functions(id) ON DELETE CASCADE,
    FOREIGN KEY (section_id) REFERENCES sections(id) ON DELETE CASCADE
);

-- Full-text search virtual table (SQLite FTS5)
CREATE VIRTUAL TABLE IF NOT EXISTS functions_fts USING fts5(
    name,
    title,
    description,
    details,
    content=functions,
    content_rowid=id
);

-- Triggers to keep FTS in sync
CREATE TRIGGER IF NOT EXISTS functions_ai AFTER INSERT ON functions BEGIN
    INSERT INTO functions_fts(rowid, name, title, description, details)
    VALUES (new.id, new.name, new.title, new.description, new.details);
END;

CREATE TRIGGER IF NOT EXISTS functions_ad AFTER DELETE ON functions BEGIN
    INSERT INTO functions_fts(functions_fts, rowid, name, title, description, details)
    VALUES('delete', old.id, old.name, old.title, old.description, old.details);
END;

CREATE TRIGGER IF NOT EXISTS functions_au AFTER UPDATE ON functions BEGIN
    INSERT INTO functions_fts(functions_fts, rowid, name, title, description, details)
    VALUES('delete', old.id, old.name, old.title, old.description, old.details);
    INSERT INTO functions_fts(rowid, name, title, description, details)
    VALUES (new.id, new.name, new.title, new.description, new.details);
END;

-- Indexes for common queries
CREATE INDEX IF NOT EXISTS idx_aliases_alias ON aliases(alias);
CREATE INDEX IF NOT EXISTS idx_parameters_function ON parameters(function_id);
CREATE INDEX IF NOT EXISTS idx_examples_function ON examples(function_id);
CREATE INDEX IF NOT EXISTS idx_seealso_function ON seealso(function_id);
CREATE INDEX IF NOT EXISTS idx_functions_keywords ON functions(keywords);

-- Metadata table for export info
CREATE TABLE IF NOT EXISTS metadata (
    key TEXT PRIMARY KEY,
    value TEXT
);
