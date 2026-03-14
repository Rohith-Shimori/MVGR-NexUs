-- ============================================
-- MVGR NexUs Database Setup
-- File: 16_supabase_fixes.sql
-- Purpose: Fix all Supabase Advisor issues
-- Run Order: 16
-- ============================================

-- ============================================
-- SECTION 1: FIX FUNCTION SEARCH_PATH (SECURITY)
-- All functions need explicit search_path to prevent injection
-- Drop functions first to allow parameter name changes
-- ============================================

-- Fix increment_play_count
DROP FUNCTION IF EXISTS public.increment_play_count(UUID);
CREATE OR REPLACE FUNCTION public.increment_play_count(track_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE radio_tracks SET play_count = play_count + 1 WHERE id = track_id;
END;
$$;

-- Fix update_updated_at_column
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

-- Fix handle_new_user
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.users (id, email, full_name, created_at)
  VALUES (NEW.id, NEW.email, COALESCE(NEW.raw_user_meta_data->>'full_name', ''), NOW())
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

-- Fix increment_forum_answer_count
DROP FUNCTION IF EXISTS public.increment_forum_answer_count(UUID);
CREATE OR REPLACE FUNCTION public.increment_forum_answer_count(question_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE forum_questions SET answer_count = answer_count + 1 WHERE id = question_id;
END;
$$;

-- Fix increment_forum_upvote
DROP FUNCTION IF EXISTS public.increment_forum_upvote(UUID);
CREATE OR REPLACE FUNCTION public.increment_forum_upvote(question_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE forum_questions SET upvotes = upvotes + 1 WHERE id = question_id;
END;
$$;

-- Fix decrement_forum_upvote
DROP FUNCTION IF EXISTS public.decrement_forum_upvote(UUID);
CREATE OR REPLACE FUNCTION public.decrement_forum_upvote(question_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE forum_questions SET upvotes = GREATEST(upvotes - 1, 0) WHERE id = question_id;
END;
$$;

-- Fix increment_vault_download (also called increment_download_count)
DROP FUNCTION IF EXISTS public.increment_vault_download(UUID);
CREATE OR REPLACE FUNCTION public.increment_vault_download(item_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE vault_items SET download_count = download_count + 1 WHERE id = item_id;
END;
$$;

-- Also create increment_download_count alias if it doesn't exist
DROP FUNCTION IF EXISTS public.increment_download_count(UUID);
CREATE OR REPLACE FUNCTION public.increment_download_count(item_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE vault_items SET download_count = download_count + 1 WHERE id = item_id;
END;
$$;

-- Fix is_moderator
DROP FUNCTION IF EXISTS public.is_moderator(UUID);
CREATE OR REPLACE FUNCTION public.is_moderator(user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM users WHERE id = user_id AND role IN ('moderator', 'admin', 'faculty')
  );
END;
$$;

-- Fix get_user_role
DROP FUNCTION IF EXISTS public.get_user_role(UUID);
CREATE OR REPLACE FUNCTION public.get_user_role(user_id UUID)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  user_role TEXT;
BEGIN
  SELECT role INTO user_role FROM users WHERE id = user_id;
  RETURN COALESCE(user_role, 'student');
END;
$$;

-- Fix increment_answer_helpful
DROP FUNCTION IF EXISTS public.increment_answer_helpful(UUID);
CREATE OR REPLACE FUNCTION public.increment_answer_helpful(answer_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE forum_answers SET helpful_count = helpful_count + 1 WHERE id = answer_id;
END;
$$;

-- Fix decrement_answer_helpful
DROP FUNCTION IF EXISTS public.decrement_answer_helpful(UUID);
CREATE OR REPLACE FUNCTION public.decrement_answer_helpful(answer_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE forum_answers SET helpful_count = GREATEST(helpful_count - 1, 0) WHERE id = answer_id;
END;
$$;

-- ============================================
-- SECTION 2: MOVE pg_trgm EXTENSION TO PROPER SCHEMA
-- ============================================

-- Move pg_trgm to extensions schema (if not already there)
DO $$
BEGIN
  -- Check if extension exists in public
  IF EXISTS (
    SELECT 1 FROM pg_extension e 
    JOIN pg_namespace n ON e.extnamespace = n.oid 
    WHERE e.extname = 'pg_trgm' AND n.nspname = 'public'
  ) THEN
    -- Drop and recreate in extensions schema
    DROP EXTENSION IF EXISTS pg_trgm CASCADE;
    CREATE EXTENSION IF NOT EXISTS pg_trgm SCHEMA extensions;
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Could not move pg_trgm: %', SQLERRM;
END;
$$;

-- ============================================
-- SECTION 3: FIX OVERLY PERMISSIVE RLS POLICIES ON users TABLE
-- ============================================

-- Drop and recreate "Allow auth insert" policy with proper check
DROP POLICY IF EXISTS "Allow auth insert" ON public.users;
CREATE POLICY "Allow auth insert" ON public.users
  FOR INSERT
  TO authenticated
  WITH CHECK ((SELECT auth.uid()) = id);

-- Fix "Allow auth update own" policy (using (true) is overly permissive)
DROP POLICY IF EXISTS "Allow auth update own" ON public.users;
CREATE POLICY "Allow auth update own" ON public.users
  FOR UPDATE
  TO authenticated
  USING ((SELECT auth.uid()) = id)
  WITH CHECK ((SELECT auth.uid()) = id);

-- ============================================
-- SECTION 4: FIX RLS POLICIES PERFORMANCE (auth.uid() -> (select auth.uid()))
-- This optimizes RLS policies to not re-evaluate auth functions for each row
-- ============================================

-- CLUBS TABLE
DROP POLICY IF EXISTS "clubs_insert_auth" ON public.clubs;
CREATE POLICY "clubs_insert_auth" ON public.clubs
  FOR INSERT TO authenticated
  WITH CHECK ((SELECT auth.uid()) IS NOT NULL);

DROP POLICY IF EXISTS "clubs_update_auth" ON public.clubs;
CREATE POLICY "clubs_update_auth" ON public.clubs
  FOR UPDATE TO authenticated
  USING (created_by = (SELECT auth.uid()));

DROP POLICY IF EXISTS "clubs_delete_auth" ON public.clubs;
CREATE POLICY "clubs_delete_auth" ON public.clubs
  FOR DELETE TO authenticated
  USING (created_by = (SELECT auth.uid()));

-- Remove duplicate permissive policies on clubs (keep only one per action)
DROP POLICY IF EXISTS "clubs_update_owner" ON public.clubs;
DROP POLICY IF EXISTS "clubs_delete_owner" ON public.clubs;

-- CLUB_MEMBERS TABLE
DROP POLICY IF EXISTS "club_members_insert_auth" ON public.club_members;
CREATE POLICY "club_members_insert_auth" ON public.club_members
  FOR INSERT TO authenticated
  WITH CHECK (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "club_members_delete_own" ON public.club_members;
CREATE POLICY "club_members_delete_own" ON public.club_members
  FOR DELETE TO authenticated
  USING (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "club_members_update_auth" ON public.club_members;
CREATE POLICY "club_members_update_auth" ON public.club_members
  FOR UPDATE TO authenticated
  USING (user_id = (SELECT auth.uid()));

-- USERS TABLE
DROP POLICY IF EXISTS "Allow auth delete own" ON public.users;
CREATE POLICY "Allow auth delete own" ON public.users
  FOR DELETE TO authenticated
  USING (id = (SELECT auth.uid()));

-- CLUB_JOIN_REQUESTS TABLE
DROP POLICY IF EXISTS "club_requests_select" ON public.club_join_requests;
CREATE POLICY "club_requests_select" ON public.club_join_requests
  FOR SELECT TO authenticated
  USING (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "club_requests_insert_auth" ON public.club_join_requests;
CREATE POLICY "club_requests_insert_auth" ON public.club_join_requests
  FOR INSERT TO authenticated
  WITH CHECK (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "club_requests_update_auth" ON public.club_join_requests;
CREATE POLICY "club_requests_update_auth" ON public.club_join_requests
  FOR UPDATE TO authenticated
  USING (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "club_requests_delete_own" ON public.club_join_requests;
CREATE POLICY "club_requests_delete_own" ON public.club_join_requests
  FOR DELETE TO authenticated
  USING (user_id = (SELECT auth.uid()));

-- CLUB_POSTS TABLE
DROP POLICY IF EXISTS "club_posts_insert_auth" ON public.club_posts;
CREATE POLICY "club_posts_insert_auth" ON public.club_posts
  FOR INSERT TO authenticated
  WITH CHECK (author_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "club_posts_update_own" ON public.club_posts;
CREATE POLICY "club_posts_update_own" ON public.club_posts
  FOR UPDATE TO authenticated
  USING (author_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "club_posts_delete_own" ON public.club_posts;
CREATE POLICY "club_posts_delete_own" ON public.club_posts
  FOR DELETE TO authenticated
  USING (author_id = (SELECT auth.uid()));

-- EVENTS TABLE
DROP POLICY IF EXISTS "events_insert_auth" ON public.events;
CREATE POLICY "events_insert_auth" ON public.events
  FOR INSERT TO authenticated
  WITH CHECK (author_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "events_update_own" ON public.events;
CREATE POLICY "events_update_own" ON public.events
  FOR UPDATE TO authenticated
  USING (author_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "events_delete_own" ON public.events;
CREATE POLICY "events_delete_own" ON public.events
  FOR DELETE TO authenticated
  USING (author_id = (SELECT auth.uid()));

-- EVENT_RSVPS TABLE
DROP POLICY IF EXISTS "event_rsvps_insert_auth" ON public.event_rsvps;
CREATE POLICY "event_rsvps_insert_auth" ON public.event_rsvps
  FOR INSERT TO authenticated
  WITH CHECK (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "event_rsvps_update_own" ON public.event_rsvps;
CREATE POLICY "event_rsvps_update_own" ON public.event_rsvps
  FOR UPDATE TO authenticated
  USING (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "event_rsvps_delete_own" ON public.event_rsvps;
CREATE POLICY "event_rsvps_delete_own" ON public.event_rsvps
  FOR DELETE TO authenticated
  USING (user_id = (SELECT auth.uid()));

-- ANNOUNCEMENTS TABLE
DROP POLICY IF EXISTS "announcements_insert_auth" ON public.announcements;
CREATE POLICY "announcements_insert_auth" ON public.announcements
  FOR INSERT TO authenticated
  WITH CHECK (author_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "announcements_update_own" ON public.announcements;
CREATE POLICY "announcements_update_own" ON public.announcements
  FOR UPDATE TO authenticated
  USING (author_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "announcements_delete_own" ON public.announcements;
CREATE POLICY "announcements_delete_own" ON public.announcements
  FOR DELETE TO authenticated
  USING (author_id = (SELECT auth.uid()));

-- VAULT_ITEMS TABLE
DROP POLICY IF EXISTS "vault_items_insert_auth" ON public.vault_items;
CREATE POLICY "vault_items_insert_auth" ON public.vault_items
  FOR INSERT TO authenticated
  WITH CHECK (uploader_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "vault_items_update_own" ON public.vault_items;
CREATE POLICY "vault_items_update_own" ON public.vault_items
  FOR UPDATE TO authenticated
  USING (uploader_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "vault_items_delete_own" ON public.vault_items;
CREATE POLICY "vault_items_delete_own" ON public.vault_items
  FOR DELETE TO authenticated
  USING (uploader_id = (SELECT auth.uid()));

-- FORUM_QUESTIONS TABLE
DROP POLICY IF EXISTS "forum_questions_insert_auth" ON public.forum_questions;
CREATE POLICY "forum_questions_insert_auth" ON public.forum_questions
  FOR INSERT TO authenticated
  WITH CHECK (author_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "forum_questions_update_own" ON public.forum_questions;
CREATE POLICY "forum_questions_update_own" ON public.forum_questions
  FOR UPDATE TO authenticated
  USING (author_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "forum_questions_delete_own" ON public.forum_questions;
CREATE POLICY "forum_questions_delete_own" ON public.forum_questions
  FOR DELETE TO authenticated
  USING (author_id = (SELECT auth.uid()));

-- FORUM_ANSWERS TABLE
DROP POLICY IF EXISTS "forum_answers_insert_auth" ON public.forum_answers;
CREATE POLICY "forum_answers_insert_auth" ON public.forum_answers
  FOR INSERT TO authenticated
  WITH CHECK (author_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "forum_answers_update_own" ON public.forum_answers;
CREATE POLICY "forum_answers_update_own" ON public.forum_answers
  FOR UPDATE TO authenticated
  USING (author_id = (SELECT auth.uid()));

-- FORUM_VOTES TABLE
DROP POLICY IF EXISTS "forum_votes_insert_auth" ON public.forum_votes;
CREATE POLICY "forum_votes_insert_auth" ON public.forum_votes
  FOR INSERT TO authenticated
  WITH CHECK (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "forum_votes_delete_own" ON public.forum_votes;
CREATE POLICY "forum_votes_delete_own" ON public.forum_votes
  FOR DELETE TO authenticated
  USING (user_id = (SELECT auth.uid()));

-- STUDY_REQUESTS TABLE
DROP POLICY IF EXISTS "study_requests_select_active" ON public.study_requests;
CREATE POLICY "study_requests_select_active" ON public.study_requests
  FOR SELECT TO authenticated
  USING (is_active = true OR user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "study_requests_insert_auth" ON public.study_requests;
CREATE POLICY "study_requests_insert_auth" ON public.study_requests
  FOR INSERT TO authenticated
  WITH CHECK (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "study_requests_update_own" ON public.study_requests;
CREATE POLICY "study_requests_update_own" ON public.study_requests
  FOR UPDATE TO authenticated
  USING (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "study_requests_delete_own" ON public.study_requests;
CREATE POLICY "study_requests_delete_own" ON public.study_requests
  FOR DELETE TO authenticated
  USING (user_id = (SELECT auth.uid()));

-- STUDY_REQUEST_RESPONSES TABLE
DROP POLICY IF EXISTS "study_responses_insert_auth" ON public.study_request_responses;
CREATE POLICY "study_responses_insert_auth" ON public.study_request_responses
  FOR INSERT TO authenticated
  WITH CHECK (responder_id = (SELECT auth.uid()));

-- TEAM_REQUESTS TABLE
DROP POLICY IF EXISTS "team_requests_select_open" ON public.team_requests;
CREATE POLICY "team_requests_select_open" ON public.team_requests
  FOR SELECT TO authenticated
  USING (is_open = true OR creator_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "team_requests_insert_auth" ON public.team_requests;
CREATE POLICY "team_requests_insert_auth" ON public.team_requests
  FOR INSERT TO authenticated
  WITH CHECK (creator_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "team_requests_update_own" ON public.team_requests;
CREATE POLICY "team_requests_update_own" ON public.team_requests
  FOR UPDATE TO authenticated
  USING (creator_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "team_requests_delete_own" ON public.team_requests;
CREATE POLICY "team_requests_delete_own" ON public.team_requests
  FOR DELETE TO authenticated
  USING (creator_id = (SELECT auth.uid()));

-- TEAM_MEMBERS TABLE
DROP POLICY IF EXISTS "team_members_insert_auth" ON public.team_members;
CREATE POLICY "team_members_insert_auth" ON public.team_members
  FOR INSERT TO authenticated
  WITH CHECK (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "team_members_delete_own" ON public.team_members;
CREATE POLICY "team_members_delete_own" ON public.team_members
  FOR DELETE TO authenticated
  USING (user_id = (SELECT auth.uid()));

-- MENTORS TABLE
DROP POLICY IF EXISTS "mentors_select_available" ON public.mentors;
CREATE POLICY "mentors_select_available" ON public.mentors
  FOR SELECT TO authenticated
  USING (is_available = true OR user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "mentors_insert_auth" ON public.mentors;
CREATE POLICY "mentors_insert_auth" ON public.mentors
  FOR INSERT TO authenticated
  WITH CHECK (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "mentors_update_own" ON public.mentors;
CREATE POLICY "mentors_update_own" ON public.mentors
  FOR UPDATE TO authenticated
  USING (user_id = (SELECT auth.uid()));

-- MEETUPS TABLE
DROP POLICY IF EXISTS "meetups_select_active" ON public.meetups;
CREATE POLICY "meetups_select_active" ON public.meetups
  FOR SELECT TO authenticated
  USING (is_active = true OR organizer_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "meetups_insert_auth" ON public.meetups;
CREATE POLICY "meetups_insert_auth" ON public.meetups
  FOR INSERT TO authenticated
  WITH CHECK (organizer_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "meetups_update_own" ON public.meetups;
CREATE POLICY "meetups_update_own" ON public.meetups
  FOR UPDATE TO authenticated
  USING (organizer_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "meetups_delete_own" ON public.meetups;
CREATE POLICY "meetups_delete_own" ON public.meetups
  FOR DELETE TO authenticated
  USING (organizer_id = (SELECT auth.uid()));

-- MEETUP_PARTICIPANTS TABLE
DROP POLICY IF EXISTS "meetup_participants_insert_auth" ON public.meetup_participants;
CREATE POLICY "meetup_participants_insert_auth" ON public.meetup_participants
  FOR INSERT TO authenticated
  WITH CHECK (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "meetup_participants_delete_own" ON public.meetup_participants;
CREATE POLICY "meetup_participants_delete_own" ON public.meetup_participants
  FOR DELETE TO authenticated
  USING (user_id = (SELECT auth.uid()));

-- LOST_FOUND_ITEMS TABLE
DROP POLICY IF EXISTS "lost_found_items_select_active" ON public.lost_found_items;
CREATE POLICY "lost_found_items_select_active" ON public.lost_found_items
  FOR SELECT TO authenticated
  USING (status != 'resolved' OR user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "lost_found_items_insert_auth" ON public.lost_found_items;
CREATE POLICY "lost_found_items_insert_auth" ON public.lost_found_items
  FOR INSERT TO authenticated
  WITH CHECK (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "lost_found_items_update_own" ON public.lost_found_items;
CREATE POLICY "lost_found_items_update_own" ON public.lost_found_items
  FOR UPDATE TO authenticated
  USING (user_id = (SELECT auth.uid()));

-- CONTENT_REPORTS TABLE
DROP POLICY IF EXISTS "content_reports_select_own" ON public.content_reports;
CREATE POLICY "content_reports_select_own" ON public.content_reports
  FOR SELECT TO authenticated
  USING (reporter_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "content_reports_insert_auth" ON public.content_reports;
CREATE POLICY "content_reports_insert_auth" ON public.content_reports
  FOR INSERT TO authenticated
  WITH CHECK (reporter_id = (SELECT auth.uid()));

-- FEEDBACK_SUBMISSIONS TABLE
DROP POLICY IF EXISTS "feedback_insert_auth" ON public.feedback_submissions;
CREATE POLICY "feedback_insert_auth" ON public.feedback_submissions
  FOR INSERT TO authenticated
  WITH CHECK (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "feedback_select_own" ON public.feedback_submissions;
CREATE POLICY "feedback_select_own" ON public.feedback_submissions
  FOR SELECT TO authenticated
  USING (user_id = (SELECT auth.uid()));

-- RADIO_TRACKS TABLE
DROP POLICY IF EXISTS "radio_select_approved" ON public.radio_tracks;
CREATE POLICY "radio_select_approved" ON public.radio_tracks
  FOR SELECT TO authenticated
  USING (is_approved = true OR uploaded_by = (SELECT auth.uid()));

DROP POLICY IF EXISTS "radio_insert_auth" ON public.radio_tracks;
CREATE POLICY "radio_insert_auth" ON public.radio_tracks
  FOR INSERT TO authenticated
  WITH CHECK (uploaded_by = (SELECT auth.uid()));

-- USER_LIKED_TRACKS TABLE
DROP POLICY IF EXISTS "liked_tracks_insert_auth" ON public.user_liked_tracks;
CREATE POLICY "liked_tracks_insert_auth" ON public.user_liked_tracks
  FOR INSERT TO authenticated
  WITH CHECK (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "liked_tracks_delete_own" ON public.user_liked_tracks;
CREATE POLICY "liked_tracks_delete_own" ON public.user_liked_tracks
  FOR DELETE TO authenticated
  USING (user_id = (SELECT auth.uid()));

-- MENTORSHIP_SESSIONS TABLE
DROP POLICY IF EXISTS "sessions_select_own" ON public.mentorship_sessions;
CREATE POLICY "sessions_select_own" ON public.mentorship_sessions
  FOR SELECT TO authenticated
  USING (mentee_id = (SELECT auth.uid()) OR mentor_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "sessions_insert_auth" ON public.mentorship_sessions;
CREATE POLICY "sessions_insert_auth" ON public.mentorship_sessions
  FOR INSERT TO authenticated
  WITH CHECK (mentee_id = (SELECT auth.uid()));

-- ESCALATIONS TABLE
DROP POLICY IF EXISTS "escalations_faculty_select" ON public.escalations;
CREATE POLICY "escalations_faculty_select" ON public.escalations
  FOR SELECT TO authenticated
  USING (
    submitted_by_id = (SELECT auth.uid()) 
    OR EXISTS (SELECT 1 FROM users WHERE id = (SELECT auth.uid()) AND role IN ('faculty', 'admin'))
  );

DROP POLICY IF EXISTS "escalations_insert_authenticated" ON public.escalations;
CREATE POLICY "escalations_insert_authenticated" ON public.escalations
  FOR INSERT TO authenticated
  WITH CHECK (submitted_by_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "escalations_faculty_update" ON public.escalations;
CREATE POLICY "escalations_faculty_update" ON public.escalations
  FOR UPDATE TO authenticated
  USING (EXISTS (SELECT 1 FROM users WHERE id = (SELECT auth.uid()) AND role IN ('faculty', 'admin')));

-- ANALYTICS_EVENTS TABLE
DROP POLICY IF EXISTS "analytics_insert_authenticated" ON public.analytics_events;
CREATE POLICY "analytics_insert_authenticated" ON public.analytics_events
  FOR INSERT TO authenticated
  WITH CHECK (user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "analytics_select_own" ON public.analytics_events;
CREATE POLICY "analytics_select_own" ON public.analytics_events
  FOR SELECT TO authenticated
  USING (user_id = (SELECT auth.uid()));

-- ============================================
-- SECTION 5: ADD MISSING FOREIGN KEY INDEXES (PERFORMANCE)
-- ============================================

-- announcements
CREATE INDEX IF NOT EXISTS idx_announcements_author_id ON public.announcements(author_id);

-- club_join_requests
CREATE INDEX IF NOT EXISTS idx_club_join_requests_club_id ON public.club_join_requests(club_id);
CREATE INDEX IF NOT EXISTS idx_club_join_requests_user_id ON public.club_join_requests(user_id);

-- club_posts
CREATE INDEX IF NOT EXISTS idx_club_posts_author_id ON public.club_posts(author_id);
CREATE INDEX IF NOT EXISTS idx_club_posts_club_id ON public.club_posts(club_id);

-- clubs
CREATE INDEX IF NOT EXISTS idx_clubs_created_by ON public.clubs(created_by);

-- content_reports
CREATE INDEX IF NOT EXISTS idx_content_reports_reporter_id ON public.content_reports(reporter_id);
CREATE INDEX IF NOT EXISTS idx_content_reports_reviewer_id ON public.content_reports(reviewer_id);

-- escalations
CREATE INDEX IF NOT EXISTS idx_escalations_submitted_by_id ON public.escalations(submitted_by_id);

-- events
CREATE INDEX IF NOT EXISTS idx_events_author_id ON public.events(author_id);

-- feedback_submissions
CREATE INDEX IF NOT EXISTS idx_feedback_submissions_user_id ON public.feedback_submissions(user_id);

-- forum_answers
CREATE INDEX IF NOT EXISTS idx_forum_answers_author_id ON public.forum_answers(author_id);

-- forum_questions
CREATE INDEX IF NOT EXISTS idx_forum_questions_author_id ON public.forum_questions(author_id);

-- lost_found_items
CREATE INDEX IF NOT EXISTS idx_lost_found_items_claimer_id ON public.lost_found_items(claimer_id);
CREATE INDEX IF NOT EXISTS idx_lost_found_items_user_id ON public.lost_found_items(user_id);

-- meetup_participants
CREATE INDEX IF NOT EXISTS idx_meetup_participants_user_id ON public.meetup_participants(user_id);

-- meetups
CREATE INDEX IF NOT EXISTS idx_meetups_organizer_id ON public.meetups(organizer_id);

-- mentors
CREATE INDEX IF NOT EXISTS idx_mentors_user_id ON public.mentors(user_id);

-- mentorship_sessions
CREATE INDEX IF NOT EXISTS idx_mentorship_sessions_mentee_id ON public.mentorship_sessions(mentee_id);
CREATE INDEX IF NOT EXISTS idx_mentorship_sessions_mentor_id ON public.mentorship_sessions(mentor_id);

-- radio_tracks
CREATE INDEX IF NOT EXISTS idx_radio_tracks_uploaded_by ON public.radio_tracks(uploaded_by);

-- study_request_responses
CREATE INDEX IF NOT EXISTS idx_study_request_responses_responder_id ON public.study_request_responses(responder_id);

-- study_requests
CREATE INDEX IF NOT EXISTS idx_study_requests_user_id ON public.study_requests(user_id);

-- team_members
CREATE INDEX IF NOT EXISTS idx_team_members_user_id ON public.team_members(user_id);

-- team_requests
CREATE INDEX IF NOT EXISTS idx_team_requests_creator_id ON public.team_requests(creator_id);

-- user_liked_tracks
CREATE INDEX IF NOT EXISTS idx_user_liked_tracks_track_id ON public.user_liked_tracks(track_id);

-- vault_items
CREATE INDEX IF NOT EXISTS idx_vault_items_uploader_id ON public.vault_items(uploader_id);

-- ============================================
-- SECTION 6: CREATE MISSING STORAGE BUCKET (vault-files)
-- The code uses 'vault-files' but migration creates 'vault'
-- ============================================

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'vault-files', 
    'vault-files', 
    true,
    52428800,  -- 50MB limit
    ARRAY['application/pdf', 'image/jpeg', 'image/png', 'application/msword', 
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
          'application/vnd.ms-powerpoint',
          'application/vnd.openxmlformats-officedocument.presentationml.presentation']
)
ON CONFLICT (id) DO NOTHING;

-- Storage policies for vault-files
CREATE POLICY "vault_files_select_public" ON storage.objects
    FOR SELECT USING (bucket_id = 'vault-files');

CREATE POLICY "vault_files_insert_auth" ON storage.objects
    FOR INSERT TO authenticated
    WITH CHECK (bucket_id = 'vault-files');

CREATE POLICY "vault_files_update_own" ON storage.objects
    FOR UPDATE TO authenticated
    USING (bucket_id = 'vault-files' AND (storage.foldername(name))[1] = (SELECT auth.uid())::text);

CREATE POLICY "vault_files_delete_own" ON storage.objects
    FOR DELETE TO authenticated
    USING (bucket_id = 'vault-files' AND (storage.foldername(name))[1] = (SELECT auth.uid())::text);

-- ============================================
-- DONE!
-- ============================================
