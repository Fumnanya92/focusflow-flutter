#!/bin/bash

echo "🔧 Creating fixed trigger with proper username length handling..."

SUPABASE_URL="https://zulkbxcxxplruibcewqb.supabase.co"
SERVICE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp1bGtieGN4eHBscnVpYmNld3FiIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NDM1NjU1OCwiZXhwIjoyMDc5OTMyNTU4fQ.8YWJ3YKaGfi3YVJ2hAQ_RQJVANaghbVcKUz6M7ny-Fk"

# First re-enable RLS since we disabled it for testing
echo "Re-enabling RLS policies..."
RLS_SQL="
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_points ENABLE ROW LEVEL SECURITY;
ALTER TABLE badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE challenge_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE badge_conditions ENABLE ROW LEVEL SECURITY;
"

curl -s -X POST "$SUPABASE_URL/rest/v1/rpc/exec_sql" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $SERVICE_KEY" \
    -H "apikey: $SERVICE_KEY" \
    -d "{\"sql\": \"$RLS_SQL\"}"

# Create the fixed trigger function
FIXED_TRIGGER_SQL="
CREATE OR REPLACE FUNCTION public.handle_new_user() 
RETURNS trigger 
LANGUAGE plpgsql 
SECURITY DEFINER
AS \$\$
DECLARE
    base_username text;
    final_username text;
    attempt_count integer := 0;
BEGIN
    -- Extract base username from email and truncate to 15 chars max (leaving room for suffix)
    base_username := left(split_part(NEW.email, '@', 1), 15);
    
    -- Clean up the username (remove any non-alphanumeric except underscore)
    base_username := regexp_replace(base_username, '[^a-zA-Z0-9_]', '', 'g');
    
    -- Ensure it's at least 3 characters
    IF length(base_username) < 3 THEN
        base_username := 'user' || floor(random() * 1000)::text;
    END IF;
    
    final_username := base_username;
    
    -- Check if username exists, if so add suffix
    WHILE EXISTS(SELECT 1 FROM profiles WHERE username = final_username) LOOP
        attempt_count := attempt_count + 1;
        final_username := left(base_username, 15) || '_' || attempt_count::text;
        
        -- Safety check to prevent infinite loop
        IF attempt_count > 100 THEN
            final_username := 'user_' || floor(random() * 100000)::text;
            EXIT;
        END IF;
    END LOOP;
    
    -- Insert profile
    INSERT INTO profiles (id, username, email, created_at, updated_at, is_active, is_premium, notifications_enabled)
    VALUES (
        NEW.id,
        final_username,
        NEW.email,
        NOW(),
        NOW(),
        true,
        false,
        true
    );
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        RAISE LOG 'Error in handle_new_user for user %: %', NEW.email, SQLERRM;
        RETURN NEW; -- Don't fail the signup, just log the error
END;
\$\$;

-- Recreate the trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();
"

echo "Creating fixed trigger function..."
response=$(curl -s -X POST "$SUPABASE_URL/rest/v1/rpc/exec_sql" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $SERVICE_KEY" \
    -H "apikey: $SERVICE_KEY" \
    -d "{\"sql\": \"$FIXED_TRIGGER_SQL\"}")

if [[ $response == *"error"* ]]; then
    echo "❌ Failed to create fixed trigger: $response"
else
    echo "✅ Fixed trigger created successfully!"
fi