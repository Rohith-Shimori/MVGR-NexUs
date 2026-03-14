-- ============================================
-- QUICK FIX: Column Mismatches
-- Run this in Supabase SQL Editor
-- ============================================

-- 1. Add is_active to team_requests (Dart expects this)
ALTER TABLE public.team_requests 
ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE;

-- 2. Add is_active to study_requests (Dart expects this)
ALTER TABLE public.study_requests 
ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE;

-- 3. Add is_resolved to lost_found_items (Dart expects this)
ALTER TABLE public.lost_found_items 
ADD COLUMN IF NOT EXISTS is_resolved BOOLEAN DEFAULT FALSE;

-- 4. Rename scheduled_at to date_time on meetups (Dart expects date_time)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'meetups' AND column_name = 'scheduled_at'
    ) THEN
        ALTER TABLE public.meetups RENAME COLUMN scheduled_at TO date_time;
    END IF;
END $$;

-- 5. Fix RLS policy for users table (allow insert on signup)
DROP POLICY IF EXISTS "users_insert_own" ON public.users;
CREATE POLICY "users_insert_own" ON public.users
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Also allow the trigger to insert (SECURITY DEFINER handles this, but just in case)
DROP POLICY IF EXISTS "users_insert_trigger" ON public.users;
CREATE POLICY "users_insert_trigger" ON public.users
    FOR INSERT WITH CHECK (true);

-- Success
SELECT '✅ Column fixes applied!' as status;
