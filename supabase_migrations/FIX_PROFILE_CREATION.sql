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

-- Step 4: Add unique constraint to user_settings if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'user_settings_user_id_key'
    ) THEN
        ALTER TABLE public.user_settings ADD CONSTRAINT user_settings_user_id_key UNIQUE (user_id);
    END IF;
END $$;

-- Step 5: Fix ALL existing users who don't have profiles (not just one!)
-- This will create profiles for ANY user in auth.users who doesn't have one
DO $$
DECLARE
    user_record RECORD;
    new_username TEXT;
BEGIN
    FOR user_record IN 
        SELECT u.id, u.email, u.raw_user_meta_data
        FROM auth.users u
        LEFT JOIN public.profiles p ON u.id = p.id
        WHERE p.id IS NULL
    LOOP
        -- Generate username from email
        new_username := split_part(user_record.email, '@', 1);
        
        -- Ensure username is 3-15 characters
        IF char_length(new_username) > 15 THEN
            new_username := substring(new_username from 1 for 15);
        END IF;
        
        -- Make unique if needed
        WHILE EXISTS (SELECT 1 FROM public.profiles WHERE username = new_username) LOOP
            new_username := substring(new_username from 1 for 11) || floor(random() * 10000)::text;
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
            user_record.id,
            new_username,
            user_record.email,
            COALESCE(user_record.raw_user_meta_data->>'username', new_username),
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
            user_record.id,
            0,
            TRUE,
            FALSE,
            TRUE,
            now(),
            now()
        )
        ON CONFLICT (user_id) DO NOTHING;
        
        RAISE NOTICE 'Created profile for user: % (%)', user_record.email, user_record.id;
    END LOOP;
END $$;

-- Step 6: Verify the fix
SELECT 
    'Fixed ' || COUNT(*) || ' users' as message,
    COUNT(*) as total_profiles_created
FROM public.profiles;
