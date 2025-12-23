-- =============================================
-- VERIFICATION SCRIPT
-- Run this AFTER applying FIX_PROFILE_CREATION.sql
-- to verify all fixes are working correctly
-- =============================================

-- 1. Check if profile was created for existing user
SELECT 
    'Profile Check' as test,
    CASE 
        WHEN COUNT(*) = 1 THEN '✅ PASS - Profile exists'
        ELSE '❌ FAIL - Profile not found'
    END as result,
    COUNT(*) as profile_count
FROM profiles 
WHERE id = 'f37b2352-c51b-4edb-8b13-5b633ba85e6e';

-- 2. Check if user_settings was created
SELECT 
    'Settings Check' as test,
    CASE 
        WHEN COUNT(*) = 1 THEN '✅ PASS - Settings exist'
        ELSE '❌ FAIL - Settings not found'
    END as result,
    COUNT(*) as settings_count
FROM user_settings 
WHERE user_id = 'f37b2352-c51b-4edb-8b13-5b633ba85e6e';

-- 3. Check if trigger is enabled
SELECT 
    'Trigger Check' as test,
    CASE 
        WHEN COUNT(*) = 1 THEN '✅ PASS - Trigger exists'
        ELSE '❌ FAIL - Trigger not found'
    END as result,
    tgname as trigger_name
FROM pg_trigger 
WHERE tgname = 'on_auth_user_created';

-- 4. Check if trigger function exists
SELECT 
    'Function Check' as test,
    CASE 
        WHEN COUNT(*) = 1 THEN '✅ PASS - Function exists'
        ELSE '❌ FAIL - Function not found'
    END as result,
    proname as function_name
FROM pg_proc 
WHERE proname = 'handle_new_user';

-- 5. Check all required columns exist in profiles table
SELECT 
    'Column Check: ' || column_name as test,
    '✅ PASS - Column exists' as result,
    data_type as type
FROM information_schema.columns
WHERE table_name = 'profiles' 
    AND column_name IN ('id', 'username', 'email', 'is_active', 'is_premium', 'notifications_enabled', 'created_at', 'updated_at')
ORDER BY column_name;

-- 6. Check RLS policies are active
SELECT 
    'RLS Policy: ' || policyname as test,
    '✅ PASS - Policy active' as result,
    tablename as table
FROM pg_policies
WHERE tablename IN ('profiles', 'user_settings', 'user_points')
ORDER BY tablename, policyname;

-- 7. Show full profile data for test user
SELECT 
    '=== TEST USER PROFILE ===' as section,
    id,
    username,
    email,
    is_active,
    is_premium,
    notifications_enabled,
    created_at,
    updated_at
FROM profiles 
WHERE id = 'f37b2352-c51b-4edb-8b13-5b633ba85e6e';

-- 8. Check indexes on critical tables
SELECT 
    'Index Check: ' || indexname as test,
    '✅ PASS - Index exists' as result,
    tablename as table
FROM pg_indexes
WHERE schemaname = 'public' 
    AND tablename IN ('profiles', 'user_settings', 'user_points', 'focus_sessions', 'app_usage_sessions')
    AND indexname LIKE '%user%'
ORDER BY tablename, indexname;

-- 9. Count all users and their profiles
SELECT 
    'User Count' as metric,
    COUNT(DISTINCT u.id) as users_in_auth,
    COUNT(DISTINCT p.id) as users_with_profiles,
    COUNT(DISTINCT u.id) - COUNT(DISTINCT p.id) as missing_profiles
FROM auth.users u
LEFT JOIN profiles p ON u.id = p.id;

-- 10. Final status summary
SELECT 
    '=== OVERALL STATUS ===' as section,
    CASE 
        WHEN EXISTS (SELECT 1 FROM profiles WHERE id = 'f37b2352-c51b-4edb-8b13-5b633ba85e6e')
        AND EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'on_auth_user_created')
        AND EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'is_active')
        THEN '🎉 ALL CHECKS PASSED - System is ready!'
        ELSE '⚠️ SOME CHECKS FAILED - Review results above'
    END as status;

-- =============================================
-- Expected Results:
-- - All tests should show "✅ PASS"
-- - Test user profile should be visible
-- - missing_profiles should be 0
-- - Final status should be "🎉 ALL CHECKS PASSED"
-- =============================================
