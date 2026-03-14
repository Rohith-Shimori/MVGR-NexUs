-- ============================================
-- MVGR NexUs Database Setup
-- File: 12_seed_data.sql
-- Purpose: Demo/test data (OPTIONAL)
-- Run Order: 13 (Last)
-- ============================================

-- ⚠️ This file is OPTIONAL
-- Only run if you want demo data for testing
-- Do NOT run in production

-- ============================================
-- DEMO CLUBS
-- ============================================

INSERT INTO public.clubs (id, name, description, category, is_approved, is_official) VALUES
    ('11111111-1111-1111-1111-111111111111', 'CodeCraft', 'Technical club focused on competitive programming and software development', 'technical', true, true),
    ('22222222-2222-2222-2222-222222222222', 'Rhythms', 'Music and dance club for cultural activities', 'cultural', true, true),
    ('33333333-3333-3333-3333-333333333333', 'Sports Club', 'All sports activities and tournaments', 'sports', true, true),
    ('44444444-4444-4444-4444-444444444444', 'IEEE Student Branch', 'IEEE technical activities and workshops', 'technical', true, true),
    ('55555555-5555-5555-5555-555555555555', 'Entrepreneurship Cell', 'Startup culture and business ideas', 'social', true, false)
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- DEMO ANNOUNCEMENTS  
-- ============================================

-- Note: These will fail if you don't have a user with matching ID
-- You'll need to signup first, then run these manually

-- Sample announcement structure (for reference):
-- INSERT INTO public.announcements (title, content, author_id, author_name, source, is_pinned) VALUES
-- ('Welcome to MVGR NexUs!', 'The official campus community platform is now live.', 'YOUR_USER_ID', 'Your Name', 'Council', true);

-- ============================================
-- SUCCESS MESSAGE
-- ============================================

SELECT '✅ Seed data inserted: 5 demo clubs' as status;
SELECT 'ℹ️ Note: Add announcements and other data after you have registered users' as info;
