-- ============================================
-- MVGR NexUs - CORRECTED COMPLETE SCHEMA
-- Run this to create a clean database that matches the app models
-- Date: 2024-01-09
-- ============================================

-- ============================================
-- STEP 1: DROP EXISTING (Clean Slate)
-- ============================================
DROP TABLE IF EXISTS public.forum_votes CASCADE;
DROP TABLE IF EXISTS public.forum_answers CASCADE;
DROP TABLE IF EXISTS public.forum_questions CASCADE;
DROP TABLE IF EXISTS public.forum_comments CASCADE;
DROP TABLE IF EXISTS public.forum_posts CASCADE;
DROP TABLE IF EXISTS public.reports CASCADE;
DROP TABLE IF EXISTS public.vault_items CASCADE;
DROP TABLE IF EXISTS public.announcements CASCADE;
DROP TABLE IF EXISTS public.event_rsvps CASCADE;
DROP TABLE IF EXISTS public.events CASCADE;
DROP TABLE IF EXISTS public.club_posts CASCADE;
DROP TABLE IF EXISTS public.club_join_requests CASCADE;
DROP TABLE IF EXISTS public.club_requests CASCADE;
DROP TABLE IF EXISTS public.club_members CASCADE;
DROP TABLE IF EXISTS public.clubs CASCADE;
DROP TABLE IF EXISTS public.users CASCADE;

-- ============================================
-- STEP 2: ENABLE EXTENSIONS
-- ============================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- STEP 3: USERS TABLE
-- ============================================
CREATE TABLE public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL DEFAULT 'User',
    roll_number TEXT DEFAULT '',
    department TEXT DEFAULT '',
    year INTEGER DEFAULT 1,
    role TEXT NOT NULL DEFAULT 'student' CHECK (role IN ('student', 'clubAdmin', 'council', 'faculty')),
    club_ids TEXT[] DEFAULT '{}',
    interests TEXT[] DEFAULT '{}',
    skills TEXT[] DEFAULT '{}',
    profile_photo_url TEXT,
    bio TEXT,
    phone_number TEXT,
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- STEP 4: CLUBS TABLE (with arrays for compatibility)
-- ============================================
CREATE TABLE public.clubs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT DEFAULT '',
    category TEXT NOT NULL DEFAULT 'other' CHECK (category IN ('technical', 'cultural', 'sports', 'social', 'academic', 'other')),
    -- Array columns for app compatibility
    admin_ids TEXT[] DEFAULT '{}',
    member_ids TEXT[] DEFAULT '{}',
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

-- ============================================
-- STEP 5: CLUB_MEMBERS (Junction Table)
-- ============================================
CREATE TABLE public.club_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    club_id UUID NOT NULL REFERENCES public.clubs(id) ON DELETE CASCADE,
    user_name TEXT NOT NULL DEFAULT '',
    role TEXT NOT NULL DEFAULT 'member' CHECK (role IN ('member', 'admin', 'owner')),
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, club_id)
);

-- ============================================
-- STEP 6: CLUB_REQUESTS (Join Requests)
-- ============================================
CREATE TABLE public.club_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    club_id UUID NOT NULL REFERENCES public.clubs(id) ON DELETE CASCADE,
    club_name TEXT NOT NULL DEFAULT '',
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    user_name TEXT NOT NULL DEFAULT '',
    note TEXT,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create alias view for backwards compatibility
CREATE VIEW public.club_join_requests AS SELECT * FROM public.club_requests;

-- ============================================
-- STEP 7: CLUB_POSTS
-- ============================================
CREATE TABLE public.club_posts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    club_id UUID NOT NULL REFERENCES public.clubs(id) ON DELETE CASCADE,
    author_id UUID NOT NULL REFERENCES auth.users(id),
    author_name TEXT NOT NULL DEFAULT '',
    title TEXT NOT NULL,
    content TEXT,
    image_url TEXT,
    post_type TEXT NOT NULL DEFAULT 'general' CHECK (post_type IN ('announcement', 'event', 'recruitment', 'general')),
    is_pinned BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- STEP 8: EVENTS TABLE (with all needed columns)
-- ============================================
CREATE TABLE public.events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    description TEXT DEFAULT '',
    club_id UUID REFERENCES public.clubs(id) ON DELETE SET NULL,
    club_name TEXT,
    author_id UUID NOT NULL REFERENCES auth.users(id),
    author_name TEXT NOT NULL DEFAULT '',
    event_date TIMESTAMPTZ NOT NULL,
    end_date TIMESTAMPTZ,
    venue TEXT NOT NULL DEFAULT '',
    venue_details TEXT,
    max_participants INTEGER,
    -- Array columns for app compatibility
    rsvp_ids TEXT[] DEFAULT '{}',
    interested_ids TEXT[] DEFAULT '{}',
    category TEXT NOT NULL DEFAULT 'other' CHECK (category IN ('academic', 'cultural', 'sports', 'hackathon', 'workshop', 'seminar', 'competition', 'other')),
    image_url TEXT,
    registration_link TEXT,
    requires_registration BOOLEAN DEFAULT FALSE,
    is_online BOOLEAN DEFAULT FALSE,
    meeting_link TEXT,
    rsvp_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- STEP 9: EVENT_RSVPS (Junction Table)
