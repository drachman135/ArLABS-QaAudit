import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../project/domain/project_model.dart';
import '../../project/data/project_repository.dart';
import '../../module/domain/module_model.dart';
import '../../module/data/module_repository.dart';
import '../../feature/domain/feature_model.dart';
import '../../feature/data/feature_repository.dart';
import '../../function/domain/function_model.dart';
import '../../function/data/function_repository.dart';
import '../../audit/domain/audit_model.dart';
import '../../activity/data/activity_repository.dart';

// Structs to represent the assembled hierarchy tree
class ProjectTreeData {
  final Project project;
  final List<ModuleNode> modules;

  ProjectTreeData({required this.project, required this.modules});

  ProjectTreeData copyWith({
    Project? project,
    List<ModuleNode>? modules,
  }) {
    return ProjectTreeData(
      project: project ?? this.project,
      modules: modules ?? this.modules,
    );
  }
}

class ModuleNode {
  final Module module;
  final List<FeatureNode> features;

  ModuleNode({required this.module, required this.features});

  ModuleNode copyWith({
    Module? module,
    List<FeatureNode>? features,
  }) {
    return ModuleNode(
      module: module ?? this.module,
      features: features ?? this.features,
    );
  }
}

class FeatureNode {
  final Feature feature;
  final List<AppFunction> functions;

  FeatureNode({required this.feature, required this.functions});

  FeatureNode copyWith({
    Feature? feature,
    List<AppFunction>? functions,
  }) {
    return FeatureNode(
      feature: feature ?? this.feature,
      functions: functions ?? this.functions,
    );
  }
}

class ProjectTreeNotifier extends StateNotifier<AsyncValue<ProjectTreeData>> {
  final String _projectId;
  final ProjectRepository _projectRepo;
  final ModuleRepository _moduleRepo;
  final FeatureRepository _featureRepo;
  final FunctionRepository _functionRepo;
  final Ref _ref;

  ProjectTreeNotifier({
    required String projectId,
    required ProjectRepository projectRepo,
    required ModuleRepository moduleRepo,
    required FeatureRepository featureRepo,
    required FunctionRepository functionRepo,
    required Ref ref,
  })  : _projectId = projectId,
        _projectRepo = projectRepo,
        _moduleRepo = moduleRepo,
        _featureRepo = featureRepo,
        _functionRepo = functionRepo,
        _ref = ref,
        super(const AsyncValue.loading()) {
    loadTree();
  }

