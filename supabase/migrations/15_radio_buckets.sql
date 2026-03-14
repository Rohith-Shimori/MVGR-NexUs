-- ============================================
-- 15_radio_buckets.sql
-- Create radio-tracks and radio-covers storage buckets
-- Safe to run multiple times (uses ON CONFLICT DO NOTHING)
-- ============================================

-- Radio tracks bucket (audio files)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'radio-tracks', 
    'radio-tracks', 
    true,
    52428800,  -- 50MB limit for audio
    ARRAY['audio/mpeg', 'audio/mp3', 'audio/wav', 'audio/ogg', 'audio/x-m4a', 'audio/aac']
)
ON CONFLICT (id) DO NOTHING;

-- Radio covers bucket (album art)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'radio-covers', 
    'radio-covers', 
    true,
    5242880,  -- 5MB limit for images
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']
)
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- STORAGE POLICIES FOR RADIO BUCKETS
-- ============================================

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "radio_tracks_select_public" ON storage.objects;
DROP POLICY IF EXISTS "radio_tracks_insert_auth" ON storage.objects;
DROP POLICY IF EXISTS "radio_tracks_update_auth" ON storage.objects;
DROP POLICY IF EXISTS "radio_tracks_delete_auth" ON storage.objects;
DROP POLICY IF EXISTS "radio_covers_select_public" ON storage.objects;
DROP POLICY IF EXISTS "radio_covers_insert_auth" ON storage.objects;
DROP POLICY IF EXISTS "radio_covers_update_auth" ON storage.objects;
DROP POLICY IF EXISTS "radio_covers_delete_auth" ON storage.objects;

-- RADIO-TRACKS BUCKET --

-- Anyone can listen to tracks
CREATE POLICY "radio_tracks_select_public" ON storage.objects
    FOR SELECT USING (bucket_id = 'radio-tracks');

-- Authenticated users can upload tracks
CREATE POLICY "radio_tracks_insert_auth" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'radio-tracks' AND 
        auth.role() = 'authenticated'
    );

-- Authenticated users can update their uploads
CREATE POLICY "radio_tracks_update_auth" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'radio-tracks' AND 
        auth.role() = 'authenticated'
    );

-- Authenticated users can delete their uploads
CREATE POLICY "radio_tracks_delete_auth" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'radio-tracks' AND 
        auth.role() = 'authenticated'
    );

-- RADIO-COVERS BUCKET --

-- Anyone can view covers
CREATE POLICY "radio_covers_select_public" ON storage.objects
    FOR SELECT USING (bucket_id = 'radio-covers');

-- Authenticated users can upload covers
CREATE POLICY "radio_covers_insert_auth" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'radio-covers' AND 
        auth.role() = 'authenticated'
    );

-- Authenticated users can update covers
CREATE POLICY "radio_covers_update_auth" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'radio-covers' AND 
        auth.role() = 'authenticated'
    );

-- Authenticated users can delete covers
CREATE POLICY "radio_covers_delete_auth" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'radio-covers' AND 
        auth.role() = 'authenticated'
    );

-- Success message
DO $$ 
BEGIN 
    RAISE NOTICE '✅ Radio storage buckets created: radio-tracks, radio-covers';
END $$;
