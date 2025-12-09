-- =============================================
-- FocusFlow Database Migration 08: Performance Indexes
-- Database optimization for better query performance
-- =============================================

-- Add indexes for better query performance
CREATE INDEX IF NOT EXISTS profiles_user_idx ON public.profiles(id);
CREATE INDEX IF NOT EXISTS user_settings_user_idx ON public.user_settings(user_id);
CREATE INDEX IF NOT EXISTS app_usage_sessions_user_idx ON public.app_usage_sessions(user_id);
CREATE INDEX IF NOT EXISTS app_usage_sessions_app_idx ON public.app_usage_sessions(app_name);
CREATE INDEX IF NOT EXISTS app_usage_summaries_user_idx ON public.app_usage_summaries(user_id);
CREATE INDEX IF NOT EXISTS app_usage_summaries_date_idx ON public.app_usage_summaries(date);
CREATE INDEX IF NOT EXISTS user_badges_user_idx ON public.user_badges(user_id);
CREATE INDEX IF NOT EXISTS user_badges_badge_idx ON public.user_badges(badge_id);
-- Only create indexes on tables that exist
DO $$ BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'user_challenges') THEN
        CREATE INDEX IF NOT EXISTS user_challenges_user_idx ON public.user_challenges(user_id);
        CREATE INDEX IF NOT EXISTS user_challenges_challenge_idx ON public.user_challenges(challenge_id);
    END IF;
END $$;

-- Additional performance indexes
CREATE INDEX IF NOT EXISTS app_usage_sessions_started_idx ON public.app_usage_sessions(started_at);
CREATE INDEX IF NOT EXISTS app_usage_summaries_date_user_idx ON public.app_usage_summaries(date, user_id);
-- Additional indexes for tables that exist
DO $$ BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'user_challenges') THEN
        CREATE INDEX IF NOT EXISTS user_challenges_completed_idx ON public.user_challenges(completed) WHERE completed = true;
    END IF;
END $$;

-- Indexes for new tables added in migration 09
DO $$ BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'user_points') THEN
        CREATE INDEX IF NOT EXISTS user_points_user_idx ON public.user_points(user_id);
        CREATE INDEX IF NOT EXISTS user_points_updated_idx ON public.user_points(updated_at);
    END IF;
END $$;

DO $$ BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'points_transactions') THEN
        CREATE INDEX IF NOT EXISTS points_transactions_user_idx ON public.points_transactions(user_id);
        CREATE INDEX IF NOT EXISTS points_transactions_type_idx ON public.points_transactions(transaction_type);
        CREATE INDEX IF NOT EXISTS points_transactions_created_idx ON public.points_transactions(created_at);
    END IF;
END $$;

DO $$ BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'achievements') THEN
        CREATE INDEX IF NOT EXISTS achievements_user_idx ON public.achievements(user_id);
        CREATE INDEX IF NOT EXISTS achievements_type_idx ON public.achievements(achievement_type);
        CREATE INDEX IF NOT EXISTS achievements_date_idx ON public.achievements(date_earned);
    END IF;
END $$;

DO $$ BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'focus_sessions') THEN
        CREATE INDEX IF NOT EXISTS focus_sessions_user_idx ON public.focus_sessions(user_id);
        CREATE INDEX IF NOT EXISTS focus_sessions_started_idx ON public.focus_sessions(started_at);
        CREATE INDEX IF NOT EXISTS focus_sessions_status_idx ON public.focus_sessions(completion_status);
    END IF;
END $$;

DO $$ BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'user_profiles') THEN
        CREATE INDEX IF NOT EXISTS user_profiles_user_idx ON public.user_profiles(user_id);
        CREATE INDEX IF NOT EXISTS user_profiles_updated_idx ON public.user_profiles(updated_at);
    END IF;
END $$;

-- Success message
SELECT 'FocusFlow database schema updated successfully with your preferred structure! 🚀' as message;