-- ============================================
CREATE TABLE public.event_rsvps (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    event_id UUID NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
    user_name TEXT NOT NULL DEFAULT '',
    status TEXT NOT NULL DEFAULT 'going' CHECK (status IN ('going', 'interested', 'checked_in')),
    rsvp_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, event_id)
);

-- ============================================
-- STEP 10: ANNOUNCEMENTS
-- ============================================
CREATE TABLE public.announcements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    author_id UUID NOT NULL REFERENCES auth.users(id),
    author_name TEXT NOT NULL DEFAULT '',
    author_role TEXT NOT NULL DEFAULT 'Council',
    is_pinned BOOLEAN DEFAULT FALSE,
    is_urgent BOOLEAN DEFAULT FALSE,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- STEP 11: VAULT_ITEMS
-- ============================================
CREATE TABLE public.vault_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    description TEXT DEFAULT '',
    file_url TEXT NOT NULL,
    file_name TEXT DEFAULT '',
    file_size_bytes INTEGER DEFAULT 0,
    type TEXT NOT NULL CHECK (type IN ('notes', 'pyq', 'assignment', 'lab', 'book', 'other')),
    subject TEXT NOT NULL DEFAULT '',
    branch TEXT NOT NULL DEFAULT '',
    year INTEGER NOT NULL DEFAULT 1,
    semester INTEGER DEFAULT 1,
    tags TEXT[] DEFAULT '{}',
    uploader_id UUID NOT NULL REFERENCES auth.users(id),
    uploader_name TEXT NOT NULL DEFAULT '',
    download_count INTEGER DEFAULT 0,
    rating DECIMAL(2,1) DEFAULT 0,
    is_approved BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- STEP 12: FORUM TABLES
-- ============================================
CREATE TABLE public.forum_questions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    subject TEXT DEFAULT '',
    topic TEXT DEFAULT '',
    category TEXT NOT NULL DEFAULT 'academic',
    tags TEXT[] DEFAULT '{}',
    author_id UUID NOT NULL REFERENCES auth.users(id),
    author_name TEXT DEFAULT '',
    is_anonymous BOOLEAN DEFAULT FALSE,
    is_resolved BOOLEAN DEFAULT FALSE,
    accepted_answer_id UUID,
    view_count INTEGER DEFAULT 0,
    answer_count INTEGER DEFAULT 0,
    upvote_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE public.forum_answers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    question_id UUID NOT NULL REFERENCES public.forum_questions(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    author_id UUID NOT NULL REFERENCES auth.users(id),
    author_name TEXT NOT NULL DEFAULT '',
    is_accepted BOOLEAN DEFAULT FALSE,
    helpful_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE public.forum_votes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id),
    item_id UUID NOT NULL,
    type TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, item_id)
);

-- ============================================
-- STEP 13: REPORTS
-- ============================================
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
-- STEP 14: RPC FUNCTIONS
-- ============================================
CREATE OR REPLACE FUNCTION increment_forum_answer_count(p_question_id UUID)
RETURNS void AS $$
BEGIN
    UPDATE forum_questions SET answer_count = answer_count + 1 WHERE id = p_question_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION increment_forum_upvote(p_question_id UUID)
RETURNS void AS $$
BEGIN
    UPDATE forum_questions SET upvote_count = upvote_count + 1 WHERE id = p_question_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION decrement_forum_upvote(p_question_id UUID)
RETURNS void AS $$
BEGIN
    UPDATE forum_questions SET upvote_count = GREATEST(upvote_count - 1, 0) WHERE id = p_question_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION increment_vault_download(p_item_id UUID)
RETURNS void AS $$
BEGIN
    UPDATE vault_items SET download_count = download_count + 1 WHERE id = p_item_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- STEP 15: TRIGGERS
-- ============================================
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_clubs_updated_at BEFORE UPDATE ON public.clubs FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_events_updated_at BEFORE UPDATE ON public.events FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_club_requests_updated_at BEFORE UPDATE ON public.club_requests FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_forum_questions_updated_at BEFORE UPDATE ON public.forum_questions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- STEP 16: ROW LEVEL SECURITY
-- ============================================
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

-- Very permissive policies for demo
CREATE POLICY "Public read users" ON public.users FOR SELECT USING (true);
CREATE POLICY "Auth insert users" ON public.users FOR INSERT WITH CHECK (true);
CREATE POLICY "Auth update users" ON public.users FOR UPDATE USING (true);

CREATE POLICY "Public read clubs" ON public.clubs FOR SELECT USING (true);
CREATE POLICY "Auth insert clubs" ON public.clubs FOR INSERT WITH CHECK (true);
CREATE POLICY "Auth update clubs" ON public.clubs FOR UPDATE USING (true);
CREATE POLICY "Auth delete clubs" ON public.clubs FOR DELETE USING (true);

