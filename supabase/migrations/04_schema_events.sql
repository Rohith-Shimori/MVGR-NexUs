-- ============================================
-- MVGR NexUs Database Setup
-- File: 04_schema_events.sql
-- Purpose: Events and RSVPs
-- Run Order: 5
-- ============================================

-- EVENTS TABLE
-- Campus events: workshops, hackathons, cultural events, etc.
CREATE TABLE public.events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Basic info
    title TEXT NOT NULL,
    description TEXT,
    
    -- Organizer (can be club or individual)
    club_id UUID REFERENCES public.clubs(id) ON DELETE SET NULL,
    club_name TEXT,  -- Denormalized
    author_id UUID NOT NULL REFERENCES auth.users(id),
    author_name TEXT NOT NULL,
    
    -- Event timing
    event_date TIMESTAMPTZ NOT NULL,
    end_date TIMESTAMPTZ,
    
    -- Location
    venue TEXT,
    is_online BOOLEAN DEFAULT FALSE,
    meeting_link TEXT,
    
    -- Category
    category TEXT NOT NULL DEFAULT 'other' 
        CHECK (category IN (
            'academic', 'cultural', 'sports', 'hackathon', 
            'workshop', 'seminar', 'competition', 'other'
        )),
    
    -- Media
    image_url TEXT,
    
    -- Registration
    requires_registration BOOLEAN DEFAULT FALSE,
    registration_link TEXT,
    max_capacity INTEGER,
    
    -- Counters (denormalized for performance)
    rsvp_count INTEGER DEFAULT 0,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.events IS 'Campus events and activities';

-- ============================================

-- EVENT RSVPS (Junction Table: Users ↔ Events)
-- Tracks who is attending which event
CREATE TABLE public.event_rsvps (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Foreign keys
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    event_id UUID NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
    
    -- Denormalized
    user_name TEXT NOT NULL,
    
    -- Status
    -- going: Confirmed attendance
    -- interested: Maybe attending
    -- checked_in: Verified at venue
    status TEXT NOT NULL DEFAULT 'going' 
        CHECK (status IN ('going', 'interested', 'checked_in')),
    
    -- Timestamps
    rsvp_at TIMESTAMPTZ DEFAULT NOW(),
    checked_in_at TIMESTAMPTZ,
    
    -- Each user can only RSVP once per event
    UNIQUE(user_id, event_id)
);

COMMENT ON TABLE public.event_rsvps IS 'Event attendance tracking';

-- Success message
SELECT '✅ Events schema created: events, event_rsvps' as status;
