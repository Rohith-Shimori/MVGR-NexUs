-- ============================================
-- MVGR NexUs Database Setup
-- File: 00_cleanup.sql
-- Purpose: Clean slate - drops ALL existing objects
-- Run Order: 1 (First)
-- ============================================

-- ⚠️ WARNING: This will DELETE ALL DATA!
-- Only run this when you want to start fresh

-- Drop ALL tables in dependency order (children first)
-- Includes both old table names and new table names

-- Extra/Radio/Feedback tables
DROP TABLE IF EXISTS public.user_liked_tracks CASCADE;
DROP TABLE IF EXISTS public.radio_tracks CASCADE;
DROP TABLE IF EXISTS public.feedback_submissions CASCADE;
DROP TABLE IF EXISTS public.content_reports CASCADE;  -- Old name for reports

-- Mentorship tables
DROP TABLE IF EXISTS public.mentorship_sessions CASCADE;
DROP TABLE IF EXISTS public.mentors CASCADE;

-- Community tables
DROP TABLE IF EXISTS public.meetup_participants CASCADE;
DROP TABLE IF EXISTS public.meetups CASCADE;
DROP TABLE IF EXISTS public.team_members CASCADE;
DROP TABLE IF EXISTS public.team_requests CASCADE;
DROP TABLE IF EXISTS public.study_request_responses CASCADE;
DROP TABLE IF EXISTS public.study_requests CASCADE;

-- Lost & Found
DROP TABLE IF EXISTS public.lost_found_items CASCADE;

-- Content tables
DROP TABLE IF EXISTS public.forum_votes CASCADE;
DROP TABLE IF EXISTS public.forum_comments CASCADE;
DROP TABLE IF EXISTS public.forum_answers CASCADE;
DROP TABLE IF EXISTS public.forum_questions CASCADE;
DROP TABLE IF EXISTS public.forum_replies CASCADE;
DROP TABLE IF EXISTS public.forum_posts CASCADE;
DROP TABLE IF EXISTS public.vault_items CASCADE;
DROP TABLE IF EXISTS public.announcements CASCADE;

-- Events tables
DROP TABLE IF EXISTS public.event_rsvps CASCADE;
DROP TABLE IF EXISTS public.event_registrations CASCADE;  -- Old name
DROP TABLE IF EXISTS public.events CASCADE;

-- Clubs tables
DROP TABLE IF EXISTS public.club_posts CASCADE;
DROP TABLE IF EXISTS public.club_requests CASCADE;
DROP TABLE IF EXISTS public.club_join_requests CASCADE;  -- Old name
DROP TABLE IF EXISTS public.club_members CASCADE;
DROP TABLE IF EXISTS public.clubs CASCADE;

-- Users table (must be last, many FKs reference it)
DROP TABLE IF EXISTS public.users CASCADE;

-- Reports table
DROP TABLE IF EXISTS public.reports CASCADE;

-- Drop ALL functions
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS public.update_updated_at_column() CASCADE;
DROP FUNCTION IF EXISTS public.update_updated_at() CASCADE;  -- Old name
DROP FUNCTION IF EXISTS public.increment_forum_answer_count(UUID) CASCADE;
DROP FUNCTION IF EXISTS public.increment_forum_upvote(UUID) CASCADE;
DROP FUNCTION IF EXISTS public.decrement_forum_upvote(UUID) CASCADE;
DROP FUNCTION IF EXISTS public.increment_answer_helpful(UUID) CASCADE;
DROP FUNCTION IF EXISTS public.decrement_answer_helpful(UUID) CASCADE;
DROP FUNCTION IF EXISTS public.increment_vault_download(UUID) CASCADE;
DROP FUNCTION IF EXISTS public.increment_play_count(UUID) CASCADE;
DROP FUNCTION IF EXISTS public.is_moderator() CASCADE;
DROP FUNCTION IF EXISTS public.get_user_role() CASCADE;

-- Success message
SELECT '✅ Cleanup complete! All tables and functions dropped.' as status;
