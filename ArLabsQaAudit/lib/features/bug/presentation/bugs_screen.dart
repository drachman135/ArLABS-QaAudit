import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/bug_model.dart';
import '../data/bug_repository.dart';
import '../../project/data/project_repository.dart';
import '../../project/domain/project_model.dart';
import '../../../core/widgets/empty_state.dart';

// UI local state state providers for filters
final bugSearchProvider = StateProvider<String>((ref) => '');
final bugSeverityFilterProvider = StateProvider<String>((ref) => 'All');
final bugStatusFilterProvider = StateProvider<String>((ref) => 'All');
final bugProjectFilterProvider = StateProvider<String>((ref) => 'All');
final bugAssignedFilterProvider = StateProvider<String>((ref) => 'All');
final bugSortProvider = StateProvider<String>((ref) => 'Newest');

class BugsScreen extends ConsumerWidget {
  const BugsScreen({super.key});

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'Critical':
        return const Color(0xFF7F1D1D); // Merah pekat
      case 'High':
        return const Color(0xFFEF4444); // Merah
      case 'Medium':
        return const Color(0xFFF59E0B); // Oranye
      case 'Low':
        return const Color(0xFF10B981); // Hijau
      default:
        return const Color(0xFF64748B);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Open':
        return const Color(0xFF3B82F6); // Blue
      case 'In Progress':
        return const Color(0xFF8B5CF6); // Purple
      case 'Ready To Test':
        return const Color(0xFFF59E0B); // Orange
      case 'Resolved':
        return const Color(0xFF10B981); // Green
      case 'Closed':
        return const Color(0xFF64748B); // Slate
      case 'Rejected':
        return const Color(0xFFEF4444); // Red
      default:
        return const Color(0xFF64748B);
    }
  }

  int _getSeverityWeight(String severity) {
    switch (severity) {
      case 'Critical':
        return 4;
      case 'High':
        return 3;
      case 'Medium':
        return 2;
      case 'Low':
        return 1;
      default:
        return 0;
    }
  }

  int _getStatusWeight(String status) {
    switch (status) {
      case 'Open':
        return 6;
      case 'In Progress':
        return 5;
      case 'Ready To Test':
        return 4;
      case 'Resolved':
        return 3;
      case 'Closed':
        return 2;
      case 'Rejected':
        return 1;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final bugsAsync = ref.watch(bugsListProvider);
    final projectsAsync = ref.watch(projectListProvider);

    // Watch filters state
    final search = ref.watch(bugSearchProvider);
    final sevFilter = ref.watch(bugSeverityFilterProvider);
    final statFilter = ref.watch(bugStatusFilterProvider);
    final projFilter = ref.watch(bugProjectFilterProvider);
    final assignFilter = ref.watch(bugAssignedFilterProvider);
    final sortBy = ref.watch(bugSortProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bugs Registry',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Track, manage, and resolve feature audit bugs.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => context.push('/bugs/new'),
                  icon: const Icon(Icons.bug_report_rounded),
                  label: const Text('Report Bug'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Search Bar & Filters Card
            _buildSearchAndFilters(context, ref, projectsAsync),
            const SizedBox(height: 24),

            // Bugs List Section
            Expanded(
              child: bugsAsync.when(
                data: (bugs) {
                  // 1. Apply Search and Filters locally
                  List<Bug> filteredBugs = bugs.where((bug) {
                    final query = search.toLowerCase();
                    final matchesSearch = query.isEmpty ||
                        bug.title.toLowerCase().contains(query) ||
                        bug.description.toLowerCase().contains(query) ||
                        (bug.projectName?.toLowerCase().contains(query) ?? false) ||
                        (bug.moduleName?.toLowerCase().contains(query) ?? false) ||
                        (bug.featureName?.toLowerCase().contains(query) ?? false) ||
                        (bug.functionName?.toLowerCase().contains(query) ?? false);

                    final matchesSeverity = sevFilter == 'All' || bug.severity == sevFilter;
                    final matchesStatus = statFilter == 'All' || bug.status == statFilter;
                    final matchesProject = projFilter == 'All' || bug.projectId == projFilter;
                    final matchesAssigned = assignFilter == 'All' ||
                        (assignFilter == 'Unassigned' && bug.assignedTo == null) ||
                        bug.assignedTo == assignFilter;

                    return matchesSearch && matchesSeverity && matchesStatus && matchesProject && matchesAssigned;
                  }).toList();

                  // 2. Apply Sort options
                  if (sortBy == 'Newest') {
                    filteredBugs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                  } else if (sortBy == 'Oldest') {
                    filteredBugs.sort((a, b) => a.createdAt.compareTo(b.createdAt));
                  } else if (sortBy == 'Severity') {
                    filteredBugs.sort((a, b) => _getSeverityWeight(b.severity).compareTo(_getSeverityWeight(a.severity)));
                  } else if (sortBy == 'Status') {
                    filteredBugs.sort((a, b) => _getStatusWeight(b.status).compareTo(_getStatusWeight(a.status)));
                  } else if (sortBy == 'Project') {
                    filteredBugs.sort((a, b) => (a.projectName ?? '').compareTo(b.projectName ?? ''));
                  } else if (sortBy == 'Title') {
                    filteredBugs.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
                  }

                  if (filteredBugs.isEmpty) {
                    return EmptyState(
                      icon: Icons.bug_report_outlined,
                      title: 'No Bugs Found',
                      description: bugs.isEmpty
                          ? 'No bugs have been reported in this workspace yet.'
                          : 'No bugs match your active filter criteria.',
                      actionLabel: bugs.isEmpty ? 'Report Bug' : null,
                      onActionPressed: bugs.isEmpty ? () => context.push('/bugs/new') : null,
                    );
                  }

                  return ListView.separated(
                    itemCount: filteredBugs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final bug = filteredBugs[index];
                      return _buildBugCard(context, ref, bug);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, st) => EmptyState(
                  icon: Icons.error_outline_rounded,
                  title: 'Error loading bugs',
                  description: err.toString(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters(BuildContext context, WidgetRef ref, AsyncValue<List<ProjectWithStats>> projectsAsync) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final sevFilter = ref.watch(bugSeverityFilterProvider);
    final statFilter = ref.watch(bugStatusFilterProvider);
    final projFilter = ref.watch(bugProjectFilterProvider);
    final sortBy = ref.watch(bugSortProvider);

    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF1E293B).withOpacity(0.2) : const Color(0xFFF8FAFC),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isDark ? const Color(0xFF334155).withValues(alpha: 0.4) : const Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Search field
            TextField(
              onChanged: (val) => ref.read(bugSearchProvider.notifier).state = val,
              decoration: const InputDecoration(
                hintText: 'Search bugs by title, description, function, feature, project...',
                prefixIcon: Icon(Icons.search_rounded),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),

            // Dropdown filters
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _buildFilterLabel(context, Icons.filter_alt_outlined, 'Filters:'),
                
                // Severity filter
                _buildDropdown(
                  context: context,
                  label: 'Severity',
                  value: sevFilter,
                  items: ['All', 'Critical', 'High', 'Medium', 'Low'],
                  onChanged: (val) => ref.read(bugSeverityFilterProvider.notifier).state = val!,
                ),

                // Status filter
                _buildDropdown(
                  context: context,
                  label: 'Status',
                  value: statFilter,
                  items: ['All', 'Open', 'In Progress', 'Ready To Test', 'Resolved', 'Closed', 'Rejected'],
                  onChanged: (val) => ref.read(bugStatusFilterProvider.notifier).state = val!,
                ),

                // Project filter
                projectsAsync.when(
                  data: (projects) {
                    final items = ['All', ...projects.map((p) => p.project.id)];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: projFilter,
                          isDense: true,
                          style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, fontSize: 11),
                          items: items.map((opt) {
                            String name = 'Project: All';
                            if (opt != 'All') {
                              name = 'Project: ${projects.firstWhere((p) => p.project.id == opt).project.name}';
                            }
                            return DropdownMenuItem<String>(
                              value: opt,
                              child: Text(name),
                            );
                          }).toList(),
                          onChanged: (val) => ref.read(bugProjectFilterProvider.notifier).state = val!,
                        ),
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                _buildFilterLabel(context, Icons.sort_rounded, 'Sort:'),

                // Sort option
                _buildDropdown(
                  context: context,
                  label: 'Sort By',
                  value: sortBy,
                  items: ['Newest', 'Oldest', 'Severity', 'Status', 'Project', 'Title'],
                  onChanged: (val) => ref.read(bugSortProvider.notifier).state = val!,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterLabel(BuildContext context, IconData icon, String label) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6366F1)),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 11),
        ),
      ],
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
          style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, fontSize: 11),
          items: items.map((opt) {
            return DropdownMenuItem<String>(
              value: opt,
              child: Text(opt == 'All' ? '$label: All' : opt),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildBugCard(BuildContext context, WidgetRef ref, Bug bug) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final sevColor = _getSeverityColor(bug.severity);
    final statColor = _getStatusColor(bug.status);

    final pathStr = "${bug.projectName ?? 'Project'}  /  ${bug.moduleName ?? 'Module'}  /  ${bug.featureName ?? 'Feature'}  /  ${bug.functionName ?? 'Function'}";
    final lastUpdatedStr = "${bug.updatedAt.day}/${bug.updatedAt.month}/${bug.updatedAt.year}";

    return Card(
      child: InkWell(
        onTap: () => context.push('/bugs/${bug.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              // Bug icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: sevColor.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.bug_report_rounded, color: sevColor, size: 24),
              ),
              const SizedBox(width: 20),

              // Title and context info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          pathStr,
                          style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        Text(
                          'Last updated $lastUpdatedStr',
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      bug.title,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bug.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // Severity tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: sevColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: sevColor.withOpacity(0.2)),
                          ),
                          child: Text(
                            bug.severity,
                            style: TextStyle(
                              color: sevColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Status tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: statColor.withOpacity(0.2)),
                          ),
                          child: Text(
                            bug.status,
                            style: TextStyle(
                              color: statColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.person_outline_rounded, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          bug.assignedTo ?? 'Unassigned',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
