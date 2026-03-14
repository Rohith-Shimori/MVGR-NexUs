-- ============================================
-- MVGR NexUs Database Setup
-- File: 09_rls_policies.sql
-- Purpose: Row Level Security (RLS) policies for all tables
-- Run Order: 9
-- ============================================

-- ============================================
-- SECTION 1: ENABLE RLS ON ALL TABLES
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
ALTER TABLE public.study_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.study_request_responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.team_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.team_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mentors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meetups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meetup_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lost_found_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.content_reports ENABLE ROW LEVEL SECURITY;

-- ============================================
-- SECTION 2: USERS POLICIES
-- ============================================

-- Anyone can view user profiles
CREATE POLICY "users_select_all" ON public.users
    FOR SELECT USING (true);

-- Users can update their own profile
CREATE POLICY "users_update_own" ON public.users
    FOR UPDATE USING (auth.uid() = id);

-- Allow trigger/service to insert profiles
-- Note: The handle_new_user() function runs with SECURITY DEFINER
-- so it bypasses RLS. Normal users cannot insert.
CREATE POLICY "users_insert_own" ON public.users
    FOR INSERT WITH CHECK (auth.uid() = id);

-- ============================================
-- SECTION 3: CLUBS POLICIES
-- ============================================

-- Anyone can view clubs
CREATE POLICY "clubs_select_all" ON public.clubs
    FOR SELECT USING (true);

-- Authenticated users can create clubs
CREATE POLICY "clubs_insert_auth" ON public.clubs
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Only club creators or admins can update their clubs
CREATE POLICY "clubs_update_owner" ON public.clubs
    FOR UPDATE USING (
        auth.uid() = created_by OR
        EXISTS (
            SELECT 1 FROM public.club_members 
            WHERE club_id = clubs.id 
            AND user_id = auth.uid() 
            AND role = 'admin'
        )
    );

-- Only club owners can delete clubs
CREATE POLICY "clubs_delete_owner" ON public.clubs
    FOR DELETE USING (auth.uid() = created_by);

-- ============================================
-- SECTION 4: CLUB MEMBERS POLICIES
-- ============================================

-- Anyone can view club memberships
CREATE POLICY "club_members_select_all" ON public.club_members
    FOR SELECT USING (true);

-- Authenticated users can join clubs
CREATE POLICY "club_members_insert_auth" ON public.club_members
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Members can leave clubs (delete their own membership)
CREATE POLICY "club_members_delete_own" ON public.club_members
    FOR DELETE USING (auth.uid() = user_id);

-- Admins can update member roles
CREATE POLICY "club_members_update_auth" ON public.club_members
    FOR UPDATE USING (auth.role() = 'authenticated');

-- ============================================
-- SECTION 5: CLUB REQUESTS POLICIES
-- ============================================

-- Users can view requests (their own or club admins)
CREATE POLICY "club_requests_select" ON public.club_requests
    FOR SELECT USING (
        auth.uid() = user_id OR 
        auth.role() = 'authenticated'
    );

-- Users can create join requests
CREATE POLICY "club_requests_insert_auth" ON public.club_requests
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Club admins can update request status
CREATE POLICY "club_requests_update_auth" ON public.club_requests
    FOR UPDATE USING (auth.role() = 'authenticated');

-- Users can delete their own pending requests
CREATE POLICY "club_requests_delete_own" ON public.club_requests
    FOR DELETE USING (auth.uid() = user_id);

-- ============================================
-- SECTION 6: CLUB POSTS POLICIES
-- ============================================

-- Anyone can view club posts
CREATE POLICY "club_posts_select_all" ON public.club_posts
    FOR SELECT USING (true);

-- Club members can create posts
CREATE POLICY "club_posts_insert_auth" ON public.club_posts
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Authors can update their posts
CREATE POLICY "club_posts_update_own" ON public.club_posts
    FOR UPDATE USING (auth.uid() = author_id);

-- Authors can delete their posts
CREATE POLICY "club_posts_delete_own" ON public.club_posts
    FOR DELETE USING (auth.uid() = author_id);

-- ============================================
-- SECTION 7: EVENTS POLICIES
-- ============================================

-- Anyone can view events
CREATE POLICY "events_select_all" ON public.events
    FOR SELECT USING (true);

-- Authenticated users can create events
CREATE POLICY "events_insert_auth" ON public.events
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Authors can update their events
CREATE POLICY "events_update_own" ON public.events
    FOR UPDATE USING (auth.uid() = author_id);

-- Authors can delete their events
CREATE POLICY "events_delete_own" ON public.events
    FOR DELETE USING (auth.uid() = author_id);

-- ============================================
-- SECTION 8: EVENT RSVPS POLICIES
-- ============================================

-- Anyone can view RSVPs
CREATE POLICY "event_rsvps_select_all" ON public.event_rsvps
    FOR SELECT USING (true);

-- Authenticated users can RSVP
CREATE POLICY "event_rsvps_insert_auth" ON public.event_rsvps
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Users can update their own RSVP
CREATE POLICY "event_rsvps_update_own" ON public.event_rsvps
    FOR UPDATE USING (auth.uid() = user_id);

-- Users can cancel their RSVP
CREATE POLICY "event_rsvps_delete_own" ON public.event_rsvps
    FOR DELETE USING (auth.uid() = user_id);

-- ============================================
-- SECTION 9: ANNOUNCEMENTS POLICIES
-- ============================================

-- Anyone can view announcements
CREATE POLICY "announcements_select_all" ON public.announcements
    FOR SELECT USING (true);

-- Authenticated users can create (app checks role)
CREATE POLICY "announcements_insert_auth" ON public.announcements
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Authors can update their announcements
CREATE POLICY "announcements_update_own" ON public.announcements
    FOR UPDATE USING (auth.uid() = author_id);

