import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SupabaseConfig {
  static const String url = 'https://pfkafuqkszkozvyrwxxt.supabase.co';
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBma2FmdXFrc3prb3p2eXJ3eHh0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODMwMTA4MjYsImV4cCI6MjA5ODU4NjgyNn0.n6VSctErFs1whK7XCWmkQq1CxJyiqIAEHkBCYKBZzfE';
}

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});
