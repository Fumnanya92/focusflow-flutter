#!/bin/bash

echo "🔧 Force recreating the trigger function..."

SUPABASE_URL="https://zulkbxcxxplruibcewqb.supabase.co"
SERVICE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp1bGtieGN4eHBscnVpYmNld3FiIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NDM1NjU1OCwiZXhwIjoyMDc5OTMyNTU4fQ.8YWJ3YKaGfi3YVJ2hAQ_RQJVANaghbVcKUz6M7ny-Fk"

# Drop and recreate completely
echo "Step 1: Dropping old trigger and function..."
DROP_SQL="
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users CASCADE;
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
"

response1=$(curl -s -X POST "$SUPABASE_URL/rest/v1/rpc/exec_sql" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $SERVICE_KEY" \
    -H "apikey: $SERVICE_KEY" \
    -d "{\"sql\": \"$DROP_SQL\"}")

if [[ $response1 == *"error"* ]]; then
    echo "❌ Error dropping: $response1"
else
    echo "✅ Old trigger/function dropped"
fi

# Create new function with explicit length limits
echo "Step 2: Creating new function..."
CREATE_SQL="
CREATE OR REPLACE FUNCTION public.handle_new_user() 
RETURNS trigger 
LANGUAGE plpgsql 
SECURITY DEFINER
AS \\\$\\\$
DECLARE
    base_username text;
    final_username text;
    attempt_count integer := 0;
BEGIN
    -- Extract and truncate username to max 15 chars (leaving room for _suffix)
    base_username := left(split_part(NEW.email, '@', 1), 15);
    
    -- Clean up - only allow alphanumeric and underscore
    base_username := regexp_replace(base_username, '[^a-zA-Z0-9_]', '', 'g');
    
    -- Ensure minimum length
    IF length(base_username) < 3 THEN
        base_username := 'user' || floor(random() * 100)::text;
    END IF;
    
    -- Start with base username
    final_username := base_username;
    
    -- Ensure it's within 20 char limit
    IF length(final_username) > 20 THEN
        final_username := left(final_username, 20);
    END IF;
    
    -- Handle duplicates by adding suffix
    WHILE EXISTS(SELECT 1 FROM profiles WHERE username = final_username) LOOP
        attempt_count := attempt_count + 1;
        -- Make sure suffix doesn't make it too long
        final_username := left(base_username, 15) || '_' || attempt_count::text;
        
        IF length(final_username) > 20 THEN
            final_username := left(base_username, 10) || '_' || attempt_count::text;
        END IF;
        
        -- Prevent infinite loop
        IF attempt_count > 50 THEN
            final_username := 'user_' || floor(random() * 10000)::text;
            EXIT;
        END IF;
    END LOOP;
    
    -- Final safety check
    IF length(final_username) > 20 THEN
        final_username := left(final_username, 20);
    END IF;
    
    -- Insert the profile
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
        -- Log error but don't fail signup
        RAISE LOG 'Error in handle_new_user for %: %', NEW.email, SQLERRM;
        RETURN NEW;
END;
\\\$\\\$;
"

response2=$(curl -s -X POST "$SUPABASE_URL/rest/v1/rpc/exec_sql" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $SERVICE_KEY" \
    -H "apikey: $SERVICE_KEY" \
    -d "{\"sql\": \"$CREATE_SQL\"}")

if [[ $response2 == *"error"* ]]; then
    echo "❌ Error creating function: $response2"
else
    echo "✅ New function created"
fi

# Recreate trigger
echo "Step 3: Creating trigger..."
TRIGGER_SQL="
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
"

response3=$(curl -s -X POST "$SUPABASE_URL/rest/v1/rpc/exec_sql" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $SERVICE_KEY" \
    -H "apikey: $SERVICE_KEY" \
    -d "{\"sql\": \"$TRIGGER_SQL\"}")

if [[ $response3 == *"error"* ]]; then
    echo "❌ Error creating trigger: $response3"
else
    echo "✅ New trigger created"
fi

echo ""
echo "🧪 Testing with a new short email..."

ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp1bGtieGN4eHBscnVpYmNld3FiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNTY1NTgsImV4cCI6MjA3OTkzMjU1OH0.acWOipPiG1LaV3wtJ5Oqjthq7d2z9t-qAyAd_wmQICs"

# Use a shorter email to test
SHORT_EMAIL="test$(date +%s | tail -c 6)@example.com"
PAYLOAD='{
    "email": "'$SHORT_EMAIL'",
    "password": "testpassword123"
}'

echo "Testing with email: $SHORT_EMAIL"
signup_response=$(curl -s -X POST "$SUPABASE_URL/auth/v1/signup" \
    -H "Content-Type: application/json" \
    -H "apikey: $ANON_KEY" \
    -d "$PAYLOAD")

echo "Response: $signup_response"

if [[ $signup_response == *'"id":'* ]] && [[ ! $signup_response == *'"error"'* ]]; then
    echo "🎉 SUCCESS! The fix worked!"
else
    echo "❌ Still failing: $signup_response"
fi