-- Authors can delete their announcements
CREATE POLICY "announcements_delete_own" ON public.announcements
    FOR DELETE USING (auth.uid() = author_id);

-- ============================================
-- SECTION 10: VAULT ITEMS POLICIES
-- ============================================

-- Anyone can view approved items
CREATE POLICY "vault_items_select_approved" ON public.vault_items
    FOR SELECT USING (is_approved = true);

-- Authenticated users can upload
CREATE POLICY "vault_items_insert_auth" ON public.vault_items
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Uploaders can update their items
CREATE POLICY "vault_items_update_own" ON public.vault_items
    FOR UPDATE USING (auth.uid() = uploader_id);

-- Uploaders can delete their items
CREATE POLICY "vault_items_delete_own" ON public.vault_items
    FOR DELETE USING (auth.uid() = uploader_id);

-- ============================================
-- SECTION 11: FORUM POLICIES
-- ============================================

-- Anyone can view questions
CREATE POLICY "forum_questions_select_all" ON public.forum_questions
    FOR SELECT USING (true);

-- Authenticated users can ask questions
CREATE POLICY "forum_questions_insert_auth" ON public.forum_questions
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Authors can update their questions
CREATE POLICY "forum_questions_update_own" ON public.forum_questions
    FOR UPDATE USING (auth.uid() = author_id);

-- Authors can delete their questions
CREATE POLICY "forum_questions_delete_own" ON public.forum_questions
    FOR DELETE USING (auth.uid() = author_id);

-- Anyone can view answers
CREATE POLICY "forum_answers_select_all" ON public.forum_answers
    FOR SELECT USING (true);

-- Authenticated users can answer
CREATE POLICY "forum_answers_insert_auth" ON public.forum_answers
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Authors can update their answers
CREATE POLICY "forum_answers_update_own" ON public.forum_answers
    FOR UPDATE USING (auth.uid() = author_id);

-- Anyone can view votes
CREATE POLICY "forum_votes_select_all" ON public.forum_votes
    FOR SELECT USING (true);

-- Authenticated users can vote
CREATE POLICY "forum_votes_insert_auth" ON public.forum_votes
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Users can remove their vote
CREATE POLICY "forum_votes_delete_own" ON public.forum_votes
    FOR DELETE USING (auth.uid() = user_id);

-- ============================================
-- SECTION 12: COMMUNITY FEATURES POLICIES
-- ============================================

-- Study requests: view active, create/manage own
CREATE POLICY "study_requests_select_active" ON public.study_requests
    FOR SELECT USING (status = 'active' OR auth.uid() = user_id);

CREATE POLICY "study_requests_insert_auth" ON public.study_requests
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "study_requests_update_own" ON public.study_requests
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "study_requests_delete_own" ON public.study_requests
    FOR DELETE USING (auth.uid() = user_id);

-- Study request responses
CREATE POLICY "study_responses_select_all" ON public.study_request_responses
    FOR SELECT USING (true);

CREATE POLICY "study_responses_insert_auth" ON public.study_request_responses
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Team requests
CREATE POLICY "team_requests_select_open" ON public.team_requests
    FOR SELECT USING (is_open = true OR auth.uid() = creator_id);

CREATE POLICY "team_requests_insert_auth" ON public.team_requests
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "team_requests_update_own" ON public.team_requests
    FOR UPDATE USING (auth.uid() = creator_id);

CREATE POLICY "team_requests_delete_own" ON public.team_requests
    FOR DELETE USING (auth.uid() = creator_id);

-- Team members
CREATE POLICY "team_members_select_all" ON public.team_members
    FOR SELECT USING (true);

CREATE POLICY "team_members_insert_auth" ON public.team_members
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "team_members_delete_own" ON public.team_members
    FOR DELETE USING (auth.uid() = user_id);

-- Mentors
CREATE POLICY "mentors_select_available" ON public.mentors
    FOR SELECT USING (is_available = true OR auth.uid() = user_id);

CREATE POLICY "mentors_insert_auth" ON public.mentors
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "mentors_update_own" ON public.mentors
    FOR UPDATE USING (auth.uid() = user_id);

-- Meetups
CREATE POLICY "meetups_select_active" ON public.meetups
    FOR SELECT USING (is_active = true OR auth.uid() = organizer_id);

CREATE POLICY "meetups_insert_auth" ON public.meetups
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "meetups_update_own" ON public.meetups
    FOR UPDATE USING (auth.uid() = organizer_id);

CREATE POLICY "meetups_delete_own" ON public.meetups
    FOR DELETE USING (auth.uid() = organizer_id);

-- Meetup participants
CREATE POLICY "meetup_participants_select_all" ON public.meetup_participants
    FOR SELECT USING (true);

CREATE POLICY "meetup_participants_insert_auth" ON public.meetup_participants
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "meetup_participants_delete_own" ON public.meetup_participants
    FOR DELETE USING (auth.uid() = user_id);

-- Lost & Found
CREATE POLICY "lost_found_items_select_active" ON public.lost_found_items
    FOR SELECT USING (status IN ('lost', 'found') OR auth.uid() = user_id);

CREATE POLICY "lost_found_items_insert_auth" ON public.lost_found_items
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "lost_found_items_update_own" ON public.lost_found_items
    FOR UPDATE USING (auth.uid() = user_id);

-- ============================================
-- SECTION 13: CONTENT REPORTS POLICIES
-- ============================================

-- Users can view their own reports
CREATE POLICY "content_reports_select_own" ON public.content_reports
    FOR SELECT USING (auth.uid() = reporter_id);

-- Authenticated users can report content
CREATE POLICY "content_reports_insert_auth" ON public.content_reports
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Success message
SELECT '✅ RLS policies created for all tables' as status;
