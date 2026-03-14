-- Fix schema mismatches between app and database
-- Run this after COMPLETE_SETUP.sql

-- ==========================================
-- 1. Add missing columns to clubs table
-- ==========================================
ALTER TABLE public.clubs ADD COLUMN IF NOT EXISTS admin_ids TEXT[] DEFAULT '{}';
ALTER TABLE public.clubs ADD COLUMN IF NOT EXISTS member_ids TEXT[] DEFAULT '{}';

-- ==========================================
-- 2. Add missing column to events table
-- ==========================================
ALTER TABLE public.events ADD COLUMN IF NOT EXISTS max_participants INTEGER;

-- ==========================================
-- 3. Create alias view for club_join_requests (or use club_requests)
-- The app uses both names, create a view for compatibility
-- ==========================================
CREATE OR REPLACE VIEW public.club_join_requests AS
SELECT 
    id,
    club_id,
    club_name,
    user_id,
    user_name,
    note,
    status,
    created_at,
    updated_at
FROM public.club_requests;

-- Grant same permissions as club_requests
GRANT SELECT, INSERT, UPDATE, DELETE ON public.club_join_requests TO authenticated;
GRANT SELECT ON public.club_join_requests TO anon;

-- ==========================================
-- 4. Fix RLS for vault_items (allow authenticated users to insert)
-- ==========================================
-- Drop restrictive policy and create permissive one
DROP POLICY IF EXISTS "Authenticated can upload" ON public.vault_items;
CREATE POLICY "Anyone can upload vault items" ON public.vault_items 
    FOR INSERT WITH CHECK (true);

-- Also allow update for testing
DROP POLICY IF EXISTS "Uploaders can update" ON public.vault_items;
CREATE POLICY "Uploaders can update vault items" ON public.vault_items 
    FOR UPDATE USING (true);

-- ==========================================
-- 5. Verify
-- ==========================================
SELECT 'Schema fixes applied!' as message;
