-- ============================================
-- MVGR NexUs - Storage Buckets Setup
-- Run this in Supabase SQL Editor
-- ============================================

-- Create storage buckets for file uploads
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES 
  ('profile-photos', 'profile-photos', true, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp']),
  ('club-logos', 'club-logos', true, 2097152, ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/svg+xml']),
  ('club-covers', 'club-covers', true, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp']),
  ('event-images', 'event-images', true, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp']),
  ('vault-files', 'vault-files', true, 52428800, ARRAY['application/pdf', 'image/jpeg', 'image/png', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document']),
  ('lost-found-images', 'lost-found-images', true, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp']),
  ('announcement-images', 'announcement-images', true, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp'])
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- Storage RLS Policies
-- ============================================

-- Profile Photos: Anyone can view, users can upload their own
CREATE POLICY "Profile photos are publicly viewable"
ON storage.objects FOR SELECT
USING (bucket_id = 'profile-photos');

CREATE POLICY "Users can upload their own profile photo"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'profile-photos' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can update their own profile photo"
ON storage.objects FOR UPDATE
USING (bucket_id = 'profile-photos' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Club Logos: Anyone can view, club admins can upload
CREATE POLICY "Club logos are publicly viewable"
ON storage.objects FOR SELECT
USING (bucket_id = 'club-logos');

CREATE POLICY "Authenticated users can upload club logos"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'club-logos' AND auth.role() = 'authenticated');

-- Club Covers: Anyone can view, club admins can upload
CREATE POLICY "Club covers are publicly viewable"
ON storage.objects FOR SELECT
USING (bucket_id = 'club-covers');

CREATE POLICY "Authenticated users can upload club covers"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'club-covers' AND auth.role() = 'authenticated');

-- Event Images: Anyone can view, authenticated users can upload
CREATE POLICY "Event images are publicly viewable"
ON storage.objects FOR SELECT
USING (bucket_id = 'event-images');

CREATE POLICY "Authenticated users can upload event images"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'event-images' AND auth.role() = 'authenticated');

-- Vault Files: Anyone can view, authenticated users can upload
CREATE POLICY "Vault files are publicly viewable"
ON storage.objects FOR SELECT
USING (bucket_id = 'vault-files');

CREATE POLICY "Authenticated users can upload vault files"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'vault-files' AND auth.role() = 'authenticated');

-- Lost & Found Images: Anyone can view, authenticated users can upload
CREATE POLICY "Lost found images are publicly viewable"
ON storage.objects FOR SELECT
USING (bucket_id = 'lost-found-images');

CREATE POLICY "Authenticated users can upload lost found images"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'lost-found-images' AND auth.role() = 'authenticated');

-- Announcement Images: Anyone can view, council/faculty can upload
CREATE POLICY "Announcement images are publicly viewable"
ON storage.objects FOR SELECT
USING (bucket_id = 'announcement-images');

CREATE POLICY "Authenticated users can upload announcement images"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'announcement-images' AND auth.role() = 'authenticated');

-- ============================================
-- Enable Realtime for tables
-- ============================================
ALTER PUBLICATION supabase_realtime ADD TABLE public.clubs;
ALTER PUBLICATION supabase_realtime ADD TABLE public.events;
ALTER PUBLICATION supabase_realtime ADD TABLE public.announcements;
ALTER PUBLICATION supabase_realtime ADD TABLE public.club_posts;
ALTER PUBLICATION supabase_realtime ADD TABLE public.event_rsvps;

SELECT '✅ Storage buckets and realtime enabled!' as message;
