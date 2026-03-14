-- ============================================
-- MVGR NexUs Database Setup
-- File: 10_storage.sql
-- Purpose: Storage buckets and policies
-- Run Order: 11
-- ============================================

-- ============================================
-- SECTION 1: CREATE STORAGE BUCKETS
-- ============================================

-- Profile photos bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'profiles', 
    'profiles', 
    true,
    5242880,  -- 5MB limit
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']
)
ON CONFLICT (id) DO NOTHING;

-- Club logos and covers
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'clubs', 
    'clubs', 
    true,
    10485760,  -- 10MB limit
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']
)
ON CONFLICT (id) DO NOTHING;

-- Event images
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'events', 
    'events', 
    true,
    10485760,  -- 10MB limit
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']
)
ON CONFLICT (id) DO NOTHING;

-- Vault files (study materials)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'vault', 
    'vault', 
    true,
    52428800,  -- 50MB limit
    ARRAY['application/pdf', 'image/jpeg', 'image/png', 'application/msword', 
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
          'application/vnd.ms-powerpoint',
          'application/vnd.openxmlformats-officedocument.presentationml.presentation']
)
ON CONFLICT (id) DO NOTHING;

-- Lost & Found images
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'lost-found', 
    'lost-found', 
    true,
    5242880,  -- 5MB limit
    ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- Radio tracks and covers
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'radio', 
    'radio', 
    true,
    52428800,  -- 50MB limit for audio
    ARRAY['audio/mpeg', 'audio/mp3', 'audio/wav', 'audio/ogg', 'image/jpeg', 'image/png']
)
ON CONFLICT (id) DO NOTHING;

-- User avatars (alias for profiles)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'avatars', 
    'avatars', 
    true,
    5242880,  -- 5MB limit
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']
)
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- SECTION 2: STORAGE POLICIES
-- ============================================

-- PROFILES BUCKET --

-- Anyone can view profile photos
CREATE POLICY "profiles_select_public" ON storage.objects
    FOR SELECT USING (bucket_id = 'profiles');

-- Authenticated users can upload their photos
CREATE POLICY "profiles_insert_auth" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'profiles' AND 
        auth.role() = 'authenticated'
    );

-- Users can update their own photos
CREATE POLICY "profiles_update_own" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'profiles' AND 
        auth.role() = 'authenticated'
    );

-- Users can delete their own photos
CREATE POLICY "profiles_delete_own" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'profiles' AND 
        auth.role() = 'authenticated'
    );

-- CLUBS BUCKET --

CREATE POLICY "clubs_select_public" ON storage.objects
    FOR SELECT USING (bucket_id = 'clubs');

CREATE POLICY "clubs_insert_auth" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'clubs' AND 
        auth.role() = 'authenticated'
    );

CREATE POLICY "clubs_update_auth" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'clubs' AND 
        auth.role() = 'authenticated'
    );

CREATE POLICY "clubs_delete_auth" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'clubs' AND 
        auth.role() = 'authenticated'
    );

-- EVENTS BUCKET --

CREATE POLICY "events_select_public" ON storage.objects
    FOR SELECT USING (bucket_id = 'events');

CREATE POLICY "events_insert_auth" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'events' AND 
        auth.role() = 'authenticated'
    );

CREATE POLICY "events_update_auth" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'events' AND 
        auth.role() = 'authenticated'
    );

CREATE POLICY "events_delete_auth" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'events' AND 
        auth.role() = 'authenticated'
    );

-- VAULT BUCKET --

CREATE POLICY "vault_select_public" ON storage.objects
    FOR SELECT USING (bucket_id = 'vault');

CREATE POLICY "vault_insert_auth" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'vault' AND 
        auth.role() = 'authenticated'
    );

CREATE POLICY "vault_update_auth" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'vault' AND 
        auth.role() = 'authenticated'
    );

CREATE POLICY "vault_delete_auth" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'vault' AND 
        auth.role() = 'authenticated'
    );

-- LOST-FOUND BUCKET --

CREATE POLICY "lost_found_select_public" ON storage.objects
    FOR SELECT USING (bucket_id = 'lost-found');

CREATE POLICY "lost_found_insert_auth" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'lost-found' AND 
        auth.role() = 'authenticated'
    );

CREATE POLICY "lost_found_update_auth" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'lost-found' AND 
        auth.role() = 'authenticated'
    );

CREATE POLICY "lost_found_delete_auth" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'lost-found' AND 
        auth.role() = 'authenticated'
    );

-- Success message
SELECT '✅ Storage buckets and policies created: profiles, clubs, events, vault, lost-found' as status;
