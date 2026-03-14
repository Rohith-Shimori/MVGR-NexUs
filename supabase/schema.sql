-- ============================================
-- MVGR NexUs - Supabase Database Schema
-- Run this in Supabase SQL Editor
-- ============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- 1. USERS TABLE (linked to Supabase Auth)
-- ============================================
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    roll_number TEXT,
    department TEXT,
    year INTEGER DEFAULT 1,
    role TEXT NOT NULL DEFAULT 'student' CHECK (role IN ('student', 'clubAdmin', 'council', 'faculty')),
    interests TEXT[] DEFAULT '{}',
    skills TEXT[] DEFAULT '{}',
    profile_photo_url TEXT,
    bio TEXT,
    phone_number TEXT,
    background_type TEXT DEFAULT 'color',
    background_color_value INTEGER,
    background_image_url TEXT,
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    last_active_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 2. CLUBS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.clubs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    category TEXT NOT NULL DEFAULT 'other' CHECK (category IN ('technical', 'cultural', 'sports', 'social', 'academic', 'other')),
    logo_url TEXT,
    cover_image_url TEXT,
    contact_email TEXT,
    instagram_handle TEXT,
    is_approved BOOLEAN DEFAULT FALSE,
    is_official BOOLEAN DEFAULT FALSE,
    created_by UUID REFERENCES public.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 3. CLUB_MEMBERS (Junction: Users <-> Clubs)
-- ============================================
CREATE TABLE IF NOT EXISTS public.club_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    club_id UUID NOT NULL REFERENCES public.clubs(id) ON DELETE CASCADE,
    role TEXT NOT NULL DEFAULT 'member' CHECK (role IN ('member', 'admin', 'owner')),
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, club_id)
);

-- ============================================
-- 4. CLUB_POSTS
-- ============================================
CREATE TABLE IF NOT EXISTS public.club_posts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    club_id UUID NOT NULL REFERENCES public.clubs(id) ON DELETE CASCADE,
    author_id UUID NOT NULL REFERENCES public.users(id),
    author_name TEXT NOT NULL,
    title TEXT NOT NULL,
    content TEXT,
    image_url TEXT,
    post_type TEXT NOT NULL DEFAULT 'general' CHECK (post_type IN ('announcement', 'event', 'recruitment', 'general')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 5. EVENTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    description TEXT,
    club_id UUID REFERENCES public.clubs(id) ON DELETE SET NULL,
    club_name TEXT,
    author_id UUID NOT NULL REFERENCES public.users(id),
    author_name TEXT NOT NULL,
    event_date TIMESTAMPTZ NOT NULL,
    end_date TIMESTAMPTZ,
    venue TEXT,
    category TEXT NOT NULL DEFAULT 'other' CHECK (category IN ('academic', 'cultural', 'sports', 'hackathon', 'workshop', 'seminar', 'competition', 'other')),
    image_url TEXT,
    registration_link TEXT,
    requires_registration BOOLEAN DEFAULT FALSE,
    is_online BOOLEAN DEFAULT FALSE,
    meeting_link TEXT,
    max_capacity INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 6. EVENT_RSVPS (Junction: Users <-> Events)
-- ============================================
CREATE TABLE IF NOT EXISTS public.event_rsvps (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    event_id UUID NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
    user_name TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'going' CHECK (status IN ('going', 'interested', 'checked_in')),
    form_responses JSONB,
    rsvp_at TIMESTAMPTZ DEFAULT NOW(),
    checked_in_at TIMESTAMPTZ,
    UNIQUE(user_id, event_id)
);

-- ============================================
-- 7. ANNOUNCEMENTS
-- ============================================
CREATE TABLE IF NOT EXISTS public.announcements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    author_id UUID NOT NULL REFERENCES public.users(id),
    author_name TEXT NOT NULL,
    source TEXT NOT NULL DEFAULT 'Council',
    is_pinned BOOLEAN DEFAULT FALSE,
    is_urgent BOOLEAN DEFAULT FALSE,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 8. VAULT_ITEMS (Study Materials)
-- ============================================
CREATE TABLE IF NOT EXISTS public.vault_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    description TEXT,
    file_url TEXT NOT NULL,
    file_name TEXT NOT NULL,
    file_size_bytes INTEGER NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('notes', 'pyq', 'assignment', 'lab', 'book', 'other')),
    subject TEXT NOT NULL,
    branch TEXT NOT NULL,
    year INTEGER NOT NULL,
    semester INTEGER NOT NULL,
    tags TEXT[] DEFAULT '{}',
    uploader_id UUID NOT NULL REFERENCES public.users(id),
    uploader_name TEXT NOT NULL,
    download_count INTEGER DEFAULT 0,
    rating DECIMAL(2,1) DEFAULT 0,
    is_approved BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 9. LOST_FOUND_ITEMS
-- ============================================
CREATE TABLE IF NOT EXISTS public.lost_found_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    description TEXT,
    category TEXT NOT NULL CHECK (category IN ('electronics', 'documents', 'accessories', 'wallet', 'keys', 'clothing', 'other')),
    location TEXT NOT NULL,
    image_urls TEXT[] DEFAULT '{}',
    user_id UUID NOT NULL REFERENCES public.users(id),
    user_name TEXT NOT NULL,
    contact_info TEXT,
    status TEXT NOT NULL DEFAULT 'lost' CHECK (status IN ('lost', 'found', 'claimed', 'expired')),
    claimer_id UUID REFERENCES public.users(id),
    claimer_name TEXT,
    item_date TIMESTAMPTZ NOT NULL,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 10. STUDY_REQUESTS (Study Buddy)
