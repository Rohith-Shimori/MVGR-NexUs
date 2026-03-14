-- ============================================
-- MVGR NexUs Database Setup
-- File: 08_functions.sql
-- Purpose: Helper functions and triggers
-- Run Order: 9
-- ============================================

-- ============================================
-- SECTION 1: UTILITY FUNCTIONS
-- ============================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION public.update_updated_at_column IS 'Auto-updates updated_at timestamp on row update';

-- ============================================
-- SECTION 2: AUTH USER SYNC
-- This is the KEY fix for the login issue!
-- Auto-creates profile when user signs up
-- ============================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.users (id, email, name, role, created_at)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(
            NEW.raw_user_meta_data->>'name',
            split_part(NEW.email, '@', 1)
        ),
        'student',
        NOW()
    )
    ON CONFLICT (id) DO NOTHING;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.handle_new_user IS 'Auto-creates user profile on signup';

-- Create trigger on auth.users (only if it doesn't exist)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'on_auth_user_created'
    ) THEN
        CREATE TRIGGER on_auth_user_created
            AFTER INSERT ON auth.users
            FOR EACH ROW 
            EXECUTE FUNCTION public.handle_new_user();
    END IF;
END $$;

-- ============================================
-- SECTION 3: FORUM HELPER FUNCTIONS
-- ============================================

-- Increment answer count when new answer is posted
CREATE OR REPLACE FUNCTION public.increment_forum_answer_count(p_question_id UUID)
RETURNS void AS $$
BEGIN
    UPDATE public.forum_questions 
    SET answer_count = answer_count + 1 
    WHERE id = p_question_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Increment upvote count
CREATE OR REPLACE FUNCTION public.increment_forum_upvote(p_question_id UUID)
RETURNS void AS $$
BEGIN
    UPDATE public.forum_questions 
    SET upvote_count = upvote_count + 1 
    WHERE id = p_question_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Decrement upvote count
CREATE OR REPLACE FUNCTION public.decrement_forum_upvote(p_question_id UUID)
RETURNS void AS $$
BEGIN
    UPDATE public.forum_questions 
    SET upvote_count = GREATEST(upvote_count - 1, 0) 
    WHERE id = p_question_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- SECTION 4: VAULT HELPER FUNCTIONS
-- ============================================

-- Increment download count
CREATE OR REPLACE FUNCTION public.increment_vault_download(p_item_id UUID)
RETURNS void AS $$
BEGIN
    UPDATE public.vault_items 
    SET download_count = download_count + 1 
    WHERE id = p_item_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- SECTION 5: ROLE CHECK HELPER
-- ============================================

-- Check if current user can moderate
CREATE OR REPLACE FUNCTION public.is_moderator()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.users 
        WHERE id = auth.uid() 
        AND role IN ('council', 'faculty')
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.is_moderator IS 'Returns true if current user is council or faculty';

-- ============================================
-- SECTION 6: UPDATED_AT TRIGGERS
-- ============================================

-- Users
CREATE TRIGGER update_users_updated_at 
    BEFORE UPDATE ON public.users 
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Clubs
CREATE TRIGGER update_clubs_updated_at 
    BEFORE UPDATE ON public.clubs 
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Club requests
CREATE TRIGGER update_club_requests_updated_at 
    BEFORE UPDATE ON public.club_requests 
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Club posts
CREATE TRIGGER update_club_posts_updated_at 
    BEFORE UPDATE ON public.club_posts 
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Events
CREATE TRIGGER update_events_updated_at 
    BEFORE UPDATE ON public.events 
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Announcements
CREATE TRIGGER update_announcements_updated_at 
    BEFORE UPDATE ON public.announcements 
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Forum questions
CREATE TRIGGER update_forum_questions_updated_at 
    BEFORE UPDATE ON public.forum_questions 
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Forum answers
CREATE TRIGGER update_forum_answers_updated_at 
    BEFORE UPDATE ON public.forum_answers 
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================
-- SECTION 7: GET USER ROLE HELPER
-- ============================================

CREATE OR REPLACE FUNCTION public.get_user_role()
RETURNS TEXT AS $$
    SELECT COALESCE(
        (SELECT role FROM users WHERE id = auth.uid()),
        'student'
    );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

COMMENT ON FUNCTION public.get_user_role IS 'Returns current user role, defaults to student';

-- ============================================
-- SECTION 8: ANSWER HELPFUL COUNT FUNCTIONS
-- ============================================

-- Increment helpful count on answers
CREATE OR REPLACE FUNCTION public.increment_answer_helpful(p_answer_id UUID)
RETURNS void AS $$
BEGIN
    UPDATE public.forum_answers 
    SET helpful_count = helpful_count + 1
    WHERE id = p_answer_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Decrement helpful count on answers
CREATE OR REPLACE FUNCTION public.decrement_answer_helpful(p_answer_id UUID)
RETURNS void AS $$
BEGIN
    UPDATE public.forum_answers 
    SET helpful_count = GREATEST(helpful_count - 1, 0)
    WHERE id = p_answer_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Success message
SELECT '✅ Functions and triggers created: handle_new_user, update_updated_at, forum helpers, vault helpers, is_moderator, get_user_role' as status;
