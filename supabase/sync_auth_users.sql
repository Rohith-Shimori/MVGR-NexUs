-- Sync existing auth.users to public.users
-- Run this after COMPLETE_SETUP.sql if you have existing auth users

-- Insert profiles for any auth users that don't have a profile
INSERT INTO public.users (id, email, name, role, created_at)
SELECT 
    au.id,
    au.email,
    COALESCE(au.raw_user_meta_data->>'name', 'User'),
    'student',
    au.created_at
FROM auth.users au
WHERE NOT EXISTS (
    SELECT 1 FROM public.users pu WHERE pu.id = au.id
);

-- Verify
SELECT id, email, name, role FROM public.users;
