-- ============================================
-- MVGR NexUs Database Setup
-- File: 02_schema_users.sql
-- Purpose: Users table (linked to Supabase Auth)
-- Run Order: 3
-- ============================================

-- USERS TABLE
-- Links to auth.users via foreign key
-- This is the "profile" table for authenticated users
CREATE TABLE public.users (
    -- Primary key matches auth.users.id
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Basic info
    email TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    roll_number TEXT,
    phone_number TEXT,
    
    -- Academic info
    department TEXT,
    year INTEGER DEFAULT 1 CHECK (year >= 1 AND year <= 5),
    
    -- Role-based access control
    -- student: Default role, can browse and join
    -- clubAdmin: Can manage their clubs
    -- council: Can moderate content and create announcements
    -- faculty: Full moderation and oversight
    role TEXT NOT NULL DEFAULT 'student' 
        CHECK (role IN ('student', 'clubAdmin', 'council', 'faculty')),
    
    -- Profile customization
    profile_photo_url TEXT,
    bio TEXT,
    interests TEXT[] DEFAULT '{}',
    skills TEXT[] DEFAULT '{}',
    
    -- Status flags
    is_verified BOOLEAN DEFAULT FALSE,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    last_active_at TIMESTAMPTZ
);

-- Add comment for documentation
COMMENT ON TABLE public.users IS 'User profiles linked to Supabase Auth';
COMMENT ON COLUMN public.users.role IS 'Role: student, clubAdmin, council, faculty';

-- Success message
SELECT '✅ Users table created' as status;
