-- =============================================
-- FocusFlow Database Migration 08: Performance Indexes
-- Database optimization for better query performance
-- =============================================

-- Add indexes for better query performance
CREATE INDEX profiles_user_idx ON public.profiles(id);
CREATE INDEX user_settings_user_idx ON public.user_settings(user_id);
CREATE INDEX app_usage_sessions_user_idx ON public.app_usage_sessions(user_id);
CREATE INDEX app_usage_sessions_app_idx ON public.app_usage_sessions(app_name);
CREATE INDEX daily_summaries_user_idx ON public.daily_summaries(user_id);
CREATE INDEX daily_summaries_date_idx ON public.daily_summaries(date);
CREATE INDEX user_badges_user_idx ON public.user_badges(user_id);
CREATE INDEX user_badges_badge_idx ON public.user_badges(badge_id);
CREATE INDEX reward_transactions_user_idx ON public.reward_transactions(user_id);
CREATE INDEX reward_transactions_type_idx ON public.reward_transactions(type);
CREATE INDEX daily_spin_user_idx ON public.daily_spin(user_id);
CREATE INDEX user_challenges_user_idx ON public.user_challenges(user_id);
CREATE INDEX user_challenges_challenge_idx ON public.user_challenges(challenge_id);

-- Additional performance indexes
CREATE INDEX app_usage_sessions_started_idx ON public.app_usage_sessions(started_at);
CREATE INDEX daily_summaries_date_user_idx ON public.daily_summaries(date, user_id);
CREATE INDEX reward_transactions_created_idx ON public.reward_transactions(created_at);
CREATE INDEX user_challenges_completed_idx ON public.user_challenges(completed) WHERE completed = true;

-- Success message
SELECT 'FocusFlow database schema updated successfully with your preferred structure! 🚀' as message;