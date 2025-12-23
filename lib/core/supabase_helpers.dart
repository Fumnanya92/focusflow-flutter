import 'package:supabase_flutter/supabase_flutter.dart';

// Helper to access Supabase client globally (lazy initialization)
SupabaseClient get supabase {
  try {
    return Supabase.instance.client;
  } catch (e) {
    throw Exception('Supabase not initialized. Call Supabase.initialize() first.');
  }
}

// Helper to check if user is authenticated
bool get isAuthenticated {
  try {
    return supabase.auth.currentUser != null;
  } catch (e) {
    return false;
  }
}

// Helper to get current user
User? get currentUser {
  try {
    return supabase.auth.currentUser;
  } catch (e) {
    return null;
  }
}

// Helper to get current user's ID
String? get currentUserId {
  try {
    return supabase.auth.currentUser?.id;
  } catch (e) {
    return null;
  }
}
