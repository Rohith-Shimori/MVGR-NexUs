-- ============================================
-- MVGR NexUs - COMPLETE DATABASE SETUP
-- Run this in Supabase SQL Editor to reset and set up a clean database
-- Date: 2024-01-09
-- ============================================

-- ============================================
-- STEP 1: DROP EXISTING TABLES (Clean Slate)
-- ============================================
DROP TABLE IF EXISTS public.forum_votes CASCADE;
DROP TABLE IF EXISTS public.forum_answers CASCADE;
DROP TABLE IF EXISTS public.forum_questions CASCADE;
DROP TABLE IF EXISTS public.forum_comments CASCADE;
DROP TABLE IF EXISTS public.forum_posts CASCADE;
DROP TABLE IF EXISTS public.reports CASCADE;
DROP TABLE IF EXISTS public.meetup_participants CASCADE;
DROP TABLE IF EXISTS public.meetups CASCADE;
DROP TABLE IF EXISTS public.team_members CASCADE;
DROP TABLE IF EXISTS public.team_requests CASCADE;
DROP TABLE IF EXISTS public.study_connections CASCADE;
DROP TABLE IF EXISTS public.study_requests CASCADE;
DROP TABLE IF EXISTS public.lost_found_items CASCADE;
DROP TABLE IF EXISTS public.vault_items CASCADE;
DROP TABLE IF EXISTS public.announcements CASCADE;
DROP TABLE IF EXISTS public.event_rsvps CASCADE;
DROP TABLE IF EXISTS public.events CASCADE;
DROP TABLE IF EXISTS public.club_posts CASCADE;
DROP TABLE IF EXISTS public.club_requests CASCADE;
DROP TABLE IF EXISTS public.club_members CASCADE;
DROP TABLE IF EXISTS public.clubs CASCADE;
DROP TABLE IF EXISTS public.mentors CASCADE;
DROP TABLE IF EXISTS public.users CASCADE;

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- STEP 2: CORE TABLES
-- ============================================

-- USERS (linked to Supabase Auth)
CREATE TABLE public.users (
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
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- CLUBS
CREATE TABLE public.clubs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    category TEXT NOT NULL DEFAULT 'other' CHECK (category IN ('technical', 'cultural', 'sports', 'social', 'academic', 'other')),
    logo_url TEXT,
    cover_image_url TEXT,
    contact_email TEXT,
    instagram_handle TEXT,
    is_approved BOOLEAN DEFAULT TRUE,
    is_official BOOLEAN DEFAULT FALSE,
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- CLUB_MEMBERS (Junction: Users <-> Clubs)
CREATE TABLE public.club_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    club_id UUID NOT NULL REFERENCES public.clubs(id) ON DELETE CASCADE,
    user_name TEXT NOT NULL DEFAULT '',
    role TEXT NOT NULL DEFAULT 'member' CHECK (role IN ('member', 'admin', 'owner')),
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, club_id)
);

-- CLUB_REQUESTS (Join Requests)
CREATE TABLE public.club_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    club_id UUID NOT NULL REFERENCES public.clubs(id) ON DELETE CASCADE,
    club_name TEXT NOT NULL DEFAULT '',
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    user_name TEXT NOT NULL,
    note TEXT,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- CLUB_POSTS
CREATE TABLE public.club_posts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    club_id UUID NOT NULL REFERENCES public.clubs(id) ON DELETE CASCADE,
    author_id UUID NOT NULL REFERENCES auth.users(id),
    author_name TEXT NOT NULL,
    title TEXT NOT NULL,
    content TEXT,
    image_url TEXT,
    post_type TEXT NOT NULL DEFAULT 'general' CHECK (post_type IN ('announcement', 'event', 'recruitment', 'general')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- EVENTS
CREATE TABLE public.events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    description TEXT,
    club_id UUID REFERENCES public.clubs(id) ON DELETE SET NULL,
    club_name TEXT,
    author_id UUID NOT NULL REFERENCES auth.users(id),
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
    rsvp_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- EVENT_RSVPS (Junction)
CREATE TABLE public.event_rsvps (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    event_id UUID NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
    user_name TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'going' CHECK (status IN ('going', 'interested', 'checked_in')),
    rsvp_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, event_id)
);

-- ANNOUNCEMENTS
CREATE TABLE public.announcements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    author_id UUID NOT NULL REFERENCES auth.users(id),
    author_name TEXT NOT NULL,
    source TEXT NOT NULL DEFAULT 'Council',
    is_pinned BOOLEAN DEFAULT FALSE,
    is_urgent BOOLEAN DEFAULT FALSE,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- VAULT_ITEMS (Study Materials)
CREATE TABLE public.vault_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    description TEXT,
    file_url TEXT NOT NULL,
    file_name TEXT DEFAULT '',
    file_size_bytes INTEGER DEFAULT 0,
    type TEXT NOT NULL CHECK (type IN ('notes', 'pyq', 'assignment', 'lab', 'book', 'other')),
    subject TEXT NOT NULL,
    branch TEXT NOT NULL,
    year INTEGER NOT NULL,
    semester INTEGER DEFAULT 1,
    tags TEXT[] DEFAULT '{}',
    uploader_id UUID NOT NULL REFERENCES auth.users(id),
    uploader_name TEXT NOT NULL,
    download_count INTEGER DEFAULT 0,
    rating DECIMAL(2,1) DEFAULT 0,
    is_approved BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- FORUM_QUESTIONS
