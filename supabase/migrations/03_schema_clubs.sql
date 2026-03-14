-- ============================================
-- MVGR NexUs Database Setup
-- File: 03_schema_clubs.sql
-- Purpose: Clubs, members, posts, and join requests
-- Run Order: 4
-- ============================================

-- CLUBS TABLE
-- Student organizations, committees, technical clubs
CREATE TABLE public.clubs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Basic info
    name TEXT NOT NULL,
    description TEXT,
    category TEXT NOT NULL DEFAULT 'other' 
        CHECK (category IN ('technical', 'cultural', 'sports', 'social', 'academic', 'other')),
    
    -- Branding
    logo_url TEXT,
    cover_image_url TEXT,
    
    -- Contact
    contact_email TEXT,
    instagram_handle TEXT,
    
    -- Status flags
    is_approved BOOLEAN DEFAULT FALSE,  -- Needs council approval
    is_official BOOLEAN DEFAULT FALSE,  -- Official college club
    
    -- Audit
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.clubs IS 'Student clubs and organizations';

-- ============================================

-- CLUB MEMBERS (Junction Table: Users ↔ Clubs)
-- Tracks who belongs to which club and their role
CREATE TABLE public.club_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Foreign keys
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    club_id UUID NOT NULL REFERENCES public.clubs(id) ON DELETE CASCADE,
    
    -- Denormalized for performance
    user_name TEXT NOT NULL DEFAULT '',
    
    -- Role within the club
    -- member: Regular member
    -- admin: Can manage club, approve members
    -- owner: Created the club, full control
    role TEXT NOT NULL DEFAULT 'member' 
        CHECK (role IN ('member', 'admin', 'owner')),
    
    -- Timestamp
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Each user can only be in a club once
    UNIQUE(user_id, club_id)
);

COMMENT ON TABLE public.club_members IS 'Club membership junction table';

-- ============================================

-- CLUB JOIN REQUESTS
-- Pending requests to join clubs
CREATE TABLE public.club_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Foreign keys
    club_id UUID NOT NULL REFERENCES public.clubs(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Denormalized for notifications
    club_name TEXT NOT NULL DEFAULT '',
    user_name TEXT NOT NULL,
    
    -- Request details
    note TEXT,  -- "Why do you want to join?"
    status TEXT NOT NULL DEFAULT 'pending' 
        CHECK (status IN ('pending', 'approved', 'rejected')),
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.club_requests IS 'Pending club join requests';

-- ============================================

-- CLUB POSTS
-- Announcements, updates, recruitment posts by clubs
CREATE TABLE public.club_posts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Foreign keys
    club_id UUID NOT NULL REFERENCES public.clubs(id) ON DELETE CASCADE,
    author_id UUID NOT NULL REFERENCES auth.users(id),
    
    -- Denormalized
    author_name TEXT NOT NULL,
    
    -- Content
    title TEXT NOT NULL,
    content TEXT,
    image_url TEXT,
    
    -- Type of post
    post_type TEXT NOT NULL DEFAULT 'general' 
        CHECK (post_type IN ('announcement', 'event', 'recruitment', 'general')),
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.club_posts IS 'Posts made by clubs';

-- Success message
SELECT '✅ Clubs schema created: clubs, club_members, club_requests, club_posts' as status;
