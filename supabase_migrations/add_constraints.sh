#!/bin/bash

# Add unique constraint to user_points table
echo "🔧 Adding unique constraint to user_points table..."

SUPABASE_URL="https://zulkbxcxxplruibcewqb.supabase.co"
SUPABASE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp1bGtieGN4eHBscnVpYmNld3FiIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NDM1NjU1OCwiZXhwIjoyMDc5OTMyNTU4fQ.8YWJ3YKaGfi3YVJ2hAQ_RQJVANaghbVcKUz6M7ny-Fk"

SQL_CONSTRAINT="
-- Add unique constraint to user_points table to prevent duplicates
ALTER TABLE user_points ADD CONSTRAINT user_points_user_id_unique UNIQUE (user_id);

-- Also add to user_settings
ALTER TABLE user_settings ADD CONSTRAINT user_settings_user_id_unique UNIQUE (user_id);
"

echo "Adding unique constraints..."
response=$(curl -s -X POST "$SUPABASE_URL/rest/v1/rpc/exec_sql" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $SUPABASE_KEY" \
    -H "apikey: $SUPABASE_KEY" \
    -d "{\"sql\": \"$SQL_CONSTRAINT\"}")

if [[ $response == *"error"* ]]; then
    echo "⚠️ Constraint already exists or tables not ready: $response"
else
    echo "✅ Unique constraints added successfully!"
fi