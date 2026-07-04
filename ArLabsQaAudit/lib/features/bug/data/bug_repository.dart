import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/supabase_config.dart';
import '../domain/bug_model.dart';
import '../../project/data/project_repository.dart';
import '../../activity/data/activity_repository.dart';

class BugRepository {
  final SupabaseClient _client;

  BugRepository(this._client);

  Future<List<Bug>> getBugs() async {
    final response = await _client
        .from('bugs')
        .select('*, audits(*, functions(*, features(*, modules(*, projects(*)))))')
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false);

    return (response as List).map((json) => Bug.fromJson(json)).toList();
  }

  Future<Bug> getBugById(String id) async {
    final response = await _client
        .from('bugs')
        .select('*, audits(*, functions(*, features(*, modules(*, projects(*)))))')
        .eq('id', id)
        .single();

    return Bug.fromJson(response);
  }

  Future<String> getOrCreateAuditId(String functionId) async {
    final existing = await _client
        .from('audits')
        .select()
        .eq('function_id', functionId)
        .maybeSingle();

    if (existing != null) {
      return existing['id'] as String;
    }

    final created = await _client.from('audits').insert({
      'function_id': functionId,
      'status': 'Not Tested',
      'last_audited_at': DateTime.now().toIso8601String(),
    }).select().single();

    return created['id'] as String;
  }

  Future<Bug> createBug({
    required String auditId,
    required String title,
    required String description,
    required String severity,
    required String status,
    String? stepsToReproduce,
    String? expectedResult,
    String? actualResult,
    String? assignedTo,
  }) async {
    final response = await _client.from('bugs').insert({
      'audit_id': auditId,
      'title': title,
      'description': description,
      'severity': severity,
      'status': status,
      'steps_to_reproduce': stepsToReproduce,
      'expected_result': expectedResult,
      'actual_result': actualResult,
      'assigned_to': assignedTo,
    }).select('*, audits(*, functions(*, features(*, modules(*, projects(*)))))').single();

    return Bug.fromJson(response);
  }

  Future<Bug> updateBug(Bug bug) async {
    final response = await _client
        .from('bugs')
        .update({
          'title': bug.title,
          'description': bug.description,
          'severity': bug.severity,
          'status': bug.status,
          'steps_to_reproduce': bug.stepsToReproduce,
          'expected_result': bug.expectedResult,
          'actual_result': bug.actualResult,
          'assigned_to': bug.assignedTo,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', bug.id)
        .select('*, audits(*, functions(*, features(*, modules(*, projects(*)))))')
        .single();

    return Bug.fromJson(response);
  }

  Future<void> softDeleteBug(String id) async {
    await _client.from('bugs').update({
      'deleted_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }
}

final bugRepositoryProvider = Provider<BugRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return BugRepository(client);
});

// Bugs List Notifier managing state of Bugs
class BugsListNotifier extends StateNotifier<AsyncValue<List<Bug>>> {
  final BugRepository _repository;

  BugsListNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadBugs();
  }

  Future<void> loadBugs() async {
    state = const AsyncValue.loading();
    try {
      final bugs = await _repository.getBugs();
      state = AsyncValue.data(bugs);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addBug({
    required String auditId,
    required String title,
    required String description,
    required String severity,
    required String status,
    String? stepsToReproduce,
    String? expectedResult,
    String? actualResult,
    String? assignedTo,
    required WidgetRef ref,
  }) async {
    try {
      final newBug = await _repository.createBug(
        auditId: auditId,
        title: title,
        description: description,
        severity: severity,
        status: status,
        stepsToReproduce: stepsToReproduce,
        expectedResult: expectedResult,
        actualResult: actualResult,
        assignedTo: assignedTo,
      );

      state.whenData((bugs) {
        state = AsyncValue.data([newBug, ...bugs]);
      });

      // Log activity
      ref.read(activityRepositoryProvider).logActivity(
        projectId: newBug.projectId ?? '',
        entityType: 'Bug',
        entityId: newBug.id,
        entityName: newBug.title,
        action: 'Create',
        description: 'Bug baru dilaporkan pada fungsi "${newBug.functionName}": ${newBug.title}',
      );

      // Invalidate project stats
      ref.invalidate(projectListProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> editBug(Bug bug, WidgetRef ref) async {
    try {
      final oldBug = state.value?.firstWhere((b) => b.id == bug.id);
      final updated = await _repository.updateBug(bug);
      state.whenData((bugs) {
        state = AsyncValue.data(
          bugs.map((b) => b.id == bug.id ? updated : b).toList(),
        );
      });

      // Log activity
      if (oldBug != null) {
        final List<String> changes = [];
        if (oldBug.status != updated.status) {
          changes.add('status menjadi ${updated.status}');
        }
        if (oldBug.severity != updated.severity) {
          changes.add('keparahan menjadi ${updated.severity}');
        }
        if (oldBug.title != updated.title) {
          changes.add('judul diperbarui');
        }
        if (oldBug.description != updated.description) {
          changes.add('deskripsi diperbarui');
        }
        final String desc = changes.isEmpty 
            ? 'Detail Bug "${updated.title}" diperbarui'
            : 'Bug "${updated.title}" diperbarui: ${changes.join(", ")}';

        ref.read(activityRepositoryProvider).logActivity(
          projectId: updated.projectId ?? '',
          entityType: 'Bug',
          entityId: updated.id,
          entityName: updated.title,
          action: oldBug.status != updated.status ? 'Change Status' : (oldBug.severity != updated.severity ? 'Change Severity' : 'Update'),
          description: desc,
        );
      }

      // Invalidate project stats
      ref.invalidate(projectListProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> softDelete(String id, WidgetRef ref) async {
    try {
      final targetBug = state.value?.firstWhere((b) => b.id == id);
      await _repository.softDeleteBug(id);
      state.whenData((bugs) {
        state = AsyncValue.data(
          bugs.where((b) => b.id != id).toList(),
        );
      });

      // Log activity
      if (targetBug != null) {
        ref.read(activityRepositoryProvider).logActivity(
          projectId: targetBug.projectId ?? '',
          entityType: 'Bug',
          entityId: id,
          entityName: targetBug.title,
          action: 'Delete',
          description: 'Bug "${targetBug.title}" dihapus (Soft Delete)',
        );
      }

      // Invalidate project stats
      ref.invalidate(projectListProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final bugsListProvider = StateNotifierProvider<BugsListNotifier, AsyncValue<List<Bug>>>((ref) {
  final repository = ref.watch(bugRepositoryProvider);
  return BugsListNotifier(repository);
});

final bugDetailProvider = FutureProvider.family<Bug, String>((ref, id) async {
  final repository = ref.watch(bugRepositoryProvider);
  return repository.getBugById(id);
});