CREATE TABLE public.forum_questions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    subject TEXT DEFAULT '',
    topic TEXT DEFAULT '',
    category TEXT NOT NULL DEFAULT 'academic',
    tags TEXT[] DEFAULT '{}',
    author_id UUID NOT NULL REFERENCES auth.users(id),
    author_name TEXT,
    is_anonymous BOOLEAN DEFAULT FALSE,
    is_resolved BOOLEAN DEFAULT FALSE,
    accepted_answer_id UUID,
    view_count INTEGER DEFAULT 0,
    answer_count INTEGER DEFAULT 0,
    upvote_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- FORUM_ANSWERS
CREATE TABLE public.forum_answers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    question_id UUID NOT NULL REFERENCES public.forum_questions(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    author_id UUID NOT NULL REFERENCES auth.users(id),
    author_name TEXT NOT NULL,
    is_accepted BOOLEAN DEFAULT FALSE,
    helpful_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- FORUM_VOTES (Track who voted)
CREATE TABLE public.forum_votes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id),
    item_id UUID NOT NULL,
    type TEXT NOT NULL, -- 'question_upvote', 'answer_upvote'
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, item_id)
);

-- REPORTS (Content Moderation)
CREATE TABLE public.reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reporter_id UUID NOT NULL REFERENCES auth.users(id),
    content_type TEXT NOT NULL,
    content_id UUID NOT NULL,
    reason TEXT NOT NULL,
    description TEXT,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'resolved', 'dismissed')),
    resolved_by UUID REFERENCES auth.users(id),
    resolved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- STEP 3: RPC FUNCTIONS
-- ============================================

-- Increment answer count
CREATE OR REPLACE FUNCTION increment_forum_answer_count(p_question_id UUID)
RETURNS void AS $$
BEGIN
    UPDATE forum_questions SET answer_count = answer_count + 1 WHERE id = p_question_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Increment upvote
CREATE OR REPLACE FUNCTION increment_forum_upvote(p_question_id UUID)
RETURNS void AS $$
BEGIN
    UPDATE forum_questions SET upvote_count = upvote_count + 1 WHERE id = p_question_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Decrement upvote
CREATE OR REPLACE FUNCTION decrement_forum_upvote(p_question_id UUID)
RETURNS void AS $$
BEGIN
    UPDATE forum_questions SET upvote_count = GREATEST(upvote_count - 1, 0) WHERE id = p_question_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Increment download count
CREATE OR REPLACE FUNCTION increment_vault_download(p_item_id UUID)
RETURNS void AS $$
BEGIN
    UPDATE vault_items SET download_count = download_count + 1 WHERE id = p_item_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- STEP 4: TRIGGERS
-- ============================================

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_clubs_updated_at BEFORE UPDATE ON public.clubs FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_events_updated_at BEFORE UPDATE ON public.events FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_forum_questions_updated_at BEFORE UPDATE ON public.forum_questions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- STEP 5: ROW LEVEL SECURITY
-- ============================================

-- Enable RLS on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clubs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.club_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.club_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.club_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_rsvps ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vault_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.forum_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.forum_answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.forum_votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;

-- Users policies
CREATE POLICY "Users can view all users" ON public.users FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON public.users FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON public.users FOR INSERT WITH CHECK (auth.uid() = id);

-- Clubs policies
CREATE POLICY "Anyone can view clubs" ON public.clubs FOR SELECT USING (true);
CREATE POLICY "Authenticated can create clubs" ON public.clubs FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Admins can update clubs" ON public.clubs FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "Admins can delete clubs" ON public.clubs FOR DELETE USING (auth.role() = 'authenticated');

-- Club members policies
CREATE POLICY "Anyone can view club members" ON public.club_members FOR SELECT USING (true);
CREATE POLICY "Authenticated can join clubs" ON public.club_members FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Members can leave" ON public.club_members FOR DELETE USING (auth.uid() = user_id);
CREATE POLICY "Admins can update members" ON public.club_members FOR UPDATE USING (auth.role() = 'authenticated');

-- Club requests policies
CREATE POLICY "Anyone can view their requests" ON public.club_requests FOR SELECT USING (auth.uid() = user_id OR auth.role() = 'authenticated');
CREATE POLICY "Authenticated can create requests" ON public.club_requests FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Admins can update requests" ON public.club_requests FOR UPDATE USING (auth.role() = 'authenticated');
CREATE POLICY "Users can delete own requests" ON public.club_requests FOR DELETE USING (auth.uid() = user_id);

-- Club posts policies
CREATE POLICY "Anyone can view club posts" ON public.club_posts FOR SELECT USING (true);
CREATE POLICY "Members can create posts" ON public.club_posts FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Authors can update posts" ON public.club_posts FOR UPDATE USING (auth.uid() = author_id);
CREATE POLICY "Authors can delete posts" ON public.club_posts FOR DELETE USING (auth.uid() = author_id);

