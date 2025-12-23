#!/bin/bash

echo "🧪 Testing signup with email confirmation disabled..."

SUPABASE_URL="https://zulkbxcxxplruibcewqb.supabase.co"
ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp1bGtieGN4eHBscnVpYmNld3FiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNTY1NTgsImV4cCI6MjA3OTkzMjU1OH0.acWOipPiG1LaV3wtJ5Oqjthq7d2z9t-qAyAd_wmQICs"

# Check auth settings
echo "Checking current auth settings..."
settings_response=$(curl -s -X GET "$SUPABASE_URL/rest/v1/auth/settings" \
    -H "apikey: $ANON_KEY")

echo "Auth settings: $settings_response"

# Try signup with autoconfirm
TEST_EMAIL="autoconfirm$(date +%s)@example.com"
PAYLOAD='{
    "email": "'$TEST_EMAIL'",
    "password": "testpassword123",
    "options": {
        "emailRedirectTo": null,
        "data": {}
    }
}'

echo ""
echo "Testing signup with email: $TEST_EMAIL"
signup_response=$(curl -s -X POST "$SUPABASE_URL/auth/v1/signup" \
    -H "Content-Type: application/json" \
    -H "apikey: $ANON_KEY" \
    -d "$PAYLOAD")

echo "Full signup response:"
echo "$signup_response" | python -m json.tool 2>/dev/null || echo "$signup_response"

# Check what the specific error is
if [[ $signup_response == *'"error_id"'* ]]; then
    ERROR_ID=$(echo $signup_response | grep -o '"error_id":"[^"]*"' | sed 's/"error_id":"\([^"]*\)"/\1/')
    echo ""
    echo "❌ Error ID: $ERROR_ID"
    echo "This suggests an internal Supabase configuration issue"
fi