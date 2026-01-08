-- ============================================
-- MVGR NexUs - Events, Announcements, Vault Items
-- Run AFTER demo_users.sql (need valid author_id)
-- 
-- Replace CLUBADMIN_UUID with actual clubadmin user ID
-- ============================================

-- ============================================
-- 1. SAMPLE EVENTS (use club admin as author)
-- ============================================
INSERT INTO public.events (
  id, title, description, club_id, club_name,
  author_id, author_name, event_date, end_date, venue,
  category, requires_registration, is_online, created_at
) VALUES 
(
  'e1111111-1111-1111-1111-111111111111'::uuid,
  'AI/ML Workshop Series',
  'Hands-on workshop covering Machine Learning fundamentals, neural networks, and practical implementations using Python and TensorFlow. Perfect for beginners and intermediates alike!',
  'a1111111-1111-1111-1111-111111111111'::uuid,
  'AIVENGERS',
  'REPLACE_WITH_CLUBADMIN_UUID'::uuid,  -- <-- Replace!
  'AIVENGERS Team',
  NOW() + INTERVAL '7 days',
  NOW() + INTERVAL '7 days' + INTERVAL '3 hours',
  'AI Lab, Block C',
  'workshop',
  true,
  false,
  NOW()
),
(
  'e2222222-2222-2222-2222-222222222222'::uuid, 
  'Hackathon: Build with AI',
  '24-hour hackathon focused on building AI-powered solutions. Form teams, build projects, win prizes! Top projects get incubation support. 🏆',
  'a1111111-1111-1111-1111-111111111111'::uuid,
  'AIVENGERS',
  'REPLACE_WITH_CLUBADMIN_UUID'::uuid,  -- <-- Replace!
  'AIVENGERS Team',
  NOW() + INTERVAL '14 days',
  NOW() + INTERVAL '15 days',
  'Innovation Hub',
  'hackathon',
  true,
  false,
  NOW()
),
(
  'e3333333-3333-3333-3333-333333333333'::uuid,
  'Tech Talk: LLMs & The Future',
  'Special talk on Large Language Models, ChatGPT, and how AI is transforming industries. Guest speaker from the AI industry.',
  'a1111111-1111-1111-1111-111111111111'::uuid,
  'AIVENGERS',
  'REPLACE_WITH_CLUBADMIN_UUID'::uuid,  -- <-- Replace!
  'AIVENGERS Team',
  NOW() + INTERVAL '3 days',
  NOW() + INTERVAL '3 days' + INTERVAL '2 hours',
  'Auditorium',
  'seminar',
  false,
  false,
  NOW()
);

-- ============================================
-- 2. SAMPLE ANNOUNCEMENTS (use council as author)
-- ============================================
INSERT INTO public.announcements (
  id, title, content, author_id, author_name, source,
  is_pinned, is_urgent, created_at
) VALUES
(
  'f1111111-1111-1111-1111-111111111111'::uuid,
  'Welcome to MVGR NexUs! 🎉',
  'The official campus app is now live! Connect with clubs, discover events, find study buddies, and more. Download now and explore all the features.',
  'REPLACE_WITH_COUNCIL_UUID'::uuid,  -- <-- Replace!
  'Student Council',
  'Council',
  true,
  false,
  NOW()
),
(
  'f2222222-2222-2222-2222-222222222222'::uuid,
  'Mid-Semester Exam Schedule Released',
  'The mid-semester examination schedule has been published. Please check the academic portal for your exam dates and timings.',
  'REPLACE_WITH_FACULTY_UUID'::uuid,  -- <-- Replace!
  'Academic Office',
  'Faculty',
  false,
  true,
  NOW() - INTERVAL '1 day'
);

-- ============================================
-- 3. SAMPLE VAULT ITEMS
-- ============================================
INSERT INTO public.vault_items (
  id, title, description, file_url, file_name, file_size_bytes,
  type, subject, branch, year, semester, tags,
  uploader_id, uploader_name, is_approved, download_count, created_at
) VALUES
(
  'aaaa1111-1111-1111-1111-111111111111'::uuid,
  'Data Structures Complete Notes',
  'Comprehensive notes covering arrays, linked lists, trees, graphs, and algorithms with examples.',
  'https://example.com/ds-notes.pdf',
  'DS_Notes.pdf',
  2500000,
  'notes',
  'Data Structures',
  'CSE',
  2,
  3,
  ARRAY['DSA', 'algorithms', 'trees', 'graphs'],
  'REPLACE_WITH_STUDENT_UUID'::uuid,  -- <-- Replace!
  'Student Contributor',
  true,
  42,
  NOW()
),
(
  'bbbb2222-2222-2222-2222-222222222222'::uuid,
  'DBMS Previous Year Questions',
  'Collection of previous year question papers for Database Management Systems (2020-2024).',
  'https://example.com/dbms-pyq.pdf',
  'DBMS_PYQ.pdf',
  1800000,
  'pyq',
  'Database Management',
  'CSE',
  2,
  4,
  ARRAY['DBMS', 'SQL', 'important'],
  'REPLACE_WITH_STUDENT_UUID'::uuid,  -- <-- Replace!
  'Senior Student',
  true,
  78,
  NOW()
);

-- ============================================
-- SUCCESS MESSAGE
-- ============================================
SELECT '✅ Events, announcements, and vault items added!' as message;
