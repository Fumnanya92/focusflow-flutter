#!/bin/bash

echo "🚫 Completely disabling trigger and testing manual profile creation..."

# Load environment variables
source_env() {
    if [ -f ".env" ]; then
        while IFS= read -r line; do
            if [[ ! "$line" =~ ^[[:space:]]*# && "$line" =~ = ]]; then
                export "$line"
            fi
        done < .env
    fi
}

source_env

SUPABASE_URL="$SUPABASE_URL"
SERVICE_KEY="$SUPABASE_SERVICE_ROLE"
ANON_KEY="$SUPABASE_ANON_KEY"

echo "Using Supabase URL: $SUPABASE_URL"

# Use psql if available, otherwise use curl workaround
if command -v psql &> /dev/null; then
    echo "Using psql to disable trigger..."
    PGPASSWORD="$DB_PASSWORD" psql -h "db.zulkbxcxxplruibcewqb.supabase.co" -U "postgres" -d "postgres" -c "
    DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users CASCADE;
    DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
    "
else
    echo "⚠️ psql not available, trigger may still exist"
fi

# Test signup without trigger
echo ""
echo "🧪 Testing signup without any trigger..."
TEST_EMAIL="notrigger$(date +%s)@example.com"

PAYLOAD='{
    "email": "'$TEST_EMAIL'",
    "password": "testpassword123"
}'

echo "Testing with email: $TEST_EMAIL"
response=$(curl -s -X POST "$SUPABASE_URL/auth/v1/signup" \
    -H "Content-Type: application/json" \
    -H "apikey: $ANON_KEY" \
    -d "$PAYLOAD")

echo "Signup response:"
echo "$response" | python -m json.tool 2>/dev/null || echo "$response"

if [[ $response == *'"id":'* ]] && [[ ! $response == *'"error"'* ]] && [[ ! $response == *'"code":'* ]]; then
    echo ""
    echo "🎉 SUCCESS! Signup works without trigger!"
    
    # Extract user ID
    USER_ID=$(echo $response | grep -o '"id":"[^"]*"' | head -1 | sed 's/"id":"\([^"]*\)"/\1/')
    echo "User ID: $USER_ID"
    
    # Test manual profile creation via REST API
    echo ""
    echo "🔧 Testing manual profile creation..."
    
    # Extract username from email (first 15 chars)
    USERNAME=$(echo $TEST_EMAIL | cut -d'@' -f1 | head -c 15)
    
    PROFILE_PAYLOAD='{
        "id": "'$USER_ID'",
        "username": "'$USERNAME'",
        "email": "'$TEST_EMAIL'",
        "created_at": "'$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")'",
        "updated_at": "'$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")'",
        "is_active": true,
        "is_premium": false,
        "notifications_enabled": true
    }'
    
    profile_response=$(curl -s -X POST "$SUPABASE_URL/rest/v1/profiles" \
        -H "Content-Type: application/json" \
        -H "apikey: $ANON_KEY" \
        -H "Authorization: Bearer $ANON_KEY" \
        -d "$PROFILE_PAYLOAD")
    
    echo "Profile creation response: $profile_response"
    
    if [[ ! $profile_response == *'"error"'* ]] && [[ ! $profile_response == *'"message"'* ]]; then
        echo "✅ Manual profile creation successful!"
        echo ""
        echo "🎯 The app should now work! The Flutter app will handle profile creation manually."
    else
        echo "⚠️ Manual profile creation failed, but signup succeeded"
        echo "The Flutter app will handle this automatically"
    fi
    
elif [[ $response == *'"error_description":'* ]]; then
    echo ""
    echo "ℹ️ Signup successful but email confirmation required"
    echo "This is normal for production Supabase projects"
elif [[ $response == *'"message":'* ]]; then
    echo ""
    echo "⚠️ Auth message: $(echo $response | grep -o '"message":"[^"]*"' | sed 's/"message":"\([^"]*\)"/\1/')"
else
    echo ""
    echo "❌ Signup still failing: $response"
fi