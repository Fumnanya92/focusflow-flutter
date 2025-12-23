#!/bin/bash

# Fix database trigger for FocusFlow signup
# This script fixes the handle_new_user function to use correct table names

echo "🔧 Fixing FocusFlow database trigger..."

SUPABASE_URL="https://zulkbxcxxplruibcewqb.supabase.co"
SUPABASE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp1bGtieGN4eHBscnVpYmNld3FiIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NDM1NjU1OCwiZXhwIjoyMDc5OTMyNTU4fQ.8YWJ3YKaGfi3YVJ2hAQ_RQJVANaghbVcKUz6M7ny-Fk"

# Updated function to fix the trigger issue
SQL_FIX="
-- Drop existing trigger first
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Fixed function to handle new user signup
CREATE OR REPLACE FUNCTION public.handle_new_user() 
RETURNS TRIGGER AS \$\$
BEGIN
    -- Create user profile (with error handling)
    BEGIN
        INSERT INTO public.profiles (id, username, email)
        VALUES (
            NEW.id, 
            COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1)),
            NEW.email
        );
    EXCEPTION 
        WHEN unique_violation THEN
            -- Username already exists, append random number
            INSERT INTO public.profiles (id, username, email)
            VALUES (
                NEW.id, 
                COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1)) || '_' || floor(random() * 1000)::text,
                NEW.email
            );
    END;
    
    -- Initialize user settings
    INSERT INTO public.user_settings (user_id)
    VALUES (NEW.id)
    ON CONFLICT (user_id) DO NOTHING;
    
    -- Initialize user points (using correct table name)
    INSERT INTO public.user_points (user_id, total_points, level, current_streak_days, best_streak_days)
    VALUES (NEW.id, 0, 1, 0, 0)
    ON CONFLICT (user_id) DO NOTHING;
        
    RETURN NEW;
EXCEPTION 
    WHEN OTHERS THEN
        -- Log the error but don't fail the signup
        RAISE NOTICE 'Error in handle_new_user: %', SQLERRM;
        RETURN NEW;
END;
\$\$ LANGUAGE plpgsql SECURITY DEFINER;

-- Re-create trigger for new user creation
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();
"

echo "Executing database fix..."
response=$(curl -s -X POST "$SUPABASE_URL/rest/v1/rpc/exec_sql" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $SUPABASE_KEY" \
    -H "apikey: $SUPABASE_KEY" \
    -d "{\"sql\": \"$SQL_FIX\"}")

if [[ $response == *"error"* ]]; then
    echo "❌ Database fix failed: $response"
    exit 1
else
    echo "✅ Database trigger fixed successfully!"
    echo "ℹ️ Signup should now work properly"
fi