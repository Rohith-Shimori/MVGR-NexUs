-- ============================================
-- MVGR NexUs Database Setup
-- File: 06_schema_community.sql
-- Purpose: Study Buddy, Play Buddy, Meetups, Mentorship
-- Run Order: 7
-- ============================================

-- STUDY REQUESTS (Study Buddy)
-- Find study partners for specific subjects/topics
CREATE TABLE public.study_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Creator
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    user_name TEXT NOT NULL,
    
    -- What they want to study
    subject TEXT NOT NULL,
    topic TEXT,
    description TEXT,
    
    -- Preferences
    preferred_mode TEXT NOT NULL 
        CHECK (preferred_mode IN ('online', 'inPerson', 'hybrid')),
    preferred_time TEXT,
    
    -- Status
    status TEXT NOT NULL DEFAULT 'active' 
        CHECK (status IN ('active', 'matched', 'completed', 'cancelled')),
    
    -- Expiry
    expires_at TIMESTAMPTZ,
    
    -- Timestamp
    created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.study_requests IS 'Study buddy matching requests';

-- ============================================

-- STUDY REQUEST RESPONSES
-- When someone responds to a study request
CREATE TABLE public.study_request_responses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Links
    request_id UUID NOT NULL REFERENCES public.study_requests(id) ON DELETE CASCADE,
    responder_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Denormalized
    responder_name TEXT NOT NULL,
    message TEXT,
    
    -- Timestamp
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Prevent duplicate responses
    UNIQUE(request_id, responder_id)
);

COMMENT ON TABLE public.study_request_responses IS 'Responses to study buddy requests';

-- ============================================

-- TEAM REQUESTS (Play Buddy / Team Finder)
-- Find teammates for hackathons, sports, projects
CREATE TABLE public.team_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Creator
    creator_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    creator_name TEXT NOT NULL,
    
    -- Team details
    title TEXT NOT NULL,
    description TEXT,
    category TEXT NOT NULL 
        CHECK (category IN ('hackathon', 'sports', 'project', 'esports', 'other')),
    team_size INTEGER NOT NULL,
    
    -- Status
    deadline TIMESTAMPTZ,
    is_open BOOLEAN DEFAULT TRUE,
    
    -- Timestamp
    created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.team_requests IS 'Team formation requests';

-- ============================================

-- TEAM MEMBERS
-- People who joined a team
CREATE TABLE public.team_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Links
    request_id UUID NOT NULL REFERENCES public.team_requests(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Denormalized
    user_name TEXT NOT NULL,
    
    -- Timestamp
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Prevent duplicate joins
    UNIQUE(request_id, user_id)
);

COMMENT ON TABLE public.team_members IS 'Team membership';

-- ============================================

-- MENTORS
-- Seniors, alumni, faculty offering mentorship
CREATE TABLE public.mentors (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Link to user
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    
    -- Type
    mentor_type TEXT NOT NULL 
        CHECK (mentor_type IN ('senior', 'alumni', 'faculty')),
    department TEXT,
    
    -- Expertise
    areas TEXT[] DEFAULT '{}',      -- Career, academics, etc.
    expertise TEXT[] DEFAULT '{}',  -- Specific skills
    bio TEXT,
    linkedin_url TEXT,
    
    -- Capacity
    max_mentees INTEGER DEFAULT 5,
    current_mentees INTEGER DEFAULT 0,
    is_available BOOLEAN DEFAULT TRUE,
    
    -- Stats
    rating DECIMAL(2,1) DEFAULT 0 CHECK (rating >= 0 AND rating <= 5),
    
    -- Timestamp
    created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.mentors IS 'Mentor profiles';

-- ============================================

-- MEETUPS (Offline Community)
-- In-person gatherings: study circles, gaming, sports
CREATE TABLE public.meetups (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Basic info
    title TEXT NOT NULL,
    description TEXT,
    
    -- Organizer
    organizer_id UUID NOT NULL REFERENCES auth.users(id),
    organizer_name TEXT NOT NULL,
    
    -- Category
    category TEXT NOT NULL 
        CHECK (category IN ('studyCircle', 'gaming', 'sports', 'creative', 'other')),
    
    -- Location & time
    venue TEXT NOT NULL,
    scheduled_at TIMESTAMPTZ NOT NULL,
    
    -- Capacity
    max_participants INTEGER,
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Timestamp
    created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.meetups IS 'Offline community gatherings';

-- ============================================

-- MEETUP PARTICIPANTS
-- People joining meetups
CREATE TABLE public.meetup_participants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Links
    meetup_id UUID NOT NULL REFERENCES public.meetups(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Timestamp
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Prevent duplicate joins
    UNIQUE(meetup_id, user_id)
);

COMMENT ON TABLE public.meetup_participants IS 'Meetup attendance';

-- ============================================

-- LOST & FOUND ITEMS
-- Report lost items or found items
CREATE TABLE public.lost_found_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Item info
    title TEXT NOT NULL,
    description TEXT,
    category TEXT NOT NULL 
        CHECK (category IN ('electronics', 'documents', 'accessories', 'wallet', 'keys', 'clothing', 'other')),
    
    -- Location & date
    location TEXT NOT NULL,
    item_date TIMESTAMPTZ NOT NULL,  -- When lost/found
    
    -- Images
    image_urls TEXT[] DEFAULT '{}',
    
    -- Reporter
    user_id UUID NOT NULL REFERENCES auth.users(id),
    user_name TEXT NOT NULL,
    contact_info TEXT,
    
    -- Status
    status TEXT NOT NULL DEFAULT 'lost' 
        CHECK (status IN ('lost', 'found', 'claimed', 'expired')),
    
    -- Claim info
    claimer_id UUID REFERENCES auth.users(id),
    claimer_name TEXT,
    
    -- Expiry
    expires_at TIMESTAMPTZ,
    
    -- Timestamp
    created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.lost_found_items IS 'Lost and found items';

-- Success message
SELECT '✅ Community schema created: study_requests, study_request_responses, team_requests, team_members, mentors, meetups, meetup_participants, lost_found_items' as status;
