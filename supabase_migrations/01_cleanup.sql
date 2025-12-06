-- =============================================
-- FocusFlow Database Migration 01: Cleanup
-- Drop existing tables for clean setup
-- =============================================

-- Drop tables in correct order (dependencies first)
DROP TABLE IF EXISTS public.user_challenges CASCADE;
DROP TABLE IF EXISTS public.challenges CASCADE;
DROP TABLE IF EXISTS public.daily_spin CASCADE;
DROP TABLE IF EXISTS public.reward_transactions CASCADE;
DROP TABLE IF EXISTS public.reward_wallet CASCADE;
DROP TABLE IF EXISTS public.user_badges CASCADE;
DROP TABLE IF EXISTS public.badges CASCADE;
DROP TABLE IF EXISTS public.motivational_messages CASCADE;
DROP TABLE IF EXISTS public.daily_summaries CASCADE;
DROP TABLE IF EXISTS public.app_usage_sessions CASCADE;
DROP TABLE IF EXISTS public.user_settings CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;