  Future<void> loadTree() async {
    state = const AsyncValue.loading();
    try {
      // 1. Fetch project details
      final projects = await _projectRepo.getProjects();
      final project = projects.firstWhere((p) => p.id == _projectId);

      // 2. Fetch modules
      final modules = await _moduleRepo.getModules(_projectId);

      // 3. Assemble ModuleNodes by fetching features & functions
      final List<ModuleNode> moduleNodes = [];
      for (var module in modules) {
        final features = await _featureRepo.getFeatures(module.id);
        
        final List<FeatureNode> featureNodes = [];
        for (var feature in features) {
          final functions = await _functionRepo.getFunctions(feature.id);
          featureNodes.add(FeatureNode(feature: feature, functions: functions));
        }

        moduleNodes.add(ModuleNode(module: module, features: featureNodes));
      }

      state = AsyncValue.data(ProjectTreeData(project: project, modules: moduleNodes));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // --- MODULE ACTIONS ---

  Future<void> addModule(String name, String? description) async {
    final currentData = state.value;
    if (currentData == null) return;

    try {
      final orderIndex = currentData.modules.length;
      final newModule = await _moduleRepo.createModule(
        projectId: _projectId,
        name: name,
        description: description,
        orderIndex: orderIndex,
      );

      final newNode = ModuleNode(module: newModule, features: []);
      state = AsyncValue.data(currentData.copyWith(
        modules: [...currentData.modules, newNode],
      ));

      _ref.read(activityRepositoryProvider).logActivity(
        projectId: _projectId,
        entityType: 'Module',
        entityId: newModule.id,
        entityName: newModule.name,
        action: 'Create',
        description: 'Modul "${newModule.name}" berhasil dibuat',
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateModule(Module module) async {
    final currentData = state.value;
    if (currentData == null) return;

    try {
      final updatedModule = await _moduleRepo.updateModule(module);
      state = AsyncValue.data(currentData.copyWith(
        modules: currentData.modules.map((m) {
          if (m.module.id == module.id) {
            return m.copyWith(module: updatedModule);
          }
          return m;
        }).toList(),
      ));

      _ref.read(activityRepositoryProvider).logActivity(
        projectId: _projectId,
        entityType: 'Module',
        entityId: module.id,
        entityName: module.name,
        action: 'Update',
        description: 'Modul "${module.name}" diperbarui',
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteModule(String moduleId) async {
    final currentData = state.value;
    if (currentData == null) return;

    try {
      final name = currentData.modules.firstWhere((m) => m.module.id == moduleId).module.name;
      await _moduleRepo.deleteModule(moduleId);
      state = AsyncValue.data(currentData.copyWith(
        modules: currentData.modules.where((m) => m.module.id != moduleId).toList(),
      ));

      _ref.read(activityRepositoryProvider).logActivity(
        projectId: _projectId,
        entityType: 'Module',
        entityId: moduleId,
        entityName: name,
        action: 'Delete',
        description: 'Modul "$name" dihapus beserta seluruh fitur di dalamnya',
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> reorderModules(int oldIndex, int newIndex) async {
    final currentData = state.value;
    if (currentData == null) return;

    // Adjust indices for list modifications
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final modules = List<ModuleNode>.from(currentData.modules);
    final moved = modules.removeAt(oldIndex);
    modules.insert(newIndex, moved);

    // Update orderIndex values
    final updatedNodes = modules.asMap().entries.map((entry) {
      final index = entry.key;
      final node = entry.value;
      return node.copyWith(module: node.module.copyWith(orderIndex: index));
    }).toList();

    // Optimistic state update
    state = AsyncValue.data(currentData.copyWith(modules: updatedNodes));

    try {
      await _moduleRepo.reorderModules(updatedNodes.map((n) => n.module).toList());

      _ref.read(activityRepositoryProvider).logActivity(
        projectId: _projectId,
        entityType: 'Module',
        entityId: _projectId,
        entityName: currentData.project.name,
        action: 'Reorder',
        description: 'Urutan modul pada proyek "${currentData.project.name}" telah diatur ulang',
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // --- FEATURE ACTIONS ---

  Future<void> addFeature(String moduleId, String name, String? description) async {
    final currentData = state.value;
    if (currentData == null) return;

    try {
      final moduleNode = currentData.modules.firstWhere((m) => m.module.id == moduleId);
      final orderIndex = moduleNode.features.length;

      final newFeature = await _featureRepo.createFeature(
        moduleId: moduleId,
        name: name,
        description: description,
        orderIndex: orderIndex,
      );

      final newNode = FeatureNode(feature: newFeature, functions: []);
      state = AsyncValue.data(currentData.copyWith(
        modules: currentData.modules.map((m) {
          if (m.module.id == moduleId) {
            return m.copyWith(features: [...m.features, newNode]);
          }
          return m;
        }).toList(),
      ));

      _ref.read(activityRepositoryProvider).logActivity(
        projectId: _projectId,
        entityType: 'Feature',
        entityId: newFeature.id,
        entityName: newFeature.name,
        action: 'Create',
        description: 'Fitur "${newFeature.name}" berhasil dibuat',
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateFeature(Feature feature) async {
    final currentData = state.value;
    if (currentData == null) return;

    try {
      final updatedFeature = await _featureRepo.updateFeature(feature);
      state = AsyncValue.data(currentData.copyWith(
        modules: currentData.modules.map((m) {
          if (m.module.id == feature.moduleId) {
            return m.copyWith(
              features: m.features.map((f) {
                if (f.feature.id == feature.id) {
                  return f.copyWith(feature: updatedFeature);
                }
                return f;
              }).toList(),
            );
          }
          return m;
        }).toList(),
      ));

      _ref.read(activityRepositoryProvider).logActivity(
        projectId: _projectId,
        entityType: 'Feature',
        entityId: feature.id,
        entityName: feature.name,
        action: 'Update',
        description: 'Fitur "${feature.name}" diperbarui',
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteFeature(String moduleId, String featureId) async {
    final currentData = state.value;
    if (currentData == null) return;

    try {
      final mNode = currentData.modules.firstWhere((m) => m.module.id == moduleId);
      final name = mNode.features.firstWhere((f) => f.feature.id == featureId).feature.name;
      await _featureRepo.deleteFeature(featureId);
      state = AsyncValue.data(currentData.copyWith(
        modules: currentData.modules.map((m) {
          if (m.module.id == moduleId) {
            return m.copyWith(
              features: m.features.where((f) => f.feature.id != featureId).toList(),
            );
          }
          return m;
        }).toList(),
      ));

      _ref.read(activityRepositoryProvider).logActivity(
        projectId: _projectId,
        entityType: 'Feature',
        entityId: featureId,
        entityName: name,
        action: 'Delete',
        description: 'Fitur "$name" dihapus beserta seluruh fungsi di dalamnya',
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> reorderFeatures(String moduleId, int oldIndex, int newIndex) async {
    final currentData = state.value;
    if (currentData == null) return;

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final moduleNode = currentData.modules.firstWhere((m) => m.module.id == moduleId);
    final features = List<FeatureNode>.from(moduleNode.features);
    final moved = features.removeAt(oldIndex);
    features.insert(newIndex, moved);

    final updatedFeatures = features.asMap().entries.map((entry) {
      final index = entry.key;
      final node = entry.value;
      return node.copyWith(feature: node.feature.copyWith(orderIndex: index));
    }).toList();

    state = AsyncValue.data(currentData.copyWith(
      modules: currentData.modules.map((m) {
        if (m.module.id == moduleId) {
          return m.copyWith(features: updatedFeatures);
        }
        return m;
      }).toList(),
    ));

    try {
      await _featureRepo.reorderFeatures(updatedFeatures.map((f) => f.feature).toList());

      _ref.read(activityRepositoryProvider).logActivity(
        projectId: _projectId,
        entityType: 'Feature',
        entityId: moduleId,
        entityName: moduleNode.module.name,
        action: 'Reorder',
        description: 'Urutan fitur pada modul "${moduleNode.module.name}" telah diatur ulang',
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // --- FUNCTION ACTIONS ---

  Future<void> addFunction(String moduleId, String featureId, String name, String? description) async {
    final currentData = state.value;
    if (currentData == null) return;

    try {
      final moduleNode = currentData.modules.firstWhere((m) => m.module.id == moduleId);
      final featureNode = moduleNode.features.firstWhere((f) => f.feature.id == featureId);
      final orderIndex = featureNode.functions.length;

      final newFunction = await _functionRepo.createFunction(
        featureId: featureId,
        name: name,
        description: description,
        orderIndex: orderIndex,
      );

      state = AsyncValue.data(currentData.copyWith(
        modules: currentData.modules.map((m) {
          if (m.module.id == moduleId) {
            return m.copyWith(
              features: m.features.map((f) {
                if (f.feature.id == featureId) {
                  return f.copyWith(functions: [...f.functions, newFunction]);
                }
                return f;
              }).toList(),
            );
          }
          return m;
        }).toList(),
      ));

      _ref.read(activityRepositoryProvider).logActivity(
        projectId: _projectId,
        entityType: 'Function',
        entityId: newFunction.id,
        entityName: newFunction.name,
        action: 'Create',
        description: 'Fungsi "${newFunction.name}" berhasil dibuat',
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateFunction(String moduleId, String featureId, AppFunction function) async {
    final currentData = state.value;
    if (currentData == null) return;

    try {
      final updatedFunction = await _functionRepo.updateFunction(function);
      state = AsyncValue.data(currentData.copyWith(
        modules: currentData.modules.map((m) {
          if (m.module.id == moduleId) {
            return m.copyWith(
              features: m.features.map((f) {
                if (f.feature.id == featureId) {
                  return f.copyWith(
                    functions: f.functions.map((fn) => fn.id == function.id ? updatedFunction : fn).toList(),
                  );
                }
                return f;
              }).toList(),
            );
          }
          return m;
        }).toList(),
      ));

      _ref.read(activityRepositoryProvider).logActivity(
        projectId: _projectId,
        entityType: 'Function',
        entityId: function.id,
        entityName: function.name,
        action: 'Update',
        description: 'Fungsi "${function.name}" diperbarui',
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteFunction(String moduleId, String featureId, String functionId) async {
    final currentData = state.value;
    if (currentData == null) return;

    try {
      final mNode = currentData.modules.firstWhere((m) => m.module.id == moduleId);
      final fNode = mNode.features.firstWhere((f) => f.feature.id == featureId);
      final name = fNode.functions.firstWhere((fn) => fn.id == functionId).name;
      await _functionRepo.deleteFunction(functionId);
      state = AsyncValue.data(currentData.copyWith(
        modules: currentData.modules.map((m) {
          if (m.module.id == moduleId) {
            return m.copyWith(
              features: m.features.map((f) {
                if (f.feature.id == featureId) {
                  return f.copyWith(
                    functions: f.functions.where((fn) => fn.id != functionId).toList(),
                  );
                }
                return f;
              }).toList(),
            );
          }
          return m;
        }).toList(),
      ));

      _ref.read(activityRepositoryProvider).logActivity(
        projectId: _projectId,
        entityType: 'Function',
        entityId: functionId,
        entityName: name,
        action: 'Delete',
        description: 'Fungsi "$name" dihapus dari daftar audit',
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> reorderFunctions(String moduleId, String featureId, int oldIndex, int newIndex) async {
    final currentData = state.value;
    if (currentData == null) return;

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final moduleNode = currentData.modules.firstWhere((m) => m.module.id == moduleId);
    final featureNode = moduleNode.features.firstWhere((f) => f.feature.id == featureId);
    final functions = List<AppFunction>.from(featureNode.functions);
    final moved = functions.removeAt(oldIndex);
    functions.insert(newIndex, moved);

    final updatedFunctions = functions.asMap().entries.map((entry) {
      final index = entry.key;
      final fn = entry.value;
      return fn.copyWith(orderIndex: index);
    }).toList();

    state = AsyncValue.data(currentData.copyWith(
      modules: currentData.modules.map((m) {
        if (m.module.id == moduleId) {
          return m.copyWith(
            features: m.features.map((f) {
              if (f.feature.id == featureId) {
                return f.copyWith(functions: updatedFunctions);
              }
              return f;
            }).toList(),
          );
        }
        return m;
      }).toList(),
    ));

    try {
      await _functionRepo.reorderFunctions(updatedFunctions);

      _ref.read(activityRepositoryProvider).logActivity(
        projectId: _projectId,
        entityType: 'Function',
        entityId: featureId,
        entityName: featureNode.feature.name,
        action: 'Reorder',
        description: 'Urutan fungsi pada fitur "${featureNode.feature.name}" telah diatur ulang',
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void updateFunctionAudit(String moduleId, String featureId, String functionId, Audit audit) {
    final currentData = state.value;
    if (currentData == null) return;

    state = AsyncValue.data(currentData.copyWith(
      modules: currentData.modules.map((m) {
        if (m.module.id == moduleId) {
          return m.copyWith(
            features: m.features.map((f) {
              if (f.feature.id == featureId) {
                return f.copyWith(
                  functions: f.functions.map((fn) {
                    if (fn.id == functionId) {
                      return fn.copyWith(activeAudit: audit);
                    }
                    return fn;
                  }).toList(),
                );
              }
              return f;
            }).toList(),
          );
        }
        return m;
      }).toList(),
    ));
  }
}

// Parametrized provider for loading project trees
final projectTreeProvider = StateNotifierProvider.family<ProjectTreeNotifier, AsyncValue<ProjectTreeData>, String>((ref, projectId) {
  final projectRepo = ref.watch(projectRepositoryProvider);
  final moduleRepo = ref.watch(moduleRepositoryProvider);
  final featureRepo = ref.watch(featureRepositoryProvider);
  final functionRepo = ref.watch(functionRepositoryProvider);

  return ProjectTreeNotifier(
    projectId: projectId,
    projectRepo: projectRepo,
    moduleRepo: moduleRepo,
    featureRepo: featureRepo,
    functionRepo: functionRepo,
    ref: ref,
  );
});
