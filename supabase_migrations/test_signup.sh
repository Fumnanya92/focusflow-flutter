#!/bin/bash

# Test Supabase Auth Signup with correct anon key
echo "🧪 Testing Supabase signup with anon key..."

SUPABASE_URL="https://zulkbxcxxplruibcewqb.supabase.co"
ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp1bGtieGN4eHBscnVpYmNld3FiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNTY1NTgsImV4cCI6MjA3OTkzMjU1OH0.acWOipPiG1LaV3wtJ5Oqjthq7d2z9t-qAyAd_wmQICs"

# Test signup with a dummy email
TEST_EMAIL="test$(date +%s)@example.com"
TEST_PASSWORD="testpass123"
TEST_USERNAME="testuser$(date +%s)"

echo "Testing signup for: $TEST_EMAIL"

signup_response=$(curl -s -X POST "$SUPABASE_URL/auth/v1/signup" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $ANON_KEY" \
    -H "apikey: $ANON_KEY" \
    -d "{
        \"email\": \"$TEST_EMAIL\",
        \"password\": \"$TEST_PASSWORD\",
        \"data\": {
            \"username\": \"$TEST_USERNAME\"
        }
    }")

echo "Signup response: $signup_response"

# Check if signup was successful
if [[ $signup_response == *"user"* && $signup_response == *"id"* ]]; then
    echo "✅ Signup test SUCCESSFUL!"
else
    echo "❌ Signup test FAILED!"
    if [[ $signup_response == *"error"* ]]; then
        echo "Error details: $signup_response"
    fi
fi

echo "🔍 If this test succeeds, the issue might be in the Flutter app code"
echo "🔍 If this test fails, there's a database/Supabase configuration issue"