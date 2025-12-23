#!/bin/bash

# Test signup with correct anon key from .env
echo "🧪 Testing Supabase signup with CORRECT anon key..."

SUPABASE_URL="https://zulkbxcxxplruibcewqb.supabase.co"
ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp1bGtieGN4eHBscnVpYmNld3FiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNTY1NTgsImV4cCI6MjA3OTkzMjU1OH0.acWOipPiG1LaV3wtJ5Oqjthq7d2z9t-qAyAd_wmQICs"

TEST_EMAIL="realtest$(date +%s)@example.com"
PAYLOAD='{
    "email": "'$TEST_EMAIL'",
    "password": "testpassword123",
    "data": {}
}'

echo "Testing signup with email: $TEST_EMAIL"
response=$(curl -s -X POST "$SUPABASE_URL/auth/v1/signup" \
    -H "Content-Type: application/json" \
    -H "apikey: $ANON_KEY" \
    -d "$PAYLOAD")

echo "Signup response: $response"

if [[ $response == *'"error"'* ]] || [[ $response == *'"message"'* ]] || [[ $response == *'"code"'* ]]; then
    echo "❌ Signup failed with error"
    echo "Response details: $response"
else
    echo "✅ Signup SUCCESS! User created successfully"
    
    # Extract user ID from response
    USER_ID=$(echo $response | grep -o '"id":"[^"]*"' | head -1 | sed 's/"id":"\([^"]*\)"/\1/')
    if [ ! -z "$USER_ID" ]; then
        echo "✅ User ID: $USER_ID"
        echo "✅ Account created and ready to use!"
    fi
fi