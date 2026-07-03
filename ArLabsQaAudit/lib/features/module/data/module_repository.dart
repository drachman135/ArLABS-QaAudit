import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/supabase_config.dart';
import '../domain/module_model.dart';

class ModuleRepository {
  final SupabaseClient _client;

  ModuleRepository(this._client);

  Future<List<Module>> getModules(String projectId) async {
    final response = await _client
        .from('modules')
        .select()
        .eq('project_id', projectId)
        .order('order_index', ascending: true);

    return (response as List).map((json) => Module.fromJson(json)).toList();
  }

  Future<Module> createModule({
    required String projectId,
    required String name,
    String? description,
    required int orderIndex,
  }) async {
    final response = await _client.from('modules').insert({
      'project_id': projectId,
      'name': name,
      'description': description,
      'order_index': orderIndex,
    }).select().single();

    return Module.fromJson(response);
  }

  Future<Module> updateModule(Module module) async {
    final response = await _client
        .from('modules')
        .update({
          'name': module.name,
          'description': module.description,
          'order_index': module.orderIndex,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', module.id)
        .select()
        .single();

    return Module.fromJson(response);
  }

  Future<void> deleteModule(String id) async {
    await _client.from('modules').delete().eq('id', id);
  }

  Future<void> reorderModules(List<Module> modules) async {
    if (modules.isEmpty) return;
    
    final payload = modules.map((m) => {
      'id': m.id,
      'project_id': m.projectId,
      'name': m.name,
      'description': m.description,
      'order_index': m.orderIndex,
      'updated_at': DateTime.now().toIso8601String(),
    }).toList();

    await _client.from('modules').upsert(payload);
  }
}

final moduleRepositoryProvider = Provider<ModuleRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ModuleRepository(client);
});
