-- ============================================
-- MVGR NexUs Database Setup
-- File: 05_schema_content.sql
-- Purpose: Announcements, Vault (study materials), Forum
-- Run Order: 6
-- ============================================

-- ANNOUNCEMENTS TABLE
-- Official announcements from council/faculty
CREATE TABLE public.announcements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Content
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    
    -- Author
    author_id UUID NOT NULL REFERENCES auth.users(id),
    author_name TEXT NOT NULL,
    source TEXT NOT NULL DEFAULT 'Council',  -- Council, Department, etc.
    
    -- Importance flags
    is_pinned BOOLEAN DEFAULT FALSE,
    is_urgent BOOLEAN DEFAULT FALSE,
    
    -- Expiry
    expires_at TIMESTAMPTZ,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.announcements IS 'Official campus announcements';

-- ============================================

-- VAULT ITEMS (Study Materials)
-- Notes, PYQs, assignments shared by students
CREATE TABLE public.vault_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Content
    title TEXT NOT NULL,
    description TEXT,
    
    -- File info
    file_url TEXT NOT NULL,
    file_name TEXT DEFAULT '',
    file_size_bytes INTEGER DEFAULT 0,
    
    -- Type of material
    type TEXT NOT NULL 
        CHECK (type IN ('notes', 'pyq', 'assignment', 'lab', 'book', 'other')),
    
    -- Academic categorization
    subject TEXT NOT NULL,
    branch TEXT NOT NULL,  -- CSE, ECE, etc.
    year INTEGER NOT NULL CHECK (year >= 1 AND year <= 5),
    semester INTEGER DEFAULT 1 CHECK (semester >= 1 AND semester <= 10),
    
    -- Tags for searchability
    tags TEXT[] DEFAULT '{}',
    
    -- Uploader
    uploader_id UUID NOT NULL REFERENCES auth.users(id),
    uploader_name TEXT NOT NULL,
    
    -- Stats
    download_count INTEGER DEFAULT 0,
    rating DECIMAL(2,1) DEFAULT 0 CHECK (rating >= 0 AND rating <= 5),
    
    -- Moderation
    is_approved BOOLEAN DEFAULT TRUE,
    
    -- Timestamp
    created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.vault_items IS 'Academic resources shared by students';

-- ============================================

-- FORUM QUESTIONS
-- Academic Q&A platform
CREATE TABLE public.forum_questions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Content
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    
    -- Categorization
    subject TEXT DEFAULT '',
    topic TEXT DEFAULT '',
    category TEXT NOT NULL DEFAULT 'academic',
    tags TEXT[] DEFAULT '{}',
    
    -- Author (can be anonymous)
    author_id UUID NOT NULL REFERENCES auth.users(id),
    author_name TEXT,
    is_anonymous BOOLEAN DEFAULT FALSE,
    
    -- Status
    is_resolved BOOLEAN DEFAULT FALSE,
    accepted_answer_id UUID,
    
    -- Stats (denormalized counters)
    view_count INTEGER DEFAULT 0,
    answer_count INTEGER DEFAULT 0,
    upvote_count INTEGER DEFAULT 0,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.forum_questions IS 'Academic forum questions';

-- ============================================

-- FORUM ANSWERS
-- Answers to forum questions
CREATE TABLE public.forum_answers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Parent question
    question_id UUID NOT NULL REFERENCES public.forum_questions(id) ON DELETE CASCADE,
    
    -- Content
    content TEXT NOT NULL,
    
    -- Author
    author_id UUID NOT NULL REFERENCES auth.users(id),
    author_name TEXT NOT NULL,
    
    -- Status
    is_accepted BOOLEAN DEFAULT FALSE,
    helpful_count INTEGER DEFAULT 0,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.forum_answers IS 'Answers to forum questions';

-- ============================================

-- FORUM VOTES
-- Track upvotes to prevent duplicate voting
CREATE TABLE public.forum_votes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Who voted
    user_id UUID NOT NULL REFERENCES auth.users(id),
    
    -- What they voted on (question or answer ID)
    item_id UUID NOT NULL,
    
    -- Type of vote
    vote_type TEXT NOT NULL,  -- 'question_upvote', 'answer_upvote'
    
    -- Timestamp
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Prevent duplicate votes
    UNIQUE(user_id, item_id)
);

COMMENT ON TABLE public.forum_votes IS 'Track forum upvotes';

-- Success message
SELECT '✅ Content schema created: announcements, vault_items, forum_questions, forum_answers, forum_votes' as status;
