-- ============================================
-- MVGR NexUs - Seed Data for Hackathon Demo
-- Run AFTER schema.sql and rls_policies.sql
-- ============================================

-- ============================================
-- STEP 0: Disable FK checks temporarily for seed data
-- ============================================
-- We'll set author_id to NULL where possible, or use a system account

-- ============================================
-- 1. CLUBS (No FK issues - created_by is nullable)
-- ============================================
INSERT INTO public.clubs (
  id, name, description, category, 
  logo_url, cover_image_url, contact_email, instagram_handle,
  is_approved, is_official, created_at
) VALUES (
  'a1111111-1111-1111-1111-111111111111'::uuid,
  'AIVENGERS',
  'The AI & Innovation Club of MVGR. We explore cutting-edge artificial intelligence, machine learning, and build innovative solutions that matter. Join us to shape the future! 🚀🤖',
  'technical',
  NULL,
  NULL,
  'aivengers@mvgrce.edu.in',
  '@aivengers_mvgr',
  true,
  true,
  NOW()
) ON CONFLICT (id) DO NOTHING;

INSERT INTO public.clubs (
  id, name, description, category, 
  contact_email, is_approved, is_official, created_at
) VALUES 
(
  'b2222222-2222-2222-2222-222222222222'::uuid,
  'Google Developer Student Club',
  'Learn, grow, and connect with other developers passionate about Google technologies. Workshops, study jams, and hackathons!',
  'technical',
  'gdsc@mvgrce.edu.in',
  true,
  true,
  NOW()
),
(
  'c3333333-3333-3333-3333-333333333333'::uuid,
  'Kalanjali - Cultural Club',
  'Celebrate art, music, dance, and drama. We organize cultural fests, talent shows, and creative workshops throughout the year.',
  'cultural',
  'kalanjali@mvgrce.edu.in',
  true,
  true,
  NOW()
),
(
  'd4444444-4444-4444-4444-444444444444'::uuid,
  'Sportify',
  'For sports enthusiasts! Cricket, football, basketball, and more. Regular tournaments and fitness sessions.',
  'sports',
  'sportify@mvgrce.edu.in',
  true,
  true,
  NOW()
) ON CONFLICT (id) DO NOTHING;

-- ============================================
-- SUCCESS MESSAGE
-- ============================================
SELECT '✅ Clubs inserted successfully!' as message;
SELECT 'AIVENGERS ID: a1111111-1111-1111-1111-111111111111' as info;
SELECT '' as spacer;
SELECT 'NEXT STEPS:' as next;
SELECT '1. Create auth users in Dashboard' as step1;
SELECT '2. Run demo_users.sql with their UUIDs' as step2;
SELECT '3. Run seed_events.sql to add events' as step3;
