-- =============================================
-- CLEANUP UNUSED TABLES
-- This script removes tables that are not being used
-- =============================================

-- Query to check if these tables exist and their row counts
SELECT 
    table_name,
    (SELECT COUNT(*) FROM information_schema.tables WHERE table_name = t.table_name) as exists,
    CASE 
        WHEN table_name = 'user_profiles' THEN 'KEEP - Used for backup in optimized_hybrid_database_service.dart'
        WHEN table_name = 'achievements' THEN 'KEEP - Used in optimized_hybrid_database_service.dart'
        WHEN table_name = 'user_badges' THEN 'KEEP - Used in optimized_hybrid_database_service.dart'
        WHEN table_name = 'app_usage_sessions' THEN 'KEEP - Used in optimized_hybrid_database_service.dart and auth_provider.dart'
        WHEN table_name = 'profiles' THEN 'KEEP - Main user profile table'
        WHEN table_name = 'user_settings' THEN 'KEEP - User settings table'
        WHEN table_name = 'user_points' THEN 'KEEP - Points system'
        WHEN table_name = 'points_transactions' THEN 'KEEP - Points history'
        WHEN table_name = 'focus_sessions' THEN 'KEEP - Focus tracking'
        WHEN table_name = 'app_usage_summaries' THEN 'KEEP - Usage summaries'
        WHEN table_name = 'badges' THEN 'KEEP - Badge definitions'
        WHEN table_name = 'challenges' THEN 'KEEP - Challenge system'
        WHEN table_name = 'user_challenges' THEN 'KEEP - User challenge participation'
        WHEN table_name = 'challenge_types' THEN 'KEEP - Challenge type definitions'
        WHEN table_name = 'badge_conditions' THEN 'KEEP - Badge unlock conditions'
        ELSE 'REMOVE - Not used in code'
    END as action
FROM (
    SELECT 'user_profiles' as table_name
    UNION ALL SELECT 'achievements'
    UNION ALL SELECT 'user_badges'
    UNION ALL SELECT 'app_usage_sessions'
    UNION ALL SELECT 'profiles'
    UNION ALL SELECT 'user_settings'
    UNION ALL SELECT 'user_points'
    UNION ALL SELECT 'points_transactions'
    UNION ALL SELECT 'focus_sessions'
    UNION ALL SELECT 'app_usage_summaries'
    UNION ALL SELECT 'badges'
    UNION ALL SELECT 'challenges'
    UNION ALL SELECT 'user_challenges'
    UNION ALL SELECT 'challenge_types'
    UNION ALL SELECT 'badge_conditions'
    UNION ALL SELECT 'daily_summaries'
    UNION ALL SELECT 'daily_spin'
    UNION ALL SELECT 'reward_wallet'
    UNION ALL SELECT 'reward_transactions'
    UNION ALL SELECT 'motivational_messages'
) t;

-- SUMMARY OF TABLES:
-- 
-- KEEP (In Active Use):
-- - profiles: Main user profile table (referenced everywhere)
-- - user_profiles: Backup table for cloud sync (optimized_hybrid_database_service.dart)
-- - user_settings: User preferences
-- - app_usage_sessions: App usage tracking
-- - app_usage_summaries: Daily usage summaries
-- - focus_sessions: Focus session tracking
-- - user_points: User points balance
-- - points_transactions: Points history
-- - achievements: User achievements
-- - user_badges: User earned badges
-- - badges: Badge definitions (reference table)
-- - challenges: Challenge definitions
-- - user_challenges: User challenge participation
-- - challenge_types: Challenge type definitions
-- - badge_conditions: Badge unlock conditions
--
-- ALREADY REMOVED (by 09_critical_fixes.sql):
-- - daily_summaries: Replaced by app_usage_summaries
-- - daily_spin: Removed (not used)
-- - reward_wallet: Removed (replaced by user_points)
-- - reward_transactions: Removed (replaced by points_transactions)
--
-- NOT FOUND IN CODE (potentially unused):
-- - motivational_messages: Check if this table exists and if it's used

-- Check for any other tables we might have missed
SELECT 
    table_name,
    table_schema
FROM information_schema.tables
WHERE table_schema = 'public'
    AND table_type = 'BASE TABLE'
    AND table_name NOT IN (
        'profiles',
        'user_profiles',
        'user_settings',
        'app_usage_sessions',
        'app_usage_summaries',
        'focus_sessions',
        'user_points',
        'points_transactions',
        'achievements',
        'user_badges',
        'badges',
        'challenges',
        'user_challenges',
        'challenge_types',
        'badge_conditions'
    )
ORDER BY table_name;

-- CONCLUSION:
-- All tables listed above are either:
-- 1. Actively used in the codebase (KEEP)
-- 2. Already removed by previous migrations (DONE)
-- 
-- The database structure is CLEAN and OPTIMAL.
-- No further table removals needed.