-- ============================================
CREATE TABLE IF NOT EXISTS public.study_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    user_name TEXT NOT NULL,
    subject TEXT NOT NULL,
    topic TEXT,
    description TEXT,
    preferred_mode TEXT NOT NULL CHECK (preferred_mode IN ('online', 'inPerson', 'hybrid')),
    preferred_time TEXT,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'matched', 'completed', 'cancelled')),
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 11. STUDY_CONNECTIONS (Junction)
-- ============================================
CREATE TABLE IF NOT EXISTS public.study_connections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    request_id UUID NOT NULL REFERENCES public.study_requests(id) ON DELETE CASCADE,
    connector_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    connector_name TEXT NOT NULL,
    connected_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(request_id, connector_id)
);

-- ============================================
-- 12. TEAM_REQUESTS (Play Buddy / Team Finder)
-- ============================================
CREATE TABLE IF NOT EXISTS public.team_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    creator_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    creator_name TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    category TEXT NOT NULL CHECK (category IN ('hackathon', 'sports', 'project', 'esports', 'other')),
    team_size INTEGER NOT NULL,
    deadline TIMESTAMPTZ,
    is_open BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 13. TEAM_MEMBERS (Junction)
-- ============================================
CREATE TABLE IF NOT EXISTS public.team_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    request_id UUID NOT NULL REFERENCES public.team_requests(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    user_name TEXT NOT NULL,
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(request_id, user_id)
);

-- ============================================
-- 14. MENTORS
-- ============================================
CREATE TABLE IF NOT EXISTS public.mentors (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('senior', 'alumni', 'faculty')),
    department TEXT,
    areas TEXT[] DEFAULT '{}',
    expertise TEXT[] DEFAULT '{}',
    bio TEXT,
    linkedin_url TEXT,
    max_mentees INTEGER DEFAULT 5,
    current_mentees INTEGER DEFAULT 0,
    is_available BOOLEAN DEFAULT TRUE,
    rating DECIMAL(2,1) DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 15. MEETUPS (Offline Community)
-- ============================================
CREATE TABLE IF NOT EXISTS public.meetups (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    description TEXT,
    organizer_id UUID NOT NULL REFERENCES public.users(id),
    organizer_name TEXT NOT NULL,
    category TEXT NOT NULL CHECK (category IN ('studyCircle', 'gaming', 'sports', 'creative', 'other')),
    venue TEXT NOT NULL,
    scheduled_at TIMESTAMPTZ NOT NULL,
    max_participants INTEGER,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 16. MEETUP_PARTICIPANTS (Junction)
-- ============================================
CREATE TABLE IF NOT EXISTS public.meetup_participants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    meetup_id UUID NOT NULL REFERENCES public.meetups(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(meetup_id, user_id)
);

-- ============================================
-- 17. FORUM_POSTS
-- ============================================
CREATE TABLE IF NOT EXISTS public.forum_posts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    author_id UUID NOT NULL REFERENCES public.users(id),
    author_name TEXT NOT NULL,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    subject TEXT,
    tags TEXT[] DEFAULT '{}',
    upvotes INTEGER DEFAULT 0,
    view_count INTEGER DEFAULT 0,
    is_answered BOOLEAN DEFAULT FALSE,
    is_pinned BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 18. FORUM_COMMENTS
-- ============================================
CREATE TABLE IF NOT EXISTS public.forum_comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id UUID NOT NULL REFERENCES public.forum_posts(id) ON DELETE CASCADE,
    author_id UUID NOT NULL REFERENCES public.users(id),
    author_name TEXT NOT NULL,
    content TEXT NOT NULL,
    upvotes INTEGER DEFAULT 0,
    is_accepted BOOLEAN DEFAULT FALSE,
    parent_id UUID REFERENCES public.forum_comments(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 19. REPORTS (Content Moderation)
-- ============================================
CREATE TABLE IF NOT EXISTS public.reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reporter_id UUID NOT NULL REFERENCES public.users(id),
    content_type TEXT NOT NULL,
    content_id UUID NOT NULL,
    reason TEXT NOT NULL,
    description TEXT,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'resolved', 'dismissed')),
    resolved_by UUID REFERENCES public.users(id),
    resolved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- INDEXES for Performance
-- ============================================
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON public.users(role);
CREATE INDEX IF NOT EXISTS idx_clubs_category ON public.clubs(category);
CREATE INDEX IF NOT EXISTS idx_club_members_user ON public.club_members(user_id);
CREATE INDEX IF NOT EXISTS idx_club_members_club ON public.club_members(club_id);
CREATE INDEX IF NOT EXISTS idx_events_date ON public.events(event_date);
CREATE INDEX IF NOT EXISTS idx_events_club ON public.events(club_id);
CREATE INDEX IF NOT EXISTS idx_event_rsvps_event ON public.event_rsvps(event_id);
CREATE INDEX IF NOT EXISTS idx_vault_items_branch_year ON public.vault_items(branch, year);
CREATE INDEX IF NOT EXISTS idx_forum_posts_created ON public.forum_posts(created_at DESC);

-- ============================================
-- UPDATED_AT TRIGGER
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_clubs_updated_at BEFORE UPDATE ON public.clubs FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_events_updated_at BEFORE UPDATE ON public.events FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_forum_posts_updated_at BEFORE UPDATE ON public.forum_posts FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- SUCCESS MESSAGE
-- ============================================
SELECT 'Schema created successfully! 19 tables + indexes + triggers' as message;
