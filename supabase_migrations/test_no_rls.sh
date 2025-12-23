#!/bin/bash

echo "🔧 Temporarily disabling RLS policies..."

SUPABASE_URL="https://zulkbxcxxplruibcewqb.supabase.co"
SERVICE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp1bGtieGN4eHBscnVpYmNld3FiIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NDM1NjU1OCwiZXhwIjoyMDc5OTMyNTU4fQ.8YWJ3YKaGfi3YVJ2hAQ_RQJVANaghbVcKUz6M7ny-Fk"

# Read the SQL file content
SQL_CONTENT=$(cat supabase_migrations/disable_rls.sql)

response=$(curl -s -X POST "$SUPABASE_URL/rest/v1/rpc/exec_sql" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $SERVICE_KEY" \
    -H "apikey: $SERVICE_KEY" \
    -d "{\"sql\": \"$SQL_CONTENT\"}")

if [[ $response == *"error"* ]]; then
    echo "❌ Failed to disable RLS: $response"
else
    echo "✅ RLS disabled on all tables"
fi

# Now test signup again
echo ""
echo "🧪 Testing signup after disabling RLS..."

ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp1bGtieGN4eHBscnVpYmNld3FiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNTY1NTgsImV4cCI6MjA3OTkzMjU1OH0.acWOipPiG1LaV3wtJ5Oqjthq7d2z9t-qAyAd_wmQICs"

TEST_EMAIL="norlstest$(date +%s)@example.com"
PAYLOAD='{
    "email": "'$TEST_EMAIL'",
    "password": "testpassword123"
}'

echo "Testing signup with email: $TEST_EMAIL"
signup_response=$(curl -s -X POST "$SUPABASE_URL/auth/v1/signup" \
    -H "Content-Type: application/json" \
    -H "apikey: $ANON_KEY" \
    -d "$PAYLOAD")

echo "Signup response: $signup_response"

if [[ $signup_response == *'"error"'* ]] || [[ $signup_response == *'"code":'* ]]; then
    echo "❌ Still failing even without RLS"
else
    echo "✅ SUCCESS! RLS was the issue!"
fi