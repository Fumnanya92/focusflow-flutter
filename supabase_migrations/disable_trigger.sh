#!/bin/bash

# Disable trigger and test signup without it
echo "🚫 Disabling signup trigger to isolate issue..."

SUPABASE_URL="https://zulkbxcxxplruibcewqb.supabase.co"
SUPABASE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp1bGtieGN4eHBscnVpYmNld3FiIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NDM1NjU1OCwiZXhwIjoyMDc5OTMyNTU4fQ.8YWJ3YKaGfi3YVJ2hAQ_RQJVANaghbVcKUz6M7ny-Fk"

# Drop the trigger completely
SQL_DISABLE="DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;"

echo "Disabling trigger..."
response=$(curl -s -X POST "$SUPABASE_URL/rest/v1/rpc/exec_sql" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $SUPABASE_KEY" \
    -H "apikey: $SUPABASE_KEY" \
    -d "{\"sql\": \"$SQL_DISABLE\"}")

if [[ $response == *"error"* ]]; then
    echo "❌ Failed to disable trigger: $response"
else
    echo "✅ Trigger disabled!"
fi