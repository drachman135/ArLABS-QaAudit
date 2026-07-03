import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/project_model.dart';
import '../data/project_repository.dart';
import 'widgets/project_dialogs.dart';
import '../../../core/widgets/empty_state.dart';

// Search state provider
final projectSearchProvider = StateProvider<String>((ref) => '');
// Status filter state provider: 'Active' or 'Archived'
final projectStatusFilterProvider = StateProvider<String>((ref) => 'Active');
// Sort state provider: 'Name', 'Last Updated', or 'Progress'
final projectSortProvider = StateProvider<String>((ref) => 'Name');

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final projectsAsync = ref.watch(projectListProvider);
    final searchQuery = ref.watch(projectSearchProvider);
    final statusFilter = ref.watch(projectStatusFilterProvider);
    final sortType = ref.watch(projectSortProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Projects',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Manage, search, and configure your QA workspaces.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => ProjectDialogs.showCreateProject(context, ref),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('New Project'),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Search Bar & Filter Row
            Row(
              children: [
                // Realtime Search Input
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextFormField(
                      initialValue: searchQuery,
                      onChanged: (val) => ref.read(projectSearchProvider.notifier).state = val.trim(),
                      decoration: InputDecoration(
                        hintText: 'Search projects, modules, features, functions...',
                        prefixIcon: Icon(Icons.search_rounded, color: theme.colorScheme.primary.withOpacity(0.6)),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18),
                                onPressed: () {
                                  ref.read(projectSearchProvider.notifier).state = '';
                                  FocusScope.of(context).unfocus();
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Sorting Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: sortType,
                      icon: const Icon(Icons.sort_rounded, size: 18),
                      items: ['Name', 'Last Updated', 'Progress'].map((type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(
                            'Sort: $type',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(projectSortProvider.notifier).state = val;
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Status Filter Segmented Buttons
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'Active',
                      label: Text('Active'),
                      icon: Icon(Icons.play_arrow_outlined, size: 16),
                    ),
                    ButtonSegment(
                      value: 'Archived',
                      label: Text('Archived'),
                      icon: Icon(Icons.archive_outlined, size: 16),
                    ),
                  ],
                  selected: {statusFilter},
                  onSelectionChanged: (selection) {
                    ref.read(projectStatusFilterProvider.notifier).state = selection.first;
                  },
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Projects List/Grid Content
            Expanded(
              child: projectsAsync.when(
                data: (projects) {
                  // Filter list based on search and status
                  final filtered = projects.where((p) {
                    final matchesStatus = p.project.status == statusFilter;
                    final matchesSearch = p.matchesSearchQuery(searchQuery);
                    return matchesStatus && matchesSearch;
                  }).toList();

                  // Sort projects
                  filtered.sort((a, b) {
                    if (sortType == 'Name') {
                      return a.project.name.toLowerCase().compareTo(b.project.name.toLowerCase());
                    } else if (sortType == 'Last Updated') {
                      return b.project.updatedAt.compareTo(a.project.updatedAt);
                    } else { // Progress
                      return b.stats.progressPercentage.compareTo(a.stats.progressPercentage);
                    }
                  });

                  if (filtered.isEmpty) {
                    if (projects.isEmpty) {
                      return EmptyState(
                        icon: Icons.folder_open_outlined,
                        title: 'No Projects Yet',
                        description: 'Create a project to start planning modules and functions.',
                        actionLabel: 'Create Project',
                        onActionPressed: () => ProjectDialogs.showCreateProject(context, ref),
                      );
                    }

                    return EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'No Projects Found',
                      description: 'No projects match your search criteria. Try a different keyword.',
                      actionLabel: 'Clear Search',
                      onActionPressed: () {
                        ref.read(projectSearchProvider.notifier).state = '';
                        ref.read(projectStatusFilterProvider.notifier).state = 'Active';
                      },
                    );
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final cols = constraints.maxWidth > 1100 ? 3 : (constraints.maxWidth > 700 ? 2 : 1);
                      return GridView.builder(
                        itemCount: filtered.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cols,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          childAspectRatio: cols == 3 ? 1.25 : (cols == 2 ? 1.35 : 1.7),
                        ),
                        itemBuilder: (context, index) {
                          final projectWithStats = filtered[index];
                          return _buildProjectGridCard(context, ref, projectWithStats);
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, st) => EmptyState(
                  icon: Icons.error_outline_rounded,
                  title: 'Connection Error',
                  description: 'Failed to load projects from Supabase. Make sure your credentials are correct.',
                  actionLabel: 'Retry',
                  onActionPressed: () => ref.read(projectListProvider.notifier).loadProjects(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectGridCard(BuildContext context, WidgetRef ref, ProjectWithStats projectWithStats) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final project = projectWithStats.project;
    final stats = projectWithStats.stats;

    final color = ProjectDialogs.getColor(project.color);
    final icon = ProjectDialogs.getIconData(project.icon);
    final lastUpdatedStr = "${project.updatedAt.day}/${project.updatedAt.month}/${project.updatedAt.year}";

    final isActive = project.status == 'Active';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/projects/${project.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon + Status + Menu actions Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (isActive ? const Color(0xFF10B981) : Colors.amber).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: (isActive ? const Color(0xFF10B981) : Colors.amber).withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          project.status,
                          style: TextStyle(
                            color: isActive ? const Color(0xFF10B981) : Colors.amber,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded, size: 18),
                        onSelected: (action) {
                          if (action == 'edit') {
                            ProjectDialogs.showEditProject(context, ref, project);
                          } else if (action == 'archive') {
                            ProjectDialogs.showArchiveProject(context, ref, project);
                          } else if (action == 'delete') {
                            ProjectDialogs.showDeleteProject(context, ref, project);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 16),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'archive',
                            child: Row(
                              children: [
                                Icon(isActive ? Icons.archive_outlined : Icons.unarchive_outlined, size: 16),
                                SizedBox(width: 8),
                                Text(isActive ? 'Archive' : 'Unarchive'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error, size: 16),
                                const SizedBox(width: 8),
                                const Text('Delete'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Name
              Text(
                project.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              // Description
              Text(
                project.description ?? 'No description provided.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  height: 1.4,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),

              // Progress Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress',
                    style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, fontSize: 11),
                  ),
                  Text(
                    '${stats.progressPercentage.toStringAsFixed(1)}%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: stats.progressPercentage / 100,
                backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(4),
                minHeight: 5,
              ),
              const SizedBox(height: 14),

              // Stats indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatItem(context, 'Total Funcs', stats.totalCount.toString()),
                  _buildStatItem(context, 'Audited', stats.auditedCount.toString()),
                  _buildStatItem(context, 'Not Tested', stats.notTestedCount.toString()),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              // Footer metadata
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Updated $lastUpdatedStr',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      fontSize: 10,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: theme.colorScheme.primary.withOpacity(0.8),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}
