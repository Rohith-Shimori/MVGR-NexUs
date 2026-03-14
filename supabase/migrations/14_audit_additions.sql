-- ============================================
-- 14_audit_additions.sql
-- New tables and policies from the audit fixes
-- Safe to run multiple times (uses IF NOT EXISTS)
-- Run Order: After all existing migrations
-- ============================================

-- ============================================
-- 1. ESCALATIONS TABLE (Faculty Escalation System)
-- ============================================
CREATE TABLE IF NOT EXISTS public.escalations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('dispute', 'misconduct', 'appeal', 'other')),
    priority TEXT NOT NULL CHECK (priority IN ('urgent', 'high', 'medium', 'low')),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'resolved')),
    submitted_by TEXT NOT NULL,
    submitted_by_id UUID REFERENCES auth.users(id),
    assigned_to TEXT,
    resolution TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    resolved_at TIMESTAMPTZ
);

-- Enable RLS
ALTER TABLE public.escalations ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist, then create new ones
DROP POLICY IF EXISTS "escalations_faculty_select" ON public.escalations;
DROP POLICY IF EXISTS "escalations_insert_authenticated" ON public.escalations;
DROP POLICY IF EXISTS "escalations_faculty_update" ON public.escalations;

-- Faculty can view all escalations
CREATE POLICY "escalations_faculty_select" ON public.escalations
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.users
            WHERE users.id = auth.uid()
            AND users.role = 'faculty'
        )
    );

-- Any authenticated user can submit an escalation
CREATE POLICY "escalations_insert_authenticated" ON public.escalations
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- Faculty can update escalations (resolve, assign)
CREATE POLICY "escalations_faculty_update" ON public.escalations
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.users
            WHERE users.id = auth.uid()
            AND users.role = 'faculty'
        )
    );

-- ============================================
-- 2. ANALYTICS EVENTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.analytics_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_name TEXT NOT NULL,
    parameters JSONB DEFAULT '{}',
    user_id UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.analytics_events ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "analytics_insert_authenticated" ON public.analytics_events;
DROP POLICY IF EXISTS "analytics_select_own" ON public.analytics_events;

-- Allow authenticated users to insert their own analytics
CREATE POLICY "analytics_insert_authenticated" ON public.analytics_events
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- Users can only view their own analytics (admins can view all via service role)
CREATE POLICY "analytics_select_own" ON public.analytics_events
    FOR SELECT USING (user_id = auth.uid());

-- ============================================
-- 3. FIX OVERLY PERMISSIVE CLUB POLICIES
-- ============================================
-- Drop the old permissive policies
DROP POLICY IF EXISTS "clubs_update_all" ON public.clubs;
DROP POLICY IF EXISTS "clubs_delete_all" ON public.clubs;

-- Create secure policies with ownership checks
DO $$
BEGIN
    -- Only create if they don't exist
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'clubs_update_owner' AND tablename = 'clubs') THEN
        CREATE POLICY "clubs_update_owner" ON public.clubs
            FOR UPDATE USING (
                created_by = auth.uid() 
                OR EXISTS (
                    SELECT 1 FROM public.users 
                    WHERE users.id = auth.uid() 
                    AND users.role IN ('admin', 'faculty')
                )
            );
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'clubs_delete_owner' AND tablename = 'clubs') THEN
        CREATE POLICY "clubs_delete_owner" ON public.clubs
            FOR DELETE USING (
                created_by = auth.uid() 
                OR EXISTS (
                    SELECT 1 FROM public.users 
                    WHERE users.id = auth.uid() 
                    AND users.role IN ('admin', 'faculty')
                )
            );
    END IF;
END $$;

-- ============================================
-- 4. CREATE INDEXES FOR PERFORMANCE
-- ============================================
CREATE INDEX IF NOT EXISTS idx_escalations_status ON public.escalations(status);
CREATE INDEX IF NOT EXISTS idx_escalations_created_at ON public.escalations(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_analytics_user_id ON public.analytics_events(user_id);
CREATE INDEX IF NOT EXISTS idx_analytics_created_at ON public.analytics_events(created_at DESC);

-- ============================================
-- DONE!
-- ============================================
DO $$ 
BEGIN 
    RAISE NOTICE '✅ Audit additions migration completed successfully!';
    RAISE NOTICE '   - escalations table created';
    RAISE NOTICE '   - analytics_events table created';
    RAISE NOTICE '   - club policies secured';
END $$;
