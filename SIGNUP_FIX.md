# Signup Issue Fix

## Problem
The database trigger `on_auth_user_created` is failing when creating user profiles.

## Solution Options

### Option 1: Fix via Supabase Dashboard (RECOMMENDED)
1. Go to https://app.supabase.com
2. Open your project: https://zulkbxcxxplruibcewqb.supabase.co
3. Go to SQL Editor
4. Run this SQL:
```sql
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users CASCADE;
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
```

### Option 2: Contact Support
If you can't access the dashboard, contact Supabase support to disable the trigger.

### Why This Fixes It
The trigger is trying to create profiles automatically but failing due to:
- Username length constraints (max 20 chars)
- Email prefixes being too long
- Trigger logic errors

Once disabled, the Flutter app will create profiles manually using the enhanced auth provider we built.

## After Fixing
1. The app will handle profile creation through the `_createUserProfile()` method
2. Usernames will be properly constrained to 15 characters
3. All related records (user_settings, user_points) will be created correctly

## Test Again
After disabling the trigger, try signing up again with:
- Username: G_reviewer
- Email: fynkotechnologies@gmail.com
- Password: [your password]

It should work!
