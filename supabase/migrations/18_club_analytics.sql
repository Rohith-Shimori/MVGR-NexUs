-- ============================================
-- MVGR NexUs Database Setup
-- File: 18_club_analytics.sql
-- Purpose: Track engagement metrics for clubs
-- Run Order: 18
-- ============================================

-- CLUB ANALYTICS TABLE
CREATE TABLE IF NOT EXISTS public.club_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    club_id UUID NOT NULL REFERENCES public.clubs(id) ON DELETE CASCADE,
    
    -- Metrics
    views_count INTEGER DEFAULT 0,
    clicks_count INTEGER DEFAULT 0,
    joins_count INTEGER DEFAULT 0,
    
    -- Snapshots (daily/weekly tracking)
    snapshot_date DATE DEFAULT CURRENT_DATE,
    
    -- Constraints
    UNIQUE(club_id, snapshot_date)
);

-- RLS POLICIES
ALTER TABLE public.club_analytics ENABLE ROW LEVEL SECURITY;

-- Anyone can see analytics for approved clubs
CREATE POLICY "club_analytics_select_public" ON public.club_analytics
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.clubs c
            WHERE c.id = club_analytics.club_id
            AND c.is_approved = true
        )
    );

-- Only system/authenticated users can increment counts
-- Note: In a real app, this would be handled via a secure RPC function
-- to prevent users from spamming analytics.
CREATE POLICY "club_analytics_update_auth" ON public.club_analytics
    FOR UPDATE USING (auth.role() = 'authenticated');

-- FUNCTIONS FOR ANALYTICS
CREATE OR REPLACE FUNCTION public.increment_club_view(p_club_id UUID)
RETURNS VOID AS $$
BEGIN
    INSERT INTO public.club_analytics (club_id, views_count)
    VALUES (p_club_id, 1)
    ON CONFLICT (club_id, snapshot_date)
    DO UPDATE SET views_count = public.club_analytics.views_count + 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Success message
SELECT '✅ Club analytics table and functions created' as status;
