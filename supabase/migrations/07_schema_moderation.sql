-- ============================================
-- MVGR NexUs Database Setup
-- File: 07_schema_moderation.sql
-- Purpose: Content moderation and reports
-- Run Order: 8
-- ============================================

-- CONTENT REPORTS TABLE
-- User reports for content moderation
-- NOTE: Table named 'content_reports' to match Dart service
CREATE TABLE public.content_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Reporter
    reporter_id UUID NOT NULL REFERENCES auth.users(id),
    
    -- What's being reported
    content_type TEXT NOT NULL CHECK (content_type IN ('club', 'event', 'forum_post', 'comment', 'user', 'other')),
    content_id TEXT NOT NULL,
    
    -- Reason for report
    reason TEXT NOT NULL CHECK (reason IN ('spam', 'harassment', 'inappropriateContent', 'violatesGuidelines', 'impersonation', 'misinformation', 'other')),
    additional_details TEXT,
    
    -- Status workflow
    -- pending: New report, needs review
    -- underReview: Council/faculty looking at it
    -- actionTaken: Action taken
    -- dismissed: Not a violation
    status TEXT NOT NULL DEFAULT 'pending' 
        CHECK (status IN ('pending', 'underReview', 'actionTaken', 'dismissed')),
    
    -- Resolution
    reviewer_id UUID REFERENCES auth.users(id),
    action_notes TEXT,
    reviewed_at TIMESTAMPTZ,
    
    -- Timestamp
    created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.content_reports IS 'User content reports for moderation';

-- Success message
SELECT '✅ Moderation schema created: content_reports' as status;
