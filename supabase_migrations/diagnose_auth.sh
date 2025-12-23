#!/bin/bash

# Check row-level security policies that might be blocking signup
echo "🔍 Checking database policies..."

SUPABASE_URL="https://zulkbxcxxplruibcewqb.supabase.co"
SUPABASE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp1bGtieGN4eHBscnVpYmNld3FiIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NDM1NjU1OCwiZXhwIjoyMDc5OTMyNTU4fQ.8YWJ3YKaGfi3YVJ2hAQ_RQJVANaghbVcKUz6M7ny-Fk"

# Check if there are any policies on auth.users that might be blocking
echo "Checking auth.users table policies..."
SQL_CHECK="SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check 
           FROM pg_policies 
           WHERE schemaname = 'auth' AND tablename = 'users';"

response=$(curl -s -X POST "$SUPABASE_URL/rest/v1/rpc/exec_sql" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $SUPABASE_KEY" \
    -H "apikey: $SUPABASE_KEY" \
    -d "{\"sql\": \"$SQL_CHECK\"}")

echo "Auth policies response: $response"

# Try a simpler signup approach with basic auth
echo ""
echo "🧪 Testing basic Supabase auth signup..."
ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp1bGtieGN4eHBscnVpYmNld3FiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNTY1NTgsImV4cCI6MjA3OTkzMjU1OH0.sWFrIjVtQ3FlFpO9xkULizkN8j1qrI7cNWY85_Xhgwo"

SIMPLE_PAYLOAD='{
    "email": "simpletest'$(date +%s)'@example.com",
    "password": "testpassword123"
}'

echo "Testing with email: $(echo $SIMPLE_PAYLOAD | grep -o '[a-zA-Z0-9._%+-]*@[a-zA-Z0-9.-]*\.[a-zA-Z]{2,}')"
simple_response=$(curl -s -X POST "$SUPABASE_URL/auth/v1/signup" \
    -H "Content-Type: application/json" \
    -H "apikey: $ANON_KEY" \
    -d "$SIMPLE_PAYLOAD")

echo "Simple signup response: $simple_response"

if [[ $simple_response == *'"error"'* ]]; then
    echo "❌ Simple signup failed"
else
    echo "✅ Simple signup worked!"
fi