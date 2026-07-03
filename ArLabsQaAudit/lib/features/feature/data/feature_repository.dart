import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/supabase_config.dart';
import '../domain/feature_model.dart';

class FeatureRepository {
  final SupabaseClient _client;

  FeatureRepository(this._client);

  Future<List<Feature>> getFeatures(String moduleId) async {
    final response = await _client
        .from('features')
        .select()
        .eq('module_id', moduleId)
        .order('order_index', ascending: true);

    return (response as List).map((json) => Feature.fromJson(json)).toList();
  }

  Future<Feature> createFeature({
    required String moduleId,
    required String name,
    String? description,
    required int orderIndex,
  }) async {
    final response = await _client.from('features').insert({
      'module_id': moduleId,
      'name': name,
      'description': description,
      'order_index': orderIndex,
    }).select().single();

    return Feature.fromJson(response);
  }

  Future<Feature> updateFeature(Feature feature) async {
    final response = await _client
        .from('features')
        .update({
          'name': feature.name,
          'description': feature.description,
          'order_index': feature.orderIndex,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', feature.id)
        .select()
        .single();

    return Feature.fromJson(response);
  }

  Future<void> deleteFeature(String id) async {
    await _client.from('features').delete().eq('id', id);
  }

  Future<void> reorderFeatures(List<Feature> features) async {
    if (features.isEmpty) return;

    final payload = features.map((f) => {
      'id': f.id,
      'module_id': f.moduleId,
      'name': f.name,
      'description': f.description,
      'order_index': f.orderIndex,
      'updated_at': DateTime.now().toIso8601String(),
    }).toList();

    await _client.from('features').upsert(payload);
  }
}

final featureRepositoryProvider = Provider<FeatureRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return FeatureRepository(client);
});
