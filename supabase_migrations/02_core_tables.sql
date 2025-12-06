-- =============================================
-- FocusFlow Database Migration 02: Core Tables
-- Essential user data structures
-- =============================================

-- ===========================================
-- USERS TABLE (comes built-in on Supabase)
-- ===========================================
-- We will extend it with profiles

CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username TEXT UNIQUE NOT NULL,
    email TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    
    -- Profile information
    avatar_url TEXT,
    display_name TEXT,
    bio TEXT,
    
    -- App preferences
    notifications_enabled BOOLEAN DEFAULT TRUE,
    dark_mode BOOLEAN DEFAULT FALSE,
    sound_enabled BOOLEAN DEFAULT TRUE,
    
    -- Constraints
    CONSTRAINT username_length CHECK (char_length(username) >= 3 AND char_length(username) <= 20),
    CONSTRAINT username_format CHECK (username ~ '^[a-zA-Z0-9_]+$')
);

-- ===========================================
-- APP SETTINGS / USER SETTINGS
-- ===========================================
CREATE TABLE user_settings (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,

    daily_screen_time_limit INTEGER DEFAULT 0, -- e.g. minutes users set
    reward_notifications BOOLEAN DEFAULT TRUE,
    strict_mode BOOLEAN DEFAULT FALSE,
    allow_override BOOLEAN DEFAULT TRUE,

    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- ===========================================
-- SOCIAL MEDIA USAGE TRACKING
-- ===========================================
CREATE TABLE app_usage_sessions (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    
    app_name TEXT NOT NULL,          -- "Instagram", "TikTok", "X", etc.
    started_at TIMESTAMPTZ NOT NULL,
    ended_at TIMESTAMPTZ,            -- null if currently running
    duration_seconds INTEGER,        -- auto-calculated by backend

    created_at TIMESTAMPTZ DEFAULT now()
);

-- ===========================================
-- DAILY STATS (AGGREGATED)
-- ===========================================
CREATE TABLE daily_summaries (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,

    date DATE NOT NULL,
    total_seconds INTEGER DEFAULT 0,
    app_breakdown JSONB DEFAULT '{}', -- {"Instagram":1200, "TikTok":900, ...}

    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(user_id, date)
);

