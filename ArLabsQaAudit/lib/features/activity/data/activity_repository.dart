import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/supabase_config.dart';
import '../domain/activity_model.dart';

class ActivityRepository {
  final SupabaseClient _client;

  ActivityRepository(this._client);

  Future<void> logActivity({
    required String projectId,
    required String entityType,
    required String entityId,
    required String entityName,
    required String action,
    required String description,
  }) async {
    try {
      await _client.from('activities').insert({
        'project_id': projectId,
        'entity_type': entityType,
        'entity_id': entityId,
        'entity_name': entityName,
        'action': action,
        'description': description,
      });
    } catch (_) {
      // Gracefully catch logging errors so it doesn't break the main user flow
    }
  }

  Future<List<Activity>> getActivities({
    String? projectId,
    String? entityType,
    String? action,
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = _client.from('activities').select();

    if (projectId != null && projectId != 'All') {
      query = query.eq('project_id', projectId);
    }
    if (entityType != null && entityType != 'All') {
      query = query.eq('entity_type', entityType);
    }
    if (action != null && action != 'All') {
      query = query.eq('action', action);
    }
    if (startDate != null) {
      query = query.gte('created_at', startDate.toIso8601String());
    }
    if (endDate != null) {
      query = query.lte('created_at', endDate.toIso8601String());
    }

    final response = await query.order('created_at', ascending: false);
    final List<Activity> list = (response as List).map((json) => Activity.fromJson(json)).toList();

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final term = searchQuery.toLowerCase();
      return list.where((act) {
        return act.entityName.toLowerCase().contains(term) ||
            act.action.toLowerCase().contains(term) ||
            act.description.toLowerCase().contains(term);
      }).toList();
    }

    return list;
  }
}

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ActivityRepository(client);
});

// Providers for loading activities list (Global & Project-specific)
final globalActivitiesProvider = FutureProvider.family<List<Activity>, Map<String, dynamic>?>((ref, filters) async {
  final repository = ref.watch(activityRepositoryProvider);
  return repository.getActivities(
    projectId: filters?['projectId'] as String?,
    entityType: filters?['entityType'] as String?,
    action: filters?['action'] as String?,
    searchQuery: filters?['searchQuery'] as String?,
    startDate: filters?['startDate'] as DateTime?,
    endDate: filters?['endDate'] as DateTime?,
  );
});
