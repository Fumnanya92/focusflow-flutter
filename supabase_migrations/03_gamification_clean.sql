-- =============================================
-- FocusFlow Database Migration 03: Gamification (SAFE VERSION)
-- Badge system and rewards - with DROP IF EXISTS protection
-- =============================================

-- Drop existing tables if they exist (safe cleanup)
DROP TABLE IF EXISTS user_badges CASCADE;
DROP TABLE IF EXISTS badges CASCADE;
DROP TABLE IF EXISTS points_transactions CASCADE;
DROP TABLE IF EXISTS achievements CASCADE;
DROP TABLE IF EXISTS focus_sessions CASCADE;
DROP TABLE IF EXISTS user_points CASCADE;
DROP TABLE IF EXISTS daily_spin CASCADE;

-- ===========================================
-- BADGES & ACHIEVEMENTS
-- ===========================================
CREATE TABLE badges (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    icon_url TEXT,
    reward_points INTEGER DEFAULT 0
);

CREATE TABLE user_badges (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    badge_id BIGINT REFERENCES badges(id),
    
    unlocked_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(user_id, badge_id)
);

-- ===========================================
-- POINTS SYSTEM (Fun, Fair & Addictive)
-- ===========================================
CREATE TABLE user_points (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    total_points INTEGER DEFAULT 0,
    level INTEGER DEFAULT 1,
    daily_points INTEGER DEFAULT 0,
    daily_goal_minutes INTEGER DEFAULT 60,
    current_streak_days INTEGER DEFAULT 0,
    best_streak_days INTEGER DEFAULT 0,
    last_activity_date DATE,
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE points_transactions (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    
    points_change INTEGER NOT NULL, -- Can be positive or negative
    transaction_type TEXT NOT NULL, -- 'focus_minute', 'session_complete', 'daily_goal', 'streak_bonus', 'early_exit_penalty', 'emergency_stop_penalty'
    description TEXT NOT NULL,
    session_id BIGINT, -- Reference to focus session if applicable
    
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE achievements (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    
    achievement_type TEXT NOT NULL, -- 'morning_starter', 'night_warrior', 'perfect_day', 'comeback_bonus', 'streak_master'
    achievement_name TEXT NOT NULL,
    points_awarded INTEGER NOT NULL,
    date_earned DATE NOT NULL,
    
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE focus_sessions (
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

-- ===========================================
-- DAILY SPIN SYSTEM
-- ===========================================
CREATE TABLE daily_spin (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,

    last_spin_date DATE,
    reward TEXT,     -- e.g. "50 points", "No social media for 1 hour"
    created_at TIMESTAMPTZ DEFAULT now()
);

-- ===========================================
-- INSERT DEFAULT BADGES
-- ===========================================
INSERT INTO badges (title, description, icon_url, reward_points) VALUES
-- Achievement Badges
('Morning Starter', 'Complete first session before 12pm', '🌅', 25),
('Night Warrior', 'Complete last session after 8pm', '🌙', 25),
('Perfect Day', 'Complete 100% of daily goals', '🔥', 50),
('Comeback Bonus', 'Return after missing a day', '💪', 30),
('Weekly Streak Master', '7-day focus streak', '🏆', 100),

-- Milestone Badges
('Focus Rookie', 'Complete first 10 focus sessions', '🎯', 100),
('Focus Veteran', 'Complete 100 focus sessions', '⭐', 250),
('Focus Legend', 'Complete 500 focus sessions', '👑', 500),
('Point Master', 'Earn 1000 total points', '💎', 200),
('Point Legend', 'Earn 10000 total points', '💰', 1000),

-- Streak Badges
('Streak Starter', '3-day streak', '🔥', 50),
('Streak Warrior', '10-day streak', '💪', 150),
('Streak Master', '30-day streak', '🏆', 300),
('Streak Legend', '100-day streak', '👑', 1000);