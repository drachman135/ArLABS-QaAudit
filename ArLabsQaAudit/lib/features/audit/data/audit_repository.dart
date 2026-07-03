import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/supabase_config.dart';
import '../domain/audit_model.dart';

class AuditRepository {
  final SupabaseClient _client;

  AuditRepository(this._client);

  Future<Audit> upsertAudit({
    required String functionId,
    required String status,
    String? priority,
    String? notes,
    String? auditorName,
  }) async {
    // Update or insert the active audit for the function
    final response = await _client.from('audits').upsert({
      'function_id': functionId,
      'status': status,
      'priority': priority,
      'notes': notes,
      'auditor_name': auditorName,
      'last_audited_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'function_id').select().single();

    return Audit.fromJson(response);
  }

  Future<List<Map<String, dynamic>>> getRecentAudits({int limit = 10}) async {
    // Fetch recent audits and join metadata
    final response = await _client
        .from('audits')
        .select('''
          id,
          status,
          priority,
          last_audited_at,
          auditor_name,
          functions (
            id,
            name,
            features (
              id,
              name,
              modules (
                id,
                name,
                projects (
                  id,
                  name
                )
              )
            )
          )
        ''')
        .order('last_audited_at', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(response);
  }
}

final auditRepositoryProvider = Provider<AuditRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuditRepository(client);
});
