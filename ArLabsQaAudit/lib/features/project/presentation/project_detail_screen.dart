import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/project_tree_provider.dart';
import '../../module/domain/module_model.dart';
import '../../feature/domain/feature_model.dart';
import '../../function/domain/function_model.dart';
import '../../../core/widgets/empty_state.dart';
import '../../audit/domain/audit_statistics.dart';

// StateProviders to track expanded nodes locally in the UI
final expandedModulesProvider = StateProvider.family<Set<String>, String>((ref, projectId) => {});
final expandedFeaturesProvider = StateProvider.family<Set<String>, String>((ref, projectId) => {});

// Filter & Sort State Providers for this Project details tree
final detailStatusFilterProvider = StateProvider.family<String, String>((ref, projectId) => 'All');
final detailPriorityFilterProvider = StateProvider.family<String, String>((ref, projectId) => 'All');
final detailModuleSortProvider = StateProvider.family<String, String>((ref, projectId) => 'Default');
final detailFeatureSortProvider = StateProvider.family<String, String>((ref, projectId) => 'Default');
final detailFunctionSortProvider = StateProvider.family<String, String>((ref, projectId) => 'Default');

class ProjectDetailScreen extends ConsumerWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Passed':
        return const Color(0xFF10B981); // Emerald
      case 'Failed':
        return const Color(0xFFEF4444); // Red
      case 'Warning':
        return const Color(0xFFF59E0B); // Amber
      case 'Skipped':
        return const Color(0xFF3B82F6); // Blue
      case 'Not Implemented':
        return const Color(0xFF334155); // Slate
      default:
        return const Color(0xFF64748B); // Cool Gray
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Passed':
        return Icons.check_circle_rounded;
      case 'Failed':
        return Icons.cancel_rounded;
      case 'Warning':
        return Icons.warning_rounded;
      case 'Skipped':
        return Icons.skip_next_rounded;
      case 'Not Implemented':
        return Icons.construction_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  Widget _buildDotCount(Color color, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          count.toString(),
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final treeAsync = ref.watch(projectTreeProvider(projectId));

    // Read filter & sort state
    final statusFilter = ref.watch(detailStatusFilterProvider(projectId));
    final priorityFilter = ref.watch(detailPriorityFilterProvider(projectId));
    final moduleSort = ref.watch(detailModuleSortProvider(projectId));
    final featureSort = ref.watch(detailFeatureSortProvider(projectId));
    final functionSort = ref.watch(detailFunctionSortProvider(projectId));

    return Scaffold(
      body: treeAsync.when(
        data: (treeData) {
          final project = treeData.project;

          // 1. Process and apply filters/sorting locally on the client-side
          List<ModuleNode> processedModules = [];

          for (final modNode in treeData.modules) {
            List<FeatureNode> processedFeatures = [];

            for (final featNode in modNode.features) {
              // Filter functions
              List<AppFunction> filteredFunctions = featNode.functions.where((func) {
                final status = func.activeAudit?.status ?? 'Not Tested';
                final priority = func.activeAudit?.priority ?? 'None';

                final matchesStatus = statusFilter == 'All' || status == statusFilter;
                
                bool matchesPriority = true;
                if (priorityFilter != 'All') {
                  if (priorityFilter == 'None') {
                    matchesPriority = func.activeAudit?.priority == null;
                  } else {
                    matchesPriority = priority == priorityFilter;
                  }
                }

                return matchesStatus && matchesPriority;
              }).toList();

              // Sort functions
              if (functionSort == 'Name') {
                filteredFunctions.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
              } else if (functionSort == 'Last Updated') {
                filteredFunctions.sort((a, b) {
                  final timeA = a.activeAudit?.lastAuditedAt ?? a.updatedAt;
                  final timeB = b.activeAudit?.lastAuditedAt ?? b.updatedAt;
                  return timeB.compareTo(timeA); // Descending
                });
              } else if (functionSort == 'Status') {
                filteredFunctions.sort((a, b) {
                  final statusA = a.activeAudit?.status ?? 'Not Tested';
                  final statusB = b.activeAudit?.status ?? 'Not Tested';
                  return statusA.compareTo(statusB);
                });
              } else {
                // Default: orderIndex
                filteredFunctions.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
              }

              // Only keep feature if filter is inactive or if we have matching functions
              final isFilterActive = statusFilter != 'All' || priorityFilter != 'All';
              if (!isFilterActive || filteredFunctions.isNotEmpty) {
                processedFeatures.add(featNode.copyWith(functions: filteredFunctions));
              }
            }

            // Sort features
            if (featureSort == 'Name') {
              processedFeatures.sort((a, b) => a.feature.name.toLowerCase().compareTo(b.feature.name.toLowerCase()));
            } else if (featureSort == 'Progress') {
              processedFeatures.sort((a, b) {
                final progressA = AuditStatistics.calculate(a.functions).progressPercentage;
                final progressB = AuditStatistics.calculate(b.functions).progressPercentage;
                return progressB.compareTo(progressA);
              });
            } else {
              processedFeatures.sort((a, b) => a.feature.orderIndex.compareTo(b.feature.orderIndex));
            }

            // Only keep module if filter is inactive or we have matching features
            final isFilterActive = statusFilter != 'All' || priorityFilter != 'All';
            if (!isFilterActive || processedFeatures.isNotEmpty) {
              processedModules.add(modNode.copyWith(features: processedFeatures));
            }
          }

          // Sort modules
          if (moduleSort == 'Name') {
            processedModules.sort((a, b) => a.module.name.toLowerCase().compareTo(b.module.name.toLowerCase()));
          } else if (moduleSort == 'Progress') {
            processedModules.sort((a, b) {
              final functionsA = a.features.expand((f) => f.functions).toList();
              final functionsB = b.features.expand((f) => f.functions).toList();
              final progressA = AuditStatistics.calculate(functionsA).progressPercentage;
              final progressB = AuditStatistics.calculate(functionsB).progressPercentage;
              return progressB.compareTo(progressA);
            });
          } else {
            processedModules.sort((a, b) => a.module.orderIndex.compareTo(b.module.orderIndex));
          }

          // Compute Overall Project statistics
          final projectFunctions = treeData.modules.expand((m) => m.features.expand((f) => f.functions)).toList();
          final projStats = AuditStatistics.calculate(projectFunctions);

          return Padding(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Navigation/Breadcrumb header
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => context.go('/projects'),
                      icon: const Icon(Icons.arrow_back_rounded, size: 16),
                      label: const Text('Back to Projects'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Project Info Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                project.name,
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              if (project.description != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  project.description!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),
                              // Overall Project Progress bar in Info Card
                              Row(
                                children: [
                                  Text(
                                    'Overall Project Audit Progress: ',
                                    style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '${projStats.progressPercentage.toStringAsFixed(1)}%',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  _buildDotCount(const Color(0xFF10B981), projStats.passedCount),
                                  const SizedBox(width: 8),
                                  _buildDotCount(const Color(0xFFEF4444), projStats.failedCount),
                                  const SizedBox(width: 8),
                                  _buildDotCount(const Color(0xFFF59E0B), projStats.warningCount),
                                  const SizedBox(width: 8),
                                  _buildDotCount(const Color(0xFF64748B), projStats.notTestedCount),
                                  if (projStats.bugCount > 0) ...[
                                    const SizedBox(width: 16),
                                    const Icon(Icons.bug_report_rounded, size: 14, color: Color(0xFFEF4444)),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${projStats.bugCount} Bugs (${projStats.criticalBugs} Critical, ${projStats.highBugs} High, ${projStats.mediumBugs} Medium, ${projStats.lowBugs} Low)',
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFEF4444)),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: projStats.progressPercentage / 100,
                                backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        ElevatedButton.icon(
                          onPressed: () => _showAddModuleDialog(context, ref),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Add Module'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Filter & Sort Control Panel
                _buildFilterAndSortPanel(context, ref),
                const SizedBox(height: 24),

                // Tree Hierarchy Section
                Expanded(
                  child: processedModules.isEmpty
                      ? EmptyState(
                          icon: Icons.account_tree_outlined,
                          title: 'No Items Found',
                          description: 'No modules, features, or functions match your filters or are added yet.',
                          actionLabel: 'Add Module',
                          onActionPressed: () => _showAddModuleDialog(context, ref),
                        )
                      : _buildModulesList(context, ref, processedModules),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Error loading project detail',
          description: err.toString(),
          actionLabel: 'Retry',
          onActionPressed: () => ref.read(projectTreeProvider(projectId).notifier).loadTree(),
        ),
      ),
    );
  }

  Widget _buildFilterAndSortPanel(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final statusFilter = ref.watch(detailStatusFilterProvider(projectId));
    final priorityFilter = ref.watch(detailPriorityFilterProvider(projectId));
    final moduleSort = ref.watch(detailModuleSortProvider(projectId));
    final featureSort = ref.watch(detailFeatureSortProvider(projectId));
    final functionSort = ref.watch(detailFunctionSortProvider(projectId));

    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF1E293B).withOpacity(0.2) : const Color(0xFFF8FAFC),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? const Color(0xFF334155).withOpacity(0.4) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Wrap(
          spacing: 16,
          runSpacing: 12,
          alignment: WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.filter_list_rounded, size: 16, color: Color(0xFF6366F1)),
                const SizedBox(width: 6),
                Text(
                  'Filters',
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
            _buildDropdown(
              context: context,
              label: 'Status',
              value: statusFilter,
              items: ['All', 'Not Tested', 'Passed', 'Failed', 'Warning', 'Not Implemented', 'Skipped'],
              onChanged: (val) => ref.read(detailStatusFilterProvider(projectId).notifier).state = val!,
            ),
            _buildDropdown(
              context: context,
              label: 'Priority',
              value: priorityFilter,
              items: ['All', 'P0', 'P1', 'P2', 'P3', 'None'],
              onChanged: (val) => ref.read(detailPriorityFilterProvider(projectId).notifier).state = val!,
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.sort_rounded, size: 16, color: Color(0xFF6366F1)),
                const SizedBox(width: 6),
                Text(
                  'Sort',
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
            _buildDropdown(
              context: context,
              label: 'Module',
              value: moduleSort,
              items: ['Default', 'Name', 'Progress'],
              onChanged: (val) => ref.read(detailModuleSortProvider(projectId).notifier).state = val!,
            ),
            _buildDropdown(
              context: context,
              label: 'Feature',
              value: featureSort,
              items: ['Default', 'Name', 'Progress'],
              onChanged: (val) => ref.read(detailFeatureSortProvider(projectId).notifier).state = val!,
            ),
            _buildDropdown(
              context: context,
              label: 'Function',
              value: functionSort,
              items: ['Default', 'Name', 'Last Updated', 'Status'],
              onChanged: (val) => ref.read(detailFunctionSortProvider(projectId).notifier).state = val!,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required BuildContext context,
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 14),
          style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, fontSize: 11),
          items: items.map((opt) {
            return DropdownMenuItem<String>(
              value: opt,
              child: Text('$label: $opt'),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // --- MODULE LIST (Drag & Drop Reorderable) ---
  Widget _buildModulesList(BuildContext context, WidgetRef ref, List<ModuleNode> modules) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final expandedModules = ref.watch(expandedModulesProvider(projectId));

    return ReorderableListView.builder(
      itemCount: modules.length,
      buildDefaultDragHandles: false,
      onReorder: (oldIndex, newIndex) {
        ref.read(projectTreeProvider(projectId).notifier).reorderModules(oldIndex, newIndex);
      },
      itemBuilder: (context, index) {
        final node = modules[index];
        final module = node.module;
        final isExpanded = expandedModules.contains(module.id);

        final moduleFunctions = node.features.expand((f) => f.functions).toList();
        final modStats = AuditStatistics.calculate(moduleFunctions);

        return Card(
          key: ValueKey('module_${module.id}'),
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Module Header Row
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ReorderableDragStartListener(
                      index: index,
                      child: const Icon(Icons.drag_handle_rounded, color: Colors.grey),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        isExpanded ? Icons.expand_more_rounded : Icons.chevron_right_rounded,
                        size: 20,
                      ),
                      onPressed: () {
                        final current = ref.read(expandedModulesProvider(projectId));
                        final updated = Set<String>.from(current);
                        if (isExpanded) {
                          updated.remove(module.id);
                        } else {
                          updated.add(module.id);
                        }
                        ref.read(expandedModulesProvider(projectId).notifier).state = updated;
                      },
                    ),
                  ],
                ),
                title: Text(
                  module.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (module.description != null) ...[
                      Text(module.description!),
                      const SizedBox(height: 6),
                    ],
                    // Progress bar and details for Module
                    Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: modStats.progressPercentage / 100,
                              minHeight: 4,
                              backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${modStats.progressPercentage.toStringAsFixed(0)}% (${modStats.totalCount} Funcs)',
                          style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 12),
                        _buildDotCount(const Color(0xFF10B981), modStats.passedCount),
                        const SizedBox(width: 8),
                        _buildDotCount(const Color(0xFFEF4444), modStats.failedCount),
                        const SizedBox(width: 8),
                        _buildDotCount(const Color(0xFFF59E0B), modStats.warningCount),
                        if (modStats.bugCount > 0) ...[
                          const SizedBox(width: 12),
                          const Icon(Icons.bug_report_rounded, size: 14, color: Color(0xFFEF4444)),
                          const SizedBox(width: 4),
                          Text(
                            '${modStats.bugCount} Bugs',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFEF4444)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton.icon(
                      onPressed: () => _showAddFeatureDialog(context, ref, module.id),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Feature'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      onPressed: () => _showEditModuleDialog(context, ref, module),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                      onPressed: () => _showDeleteModuleDialog(context, ref, module),
                    ),
                  ],
                ),
              ),

              // Module Expandable Content (Features List)
              if (isExpanded) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(48, 16, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (node.features.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: EmptyState(
                            icon: Icons.extension_outlined,
                            title: 'No Features Yet',
                            description: 'Features describe target features of this module.',
                            actionLabel: 'Add Feature',
                            onActionPressed: () => _showAddFeatureDialog(context, ref, module.id),
                          ),
                        )
                      else
                        _buildFeaturesList(context, ref, module, node.features),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // --- FEATURES LIST (Drag & Drop Reorderable) ---
  Widget _buildFeaturesList(BuildContext context, WidgetRef ref, Module module, List<FeatureNode> features) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final expandedFeatures = ref.watch(expandedFeaturesProvider(projectId));

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: features.length,
      buildDefaultDragHandles: false,
      onReorder: (oldIndex, newIndex) {
        ref.read(projectTreeProvider(projectId).notifier).reorderFeatures(module.id, oldIndex, newIndex);
      },
      itemBuilder: (context, index) {
        final node = features[index];
        final feature = node.feature;
        final isExpanded = expandedFeatures.contains(feature.id);

        final featStats = AuditStatistics.calculate(node.functions);

        return Card(
          key: ValueKey('feature_${feature.id}'),
          margin: const EdgeInsets.only(bottom: 8),
          color: isDark ? const Color(0xFF1E293B).withOpacity(0.4) : const Color(0xFFF8FAFC),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                dense: true,
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ReorderableDragStartListener(
                      index: index,
                      child: const Icon(Icons.drag_handle_rounded, size: 18, color: Colors.grey),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: Icon(
                        isExpanded ? Icons.expand_more_rounded : Icons.chevron_right_rounded,
                        size: 18,
                      ),
                      onPressed: () {
                        final current = ref.read(expandedFeaturesProvider(projectId));
                        final updated = Set<String>.from(current);
                        if (isExpanded) {
                          updated.remove(feature.id);
                        } else {
                          updated.add(feature.id);
                        }
                        ref.read(expandedFeaturesProvider(projectId).notifier).state = updated;
                      },
                    ),
                  ],
                ),
                title: Text(
                  feature.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (feature.description != null) ...[
                      Text(feature.description!, style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 6),
                    ],
                    // Progress and metrics for Feature
                    Row(
                      children: [
                        SizedBox(
                          width: 60,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: featStats.progressPercentage / 100,
                              minHeight: 3,
                              backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${featStats.progressPercentage.toStringAsFixed(0)}% (${featStats.totalCount} Funcs)',
                          style: theme.textTheme.bodySmall?.copyWith(fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 12),
                        _buildDotCount(const Color(0xFF10B981), featStats.passedCount),
                        const SizedBox(width: 6),
                        _buildDotCount(const Color(0xFFEF4444), featStats.failedCount),
                        const SizedBox(width: 6),
                        _buildDotCount(const Color(0xFFF59E0B), featStats.warningCount),
                        const SizedBox(width: 6),
                        _buildDotCount(const Color(0xFF64748B), featStats.notTestedCount),
                        if (featStats.bugCount > 0) ...[
                          const SizedBox(width: 12),
                          const Icon(Icons.bug_report_rounded, size: 14, color: Color(0xFFEF4444)),
                          const SizedBox(width: 4),
                          Text(
                            '${featStats.bugCount} Bugs',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFEF4444)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton.icon(
                      onPressed: () => _showAddFunctionDialog(context, ref, module.id, feature.id),
                      icon: const Icon(Icons.add_rounded, size: 14),
                      label: const Text('Function', style: TextStyle(fontSize: 11)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      onPressed: () => _showEditFeatureDialog(context, ref, feature),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                      onPressed: () => _showDeleteFeatureDialog(context, ref, module.id, feature),
                    ),
                  ],
                ),
              ),

              // Feature Expandable Content (Functions List)
              if (isExpanded) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(40, 8, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (node.functions.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: EmptyState(
                            icon: Icons.code_rounded,
                            title: 'No Functions Yet',
                            description: 'Functions denote individual actions inside this feature.',
                            actionLabel: 'Add Function',
                            onActionPressed: () => _showAddFunctionDialog(context, ref, module.id, feature.id),
                          ),
                        )
                      else
                        _buildFunctionsList(context, ref, module, feature, node.functions),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // --- FUNCTIONS LIST (Drag & Drop Reorderable) ---
  Widget _buildFunctionsList(BuildContext context, WidgetRef ref, Module module, Feature feature, List<AppFunction> functions) {
    final theme = Theme.of(context);

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: functions.length,
      buildDefaultDragHandles: false,
      onReorder: (oldIndex, newIndex) {
        ref.read(projectTreeProvider(projectId).notifier).reorderFunctions(module.id, feature.id, oldIndex, newIndex);
      },
      itemBuilder: (context, index) {
        final function = functions[index];
        final status = function.activeAudit?.status ?? 'Not Tested';
        final priority = function.activeAudit?.priority;
        final statusColor = _getStatusColor(status);
        
        final lastUpdated = function.activeAudit?.lastAuditedAt ?? function.updatedAt;
        final lastUpdatedStr = "${lastUpdated.day}/${lastUpdated.month}/${lastUpdated.year}";

        return Container(
          key: ValueKey('function_${function.id}'),
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: theme.dividerColor.withOpacity(0.6)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              ReorderableDragStartListener(
                index: index,
                child: const Icon(Icons.drag_handle_rounded, size: 16, color: Colors.grey),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () {
                    context.push(
                      '/projects/$projectId/modules/${module.id}/features/${feature.id}/functions/${function.id}/audit',
                      extra: {
                        'functionName': function.name,
                        'moduleName': module.name,
                        'featureName': feature.name,
                        'initialAudit': function.activeAudit,
                      },
                    );
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Row(
                    children: [
                      Icon(_getStatusIcon(status), color: statusColor, size: 18),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              function.name,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (function.description != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                function.description!,
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Audit Badges
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: statusColor.withOpacity(0.2)),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (priority != null) ...[
                    const SizedBox(width: 8),
                    // Priority Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.2)),
                      ),
                      child: Text(
                        priority,
                        style: const TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  if ((function.activeAudit?.bugs.length ?? 0) > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bug_report_rounded, size: 10, color: Color(0xFFEF4444)),
                          const SizedBox(width: 4),
                          Text(
                            '${function.activeAudit!.bugs.length}',
                            style: const TextStyle(
                              color: Color(0xFFEF4444),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(width: 12),
                  // Last Updated Timestamp
                  Text(
                    lastUpdatedStr,
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, color: Colors.grey),
                  ),
                  const SizedBox(width: 8),
                  // Edit & Delete Actions
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 14),
                    onPressed: () => _showEditFunctionDialog(context, ref, module.id, feature.id, function),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 14, color: Colors.redAccent),
                    onPressed: () => _showDeleteFunctionDialog(context, ref, module.id, feature.id, function),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // --- DIALOG BUILDERS (Inline Add/Edit/Delete Modals) ---

  // Module Dialogs
  void _showAddModuleDialog(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Module'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Module Name'),
                validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                ref.read(projectTreeProvider(projectId).notifier).addModule(
                      nameController.text.trim(),
                      descController.text.trim().isEmpty ? null : descController.text.trim(),
                    );
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditModuleDialog(BuildContext context, WidgetRef ref, Module module) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: module.name);
    final descController = TextEditingController(text: module.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Module'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Module Name'),
                validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                ref.read(projectTreeProvider(projectId).notifier).updateModule(
                      module.copyWith(
                        name: nameController.text.trim(),
                        description: descController.text.trim().isEmpty ? null : descController.text.trim(),
                        updatedAt: DateTime.now(),
                      ),
                    );
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteModuleDialog(BuildContext context, WidgetRef ref, Module module) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Module'),
        content: Text('Are you sure you want to permanently delete module "${module.name}"? This will delete all its nested features and functions.'),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              ref.read(projectTreeProvider(projectId).notifier).deleteModule(module.id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Feature Dialogs
  void _showAddFeatureDialog(BuildContext context, WidgetRef ref, String moduleId) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Feature'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Feature Name'),
                validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                ref.read(projectTreeProvider(projectId).notifier).addFeature(
                      moduleId,
                      nameController.text.trim(),
                      descController.text.trim().isEmpty ? null : descController.text.trim(),
                    );
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditFeatureDialog(BuildContext context, WidgetRef ref, Feature feature) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: feature.name);
    final descController = TextEditingController(text: feature.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Feature'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Feature Name'),
                validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                ref.read(projectTreeProvider(projectId).notifier).updateFeature(
                      feature.copyWith(
                        name: nameController.text.trim(),
                        description: descController.text.trim().isEmpty ? null : descController.text.trim(),
                        updatedAt: DateTime.now(),
                      ),
                    );
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteFeatureDialog(BuildContext context, WidgetRef ref, String moduleId, Feature feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Feature'),
        content: Text('Are you sure you want to permanently delete feature "${feature.name}"? This will delete all its nested functions.'),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              ref.read(projectTreeProvider(projectId).notifier).deleteFeature(moduleId, feature.id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Function Dialogs
  void _showAddFunctionDialog(BuildContext context, WidgetRef ref, String moduleId, String featureId) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Function'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Function Name'),
                validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                ref.read(projectTreeProvider(projectId).notifier).addFunction(
                      moduleId,
                      featureId,
                      nameController.text.trim(),
                      descController.text.trim().isEmpty ? null : descController.text.trim(),
                    );
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditFunctionDialog(BuildContext context, WidgetRef ref, String moduleId, String featureId, AppFunction function) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: function.name);
    final descController = TextEditingController(text: function.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Function'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Function Name'),
                validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                ref.read(projectTreeProvider(projectId).notifier).updateFunction(
                      moduleId,
                      featureId,
                      function.copyWith(
                        name: nameController.text.trim(),
                        description: descController.text.trim().isEmpty ? null : descController.text.trim(),
                        updatedAt: DateTime.now(),
                      ),
                    );
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteFunctionDialog(BuildContext context, WidgetRef ref, String moduleId, String featureId, AppFunction function) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Function'),
        content: Text('Are you sure you want to permanently delete function "${function.name}"?'),
        actions: [
          OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              ref.read(projectTreeProvider(projectId).notifier).deleteFunction(moduleId, featureId, function.id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
