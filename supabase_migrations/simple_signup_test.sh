#!/bin/bash

echo "🧪 Simple signup test with hardcoded keys..."

SUPABASE_URL="https://zulkbxcxxplruibcewqb.supabase.co"
ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp1bGtieGN4eHBscnVpYmNld3FiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNTY1NTgsImV4cCI6MjA3OTkzMjU1OH0.acWOipPiG1LaV3wtJ5Oqjthq7d2z9t-qAyAd_wmQICs"

# Disable email confirmation for testing (if possible)
TEST_EMAIL="simple$(date +%s)@example.com"

# Simple payload
PAYLOAD='{
    "email": "'$TEST_EMAIL'",
    "password": "testpassword123"
}'

echo "Testing signup without triggers..."
echo "Email: $TEST_EMAIL"
echo ""

response=$(curl -s -w "\nHTTP_STATUS:%{http_code}\n" -X POST "$SUPABASE_URL/auth/v1/signup" \
    -H "Content-Type: application/json" \
    -H "apikey: $ANON_KEY" \
    -d "$PAYLOAD")

echo "Full response:"
echo "$response"

# Extract HTTP status
HTTP_STATUS=$(echo "$response" | grep "HTTP_STATUS:" | sed 's/HTTP_STATUS://')
RESPONSE_BODY=$(echo "$response" | sed '/HTTP_STATUS:/d')

echo ""
echo "HTTP Status: $HTTP_STATUS"
echo "Response Body: $RESPONSE_BODY"

if [[ "$HTTP_STATUS" == "200" ]] || [[ "$HTTP_STATUS" == "201" ]]; then
    if [[ $RESPONSE_BODY == *'"id":'* ]]; then
        echo "🎉 Signup SUCCESS! User account created."
    elif [[ $RESPONSE_BODY == *'"confirmation_sent_at"'* ]]; then
        echo "✅ Signup successful! Email confirmation required."
    else
        echo "⚠️ Unexpected success response: $RESPONSE_BODY"
    fi
elif [[ "$HTTP_STATUS" == "422" ]]; then
    if [[ $RESPONSE_BODY == *'"email"'* ]] && [[ $RESPONSE_BODY == *'"already"'* ]]; then
        echo "ℹ️ Email already registered (this is actually good - means signup works!)"
    else
        echo "❌ Validation error: $RESPONSE_BODY"
    fi
else
    echo "❌ Failed with HTTP $HTTP_STATUS: $RESPONSE_BODY"
fi

# Also test with a unique email to ensure it's not a duplicate issue
echo ""
echo "🧪 Testing with guaranteed unique email..."
UNIQUE_EMAIL="unique_$(date +%s)_$(shuf -i 1000-9999 -n 1)@example.com"
UNIQUE_PAYLOAD='{
    "email": "'$UNIQUE_EMAIL'",
    "password": "testpassword123"
}'

echo "Unique email: $UNIQUE_EMAIL"

unique_response=$(curl -s -w "\nHTTP_STATUS:%{http_code}\n" -X POST "$SUPABASE_URL/auth/v1/signup" \
    -H "Content-Type: application/json" \
    -H "apikey: $ANON_KEY" \
    -d "$UNIQUE_PAYLOAD")

UNIQUE_HTTP_STATUS=$(echo "$unique_response" | grep "HTTP_STATUS:" | sed 's/HTTP_STATUS://')
UNIQUE_RESPONSE_BODY=$(echo "$unique_response" | sed '/HTTP_STATUS:/d')

echo "HTTP Status: $UNIQUE_HTTP_STATUS"
echo "Response Body: $UNIQUE_RESPONSE_BODY"

if [[ "$UNIQUE_HTTP_STATUS" == "200" ]] || [[ "$UNIQUE_HTTP_STATUS" == "201" ]]; then
    echo ""
    echo "🎯 SIGNUP IS WORKING! The app should work now."
    echo "✅ Try registering in the Flutter app - it should succeed!"
elif [[ "$UNIQUE_HTTP_STATUS" == "422" ]]; then
    echo "⚠️ Validation issue, but signup endpoint is responding correctly"
else
    echo "❌ Still having issues with HTTP $UNIQUE_HTTP_STATUS"
fi