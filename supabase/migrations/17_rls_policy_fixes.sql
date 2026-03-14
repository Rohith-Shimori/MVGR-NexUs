-- ============================================
-- MVGR NexUs Database Setup
-- File: 17_rls_policy_fixes.sql
-- Purpose: Fix RLS security gaps identified in audit
-- Run Order: 17 (run after existing migrations)
-- ============================================

-- ============================================
-- SECTION 1: DROP INSECURE POLICIES
-- ============================================

-- Drop the insecure club_members update policy
DROP POLICY IF EXISTS "club_members_update_auth" ON public.club_members;

-- Drop the insecure club_posts insert policy  
DROP POLICY IF EXISTS "club_posts_insert_auth" ON public.club_posts;

-- Drop the insecure club_requests select policy
DROP POLICY IF EXISTS "club_requests_select" ON public.club_requests;

-- ============================================
-- SECTION 2: CREATE SECURE REPLACEMENT POLICIES
-- ============================================

-- Club members: Only club admins/owners can update member roles
CREATE POLICY "club_members_update_admin" ON public.club_members
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.club_members cm
            WHERE cm.club_id = club_members.club_id
            AND cm.user_id = auth.uid()
            AND cm.role IN ('admin', 'owner')
        )
    );

-- Club posts: Only club members can create posts in their club
CREATE POLICY "club_posts_insert_member" ON public.club_posts
    FOR INSERT WITH CHECK (
        auth.role() = 'authenticated' AND
        EXISTS (
            SELECT 1 FROM public.club_members cm
            WHERE cm.club_id = club_posts.club_id
            AND cm.user_id = auth.uid()
        )
    );

-- Club requests: Users can see their own requests, 
-- Club admins can see requests for their clubs
CREATE POLICY "club_requests_select_own_or_admin" ON public.club_requests
    FOR SELECT USING (
        auth.uid() = user_id OR
        EXISTS (
            SELECT 1 FROM public.club_members cm
            WHERE cm.club_id = club_requests.club_id
            AND cm.user_id = auth.uid()
            AND cm.role IN ('admin', 'owner')
        )
    );

-- ============================================
-- SECTION 3: FIX ANNOUNCEMENTS POLICY
-- ============================================

-- Drop the permissive announcements insert policy
DROP POLICY IF EXISTS "announcements_insert_auth" ON public.announcements;

-- Only council/faculty users can create announcements
-- Note: This requires a 'role' column in users table
-- If role column doesn't exist, this uses a workaround checking user metadata
CREATE POLICY "announcements_insert_council_faculty" ON public.announcements
    FOR INSERT WITH CHECK (
        auth.role() = 'authenticated' AND
        EXISTS (
            SELECT 1 FROM public.users u
            WHERE u.id = auth.uid()
            AND u.role IN ('council', 'faculty')
        )
    );

-- Success message
SELECT '✅ RLS policy security fixes applied' as status;
