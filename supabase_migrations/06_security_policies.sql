-- =============================================
-- FocusFlow Database Migration 06: Security Policies
-- Row Level Security for data protection
-- =============================================

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_usage_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_usage_summaries ENABLE ROW LEVEL SECURITY;
-- Only enable RLS on tables that exist
DO $$ BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'motivational_messages') THEN
        ALTER TABLE public.motivational_messages ENABLE ROW LEVEL SECURITY;
    END IF;
END $$;

DO $$ BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'challenges') THEN
        ALTER TABLE public.challenges ENABLE ROW LEVEL SECURITY;
    END IF;
END $$;

DO $$ BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'user_challenges') THEN
        ALTER TABLE public.user_challenges ENABLE ROW LEVEL SECURITY;
    END IF;
END $$;

-- Profiles policies (drop existing first)
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;

CREATE POLICY "Users can view own profile" ON public.profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- User settings policies (drop existing first)
DROP POLICY IF EXISTS "Users can view own settings" ON public.user_settings;
DROP POLICY IF EXISTS "Users can insert own settings" ON public.user_settings;
DROP POLICY IF EXISTS "Users can update own settings" ON public.user_settings;
DROP POLICY IF EXISTS "Users can delete own settings" ON public.user_settings;

CREATE POLICY "Users can view own settings" ON public.user_settings FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own settings" ON public.user_settings FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own settings" ON public.user_settings FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own settings" ON public.user_settings FOR DELETE USING (auth.uid() = user_id);

-- App usage sessions policies (drop existing first)
DROP POLICY IF EXISTS "Users can view own app usage" ON public.app_usage_sessions;
DROP POLICY IF EXISTS "Users can insert own app usage" ON public.app_usage_sessions;
DROP POLICY IF EXISTS "Users can update own app usage" ON public.app_usage_sessions;
DROP POLICY IF EXISTS "Users can delete own app usage" ON public.app_usage_sessions;

CREATE POLICY "Users can view own app usage" ON public.app_usage_sessions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own app usage" ON public.app_usage_sessions FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own app usage" ON public.app_usage_sessions FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own app usage" ON public.app_usage_sessions FOR DELETE USING (auth.uid() = user_id);

-- App usage summaries policies (drop existing first)
DROP POLICY IF EXISTS "Users can view own usage summaries" ON public.app_usage_summaries;
DROP POLICY IF EXISTS "Users can insert own usage summaries" ON public.app_usage_summaries;
DROP POLICY IF EXISTS "Users can update own usage summaries" ON public.app_usage_summaries;

CREATE POLICY "Users can view own usage summaries" ON public.app_usage_summaries FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own usage summaries" ON public.app_usage_summaries FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own usage summaries" ON public.app_usage_summaries FOR UPDATE USING (auth.uid() = user_id);

-- Badges policies (read-only for users) (drop existing first)
DROP POLICY IF EXISTS "Anyone can view badges" ON public.badges;
CREATE POLICY "Anyone can view badges" ON public.badges FOR SELECT USING (TRUE);

-- User badges policies (drop existing first)
DROP POLICY IF EXISTS "Users can view own badges" ON public.user_badges;
DROP POLICY IF EXISTS "Users can insert own badges" ON public.user_badges;

CREATE POLICY "Users can view own badges" ON public.user_badges FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own badges" ON public.user_badges FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Note: reward_wallet, reward_transactions, and daily_spin tables removed
-- These features were not implemented in the Flutter app

-- Policies for tables that exist
DO $$ BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'motivational_messages') THEN
        DROP POLICY IF EXISTS "Anyone can view messages" ON public.motivational_messages;
        CREATE POLICY "Anyone can view messages" ON public.motivational_messages FOR SELECT USING (TRUE);
    END IF;
END $$;

DO $$ BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'challenges') THEN
        DROP POLICY IF EXISTS "Anyone can view challenges" ON public.challenges;
        CREATE POLICY "Anyone can view challenges" ON public.challenges FOR SELECT USING (TRUE);
    END IF;
END $$;

DO $$ BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'user_challenges') THEN
        DROP POLICY IF EXISTS "Users can view own challenges" ON public.user_challenges;
        DROP POLICY IF EXISTS "Users can insert own challenges" ON public.user_challenges;
        DROP POLICY IF EXISTS "Users can update own challenges" ON public.user_challenges;
        DROP POLICY IF EXISTS "Users can delete own challenges" ON public.user_challenges;
        
        CREATE POLICY "Users can view own challenges" ON public.user_challenges FOR SELECT USING (auth.uid() = user_id);
        CREATE POLICY "Users can insert own challenges" ON public.user_challenges FOR INSERT WITH CHECK (auth.uid() = user_id);
        CREATE POLICY "Users can update own challenges" ON public.user_challenges FOR UPDATE USING (auth.uid() = user_id);
        CREATE POLICY "Users can delete own challenges" ON public.user_challenges FOR DELETE USING (auth.uid() = user_id);
    END IF;
END $$;