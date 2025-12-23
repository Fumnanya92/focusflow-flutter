#!/bin/bash

echo "🧪 Testing signup with constrained username length..."

SUPABASE_URL="https://zulkbxcxxplruibcewqb.supabase.co"
ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp1bGtieGN4eHBscnVpYmNld3FiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzNTY1NTgsImV4cCI6MjA3OTkzMjU1OH0.acWOipPiG1LaV3wtJ5Oqjthq7d2z9t-qAyAd_wmQICs"

# Test with a username that's exactly 15 characters (safe limit)
TEST_EMAIL="testuser$(date +%s | tail -c 6)@example.com"
SHORT_USERNAME="testuser$(date +%s | tail -c 5)"  # 12-13 chars

echo "Testing with:"
echo "Email: $TEST_EMAIL"
echo "Username: $SHORT_USERNAME (length: ${#SHORT_USERNAME})"

PAYLOAD='{
    "email": "'$TEST_EMAIL'",
    "password": "testpassword123",
    "data": {
        "username": "'$SHORT_USERNAME'"
    }
}'

echo ""
echo "Sending signup request..."
response=$(curl -s -w "\nHTTP_STATUS:%{http_code}\n" -X POST "$SUPABASE_URL/auth/v1/signup" \
    -H "Content-Type: application/json" \
    -H "apikey: $ANON_KEY" \
    -d "$PAYLOAD")

HTTP_STATUS=$(echo "$response" | grep "HTTP_STATUS:" | sed 's/HTTP_STATUS://')
RESPONSE_BODY=$(echo "$response" | sed '/HTTP_STATUS:/d')

echo ""
echo "HTTP Status: $HTTP_STATUS"
echo "Response Body:"
echo "$RESPONSE_BODY" | python -m json.tool 2>/dev/null || echo "$RESPONSE_BODY"

if [[ "$HTTP_STATUS" == "200" ]] || [[ "$HTTP_STATUS" == "201" ]]; then
    echo ""
    echo "🎉 SUCCESS! Signup worked with shorter username!"
    
    # Check if user was created
    if [[ $RESPONSE_BODY == *'"id":'* ]]; then
        USER_ID=$(echo "$RESPONSE_BODY" | grep -o '"id":"[^"]*"' | head -1 | sed 's/"id":"\([^"]*\)"/\1/')
        echo "✅ User ID: $USER_ID"
        echo "✅ Email: $TEST_EMAIL"
        echo "✅ Username: $SHORT_USERNAME"
        echo ""
        echo "🎯 The Flutter app signup should now work!"
        echo "📱 Try registering in the app with a username 15 characters or shorter."
    elif [[ $RESPONSE_BODY == *'"confirmation_sent_at"'* ]]; then
        echo "✅ Signup successful! Email confirmation required."
    fi
    
elif [[ "$HTTP_STATUS" == "422" ]]; then
    if [[ $RESPONSE_BODY == *'"already"'* ]]; then
        echo "ℹ️ Email already exists - signup is working!"
    else
        echo "❌ Validation error: $RESPONSE_BODY"
    fi
elif [[ "$HTTP_STATUS" == "500" ]]; then
    if [[ $RESPONSE_BODY == *'"username_length"'* ]]; then
        echo "❌ Still username length issue"
    else
        echo "❌ 500 error: $RESPONSE_BODY"
    fi
else
    echo "❌ Failed with HTTP $HTTP_STATUS"
fi

# Test with an even shorter username for safety
echo ""
echo "🧪 Testing with extra short username..."
EXTRA_SHORT="user$(date +%s | tail -c 4)"  # 8 chars
EXTRA_EMAIL="short$(date +%s | tail -c 6)@example.com"

echo "Username: $EXTRA_SHORT (length: ${#EXTRA_SHORT})"

EXTRA_PAYLOAD='{
    "email": "'$EXTRA_EMAIL'",
    "password": "testpassword123",
    "data": {
        "username": "'$EXTRA_SHORT'"
    }
}'

extra_response=$(curl -s -w "\nHTTP_STATUS:%{http_code}\n" -X POST "$SUPABASE_URL/auth/v1/signup" \
    -H "Content-Type: application/json" \
    -H "apikey: $ANON_KEY" \
    -d "$EXTRA_PAYLOAD")

EXTRA_HTTP_STATUS=$(echo "$extra_response" | grep "HTTP_STATUS:" | sed 's/HTTP_STATUS://')
EXTRA_RESPONSE_BODY=$(echo "$extra_response" | sed '/HTTP_STATUS:/d')

echo "HTTP Status: $EXTRA_HTTP_STATUS"

if [[ "$EXTRA_HTTP_STATUS" == "200" ]] || [[ "$EXTRA_HTTP_STATUS" == "201" ]]; then
    echo "🎉 PERFECT! Extra short username works!"
    echo "📱 Recommended: Use usernames 8-12 characters for reliability"
else
    echo "Result: $EXTRA_RESPONSE_BODY"
fi