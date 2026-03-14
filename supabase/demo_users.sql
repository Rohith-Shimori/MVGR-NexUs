-- ============================================
-- MVGR NexUs - Demo Users Setup
-- 
-- INSTRUCTIONS:
-- 1. First, create these users in Supabase Dashboard:
--    Authentication → Users → Add user
--    
--    | Email                      | Password  |
--    |----------------------------|-----------|
--    | student@mvgrce.edu.in      | Demo@123  |
--    | clubadmin@mvgrce.edu.in    | Demo@123  |
--    | council@mvgrce.edu.in      | Demo@123  |
--    | faculty@mvgrce.edu.in      | Demo@123  |
--
-- 2. Copy each user's ID from the Users table
-- 3. Replace the UUIDs below with actual user IDs
-- 4. Run this SQL in SQL Editor
-- ============================================

-- IMPORTANT: Replace these placeholder UUIDs with actual user IDs from auth.users
-- Format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

-- ============================================
-- DEMO USERS PROFILE DATA
-- ============================================

-- Student Account
INSERT INTO public.users (id, email, name, roll_number, department, year, role, interests, skills, is_verified, created_at)
VALUES (
  'REPLACE_WITH_STUDENT_UUID'::uuid,  -- <-- Replace this!
  'student@mvgrce.edu.in',
  'Demo Student',
  '21BCE7001',
  'Computer Science',
  3,
  'student',
  ARRAY['AI/ML', 'Web Development', 'Mobile Apps'],
  ARRAY['Python', 'Flutter', 'React'],
  true,
  NOW()
);

-- Club Admin Account (AIVENGERS Admin)
INSERT INTO public.users (id, email, name, roll_number, department, year, role, interests, skills, is_verified, created_at)
VALUES (
  'REPLACE_WITH_CLUBADMIN_UUID'::uuid,  -- <-- Replace this!
  'clubadmin@mvgrce.edu.in',
  'Club Admin',
  '21BCE7002',
  'Computer Science',
  4,
  'clubAdmin',
  ARRAY['AI/ML', 'Leadership', 'Event Management'],
  ARRAY['Python', 'TensorFlow', 'Public Speaking'],
  true,
  NOW()
);

-- Student Council Account
INSERT INTO public.users (id, email, name, roll_number, department, year, role, interests, skills, is_verified, created_at)
VALUES (
  'REPLACE_WITH_COUNCIL_UUID'::uuid,  -- <-- Replace this!
  'council@mvgrce.edu.in',
  'Council Member',
  '21BCE7003',
  'Electronics',
  4,
  'council',
  ARRAY['Student Affairs', 'Event Planning', 'Community'],
  ARRAY['Leadership', 'Communication', 'Organization'],
  true,
  NOW()
);

-- Faculty Account
INSERT INTO public.users (id, email, name, roll_number, department, year, role, interests, skills, bio, is_verified, created_at)
VALUES (
  'REPLACE_WITH_FACULTY_UUID'::uuid,  -- <-- Replace this!
  'faculty@mvgrce.edu.in',
  'Dr. Faculty Demo',
  'FAC001',
  'Computer Science',
  0,
  'faculty',
  ARRAY['Research', 'AI/ML', 'Teaching'],
  ARRAY['Machine Learning', 'Data Science', 'Python'],
  'Professor of Computer Science, specializing in Artificial Intelligence and Machine Learning.',
  true,
  NOW()
);

-- ============================================
-- MAKE CLUB ADMIN THE AIVENGERS ADMIN
-- ============================================
INSERT INTO public.club_members (user_id, club_id, role)
VALUES (
  'REPLACE_WITH_CLUBADMIN_UUID'::uuid,  -- <-- Same as above!
  'a1111111-1111-1111-1111-111111111111'::uuid,  -- AIVENGERS club ID
  'admin'
);

-- Also add student as AIVENGERS member
INSERT INTO public.club_members (user_id, club_id, role)
VALUES (
  'REPLACE_WITH_STUDENT_UUID'::uuid,  -- <-- Same as above!
  'a1111111-1111-1111-1111-111111111111'::uuid,  -- AIVENGERS club ID
  'member'
);

-- ============================================
-- SUCCESS MESSAGE
-- ============================================
SELECT '✅ Demo users created successfully!' as message;
SELECT 'Login credentials:' as info;
SELECT '  student@mvgrce.edu.in / Demo@123 (Student)' as account;
SELECT '  clubadmin@mvgrce.edu.in / Demo@123 (Club Admin)' as account;
SELECT '  council@mvgrce.edu.in / Demo@123 (Council)' as account;
SELECT '  faculty@mvgrce.edu.in / Demo@123 (Faculty)' as account;
