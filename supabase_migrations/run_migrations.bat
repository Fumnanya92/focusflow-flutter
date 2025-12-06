@echo off
REM =============================================
REM FocusFlow Database Migration Runner (Windows)
REM Run with: .\run_migrations.bat
REM =============================================

echo 🚀 Starting FocusFlow Database Migration...
echo.
echo ⚠️  IMPORTANT: Make sure you run each SQL file manually in Supabase SQL Editor
echo    The REST API method requires additional setup for direct SQL execution.
echo.
echo 📋 Migration Order:
echo    1. 01_cleanup.sql
echo    2. 02_core_tables.sql  
echo    3. 03_gamification.sql
echo    4. 04_app_blocking.sql
echo    5. 05_challenges.sql
echo    6. 06_security_policies.sql
echo    7. 07_functions_triggers.sql
echo    8. 08_performance_indexes.sql
echo.
echo 🔗 Supabase Project: https://zulkbxcxxplruibcewqb.supabase.co
echo 📂 Go to: Dashboard → SQL Editor → New Query
echo.
echo 📄 Step-by-step instructions:
echo    1. Open your Supabase dashboard
echo    2. Go to SQL Editor
echo    3. Copy and paste each file content in order
echo    4. Run each query individually
echo.

REM List all migration files to verify they exist
echo 📁 Available migration files:
if exist "01_cleanup.sql" (echo ✅ 01_cleanup.sql) else (echo ❌ 01_cleanup.sql - MISSING)
if exist "02_core_tables.sql" (echo ✅ 02_core_tables.sql) else (echo ❌ 02_core_tables.sql - MISSING)
if exist "03_gamification.sql" (echo ✅ 03_gamification.sql) else (echo ❌ 03_gamification.sql - MISSING)
if exist "04_app_blocking.sql" (echo ✅ 04_app_blocking.sql) else (echo ❌ 04_app_blocking.sql - MISSING)
if exist "05_challenges.sql" (echo ✅ 05_challenges.sql) else (echo ❌ 05_challenges.sql - MISSING)
if exist "06_security_policies.sql" (echo ✅ 06_security_policies.sql) else (echo ❌ 06_security_policies.sql - MISSING)
if exist "07_functions_triggers.sql" (echo ✅ 07_functions_triggers.sql) else (echo ❌ 07_functions_triggers.sql - MISSING)
if exist "08_performance_indexes.sql" (echo ✅ 08_performance_indexes.sql) else (echo ❌ 08_performance_indexes.sql - MISSING)

echo.
echo 🎯 Ready to migrate! Open Supabase SQL Editor and run files in order.
echo.
pause