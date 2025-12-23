# Database Migrations

## Migration Files (Run in Order)

1. **01_cleanup.sql** - Clean up old/unused tables
2. **02_core_tables.sql** - Create core tables (profiles, user_settings, app_usage_sessions)
3. **03_gamification_clean.sql** - Gamification tables (points, badges, achievements)
4. **04_app_blocking.sql** - App blocking and focus session tables
5. **05_challenges.sql** - Challenge system tables
6. **06_security_policies.sql** - Row Level Security (RLS) policies
7. **07_functions_triggers.sql** - Database functions and triggers
8. **08_performance_indexes.sql** - Performance indexes on all tables
9. **09_critical_fixes.sql** - Critical fixes and optimizations

## Current Issue Fixes

### FIX_PROFILE_CREATION.sql
**Purpose**: Fix profile creation for all users and re-enable automatic profile creation trigger.

**What it does**:
- Adds missing columns (`is_active`, `is_premium`) to profiles table
- Re-creates trigger function with correct username constraints (3-15 chars)
- Loops through ALL existing users and creates profiles for anyone missing them
- Adds unique constraint to user_settings.user_id
- Enables trigger for automatic profile creation on new signups

**When to run**: 
- If users can register but profiles aren't being created
- After disabling the trigger manually
- To fix all existing users without profiles

**Expected result**: All users in auth.users will have corresponding profiles

---

### VERIFY_FIXES.sql
**Purpose**: Verify that FIX_PROFILE_CREATION.sql worked correctly.

**What it checks**:
- Profile exists for test users
- User settings created
- Trigger is enabled
- All required columns exist
- RLS policies are active
- Indexes are in place
- Count of users vs profiles

**When to run**: After running FIX_PROFILE_CREATION.sql

**Expected result**: All tests show "✅ PASS" and final status is "🎉 ALL CHECKS PASSED"

---

### CHECK_UNUSED_TABLES.sql
**Purpose**: Audit which tables are in use and which can be safely removed.

**What it does**:
- Lists all tables with their usage status
- Shows which tables are referenced in application code
- Identifies tables already removed by previous migrations

**When to run**: When auditing database for optimization

**Expected result**: Shows that all current tables are in active use

---

## Running Migrations

### Windows (PowerShell):
```powershell
.\run_migrations.bat
```

### Linux/Mac:
```bash
chmod +x run_migrations.sh
./run_migrations.sh
```

### Manual (Supabase Dashboard):
1. Open Supabase SQL Editor
2. Copy contents of each migration file
3. Run in order (01 through 09)
4. Run FIX_PROFILE_CREATION.sql
5. Run VERIFY_FIXES.sql to confirm

## Troubleshooting

**Problem**: "User registered but no profile created"
**Solution**: Run FIX_PROFILE_CREATION.sql

**Problem**: "Trigger errors on signup"
**Solution**: Check username constraints match (3-15 chars), run FIX_PROFILE_CREATION.sql

**Problem**: "RLS policy violations"
**Solution**: Ensure user is authenticated and policies are enabled (check 06_security_policies.sql)

**Problem**: "Slow queries"
**Solution**: Verify indexes exist (check 08_performance_indexes.sql)
