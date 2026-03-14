-- ============================================
-- MVGR NexUs Database Setup
-- File: 06b_schema_extras.sql
-- Purpose: Feedback, Radio, Mentorship Sessions
-- Run Order: 7b (After 06_schema_community.sql)
-- ============================================

-- ============================================
-- FEEDBACK SUBMISSIONS TABLE
-- Bug reports, feature requests from users
-- ============================================

CREATE TABLE public.feedback_submissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Reporter
    user_id UUID NOT NULL REFERENCES auth.users(id),
    user_name TEXT,
    user_email TEXT,
    
    -- Type and category
    type TEXT NOT NULL CHECK (type IN ('bug', 'feature', 'general')),
    category TEXT,
    
    -- Content
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    priority TEXT DEFAULT 'medium' 
        CHECK (priority IN ('low', 'medium', 'high', 'critical')),
    
    -- Bug-specific fields
    device_info JSONB,
    steps_to_reproduce TEXT,
    expected_behavior TEXT,
    actual_behavior TEXT,
    
    -- Status workflow
    status TEXT DEFAULT 'submitted' 
        CHECK (status IN ('submitted', 'in_review', 'planned', 'in_progress', 'completed', 'wont_fix')),
    
    -- Resolution
    admin_notes TEXT,
    resolved_at TIMESTAMPTZ,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.feedback_submissions IS 'User feedback, bug reports, feature requests';

-- ============================================
-- RADIO TRACKS TABLE
-- Music/audio tracks for campus radio
-- ============================================

CREATE TABLE public.radio_tracks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Track info
    title TEXT NOT NULL,
    artist TEXT NOT NULL,
    album TEXT,
    genre TEXT DEFAULT 'other',
    
    -- Files
    audio_url TEXT NOT NULL,
    cover_url TEXT,
    duration_seconds INTEGER,
    
    -- Uploader
    uploaded_by UUID NOT NULL REFERENCES auth.users(id),
    uploader_name TEXT,
    
    -- Stats
    play_count INTEGER DEFAULT 0,
    like_count INTEGER DEFAULT 0,
    
    -- Moderation
    is_approved BOOLEAN DEFAULT FALSE,
    
    -- Timestamp
    created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.radio_tracks IS 'Campus radio track library';

-- ============================================
-- USER LIKED TRACKS
-- Track which users liked which tracks
-- ============================================

CREATE TABLE public.user_liked_tracks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Links
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    track_id UUID NOT NULL REFERENCES public.radio_tracks(id) ON DELETE CASCADE,
    
    -- Timestamp
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Prevent duplicate likes
    UNIQUE(user_id, track_id)
);

COMMENT ON TABLE public.user_liked_tracks IS 'User liked tracks for radio';

-- ============================================
-- MENTORSHIP SESSIONS TABLE
-- Scheduled mentorship meetings
-- ============================================

CREATE TABLE public.mentorship_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Participants
    mentor_id UUID NOT NULL REFERENCES public.mentors(id) ON DELETE CASCADE,
    mentee_id UUID NOT NULL REFERENCES auth.users(id),
    mentee_name TEXT NOT NULL,
    
    -- Session details
    topic TEXT NOT NULL,
    description TEXT,
    scheduled_at TIMESTAMPTZ NOT NULL,
    duration_minutes INTEGER DEFAULT 30,
    meeting_link TEXT,
    
    -- Status
    status TEXT DEFAULT 'pending' 
        CHECK (status IN ('pending', 'confirmed', 'completed', 'cancelled')),
    
    -- Post-session
    notes TEXT,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    feedback TEXT,
    
    -- Timestamp
    created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.mentorship_sessions IS 'Mentor-mentee scheduled sessions';

-- ============================================
-- RLS POLICIES FOR NEW TABLES
-- ============================================

ALTER TABLE public.feedback_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.radio_tracks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_liked_tracks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mentorship_sessions ENABLE ROW LEVEL SECURITY;

-- Feedback: users see own, can submit
CREATE POLICY "feedback_select_own" ON public.feedback_submissions
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "feedback_insert_auth" ON public.feedback_submissions
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Radio: view approved, submit own
CREATE POLICY "radio_select_approved" ON public.radio_tracks
    FOR SELECT USING (is_approved = true OR auth.uid() = uploaded_by);
CREATE POLICY "radio_insert_auth" ON public.radio_tracks
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Liked tracks: manage own
CREATE POLICY "liked_tracks_select_all" ON public.user_liked_tracks
    FOR SELECT USING (true);
CREATE POLICY "liked_tracks_insert_auth" ON public.user_liked_tracks
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "liked_tracks_delete_own" ON public.user_liked_tracks
    FOR DELETE USING (auth.uid() = user_id);

-- Mentorship sessions
CREATE POLICY "sessions_select_own" ON public.mentorship_sessions
    FOR SELECT USING (auth.uid() = mentee_id);
CREATE POLICY "sessions_insert_auth" ON public.mentorship_sessions
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- ============================================
-- HELPER FUNCTIONS FOR RADIO
-- ============================================

CREATE OR REPLACE FUNCTION public.increment_play_count(p_track_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE public.radio_tracks
    SET play_count = play_count + 1
    WHERE id = p_track_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- ESCALATIONS TABLE
-- Faculty escalation handling for disputes, misconduct, etc.
-- ============================================

CREATE TABLE IF NOT EXISTS public.escalations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Content
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('dispute', 'misconduct', 'appeal', 'other')),
    priority TEXT NOT NULL CHECK (priority IN ('urgent', 'high', 'medium', 'low')),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'resolved')),
    
    -- Submitter
    submitted_by TEXT NOT NULL,
    submitted_by_id UUID REFERENCES auth.users(id),
    
    -- Assignment
    assigned_to UUID REFERENCES auth.users(id),
    
    -- Resolution
    resolution TEXT,
    resolved_at TIMESTAMPTZ,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.escalations IS 'Faculty escalation queue for disputes, misconduct, appeals';

ALTER TABLE public.escalations ENABLE ROW LEVEL SECURITY;

-- Only faculty/admin can view escalations
CREATE POLICY "escalations_select_faculty" ON public.escalations
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() 
            AND role IN ('faculty', 'admin', 'council')
        )
    );

-- Authenticated users can submit escalations
CREATE POLICY "escalations_insert_auth" ON public.escalations
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Faculty can update escalations
CREATE POLICY "escalations_update_faculty" ON public.escalations
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() 
            AND role IN ('faculty', 'admin')
        )
    );

-- ============================================
-- ANALYTICS EVENTS TABLE
-- Stores app analytics and user behavior tracking
-- ============================================

CREATE TABLE IF NOT EXISTS public.analytics_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_name TEXT NOT NULL,
    parameters JSONB,
    user_id UUID REFERENCES auth.users(id),
    user_properties JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.analytics_events IS 'Analytics events for usage tracking';

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_analytics_events_name ON public.analytics_events(event_name);
CREATE INDEX IF NOT EXISTS idx_analytics_events_user ON public.analytics_events(user_id);
CREATE INDEX IF NOT EXISTS idx_analytics_events_created ON public.analytics_events(created_at);

ALTER TABLE public.analytics_events ENABLE ROW LEVEL SECURITY;

-- Only the user can view their own analytics events (or admin)
CREATE POLICY "analytics_insert_auth" ON public.analytics_events
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Success message
SELECT '✅ Extra schema created: feedback_submissions, radio_tracks, user_liked_tracks, mentorship_sessions, escalations, analytics_events' as status;

