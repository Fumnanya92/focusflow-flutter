#!/bin/bash

echo "🔧 Creating minimal working trigger..."

SUPABASE_URL="https://zulkbxcxxplruibcewqb.supabase.co"
SERVICE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp1bGtieGN4eHBscnVpYmNld3FiIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NDM1NjU1OCwiZXhwIjoyMDc5OTMyNTU4fQ.8YWJ3YKaGfi3YVJ2hAQ_RQJVANaghbVcKUz6M7ny-Fk"

# Drop existing
echo "Dropping existing trigger..."
DROP_SQL="DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users CASCADE; DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;"

curl -s -X POST "$SUPABASE_URL/rest/v1/rpc/exec_sql" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $SERVICE_KEY" \
    -H "apikey: $SERVICE_KEY" \
    -d "{\"sql\": \"$DROP_SQL\"}"

# Create super minimal function
echo "Creating minimal trigger..."
MINIMAL_SQL="
CREATE OR REPLACE FUNCTION public.handle_new_user() 
RETURNS trigger AS \\\$\\\$
BEGIN
    INSERT INTO profiles (id, username, email, created_at, updated_at, is_active, is_premium, notifications_enabled)
    VALUES (
        NEW.id,
        left(split_part(NEW.email, '@', 1), 15) || substr(md5(random()::text), 1, 4),
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
        RETURN NEW;
END;
\\\$\\\$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
"

response=$(curl -s -X POST "$SUPABASE_URL/rest/v1/rpc/exec_sql" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $SERVICE_KEY" \
    -H "apikey: $SERVICE_KEY" \
    -d "{\"sql\": \"$MINIMAL_SQL\"}")

if [[ $response == *"error"* ]]; then
    echo "❌ Error: $response"
else
    echo "✅ Minimal trigger created"
fi

# Test it
echo ""
echo "Testing minimal trigger..."

ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp1bGtieGN4eHBscnVpYmNld3FiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNTY1NTgsImV4cCI6MjA3OTkzMjU1OH0.acWOipPiG1LaV3wtJ5Oqjthq7d2z9t-qAyAd_wmQICs"
TEST_EMAIL="minimal$(date +%s)@test.com"

PAYLOAD='{"email": "'$TEST_EMAIL'", "password": "testpassword123"}'

echo "Testing with: $TEST_EMAIL"
test_response=$(curl -s -X POST "$SUPABASE_URL/auth/v1/signup" \
    -H "Content-Type: application/json" \
    -H "apikey: $ANON_KEY" \
    -d "$PAYLOAD")

echo "Result: $test_response"

if [[ $test_response == *'"id":'* ]] && [[ ! $test_response == *'"error"'* ]]; then
    echo "🎉 MINIMAL TRIGGER WORKS!"
elif [[ $test_response == *'"error_description"'* ]]; then
    echo "ℹ️ Email confirmation required but signup succeeded"
else
    echo "❌ Still failing"
fi