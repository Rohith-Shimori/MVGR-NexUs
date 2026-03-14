-- ============================================
-- MVGR NexUs Database Setup
-- File: 01_extensions.sql
-- Purpose: Enable required PostgreSQL extensions
-- Run Order: 2
-- ============================================

-- UUID generation for primary keys
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Full-text search (for forum, vault search)
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Success message
SELECT '✅ Extensions enabled: uuid-ossp, pg_trgm' as status;
