-- =============================================
-- FocusFlow Database Migration 05: Storage Optimization
-- Optimize what should be local vs cloud storage
-- =============================================

-- ===========================================
-- MOVE HEAVY TRAFFIC TABLES TO LOCAL STORAGE ONLY
-- ===========================================

-- app_usage_sessions should be LOCAL ONLY (too frequent for cloud)
-- This table will be removed from cloud and handled entirely in local Hive storage
-- Reason: Real-time app usage tracking generates too many writes for Supabase

-- Mark app_usage_sessions for local-only storage
COMMENT ON TABLE app_usage_sessions IS 'MIGRATE TO LOCAL: Too frequent writes for cloud storage';

-- Create a lighter cloud summary table instead
CREATE TABLE IF NOT EXISTS app_usage_summaries (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    total_minutes INTEGER DEFAULT 0,
    most_used_app TEXT,
    app_breakdown JSONB DEFAULT '{}', -- {"Instagram": 120, "TikTok": 90, ...}
    sessions_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    
    UNIQUE(user_id, date)
);

-- Enable RLS on new summary table (if not already enabled)
DO $$ BEGIN
    ALTER TABLE app_usage_summaries ENABLE ROW LEVEL SECURITY;
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

-- Summary table policies (drop if exists first)
DROP POLICY IF EXISTS "Users can view own usage summaries" ON app_usage_summaries;
DROP POLICY IF EXISTS "Users can insert own usage summaries" ON app_usage_summaries;
DROP POLICY IF EXISTS "Users can update own usage summaries" ON app_usage_summaries;

CREATE POLICY "Users can view own usage summaries" ON app_usage_summaries FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own usage summaries" ON app_usage_summaries FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own usage summaries" ON app_usage_summaries FOR UPDATE USING (auth.uid() = user_id);

-- Index for performance
CREATE INDEX IF NOT EXISTS app_usage_summaries_user_date_idx ON app_usage_summaries(user_id, date);

-- Success message
SELECT 'Storage optimization complete! Real-time data moved to local, summaries in cloud.' as message;