CREATE POLICY "Public read club_members" ON public.club_members FOR SELECT USING (true);
CREATE POLICY "Auth insert club_members" ON public.club_members FOR INSERT WITH CHECK (true);
CREATE POLICY "Auth update club_members" ON public.club_members FOR UPDATE USING (true);
CREATE POLICY "Auth delete club_members" ON public.club_members FOR DELETE USING (true);

CREATE POLICY "Public read club_requests" ON public.club_requests FOR SELECT USING (true);
CREATE POLICY "Auth insert club_requests" ON public.club_requests FOR INSERT WITH CHECK (true);
CREATE POLICY "Auth update club_requests" ON public.club_requests FOR UPDATE USING (true);
CREATE POLICY "Auth delete club_requests" ON public.club_requests FOR DELETE USING (true);

CREATE POLICY "Public read club_posts" ON public.club_posts FOR SELECT USING (true);
CREATE POLICY "Auth insert club_posts" ON public.club_posts FOR INSERT WITH CHECK (true);
CREATE POLICY "Auth update club_posts" ON public.club_posts FOR UPDATE USING (true);
CREATE POLICY "Auth delete club_posts" ON public.club_posts FOR DELETE USING (true);

CREATE POLICY "Public read events" ON public.events FOR SELECT USING (true);
CREATE POLICY "Auth insert events" ON public.events FOR INSERT WITH CHECK (true);
CREATE POLICY "Auth update events" ON public.events FOR UPDATE USING (true);
CREATE POLICY "Auth delete events" ON public.events FOR DELETE USING (true);

CREATE POLICY "Public read event_rsvps" ON public.event_rsvps FOR SELECT USING (true);
CREATE POLICY "Auth insert event_rsvps" ON public.event_rsvps FOR INSERT WITH CHECK (true);
CREATE POLICY "Auth delete event_rsvps" ON public.event_rsvps FOR DELETE USING (true);

CREATE POLICY "Public read announcements" ON public.announcements FOR SELECT USING (true);
CREATE POLICY "Auth insert announcements" ON public.announcements FOR INSERT WITH CHECK (true);
CREATE POLICY "Auth update announcements" ON public.announcements FOR UPDATE USING (true);
CREATE POLICY "Auth delete announcements" ON public.announcements FOR DELETE USING (true);

CREATE POLICY "Public read vault_items" ON public.vault_items FOR SELECT USING (true);
CREATE POLICY "Auth insert vault_items" ON public.vault_items FOR INSERT WITH CHECK (true);
CREATE POLICY "Auth update vault_items" ON public.vault_items FOR UPDATE USING (true);
CREATE POLICY "Auth delete vault_items" ON public.vault_items FOR DELETE USING (true);

CREATE POLICY "Public read forum_questions" ON public.forum_questions FOR SELECT USING (true);
CREATE POLICY "Auth insert forum_questions" ON public.forum_questions FOR INSERT WITH CHECK (true);
CREATE POLICY "Auth update forum_questions" ON public.forum_questions FOR UPDATE USING (true);

CREATE POLICY "Public read forum_answers" ON public.forum_answers FOR SELECT USING (true);
CREATE POLICY "Auth insert forum_answers" ON public.forum_answers FOR INSERT WITH CHECK (true);
CREATE POLICY "Auth update forum_answers" ON public.forum_answers FOR UPDATE USING (true);

CREATE POLICY "Public read forum_votes" ON public.forum_votes FOR SELECT USING (true);
CREATE POLICY "Auth insert forum_votes" ON public.forum_votes FOR INSERT WITH CHECK (true);
CREATE POLICY "Auth delete forum_votes" ON public.forum_votes FOR DELETE USING (true);

CREATE POLICY "Auth read reports" ON public.reports FOR SELECT USING (true);
CREATE POLICY "Auth insert reports" ON public.reports FOR INSERT WITH CHECK (true);

-- ============================================
-- STEP 17: STORAGE BUCKETS
-- ============================================
INSERT INTO storage.buckets (id, name, public) VALUES ('clubs', 'clubs', true) ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('events', 'events', true) ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('vault', 'vault', true) ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('profiles', 'profiles', true) ON CONFLICT (id) DO NOTHING;

-- Storage policies (very permissive for demo)
CREATE POLICY "Public read storage" ON storage.objects FOR SELECT USING (true);
CREATE POLICY "Auth insert storage" ON storage.objects FOR INSERT WITH CHECK (true);
CREATE POLICY "Auth update storage" ON storage.objects FOR UPDATE USING (true);
CREATE POLICY "Auth delete storage" ON storage.objects FOR DELETE USING (true);

-- ============================================
-- STEP 18: INDEXES
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
-- DONE!
-- ============================================
SELECT 'Database setup complete! All tables match app models.' as message;
