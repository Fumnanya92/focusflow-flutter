-- =============================================
-- FIX PROFILE CREATION ISSUE
-- This script will:
-- 1. Add missing columns to profiles table
-- 2. Re-enable trigger with fixed constraints
-- 3. Manually create profile for existing user
-- =============================================

-- Step 1: Add missing columns if they don't exist
DO $$ 
BEGIN
    -- Add is_active column
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'profiles' AND column_name = 'is_active') THEN
        ALTER TABLE public.profiles ADD COLUMN is_active BOOLEAN DEFAULT TRUE;
    END IF;
    
    -- Add is_premium column
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'profiles' AND column_name = 'is_premium') THEN
        ALTER TABLE public.profiles ADD COLUMN is_premium BOOLEAN DEFAULT FALSE;
    END IF;
END $$;

-- Step 2: Re-create the trigger function with proper username constraints
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    final_username TEXT;
BEGIN
    -- Generate username from email (first part before @)
    final_username := split_part(NEW.email, '@', 1);
    
    -- Ensure username is between 3-15 characters (not 3-20)
    -- This matches the app's constraint
    IF char_length(final_username) > 15 THEN
        final_username := substring(final_username from 1 for 15);
    END IF;
    
    -- Make username unique by appending numbers if needed
    WHILE EXISTS (SELECT 1 FROM public.profiles WHERE username = final_username) LOOP
        final_username := substring(final_username from 1 for 11) || floor(random() * 10000)::text;
    END LOOP;
    
    -- Create profile
    INSERT INTO public.profiles (
        id,
        username,
        email,
        display_name,
        is_active,
        is_premium,
        notifications_enabled,
        created_at,
        updated_at
    ) VALUES (
        NEW.id,
        final_username,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'username', final_username),
        TRUE,
        FALSE,
        TRUE,
        now(),
        now()
    );
    
    -- Create user settings
    INSERT INTO public.user_settings (
        user_id,
        daily_screen_time_limit,
        reward_notifications,
        strict_mode,
        allow_override,
        created_at,
        updated_at
    ) VALUES (
        NEW.id,
        0,
        TRUE,
        FALSE,
        TRUE,
        now(),
        now()
    );
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Log the error but don't prevent user creation
        RAISE WARNING 'Error in handle_new_user trigger: %', SQLERRM;
        RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 3: Re-enable the trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Step 4: Manually create profile for existing user (f37b2352-c51b-4edb-8b13-5b633ba85e6e)
-- This needs to be run with proper permissions, not through RLS
INSERT INTO public.profiles (
    id,
    username,
    email,
    display_name,
    is_active,
    is_premium,
    notifications_enabled,
    created_at,
    updated_at
) VALUES (
    'f37b2352-c51b-4edb-8b13-5b633ba85e6e',
    'G_reviewer',
    'fynkotechnologies@gmail.com',
    'G_reviewer',
    TRUE,
    FALSE,
    TRUE,
    now(),
    now()
)
ON CONFLICT (id) DO UPDATE SET
    username = EXCLUDED.username,
    email = EXCLUDED.email,
    display_name = EXCLUDED.display_name,
    is_active = EXCLUDED.is_active,
    is_premium = EXCLUDED.is_premium,
    updated_at = now();

-- Create user settings for existing user
INSERT INTO public.user_settings (
    user_id,
    daily_screen_time_limit,
    reward_notifications,
    strict_mode,
    allow_override,
    created_at,
    updated_at
) VALUES (
    'f37b2352-c51b-4edb-8b13-5b633ba85e6e',
    0,
    TRUE,
    FALSE,
    TRUE,
    now(),
    now()
)
ON CONFLICT (user_id) DO NOTHING;

-- Step 5: Verify the fix
SELECT 'Profile created successfully' as message, * FROM public.profiles WHERE id = 'f37b2352-c51b-4edb-8b13-5b633ba85e6e';
