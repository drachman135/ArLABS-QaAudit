import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../project/domain/project_model.dart';
import '../../project/data/project_repository.dart';
import '../../project/presentation/widgets/project_dialogs.dart';
import '../../audit/data/audit_repository.dart';
import '../../bug/domain/bug_model.dart';
import '../../bug/data/bug_repository.dart';
import '../../../core/widgets/empty_state.dart';

final recentAuditsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(auditRepositoryProvider);
  return repository.getRecentAudits();
});

// Search query provider for Dashboard global search
final dashboardSearchQueryProvider = StateProvider<String>((ref) => '');

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final projectsAsync = ref.watch(projectListProvider);
    final bugsAsync = ref.watch(bugsListProvider);
    final searchQuery = ref.watch(dashboardSearchQueryProvider);

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome Back, Auditor!',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Here is a quick overview of your QA projects.',
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

              // Global Search Bar
              TextField(
                onChanged: (val) => ref.read(dashboardSearchQueryProvider.notifier).state = val,
                decoration: InputDecoration(
                  hintText: 'Search projects, modules, features, functions or bugs...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () => ref.read(dashboardSearchQueryProvider.notifier).state = '',
                        )
                      : null,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
              ),
              const SizedBox(height: 24),

              // Search Results (if query is not empty)
              if (searchQuery.isNotEmpty)
                projectsAsync.when(
                  data: (projects) {
                    return bugsAsync.when(
                      data: (bugs) {
                        return _buildSearchResults(context, searchQuery, projects, bugs);
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Text('Error loading search bugs: $err'),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Text('Error loading search projects: $err'),
                )
              else ...[
                // Main Dashboard Statistics and cards
                projectsAsync.when(
                  data: (projects) {
                    final totalProjects = projects.length;
                    int totalFunctions = 0;
                    int auditedFunctions = 0;
                    int openFailed = 0;
                    int warnings = 0;

                    for (final p in projects) {
                      totalFunctions += p.stats.totalCount;
                      auditedFunctions += p.stats.auditedCount;
                      openFailed += p.stats.failedCount;
                      warnings += p.stats.warningCount;
                    }

                    final overallProgress = totalFunctions > 0
                        ? (auditedFunctions / totalFunctions) * 100
                        : 0.0;

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final cols = constraints.maxWidth > 1000 ? 3 : (constraints.maxWidth > 600 ? 2 : 1);
                        return GridView.count(
                          crossAxisCount: cols,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          childAspectRatio: cols == 3 ? 2.5 : (cols == 2 ? 3.0 : 4.0),
                          children: [
                            _buildMetricCard(context, 'Total Projects', totalProjects.toString(), Icons.folder_outlined, theme.colorScheme.primary),
                            _buildMetricCard(context, 'Total Functions', totalFunctions.toString(), Icons.code_rounded, const Color(0xFF6366F1)),
                            _buildMetricCard(context, 'Audited Functions', auditedFunctions.toString(), Icons.check_circle_outlined, const Color(0xFF10B981)),
                            _buildMetricCard(context, 'Open Failed', openFailed.toString(), Icons.cancel_outlined, const Color(0xFFEF4444)),
                            _buildMetricCard(context, 'Warning', warnings.toString(), Icons.warning_rounded, const Color(0xFFF59E0B)),
                            _buildMetricCard(context, 'Overall Progress', '${overallProgress.toStringAsFixed(1)}%', Icons.show_chart_rounded, const Color(0xFF8B5CF6)),
                          ],
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Text('Error loading stats: $err'),
                ),
                const SizedBox(height: 32),

                // Bugs Statistics Header
                Text(
                  'Bug Registry Statistics',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Bugs Stats Cards Grid
                bugsAsync.when(
                  data: (bugs) {
                    final total = bugs.length;
                    final open = bugs.where((b) => b.status == 'Open').length;
                    final inProgress = bugs.where((b) => b.status == 'In Progress').length;
                    final readyToTest = bugs.where((b) => b.status == 'Ready To Test').length;
                    final resolved = bugs.where((b) => b.status == 'Resolved').length;
                    final closed = bugs.where((b) => b.status == 'Closed').length;

                    // Severity counts for chart
                    final critical = bugs.where((b) => b.severity == 'Critical').length;
                    final high = bugs.where((b) => b.severity == 'High').length;
                    final medium = bugs.where((b) => b.severity == 'Medium').length;
                    final low = bugs.where((b) => b.severity == 'Low').length;

                    // Status counts for chart
                    final rejected = bugs.where((b) => b.status == 'Rejected').length;

                    return Column(
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final cols = constraints.maxWidth > 1000 ? 6 : (constraints.maxWidth > 600 ? 3 : 2);
                            return GridView.count(
                              crossAxisCount: cols,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: cols == 6 ? 1.8 : 2.2,
                              children: [
                                _buildBugStatCard(context, 'Total Bugs', total, const Color(0xFF64748B)),
                                _buildBugStatCard(context, 'Open', open, const Color(0xFF3B82F6)),
                                _buildBugStatCard(context, 'In Progress', inProgress, const Color(0xFF8B5CF6)),
                                _buildBugStatCard(context, 'Ready to Test', readyToTest, const Color(0xFFF59E0B)),
                                _buildBugStatCard(context, 'Resolved', resolved, const Color(0xFF10B981)),
                                _buildBugStatCard(context, 'Closed', closed, const Color(0xFF475569)),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 24),

                        // Simple stacked charts using CustomPainter
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildChartCard(
                                context,
                                'Bugs by Severity',
                                [
                                  _ChartSegment('Critical', critical, const Color(0xFF7F1D1D)),
                                  _ChartSegment('High', high, const Color(0xFFEF4444)),
                                  _ChartSegment('Medium', medium, const Color(0xFFF59E0B)),
                                  _ChartSegment('Low', low, const Color(0xFF10B981)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: _buildChartCard(
                                context,
                                'Bugs by Status',
                                [
                                  _ChartSegment('Open', open, const Color(0xFF3B82F6)),
                                  _ChartSegment('In Progress', inProgress, const Color(0xFF8B5CF6)),
                                  _ChartSegment('Ready To Test', readyToTest, const Color(0xFFF59E0B)),
                                  _ChartSegment('Resolved', resolved, const Color(0xFF10B981)),
                                  _ChartSegment('Closed', closed, const Color(0xFF64748B)),
                                  _ChartSegment('Rejected', rejected, const Color(0xFFEF4444)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Text('Error loading bug stats: $err'),
                ),
                const SizedBox(height: 48),

                // Recent Projects + Activity Feed section
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 900;
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: isWide ? 3 : 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Recent Projects',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              projectsAsync.when(
                                data: (projects) {
                                  final activeProjects = projects.where((p) => p.project.status == 'Active').toList();
                                  if (activeProjects.isEmpty) {
                                    return Card(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 40.0),
                                        child: EmptyState(
                                          icon: Icons.folder_open_outlined,
                                          title: 'No Projects Yet',
                                          description: 'Get started by creating your first QA project.',
                                          actionLabel: 'Create Project',
                                          onActionPressed: () => ProjectDialogs.showCreateProject(context, ref),
                                        ),
                                      ),
                                    );
                                  }
                                  
                                  final recent = activeProjects.take(3).toList();
                                  return ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: recent.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                                    itemBuilder: (context, index) {
                                      final projectWithStats = recent[index];
                                      return _buildProjectCard(context, ref, projectWithStats);
                                    },
                                  );
                                },
                                loading: () => const Center(child: CircularProgressIndicator()),
                                error: (err, _) => const SizedBox.shrink(),
                              ),
                              const SizedBox(height: 48),

                              Text(
                                'Recent Activity',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildRecentActivityList(context, ref),
                            ],
                          ),
                        ),
                        if (isWide) ...[
                          const SizedBox(width: 40),
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Quick Actions',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildQuickActionsCard(context, ref),
                              ],
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults(
    BuildContext context,
    String query,
    List<ProjectWithStats> projects,
    List<Bug> bugs,
  ) {
    final theme = Theme.of(context);
    final term = query.toLowerCase();

    // 1. Search projects & hierarchy
    final List<Map<String, dynamic>> projectMatches = [];
    final List<Map<String, dynamic>> moduleMatches = [];
    final List<Map<String, dynamic>> featureMatches = [];
    final List<Map<String, dynamic>> functionMatches = [];

    for (final p in projects) {
      if (p.project.name.toLowerCase().contains(term) || (p.project.description?.toLowerCase().contains(term) ?? false)) {
        projectMatches.add({'name': p.project.name, 'id': p.project.id});
      }

      final modules = p.rawModulesJson as List? ?? [];
      for (final m in modules) {
        final modName = m['name'] as String;
        if (modName.toLowerCase().contains(term)) {
          moduleMatches.add({'name': '$modName (${p.project.name})', 'projectId': p.project.id});
        }

        final features = m['features'] as List? ?? [];
        for (final f in features) {
          final featName = f['name'] as String;
          if (featName.toLowerCase().contains(term)) {
            featureMatches.add({'name': '$featName ($modName)', 'projectId': p.project.id});
          }

          final functions = f['functions'] as List? ?? [];
          for (final fn in functions) {
            final funcName = fn['name'] as String;
            if (funcName.toLowerCase().contains(term) || (fn['description']?.toLowerCase().contains(term) ?? false)) {
              functionMatches.add({'name': '$funcName ($featName)', 'projectId': p.project.id});
            }
          }
        }
      }
    }

    // 2. Search bugs
    final List<Bug> bugMatches = bugs.where((b) {
      return b.title.toLowerCase().contains(term) || b.description.toLowerCase().contains(term);
    }).toList();

    final int totalMatches = projectMatches.length + moduleMatches.length + featureMatches.length + functionMatches.length + bugMatches.length;

    if (totalMatches == 0) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Center(
            child: Text('No results match "$query".', style: const TextStyle(color: Colors.grey)),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Search Results ($totalMatches found)',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (bugMatches.isNotEmpty) ...[
              _buildCategoryHeader(context, 'Bugs'),
              ...bugMatches.map((b) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.bug_report_rounded, color: Color(0xFFEF4444), size: 16),
                    title: Text(b.title),
                    subtitle: Text(b.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                    onTap: () => context.push('/bugs/${b.id}'),
                  )),
            ],
            if (projectMatches.isNotEmpty) ...[
              _buildCategoryHeader(context, 'Projects'),
              ...projectMatches.map((p) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.folder_outlined, color: Colors.blue, size: 16),
                    title: Text(p['name']),
                    onTap: () => context.go('/projects/${p['id']}'),
                  )),
            ],
            if (moduleMatches.isNotEmpty) ...[
              _buildCategoryHeader(context, 'Modules'),
              ...moduleMatches.map((m) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.view_module_outlined, color: Colors.amber, size: 16),
                    title: Text(m['name']),
                    onTap: () => context.go('/projects/${m['projectId']}'),
                  )),
            ],
            if (featureMatches.isNotEmpty) ...[
              _buildCategoryHeader(context, 'Features'),
              ...featureMatches.map((f) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.extension_outlined, color: Colors.green, size: 16),
                    title: Text(f['name']),
                    onTap: () => context.go('/projects/${f['projectId']}'),
                  )),
            ],
            if (functionMatches.isNotEmpty) ...[
              _buildCategoryHeader(context, 'Functions'),
              ...functionMatches.map((fn) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.code_rounded, color: Colors.purple, size: 16),
                    title: Text(fn['name']),
                    onTap: () => context.go('/projects/${fn['projectId']}'),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryHeader(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0, bottom: 4.0, left: 16.0),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildBugStatCard(BuildContext context, String label, int value, Color color) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF1E293B).withOpacity(0.15) : const Color(0xFFF8FAFC),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: isDark ? const Color(0xFF334155).withValues(alpha: 0.15) : const Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              value.toString(),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(BuildContext context, String title, List<_ChartSegment> segments) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Container(
              height: 24,
              child: CustomPaint(
                painter: _StackedBarPainter(segments),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: segments.where((s) => s.value > 0).map((seg) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(color: seg.color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${seg.label}: ${seg.value}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(BuildContext context, String title, String count, IconData icon, Color color) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  count,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityList(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activityAsync = ref.watch(recentAuditsProvider);

    return activityAsync.when(
      data: (activities) {
        if (activities.isEmpty) {
          return Card(
            elevation: 0,
            color: isDark ? const Color(0xFF1E293B).withOpacity(0.1) : const Color(0xFFF8FAFC),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: isDark ? const Color(0xFF334155).withValues(alpha: 0.4) : const Color(0xFFE2E8F0)),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 32.0),
              child: Center(
                child: Text('No audits performed yet.', style: TextStyle(color: Colors.grey, fontSize: 13)),
              ),
            ),
          );
        }

        return Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activities.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final act = activities[index];
              final status = act['status'] as String? ?? 'Not Tested';
              
              final function = act['functions'] as Map<String, dynamic>?;
              final functionName = function?['name'] as String? ?? 'Unknown Function';
              
              final feature = function?['features'] as Map<String, dynamic>?;
              final featureName = feature?['name'] as String? ?? 'Feature';
              
              final module = feature?['modules'] as Map<String, dynamic>?;
              final moduleName = module?['name'] as String? ?? 'Module';
              
              final project = module?['projects'] as Map<String, dynamic>?;
              final projectName = project?['name'] as String? ?? 'Project';

              final auditorName = act['auditor_name'] as String? ?? 'Auditor';
              final lastAudited = DateTime.parse(act['last_audited_at'] as String);
              final timeStr = "${lastAudited.day}/${lastAudited.month}/${lastAudited.year}";

              Color statusColor = const Color(0xFF64748B);
              if (status == 'Passed') statusColor = const Color(0xFF10B981);
              if (status == 'Failed') statusColor = const Color(0xFFEF4444);
              if (status == 'Warning') statusColor = const Color(0xFFF59E0B);
              if (status == 'Skipped') statusColor = const Color(0xFF3B82F6);
              if (status == 'Not Implemented') statusColor = const Color(0xFF334155);

              return ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Icon(
                  status == 'Passed' ? Icons.check_circle_rounded : (status == 'Failed' ? Icons.cancel_rounded : Icons.info_outline_rounded),
                  color: statusColor,
                  size: 20,
                ),
                title: Text(
                  '$projectName  /  $moduleName  /  $featureName  /  $functionName',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    'Audited by $auditorName on $timeStr',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: statusColor.withOpacity(0.2)),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Text('Error loading activity: $err', style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _buildProjectCard(BuildContext context, WidgetRef ref, ProjectWithStats projectWithStats) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final project = projectWithStats.project;
    final stats = projectWithStats.stats;

    final color = ProjectDialogs.getColor(project.color);
    final icon = ProjectDialogs.getIconData(project.icon);
    final lastUpdatedStr = "${project.updatedAt.day}/${project.updatedAt.month}/${project.updatedAt.year}";

    return Card(
      child: InkWell(
        onTap: () => context.go('/projects/${project.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          project.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
                          ),
                          child: const Text(
                            'Active',
                            style: TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      project.description ?? 'No description provided.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        SizedBox(
                          width: 120,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: stats.progressPercentage / 100,
                              minHeight: 4,
                              backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${stats.progressPercentage.toStringAsFixed(0)}% Progress (${stats.totalCount} Funcs, ${stats.auditedCount} Audited)',
                          style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                        if (stats.bugCount > 0) ...[
                          const SizedBox(width: 16),
                          const Icon(Icons.bug_report_rounded, size: 14, color: Color(0xFFEF4444)),
                          const SizedBox(width: 4),
                          Text(
                            '${stats.bugCount} Bugs',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFEF4444)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Updated $lastUpdatedStr',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        tooltip: 'Edit',
                        onPressed: () => ProjectDialogs.showEditProject(context, ref, project),
                      ),
                      IconButton(
                        icon: const Icon(Icons.archive_outlined, size: 18),
                        tooltip: 'Archive',
                        onPressed: () => ProjectDialogs.showArchiveProject(context, ref, project),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: () => ProjectDialogs.showCreateProject(context, ref),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create New Project'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.push('/bugs/new'),
              icon: const Icon(Icons.bug_report_rounded),
              label: const Text('Report New Bug'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartSegment {
  final String label;
  final int value;
  final Color color;

  _ChartSegment(this.label, this.value, this.color);
}

class _StackedBarPainter extends CustomPainter {
  final List<_ChartSegment> segments;

  _StackedBarPainter(this.segments);

  @override
  void paint(Canvas canvas, Size size) {
    final int total = segments.fold(0, (sum, seg) => sum + seg.value);
    if (total == 0) {
      // Draw empty placeholder bar
      final paint = Paint()
        ..color = Colors.grey.withOpacity(0.2)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(6)),
        paint,
      );
      return;
    }

    double currentX = 0;
    final double radius = 6.0;

    for (int i = 0; i < segments.length; i++) {
      final seg = segments[i];
      if (seg.value == 0) continue;

      final double width = (seg.value / total) * size.width;
      final paint = Paint()
        ..color = seg.color
        ..style = PaintingStyle.fill;

      final rect = Rect.fromLTWH(currentX, 0, width, size.height);

      // Apply rounded corners only to the edges
      if (i == segments.indexWhere((s) => s.value > 0) && i == segments.lastIndexWhere((s) => s.value > 0)) {
        // Only one segment is visible
        canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)), paint);
      } else if (i == segments.indexWhere((s) => s.value > 0)) {
        // First visible segment (left rounded)
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            rect,
            topLeft: Radius.circular(radius),
            bottomLeft: Radius.circular(radius),
          ),
          paint,
        );
      } else if (i == segments.lastIndexWhere((s) => s.value > 0)) {
        // Last visible segment (right rounded)
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            rect,
            topRight: Radius.circular(radius),
            bottomRight: Radius.circular(radius),
          ),
          paint,
        );
      } else {
        // Middle segment (flat)
        canvas.drawRect(rect, paint);
      }

      currentX += width;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
