-- ============================================
-- MVGR NexUs - Row Level Security Policies
-- Run AFTER schema.sql in Supabase SQL Editor
-- ============================================

-- Enable RLS on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clubs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.club_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.club_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_rsvps ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vault_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lost_found_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.study_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.study_connections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.team_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.team_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mentors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meetups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meetup_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.forum_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.forum_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;

-- ============================================
-- USERS POLICIES
-- ============================================
-- Anyone can view basic user profiles
CREATE POLICY "Users are viewable by everyone" ON public.users
    FOR SELECT USING (true);

-- Users can update their own profile
CREATE POLICY "Users can update own profile" ON public.users
    FOR UPDATE USING (auth.uid() = id);

-- New users can insert their profile
CREATE POLICY "Users can insert own profile" ON public.users
    FOR INSERT WITH CHECK (auth.uid() = id);

-- ============================================
-- CLUBS POLICIES
-- ============================================
-- Approved clubs are viewable by everyone
CREATE POLICY "Approved clubs are viewable" ON public.clubs
    FOR SELECT USING (is_approved = true);

-- Council/Faculty can create clubs
CREATE POLICY "Authorized users can create clubs" ON public.clubs
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() 
            AND role IN ('council', 'faculty', 'clubAdmin')
        )
    );

-- Club admins can update their clubs
CREATE POLICY "Club admins can update clubs" ON public.clubs
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.club_members 
            WHERE club_id = clubs.id 
            AND user_id = auth.uid() 
            AND role IN ('admin', 'owner')
        )
    );

-- ============================================
-- CLUB_MEMBERS POLICIES
-- ============================================
-- Anyone can view club members
CREATE POLICY "Club members are viewable" ON public.club_members
    FOR SELECT USING (true);

-- Authenticated users can join clubs
CREATE POLICY "Users can join clubs" ON public.club_members
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can leave clubs
CREATE POLICY "Users can leave clubs" ON public.club_members
    FOR DELETE USING (auth.uid() = user_id);

-- ============================================
-- EVENTS POLICIES
-- ============================================
-- All events are viewable
CREATE POLICY "Events are viewable by everyone" ON public.events
    FOR SELECT USING (true);

-- Club admins and council can create events
CREATE POLICY "Authorized users can create events" ON public.events
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() 
            AND role IN ('council', 'faculty', 'clubAdmin')
        )
    );

-- Event authors can update their events
CREATE POLICY "Authors can update events" ON public.events
    FOR UPDATE USING (auth.uid() = author_id);

-- ============================================
-- EVENT_RSVPS POLICIES
-- ============================================
-- Event organizers can view RSVPs
CREATE POLICY "RSVPs viewable by organizers" ON public.event_rsvps
    FOR SELECT USING (
        auth.uid() = user_id OR
        EXISTS (
            SELECT 1 FROM public.events 
            WHERE id = event_rsvps.event_id 
            AND author_id = auth.uid()
        )
    );

-- Users can RSVP to events
CREATE POLICY "Users can RSVP" ON public.event_rsvps
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their RSVP
CREATE POLICY "Users can update RSVP" ON public.event_rsvps
    FOR UPDATE USING (auth.uid() = user_id);

-- Users can remove their RSVP
CREATE POLICY "Users can remove RSVP" ON public.event_rsvps
    FOR DELETE USING (auth.uid() = user_id);

-- ============================================
-- VAULT_ITEMS POLICIES
-- ============================================
-- Approved items are viewable
CREATE POLICY "Approved vault items viewable" ON public.vault_items
    FOR SELECT USING (is_approved = true);

-- Authenticated users can upload
CREATE POLICY "Users can upload vault items" ON public.vault_items
    FOR INSERT WITH CHECK (auth.uid() = uploader_id);

-- Authors can update their uploads
CREATE POLICY "Authors can update vault items" ON public.vault_items
    FOR UPDATE USING (auth.uid() = uploader_id);

-- ============================================
-- LOST_FOUND_ITEMS POLICIES
-- ============================================
-- Active items are viewable
CREATE POLICY "Active lost/found viewable" ON public.lost_found_items
    FOR SELECT USING (status IN ('lost', 'found'));

-- Users can post lost/found
CREATE POLICY "Users can post lost/found" ON public.lost_found_items
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Authors can update their posts
CREATE POLICY "Authors can update lost/found" ON public.lost_found_items
    FOR UPDATE USING (auth.uid() = user_id);

-- ============================================
-- STUDY_REQUESTS POLICIES
-- ============================================
-- Active requests are viewable
CREATE POLICY "Active study requests viewable" ON public.study_requests
    FOR SELECT USING (status = 'active');

-- Users can create requests
CREATE POLICY "Users can create study requests" ON public.study_requests
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Authors can update their requests
CREATE POLICY "Authors can update study requests" ON public.study_requests
    FOR UPDATE USING (auth.uid() = user_id);

-- ============================================
-- FORUM POLICIES
-- ============================================
-- All posts are viewable
CREATE POLICY "Forum posts are viewable" ON public.forum_posts
    FOR SELECT USING (true);

-- Authenticated users can post
CREATE POLICY "Users can create forum posts" ON public.forum_posts
    FOR INSERT WITH CHECK (auth.uid() = author_id);

-- Authors can update posts
CREATE POLICY "Authors can update forum posts" ON public.forum_posts
    FOR UPDATE USING (auth.uid() = author_id);

-- Comments are viewable
CREATE POLICY "Forum comments are viewable" ON public.forum_comments
    FOR SELECT USING (true);

-- Users can comment
CREATE POLICY "Users can comment" ON public.forum_comments
    FOR INSERT WITH CHECK (auth.uid() = author_id);

-- ============================================
-- ANNOUNCEMENTS POLICIES
-- ============================================
-- All announcements are viewable
CREATE POLICY "Announcements are viewable" ON public.announcements
    FOR SELECT USING (true);

-- Only council/faculty can create
CREATE POLICY "Council can create announcements" ON public.announcements
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() 
            AND role IN ('council', 'faculty')
        )
    );

-- ============================================
-- HELPER FUNCTION: Check if user is council+
-- ============================================
CREATE OR REPLACE FUNCTION is_moderator()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.users 
        WHERE id = auth.uid() 
        AND role IN ('council', 'faculty')
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- SUCCESS MESSAGE
-- ============================================
SELECT 'RLS policies created successfully!' as message;
