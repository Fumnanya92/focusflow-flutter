-- =============================================
-- FocusFlow Database Migration 09: CRITICAL FIXES
-- Fix missing tables, cleanup unused ones, optimize storage
-- =============================================

-- ===========================================
-- PHASE 1: ADD MISSING CRITICAL TABLES
-- ===========================================

-- Add missing user_points table (CRITICAL - used in hybrid_database_service.dart)
CREATE TABLE IF NOT EXISTS user_points (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    total_points INTEGER DEFAULT 0,
    level INTEGER DEFAULT 1,
    daily_points INTEGER DEFAULT 0,
    current_streak_days INTEGER DEFAULT 0,
    best_streak_days INTEGER DEFAULT 0,
    daily_goal_minutes INTEGER DEFAULT 60,
    last_activity_date DATE,
    updated_at TIMESTAMPTZ DEFAULT now(),
    
    -- Ensure one record per user
    UNIQUE(user_id)
);

-- Add missing points_transactions table (CRITICAL - used in hybrid_database_service.dart)
CREATE TABLE IF NOT EXISTS points_transactions (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    points_change INTEGER NOT NULL,
    transaction_type TEXT NOT NULL, -- 'focus_minute', 'session_complete', 'daily_goal', 'streak_bonus', 'penalty'
    description TEXT NOT NULL,
    session_id BIGINT, -- Reference to focus session if applicable
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Add missing achievements table (CRITICAL - used in hybrid_database_service.dart)
CREATE TABLE IF NOT EXISTS achievements (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    achievement_type TEXT NOT NULL, -- 'morning_starter', 'night_warrior', 'perfect_day', etc.
    achievement_name TEXT NOT NULL,
    points_awarded INTEGER NOT NULL,
    date_earned DATE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Add missing focus_sessions table (CRITICAL - used in hybrid_database_service.dart)
CREATE TABLE IF NOT EXISTS focus_sessions (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    planned_duration_minutes INTEGER NOT NULL,
    actual_duration_minutes INTEGER,
    session_type TEXT NOT NULL, -- 'scheduled', 'quick_focus'
    completion_status TEXT NOT NULL, -- 'completed', 'early_exit', 'emergency_stop'
    started_at TIMESTAMPTZ NOT NULL,
    ended_at TIMESTAMPTZ,
    points_earned INTEGER DEFAULT 0,
    points_lost INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Add missing user_profiles table (CRITICAL - used in hybrid_database_service.dart for backups)
CREATE TABLE IF NOT EXISTS user_profiles (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    username TEXT,
    email TEXT,
    avatar_url TEXT,
    points INTEGER DEFAULT 0,
    unlocked_badges TEXT[] DEFAULT '{}',
    last_backup TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    
    -- Ensure one record per user
    UNIQUE(user_id)
);

-- ===========================================
-- PHASE 2: CLEANUP UNUSED TABLES (SAVE MONEY)
-- ===========================================

-- Remove unused tables that waste Supabase resources
DROP TABLE IF EXISTS daily_summaries CASCADE;
DROP TABLE IF EXISTS daily_spin CASCADE;
DROP TABLE IF EXISTS reward_wallet CASCADE;
DROP TABLE IF EXISTS reward_transactions CASCADE;

-- ===========================================
-- PHASE 3: ADD PROPER SECURITY POLICIES
-- ===========================================

-- Enable RLS on new tables
ALTER TABLE user_points ENABLE ROW LEVEL SECURITY;
ALTER TABLE points_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE focus_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- User points policies
CREATE POLICY "Users can view own points" ON user_points FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own points" ON user_points FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own points" ON user_points FOR UPDATE USING (auth.uid() = user_id);

-- Points transactions policies  
CREATE POLICY "Users can view own transactions" ON points_transactions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own transactions" ON points_transactions FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Achievements policies
CREATE POLICY "Users can view own achievements" ON achievements FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own achievements" ON achievements FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Focus sessions policies
CREATE POLICY "Users can view own sessions" ON focus_sessions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own sessions" ON focus_sessions FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own sessions" ON focus_sessions FOR UPDATE USING (auth.uid() = user_id);

-- User profiles policies
CREATE POLICY "Users can view own profile backup" ON user_profiles FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own profile backup" ON user_profiles FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own profile backup" ON user_profiles FOR UPDATE USING (auth.uid() = user_id);

-- ===========================================
-- PHASE 4: ADD PERFORMANCE INDEXES
-- ===========================================

-- Indexes for new tables
CREATE INDEX IF NOT EXISTS user_points_user_idx ON user_points(user_id);
CREATE INDEX IF NOT EXISTS points_transactions_user_idx ON points_transactions(user_id);
CREATE INDEX IF NOT EXISTS points_transactions_type_idx ON points_transactions(transaction_type);
CREATE INDEX IF NOT EXISTS achievements_user_idx ON achievements(user_id);
CREATE INDEX IF NOT EXISTS achievements_type_idx ON achievements(achievement_type);
CREATE INDEX IF NOT EXISTS focus_sessions_user_idx ON focus_sessions(user_id);
CREATE INDEX IF NOT EXISTS focus_sessions_started_idx ON focus_sessions(started_at);
CREATE INDEX IF NOT EXISTS user_profiles_user_idx ON user_profiles(user_id);

-- Remove indexes for deleted tables (cleanup)
DROP INDEX IF EXISTS daily_summaries_user_idx;
DROP INDEX IF EXISTS daily_summaries_date_idx;
DROP INDEX IF EXISTS daily_summaries_date_user_idx;
DROP INDEX IF EXISTS reward_transactions_user_idx;
DROP INDEX IF EXISTS reward_transactions_type_idx;
DROP INDEX IF EXISTS reward_transactions_created_idx;
DROP INDEX IF EXISTS daily_spin_user_idx;

-- Success message
SELECT 'CRITICAL FIXES COMPLETED! ✅ Added missing tables, cleaned unused ones, optimized security!' as message;