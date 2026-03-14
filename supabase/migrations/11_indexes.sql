-- ============================================
-- MVGR NexUs Database Setup
-- File: 11_indexes.sql
-- Purpose: Performance indexes for common queries
-- Run Order: 12
-- ============================================

-- ============================================
-- USERS INDEXES
-- ============================================

-- Fast email lookup (already unique, but explicit)
CREATE INDEX IF NOT EXISTS idx_users_email 
    ON public.users(email);

-- Filter by role (for admin queries)
CREATE INDEX IF NOT EXISTS idx_users_role 
    ON public.users(role);

-- Department + year (for study buddy matching)
CREATE INDEX IF NOT EXISTS idx_users_dept_year 
    ON public.users(department, year);

-- ============================================
-- CLUBS INDEXES
-- ============================================

-- Filter by category
CREATE INDEX IF NOT EXISTS idx_clubs_category 
    ON public.clubs(category);

-- Filter approved clubs
CREATE INDEX IF NOT EXISTS idx_clubs_approved 
    ON public.clubs(is_approved) WHERE is_approved = true;

-- ============================================
-- CLUB MEMBERS INDEXES
-- ============================================

-- Find all clubs a user belongs to
CREATE INDEX IF NOT EXISTS idx_club_members_user 
    ON public.club_members(user_id);

-- Find all members of a club
CREATE INDEX IF NOT EXISTS idx_club_members_club 
    ON public.club_members(club_id);

-- ============================================
-- EVENTS INDEXES
-- ============================================

-- Sort/filter by date (most common query)
CREATE INDEX IF NOT EXISTS idx_events_date 
    ON public.events(event_date);

-- Filter by club
CREATE INDEX IF NOT EXISTS idx_events_club 
    ON public.events(club_id);

-- Filter by category
CREATE INDEX IF NOT EXISTS idx_events_category 
    ON public.events(category);

-- ============================================
-- EVENT RSVPS INDEXES
-- ============================================

-- Find RSVPs for an event
CREATE INDEX IF NOT EXISTS idx_event_rsvps_event 
    ON public.event_rsvps(event_id);

-- Find user's RSVPs
CREATE INDEX IF NOT EXISTS idx_event_rsvps_user 
    ON public.event_rsvps(user_id);

-- ============================================
-- VAULT INDEXES
-- ============================================

-- Filter by branch and year
CREATE INDEX IF NOT EXISTS idx_vault_items_branch_year 
    ON public.vault_items(branch, year);

-- Filter by subject
CREATE INDEX IF NOT EXISTS idx_vault_items_subject 
    ON public.vault_items(subject);

-- Filter by type
CREATE INDEX IF NOT EXISTS idx_vault_items_type 
    ON public.vault_items(type);

-- Sort by download count (popular items)
CREATE INDEX IF NOT EXISTS idx_vault_items_downloads 
    ON public.vault_items(download_count DESC);

-- ============================================
-- FORUM INDEXES
-- ============================================

-- Sort by creation date (latest questions)
CREATE INDEX IF NOT EXISTS idx_forum_questions_created 
    ON public.forum_questions(created_at DESC);

-- Filter by subject
CREATE INDEX IF NOT EXISTS idx_forum_questions_subject 
    ON public.forum_questions(subject);

-- Filter unresolved questions
CREATE INDEX IF NOT EXISTS idx_forum_questions_unresolved 
    ON public.forum_questions(is_resolved) WHERE is_resolved = false;

-- Find answers for a question
CREATE INDEX IF NOT EXISTS idx_forum_answers_question 
    ON public.forum_answers(question_id);

-- ============================================
-- COMMUNITY FEATURES INDEXES
-- ============================================

-- Study requests by status
CREATE INDEX IF NOT EXISTS idx_study_requests_status 
    ON public.study_requests(status);

-- Team requests by category
CREATE INDEX IF NOT EXISTS idx_team_requests_category 
    ON public.team_requests(category);

-- Active meetups
CREATE INDEX IF NOT EXISTS idx_meetups_scheduled 
    ON public.meetups(scheduled_at) WHERE is_active = true;

-- Lost & found by status
CREATE INDEX IF NOT EXISTS idx_lost_found_status 
    ON public.lost_found_items(status);

-- ============================================
-- ANNOUNCEMENTS INDEXES
-- ============================================

-- Sort by creation date
CREATE INDEX IF NOT EXISTS idx_announcements_created 
    ON public.announcements(created_at DESC);

-- Pinned announcements
CREATE INDEX IF NOT EXISTS idx_announcements_pinned 
    ON public.announcements(is_pinned) WHERE is_pinned = true;

-- ============================================
-- CONTENT REPORTS INDEXES
-- ============================================

-- Filter by status for moderation
CREATE INDEX IF NOT EXISTS idx_content_reports_status 
    ON public.content_reports(status);

-- Success message
SELECT '✅ Performance indexes created for all tables' as status;
