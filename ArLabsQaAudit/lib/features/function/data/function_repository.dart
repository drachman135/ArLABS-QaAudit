import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/supabase_config.dart';
import '../domain/function_model.dart';

class FunctionRepository {
  final SupabaseClient _client;

  FunctionRepository(this._client);

  Future<List<AppFunction>> getFunctions(String featureId) async {
    final response = await _client
        .from('functions')
        .select('*, audits(*, bugs(*))')
        .eq('feature_id', featureId)
        .order('order_index', ascending: true);

    return (response as List).map((json) => AppFunction.fromJson(json)).toList();
  }

  Future<AppFunction> createFunction({
    required String featureId,
    required String name,
    String? description,
    required int orderIndex,
  }) async {
    final response = await _client.from('functions').insert({
      'feature_id': featureId,
      'name': name,
      'description': description,
      'order_index': orderIndex,
    }).select().single();

    return AppFunction.fromJson(response);
  }

  Future<AppFunction> updateFunction(AppFunction function) async {
    final response = await _client
        .from('functions')
        .update({
          'name': function.name,
          'description': function.description,
          'order_index': function.orderIndex,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', function.id)
        .select()
        .single();

    return AppFunction.fromJson(response).copyWith(activeAudit: function.activeAudit);
  }

  Future<void> deleteFunction(String id) async {
    await _client.from('functions').delete().eq('id', id);
  }

  Future<void> reorderFunctions(List<AppFunction> functions) async {
    if (functions.isEmpty) return;

    final payload = functions.map((f) => {
      'id': f.id,
      'feature_id': f.featureId,
      'name': f.name,
      'description': f.description,
      'order_index': f.orderIndex,
      'updated_at': DateTime.now().toIso8601String(),
    }).toList();

    await _client.from('functions').upsert(payload);
  }
}

final functionRepositoryProvider = Provider<FunctionRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return FunctionRepository(client);
});
