#!/bin/bash

# Test FocusFlow Database Connection and Tables
echo "🔍 Testing FocusFlow database connection..."

SUPABASE_URL="https://zulkbxcxxplruibcewqb.supabase.co"
SUPABASE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp1bGtieGN4eHBscnVpYmNld3FiIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NDM1NjU1OCwiZXhwIjoyMDc5OTMyNTU4fQ.8YWJ3YKaGfi3YVJ2hAQ_RQJVANaghbVcKUz6M7ny-Fk"

# Check if essential tables exist
echo "📋 Checking if required tables exist..."
SQL_CHECK="
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('profiles', 'user_settings', 'user_points')
ORDER BY table_name;
"

response=$(curl -s -X POST "$SUPABASE_URL/rest/v1/rpc/exec_sql" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $SUPABASE_KEY" \
    -H "apikey: $SUPABASE_KEY" \
    -d "{\"sql\": \"$SQL_CHECK\"}")

echo "Tables found: $response"

# Check if trigger function exists
echo "🔧 Checking if trigger function exists..."
SQL_TRIGGER_CHECK="
SELECT proname, prosrc 
FROM pg_proc 
WHERE proname = 'handle_new_user';
"

trigger_response=$(curl -s -X POST "$SUPABASE_URL/rest/v1/rpc/exec_sql" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $SUPABASE_KEY" \
    -H "apikey: $SUPABASE_KEY" \
    -d "{\"sql\": \"$SQL_TRIGGER_CHECK\"}")

echo "Trigger function: $trigger_response"

# Test if we can create a simple profile
echo "👤 Testing profile creation..."
TEST_USER_ID=$(uuidgen)
SQL_PROFILE_TEST="
INSERT INTO public.profiles (id, username, email) 
VALUES ('$TEST_USER_ID', 'testuser123', 'test@example.com')
RETURNING id, username;
"

profile_response=$(curl -s -X POST "$SUPABASE_URL/rest/v1/rpc/exec_sql" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $SUPABASE_KEY" \
    -H "apikey: $SUPABASE_KEY" \
    -d "{\"sql\": \"$SQL_PROFILE_TEST\"}")

echo "Profile creation test: $profile_response"

# Clean up test data
SQL_CLEANUP="DELETE FROM public.profiles WHERE id = '$TEST_USER_ID';"
curl -s -X POST "$SUPABASE_URL/rest/v1/rpc/exec_sql" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $SUPABASE_KEY" \
    -H "apikey: $SUPABASE_KEY" \
    -d "{\"sql\": \"$SQL_CLEANUP\"}" > /dev/null

echo "✅ Database test completed"