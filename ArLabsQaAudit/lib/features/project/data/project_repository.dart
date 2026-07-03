import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/supabase_config.dart';
import '../domain/project_model.dart';
import '../../function/domain/function_model.dart';
import '../../audit/domain/audit_statistics.dart';

class ProjectRepository {
  final SupabaseClient _client;

  ProjectRepository(this._client);

  Future<List<Project>> getProjects() async {
    final response = await _client
        .from('projects')
        .select()
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false);
    
    return (response as List).map((json) => Project.fromJson(json)).toList();
  }

  Future<List<ProjectWithStats>> getProjectsWithStats() async {
    final response = await _client
        .from('projects')
        .select('*, modules(features(functions(audits(*, bugs(*)))))')
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false);

    final List<ProjectWithStats> results = [];
    for (final projJson in response as List) {
      final project = Project.fromJson(projJson as Map<String, dynamic>);
      
      final List<AppFunction> functions = [];
      final modulesJson = projJson['modules'] as List? ?? [];
      for (final modJson in modulesJson) {
        final featuresJson = modJson['features'] as List? ?? [];
        for (final featJson in featuresJson) {
          final functionsJson = featJson['functions'] as List? ?? [];
          for (final funcJson in functionsJson) {
            functions.add(AppFunction.fromJson(funcJson as Map<String, dynamic>));
          }
        }
      }
      
      final stats = AuditStatistics.calculate(functions);
      results.add(ProjectWithStats(
        project: project,
        stats: stats,
        rawModulesJson: modulesJson,
      ));
    }
    return results;
  }

  Future<Project> createProject({
    required String name,
    String? description,
    required String color,
    required String icon,
  }) async {
    final response = await _client.from('projects').insert({
      'name': name,
      'description': description,
      'color': color,
      'icon': icon,
      'status': 'Active',
    }).select().single();

    return Project.fromJson(response);
  }

  Future<Project> updateProject(Project project) async {
    final response = await _client
        .from('projects')
        .update({
          'name': project.name,
          'description': project.description,
          'color': project.color,
          'icon': project.icon,
          'status': project.status,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', project.id)
        .select()
        .single();

    return Project.fromJson(response);
  }

  Future<void> softDeleteProject(String id) async {
    await _client.from('projects').update({
      'deleted_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  Future<Project> toggleArchive(String id, bool archive) async {
    final response = await _client
        .from('projects')
        .update({
          'status': archive ? 'Archived' : 'Active',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id)
        .select()
        .single();

    return Project.fromJson(response);
  }
}

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ProjectRepository(client);
});

// StateNotifier for Managing Projects List
class ProjectListNotifier extends StateNotifier<AsyncValue<List<ProjectWithStats>>> {
  final ProjectRepository _repository;

  ProjectListNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadProjects();
  }

  Future<void> loadProjects() async {
    state = const AsyncValue.loading();
    try {
      final projects = await _repository.getProjectsWithStats();
      state = AsyncValue.data(projects);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addProject({
    required String name,
    String? description,
    required String color,
    required String icon,
  }) async {
    try {
      final newProject = await _repository.createProject(
        name: name,
        description: description,
        color: color,
        icon: icon,
      );
      state.whenData((projects) {
        state = AsyncValue.data([
          ProjectWithStats(project: newProject, stats: AuditStatistics.empty()),
          ...projects,
        ]);
      });
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> editProject(Project project) async {
    try {
      final updatedProject = await _repository.updateProject(project);
      state.whenData((projects) {
        state = AsyncValue.data(
          projects.map((p) {
            if (p.project.id == project.id) {
              return ProjectWithStats(project: updatedProject, stats: p.stats);
            }
            return p;
          }).toList(),
        );
      });
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> archiveProject(String id, bool archive) async {
    try {
      final updatedProject = await _repository.toggleArchive(id, archive);
      state.whenData((projects) {
        state = AsyncValue.data(
          projects.map((p) {
            if (p.project.id == id) {
              return ProjectWithStats(project: updatedProject, stats: p.stats);
            }
            return p;
          }).toList(),
        );
      });
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> softDelete(String id) async {
    try {
      await _repository.softDeleteProject(id);
      state.whenData((projects) {
        state = AsyncValue.data(projects.where((p) => p.project.id != id).toList());
      });
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final projectListProvider =
    StateNotifierProvider<ProjectListNotifier, AsyncValue<List<ProjectWithStats>>>((ref) {
  final repository = ref.watch(projectRepositoryProvider);
  return ProjectListNotifier(repository);
});
