#!/bin/bash

echo "🧪 Testing signup with fixed trigger..."

SUPABASE_URL="https://zulkbxcxxplruibcewqb.supabase.co"
ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp1bGtieGN4eHBscnVpYmNld3FiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNTY1NTgsImV4cCI6MjA3OTkzMjU1OH0.acWOipPiG1LaV3wtJ5Oqjthq7d2z9t-qAyAd_wmQICs"

# Test with a long email that would have failed before
TEST_EMAIL="verylongemailname$(date +%s)@example.com"
PAYLOAD='{
    "email": "'$TEST_EMAIL'",
    "password": "testpassword123"
}'

echo "Testing signup with long email: $TEST_EMAIL"
response=$(curl -s -X POST "$SUPABASE_URL/auth/v1/signup" \
    -H "Content-Type: application/json" \
    -H "apikey: $ANON_KEY" \
    -d "$PAYLOAD")

echo ""
echo "Full response:"
echo "$response" | python -m json.tool 2>/dev/null || echo "$response"

if [[ $response == *'"id":'* ]] && [[ ! $response == *'"error"'* ]]; then
    echo ""
    echo "🎉 SUCCESS! Signup worked!"
    
    # Extract user info
    USER_ID=$(echo $response | grep -o '"id":"[^"]*"' | head -1 | sed 's/"id":"\([^"]*\)"/\1/')
    EMAIL=$(echo $response | grep -o '"email":"[^"]*"' | head -1 | sed 's/"email":"\([^"]*\)"/\1/')
    
    echo "✅ User ID: $USER_ID"
    echo "✅ Email: $EMAIL"
    echo ""
    echo "🎯 The app should now work for user registration!"
    
else
    echo ""
    echo "❌ Still having issues. Response details:"
    echo "$response"
fi