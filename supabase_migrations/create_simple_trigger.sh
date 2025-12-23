#!/bin/bash

# Simple signup trigger that only creates essential records
echo "🔧 Creating simplified signup trigger..."

SUPABASE_URL="https://zulkbxcxxplruibcewqb.supabase.co"
SUPABASE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp1bGtieGN4eHBscnVpYmNld3FiIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NDM1NjU1OCwiZXhwIjoyMDc5OTMyNTU4fQ.8YWJ3YKaGfi3YVJ2hAQ_RQJVANaghbVcKUz6M7ny-Fk"

SQL_SIMPLE="
-- Drop existing trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Simplified function that only creates profile
CREATE OR REPLACE FUNCTION public.handle_new_user() 
RETURNS TRIGGER AS \$\$
BEGIN
    -- Only create the profile - keep it simple
    INSERT INTO public.profiles (id, username, email)
    VALUES (
        NEW.id, 
        COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1)),
        NEW.email
    )
    ON CONFLICT (id) DO UPDATE SET
        username = EXCLUDED.username,
        email = EXCLUDED.email,
        updated_at = now();
        
    RETURN NEW;
EXCEPTION 
    WHEN OTHERS THEN
        -- Log error but don't fail
        RAISE NOTICE 'Profile creation error: %', SQLERRM;
        RETURN NEW;
END;
\$\$ LANGUAGE plpgsql SECURITY DEFINER;

-- Re-create trigger
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();
"

echo "Creating simplified trigger..."
response=$(curl -s -X POST "$SUPABASE_URL/rest/v1/rpc/exec_sql" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $SUPABASE_KEY" \
    -H "apikey: $SUPABASE_KEY" \
    -d "{\"sql\": \"$SQL_SIMPLE\"}")

if [[ $response == *"error"* ]]; then
    echo "❌ Failed to create trigger: $response"
else
    echo "✅ Simplified trigger created!"
fi