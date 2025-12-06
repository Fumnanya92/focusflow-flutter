import 'package:supabase_flutter/supabase_flutter.dart';

// Helper to access Supabase client globally
final SupabaseClient supabase = Supabase.instance.client;

// Helper to check if user is authenticated
bool get isAuthenticated => supabase.auth.currentUser != null;

// Helper to get current user
User? get currentUser => supabase.auth.currentUser;

// Helper to get current user's ID
String? get currentUserId => supabase.auth.currentUser?.id;
