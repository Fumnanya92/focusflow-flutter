#!/bin/bash

# =============================================
# FocusFlow Database Migration Runner
# Run this to execute all migrations in order
# =============================================

echo "🚀 Starting FocusFlow Database Migration..."

# Supabase connection (replace with your actual values)
SUPABASE_URL="https://zulkbxcxxplruibcewqb.supabase.co"
SUPABASE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp1bGtieGN4eHBscnVpYmNld3FiIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NDM1NjU1OCwiZXhwIjoyMDc5OTMyNTU4fQ.8YWJ3YKaGfi3YVJ2hAQ_RQJVANaghbVcKUz6M7ny-Fk"

# Array of migration files in order
MIGRATIONS=(
    "01_cleanup.sql"
    "02_core_tables.sql" 
    "03_gamification_clean.sql"
    "04_app_blocking.sql"
    "05_challenges.sql"
    "06_security_policies.sql"
    "07_functions_triggers.sql"
    "08_performance_indexes.sql"
)

# Execute each migration
for migration in "${MIGRATIONS[@]}"; do
    echo "📝 Running $migration..."
    
    # Read SQL file and execute via curl
    sql_content=$(cat "$migration")
    
    response=$(curl -s -X POST "$SUPABASE_URL/rest/v1/rpc/exec_sql" \
        -H "apikey: $SUPABASE_KEY" \
        -H "Authorization: Bearer $SUPABASE_KEY" \
        -H "Content-Type: application/json" \
        -d "{\"sql\": $(echo "$sql_content" | jq -R -s .)}")
    
    if [ $? -eq 0 ]; then
        echo "✅ $migration completed successfully"
    else
        echo "❌ Error in $migration: $response"
        exit 1
    fi
done

echo "🎉 All migrations completed successfully!"
echo "📊 Your FocusFlow database is ready!"