-- Events policies
CREATE POLICY "Anyone can view events" ON public.events FOR SELECT USING (true);
CREATE POLICY "Authenticated can create events" ON public.events FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Authors can update events" ON public.events FOR UPDATE USING (auth.uid() = author_id);
CREATE POLICY "Authors can delete events" ON public.events FOR DELETE USING (auth.uid() = author_id);

-- Event RSVPs policies
CREATE POLICY "Anyone can view RSVPs" ON public.event_rsvps FOR SELECT USING (true);
CREATE POLICY "Authenticated can RSVP" ON public.event_rsvps FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Users can cancel RSVP" ON public.event_rsvps FOR DELETE USING (auth.uid() = user_id);

-- Announcements policies
CREATE POLICY "Anyone can view announcements" ON public.announcements FOR SELECT USING (true);
CREATE POLICY "Authenticated can create announcements" ON public.announcements FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Authors can update announcements" ON public.announcements FOR UPDATE USING (auth.uid() = author_id);
CREATE POLICY "Authors can delete announcements" ON public.announcements FOR DELETE USING (auth.uid() = author_id);

-- Vault items policies
CREATE POLICY "Anyone can view approved items" ON public.vault_items FOR SELECT USING (is_approved = true);
CREATE POLICY "Authenticated can upload" ON public.vault_items FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Uploaders can update" ON public.vault_items FOR UPDATE USING (auth.uid() = uploader_id);
CREATE POLICY "Uploaders can delete" ON public.vault_items FOR DELETE USING (auth.uid() = uploader_id);

-- Forum questions policies
CREATE POLICY "Anyone can view questions" ON public.forum_questions FOR SELECT USING (true);
CREATE POLICY "Authenticated can ask" ON public.forum_questions FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Authors can update questions" ON public.forum_questions FOR UPDATE USING (auth.uid() = author_id);
CREATE POLICY "Authors can delete questions" ON public.forum_questions FOR DELETE USING (auth.uid() = author_id);

-- Forum answers policies
CREATE POLICY "Anyone can view answers" ON public.forum_answers FOR SELECT USING (true);
CREATE POLICY "Authenticated can answer" ON public.forum_answers FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Authors can update answers" ON public.forum_answers FOR UPDATE USING (auth.uid() = author_id);

-- Forum votes policies
CREATE POLICY "Anyone can view votes" ON public.forum_votes FOR SELECT USING (true);
CREATE POLICY "Authenticated can vote" ON public.forum_votes FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Users can remove vote" ON public.forum_votes FOR DELETE USING (auth.uid() = user_id);

-- Reports policies
CREATE POLICY "Users can view own reports" ON public.reports FOR SELECT USING (auth.uid() = reporter_id);
CREATE POLICY "Authenticated can report" ON public.reports FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- ============================================
-- STEP 6: STORAGE BUCKETS
-- ============================================

INSERT INTO storage.buckets (id, name, public) VALUES ('clubs', 'clubs', true) ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('events', 'events', true) ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('vault', 'vault', true) ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('profiles', 'profiles', true) ON CONFLICT (id) DO NOTHING;

-- Storage policies
CREATE POLICY "Public read clubs" ON storage.objects FOR SELECT USING (bucket_id = 'clubs');
CREATE POLICY "Auth upload clubs" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'clubs' AND auth.role() = 'authenticated');
CREATE POLICY "Public read events" ON storage.objects FOR SELECT USING (bucket_id = 'events');
CREATE POLICY "Auth upload events" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'events' AND auth.role() = 'authenticated');
CREATE POLICY "Public read vault" ON storage.objects FOR SELECT USING (bucket_id = 'vault');
CREATE POLICY "Auth upload vault" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'vault' AND auth.role() = 'authenticated');
CREATE POLICY "Public read profiles" ON storage.objects FOR SELECT USING (bucket_id = 'profiles');
CREATE POLICY "Auth upload profiles" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'profiles' AND auth.role() = 'authenticated');

-- ============================================
-- STEP 7: INDEXES
-- ============================================

CREATE INDEX IF NOT EXISTS idx_clubs_category ON public.clubs(category);
CREATE INDEX IF NOT EXISTS idx_club_members_user ON public.club_members(user_id);
CREATE INDEX IF NOT EXISTS idx_club_members_club ON public.club_members(club_id);
CREATE INDEX IF NOT EXISTS idx_events_date ON public.events(event_date);
CREATE INDEX IF NOT EXISTS idx_events_club ON public.events(club_id);
CREATE INDEX IF NOT EXISTS idx_event_rsvps_event ON public.event_rsvps(event_id);
CREATE INDEX IF NOT EXISTS idx_vault_items_branch_year ON public.vault_items(branch, year);
CREATE INDEX IF NOT EXISTS idx_forum_questions_created ON public.forum_questions(created_at DESC);

-- ============================================
-- SUCCESS!
-- ============================================
SELECT 'Database setup complete! All tables, RLS policies, RPC functions, and storage buckets created.' as message;
