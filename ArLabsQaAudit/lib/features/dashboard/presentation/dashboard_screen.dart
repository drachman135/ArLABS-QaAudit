import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../project/domain/project_model.dart';
import '../../project/data/project_repository.dart';
import '../../project/presentation/widgets/project_dialogs.dart';
import '../../audit/data/audit_repository.dart';
import '../../bug/domain/bug_model.dart';
import '../../bug/data/bug_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../activity/data/activity_repository.dart';
import '../../activity/domain/activity_model.dart';
import '../../activity/presentation/widgets/activity_timeline_widget.dart';
import '../../activity/presentation/widgets/activity_filter_bar.dart';

final recentAuditsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(auditRepositoryProvider);
  return repository.getRecentAudits();
});

final recentActivitiesProvider = FutureProvider<List<Activity>>((ref) async {
  final repository = ref.watch(activityRepositoryProvider);
  return repository.getActivities();
});

final dashboardActivityFiltersProvider = StateProvider<Map<String, dynamic>>((ref) => {});

final dashboardSearchQueryProvider = StateProvider<String>((ref) => '');

// ─── Status helpers ───────────────────────────────────────────────────────────
String _statusLabel(String s) {
  switch (s) {
    case 'Passed': return 'Lulus';
    case 'Failed': return 'Gagal';
    case 'Warning': return 'Peringatan';
    case 'Skipped': return 'Dilewati';
    case 'Not Implemented': return 'Belum Diimplementasi';
    default: return 'Belum Diuji';
  }
}

Color _statusColor(String s) {
  switch (s) {
    case 'Passed': return AppTheme.statusPassed;
    case 'Failed': return AppTheme.statusFailed;
    case 'Warning': return AppTheme.statusWarning;
    case 'Skipped': return AppTheme.statusSkipped;
    case 'Not Implemented': return AppTheme.statusNotImplemented;
    default: return AppTheme.statusNotTested;
  }
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final projectsAsync = ref.watch(projectListProvider);
    final bugsAsync = ref.watch(bugsListProvider);
    final searchQuery = ref.watch(dashboardSearchQueryProvider);
    final activitiesAsync = ref.watch(recentActivitiesProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Command Bar / Header ──────────────────────────────────────────
            _CommandBar(
              isDark: isDark,
              theme: theme,
              ref: ref,
              searchQuery: searchQuery,
            ),

            // ── Search Results ────────────────────────────────────────────────
            if (searchQuery.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
                child: projectsAsync.when(
                  data: (projects) => bugsAsync.when(
                    data: (bugs) => activitiesAsync.when(
                      data: (activities) => _buildSearchResults(context, searchQuery, projects, bugs, activities),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => const SizedBox.shrink(),
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => const SizedBox.shrink(),
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => const SizedBox.shrink(),
                ),
              )
            else ...[
              // ── Metric Strip ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 0),
                child: projectsAsync.when(
                  data: (projects) => bugsAsync.when(
                    data: (bugs) => _buildMetricStrip(context, isDark, projects, bugs),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 32),

              // ── Main Content ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 48),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 960;
                    return isWide
                        ? _buildWideLayout(context, ref, isDark, theme)
                        : _buildNarrowLayout(context, ref, isDark, theme);
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Metric Strip
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildMetricStrip(
    BuildContext context,
    bool isDark,
    List<ProjectWithStats> projects,
    List<Bug> bugs,
  ) {
    final totalProjects = projects.length;
    int totalFunctions = 0, auditedFunctions = 0, failedCount = 0, warningCount = 0;
    for (final p in projects) {
      totalFunctions += p.stats.totalCount;
      auditedFunctions += p.stats.auditedCount;
      failedCount += p.stats.failedCount;
      warningCount += p.stats.warningCount;
    }
    final progress = totalFunctions > 0 ? (auditedFunctions / totalFunctions * 100) : 0.0;

    final totalBugs = bugs.length;
    final openBugs = bugs.where((b) => b.status == 'Open').length;
    final criticalBugs = bugs.where((b) => b.severity == 'Critical').length;

    final metrics = [
      _Metric('Total Proyek',      totalProjects.toString(),                  Icons.folder_rounded,            AppTheme.primaryColor),
      _Metric('Total Fungsi',      totalFunctions.toString(),                 Icons.functions_rounded,          const Color(0xFF7C3AED)),
      _Metric('Sudah Diaudit',     auditedFunctions.toString(),               Icons.check_circle_rounded,       AppTheme.statusPassed),
      _Metric('Progres',           '${progress.toStringAsFixed(1)}%',         Icons.analytics_rounded,          const Color(0xFF0891B2)),
      _Metric('Gagal',             failedCount.toString(),                    Icons.cancel_rounded,             AppTheme.statusFailed),
      _Metric('Peringatan',        warningCount.toString(),                   Icons.warning_rounded,            AppTheme.statusWarning),
      _Metric('Total Bug',         totalBugs.toString(),                      Icons.bug_report_rounded,         const Color(0xFFEA580C)),
      _Metric('Bug Terbuka',       openBugs.toString(),                       Icons.radio_button_unchecked,     AppTheme.primaryColor),
      _Metric('Bug Kritis',        criticalBugs.toString(),                   Icons.priority_high_rounded,      AppTheme.statusFailed),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: metrics.map((m) => _MetricChip(m: m, isDark: isDark)).toList(),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Wide layout (two columns)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildWideLayout(BuildContext context, WidgetRef ref, bool isDark, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left — 60%
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(title: 'Proyek Aktif', action: 'Lihat Semua', onAction: () => context.go('/projects')),
              const SizedBox(height: 12),
              _buildProjectList(context, ref, isDark, theme),
              const SizedBox(height: 40),
              _SectionHeader(title: 'Aktivitas Terkini', action: null, onAction: null),
              const SizedBox(height: 12),
              _buildRecentActivityList(context, ref, isDark, theme),
            ],
          ),
        ),
        const SizedBox(width: 32),
        // Right — 40%
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(title: 'Distribusi Bug', action: 'Lihat Bug', onAction: () => context.go('/bugs')),
              const SizedBox(height: 12),
              _buildBugCharts(context, ref, isDark, theme),
              const SizedBox(height: 40),
              _SectionHeader(title: 'Aksi Cepat', action: null, onAction: null),
              const SizedBox(height: 12),
              _buildQuickActions(context, ref),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(BuildContext context, WidgetRef ref, bool isDark, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Proyek Aktif', action: 'Lihat Semua', onAction: () => context.go('/projects')),
        const SizedBox(height: 12),
        _buildProjectList(context, ref, isDark, theme),
        const SizedBox(height: 40),
        _SectionHeader(title: 'Distribusi Bug', action: 'Lihat Bug', onAction: () => context.go('/bugs')),
        const SizedBox(height: 12),
        _buildBugCharts(context, ref, isDark, theme),
        const SizedBox(height: 40),
        _SectionHeader(title: 'Aktivitas Terkini', action: null, onAction: null),
        const SizedBox(height: 12),
        _buildRecentActivityList(context, ref, isDark, theme),
        const SizedBox(height: 40),
        _buildQuickActions(context, ref),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Project list
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildProjectList(BuildContext context, WidgetRef ref, bool isDark, ThemeData theme) {
    final projectsAsync = ref.watch(projectListProvider);
    return projectsAsync.when(
      data: (projects) {
        final active = projects.where((p) => p.project.status == 'Active').take(4).toList();
        if (active.isEmpty) {
          return _EmptyBox(
            icon: Icons.folder_open_outlined,
            label: 'Belum ada proyek.',
            action: 'Buat Proyek',
            onAction: () => ProjectDialogs.showCreateProject(context, ref),
            isDark: isDark,
          );
        }
        return Column(
          children: active
              .map((p) => _ProjectRow(p: p, isDark: isDark, theme: theme))
              .toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Bug charts
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildBugCharts(BuildContext context, WidgetRef ref, bool isDark, ThemeData theme) {
    final bugsAsync = ref.watch(bugsListProvider);
    return bugsAsync.when(
      data: (bugs) {
        if (bugs.isEmpty) {
          return _EmptyBox(
            icon: Icons.bug_report_outlined,
            label: 'Belum ada bug yang dilaporkan.',
            action: null,
            onAction: null,
            isDark: isDark,
          );
        }
        final critical    = bugs.where((b) => b.severity == 'Critical').length;
        final high        = bugs.where((b) => b.severity == 'High').length;
        final medium      = bugs.where((b) => b.severity == 'Medium').length;
        final low         = bugs.where((b) => b.severity == 'Low').length;
        final open        = bugs.where((b) => b.status == 'Open').length;
        final inProgress  = bugs.where((b) => b.status == 'In Progress').length;
        final rtt         = bugs.where((b) => b.status == 'Ready To Test').length;
        final resolved    = bugs.where((b) => b.status == 'Resolved').length;
        final closed      = bugs.where((b) => b.status == 'Closed').length;
        final rejected    = bugs.where((b) => b.status == 'Rejected').length;

        return Column(
          children: [
            _ChartPanel(
              title: 'Berdasarkan Tingkat Keparahan',
              isDark: isDark,
              theme: theme,
              segments: [
                _ChartSegment('Kritis',  critical, AppTheme.severityCritical),
                _ChartSegment('Tinggi',  high,     AppTheme.severityHigh),
                _ChartSegment('Sedang',  medium,   AppTheme.severityMedium),
                _ChartSegment('Rendah',  low,      AppTheme.severityLow),
              ],
            ),
            const SizedBox(height: 16),
            _ChartPanel(
              title: 'Berdasarkan Status',
              isDark: isDark,
              theme: theme,
              segments: [
                _ChartSegment('Terbuka',     open,       AppTheme.primaryColor),
                _ChartSegment('Dikerjakan',  inProgress, const Color(0xFF7C3AED)),
                _ChartSegment('Siap Uji',    rtt,        AppTheme.statusWarning),
                _ChartSegment('Selesai',     resolved,   AppTheme.statusPassed),
                _ChartSegment('Ditutup',     closed,     const Color(0xFF475569)),
                _ChartSegment('Ditolak',     rejected,   AppTheme.statusFailed),
              ],
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Recent Activity
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildRecentActivityList(BuildContext context, WidgetRef ref, bool isDark, ThemeData theme) {
    final filters = ref.watch(dashboardActivityFiltersProvider);
    final activityAsync = ref.watch(globalActivitiesProvider(filters));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ActivityFilterBar(
          onChanged: ({entityType, action, dateRange}) {
            ref.read(dashboardActivityFiltersProvider.notifier).state = {
              'projectId': 'All',
              'entityType': entityType,
              'action': action,
              'startDate': dateRange?.start,
              'endDate': dateRange?.end,
            };
          },
        ),
        const SizedBox(height: 12),
        activityAsync.when(
          data: (activities) {
            if (activities.isEmpty) {
              return _EmptyBox(
                icon: Icons.history_rounded,
                label: 'Belum ada aktivitas tercatat yang sesuai filter.',
                action: null,
                onAction: null,
                isDark: isDark,
              );
            }
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0D0F16) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? const Color(0xFF1C2033) : const Color(0xFFE3E8F0),
                ),
              ),
              child: ActivityTimelineWidget(
                activities: activities.take(8).toList(),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Quick Actions
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildQuickActions(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => ProjectDialogs.showCreateProject(context, ref),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Buat Proyek Baru'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.push('/bugs/new'),
            icon: const Icon(Icons.bug_report_rounded, size: 18),
            label: const Text('Laporkan Bug Baru'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Search Results
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildSearchResults(
    BuildContext context,
    String query,
    List<ProjectWithStats> projects,
    List<Bug> bugs,
    List<Activity> activities,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final term = query.toLowerCase();

    final List<Map<String, dynamic>> projectMatches = [];
    final List<Map<String, dynamic>> moduleMatches = [];
    final List<Map<String, dynamic>> featureMatches = [];
    final List<Map<String, dynamic>> functionMatches = [];
    final List<Activity> activityMatches = [];

    for (final p in projects) {
      if (p.project.name.toLowerCase().contains(term) ||
          (p.project.description?.toLowerCase().contains(term) ?? false)) {
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
            if (funcName.toLowerCase().contains(term) ||
                (fn['description']?.toLowerCase().contains(term) ?? false)) {
              functionMatches.add({'name': '$funcName ($featName)', 'projectId': p.project.id});
            }
          }
        }
      }
    }

    final bugMatches = bugs
        .where((b) =>
            b.title.toLowerCase().contains(term) ||
            b.description.toLowerCase().contains(term))
        .toList();

    for (final act in activities) {
      if (act.description.toLowerCase().contains(term) ||
          act.entityName.toLowerCase().contains(term) ||
          act.action.toLowerCase().contains(term)) {
        activityMatches.add(act);
      }
    }

    final total = projectMatches.length + moduleMatches.length +
        featureMatches.length + functionMatches.length + bugMatches.length + activityMatches.length;

    final borderColor = isDark ? const Color(0xFF1C2033) : const Color(0xFFE3E8F0);
    final bgColor = isDark ? const Color(0xFF0D0F16) : Colors.white;

    if (total == 0) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: Center(
          child: Text(
            'Tidak ada hasil untuk "$query".',
            style: TextStyle(color: isDark ? const Color(0xFF6B7A99) : const Color(0xFF6B7280)),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Text(
              '$total hasil ditemukan',
              style: theme.textTheme.titleSmall?.copyWith(
                color: isDark ? const Color(0xFF6B7A99) : const Color(0xFF6B7280),
              ),
            ),
          ),
          const Divider(height: 1),
          if (bugMatches.isNotEmpty) ...[
            _SearchCategory(label: 'BUG', isDark: isDark),
            ...bugMatches.map((b) => _SearchRow(
                  icon: Icons.bug_report_rounded,
                  color: AppTheme.statusFailed,
                  label: b.title,
                  subtitle: b.description,
                  isDark: isDark,
                  onTap: () => context.push('/bugs/${b.id}'),
                )),
          ],
          if (projectMatches.isNotEmpty) ...[
            _SearchCategory(label: 'PROYEK', isDark: isDark),
            ...projectMatches.map((p) => _SearchRow(
                  icon: Icons.folder_rounded,
                  color: AppTheme.primaryColor,
                  label: p['name'],
                  subtitle: null,
                  isDark: isDark,
                  onTap: () => context.go('/projects/${p['id']}'),
                )),
          ],
          if (moduleMatches.isNotEmpty) ...[
            _SearchCategory(label: 'MODUL', isDark: isDark),
            ...moduleMatches.map((m) => _SearchRow(
                  icon: Icons.view_module_outlined,
                  color: const Color(0xFFD97706),
                  label: m['name'],
                  subtitle: null,
                  isDark: isDark,
                  onTap: () => context.go('/projects/${m['projectId']}'),
                )),
          ],
          if (featureMatches.isNotEmpty) ...[
            _SearchCategory(label: 'FITUR', isDark: isDark),
            ...featureMatches.map((f) => _SearchRow(
                  icon: Icons.extension_outlined,
                  color: AppTheme.statusPassed,
                  label: f['name'],
                  subtitle: null,
                  isDark: isDark,
                  onTap: () => context.go('/projects/${f['projectId']}'),
                )),
          ],
          if (functionMatches.isNotEmpty) ...[
            _SearchCategory(label: 'FUNGSI', isDark: isDark),
            ...functionMatches.map((fn) => _SearchRow(
                  icon: Icons.code_rounded,
                  color: const Color(0xFF7C3AED),
                  label: fn['name'],
                  subtitle: null,
                  isDark: isDark,
                  onTap: () => context.go('/projects/${fn['projectId']}'),
                )),
          ],
          if (activityMatches.isNotEmpty) ...[
            _SearchCategory(label: 'AKTIVITAS', isDark: isDark),
            ...activityMatches.map((act) => _SearchRow(
                  icon: Icons.history_rounded,
                  color: const Color(0xFF0EA5E9),
                  label: act.description,
                  subtitle: '${act.entityType} • ${act.entityName}',
                  isDark: isDark,
                  onTap: () => context.go('/projects/${act.projectId}'),
                )),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _CommandBar extends StatelessWidget {
  final bool isDark;
  final ThemeData theme;
  final WidgetRef ref;
  final String searchQuery;

  const _CommandBar({
    required this.isDark,
    required this.theme,
    required this.ref,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 700;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 32,
        vertical: isMobile ? 20 : 28,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0C14) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF141826) : const Color(0xFFE3E8F0),
          ),
        ),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pantau kualitas, lacak bug, dan percepat pengujian Anda.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? const Color(0xFF6B7A99) : const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 16),
                // Search bar & New project button in a row
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (val) =>
                            ref.read(dashboardSearchQueryProvider.notifier).state = val,
                        decoration: InputDecoration(
                          hintText: 'Cari proyek, fungsi, atau bug...',
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: isDark ? const Color(0xFF4A5A70) : const Color(0xFFAAB3C5),
                            size: 18,
                          ),
                          suffixIcon: searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 16),
                                  onPressed: () =>
                                      ref.read(dashboardSearchQueryProvider.notifier).state = '',
                                )
                              : null,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Consumer(
                      builder: (context, ref, _) => ElevatedButton(
                        onPressed: () => ProjectDialogs.showCreateProject(context, ref),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          minimumSize: Size.zero,
                        ),
                        child: const Icon(Icons.add_rounded, size: 20),
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Title group
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selamat Datang, Auditor',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.6,
                          color: isDark ? Colors.white : const Color(0xFF0D1117),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pantau kualitas, lacak bug, dan percepat pengujian Anda.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark ? const Color(0xFF6B7A99) : const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // Search bar
                SizedBox(
                  width: 320,
                  child: TextField(
                    onChanged: (val) =>
                        ref.read(dashboardSearchQueryProvider.notifier).state = val,
                    decoration: InputDecoration(
                      hintText: 'Cari proyek, fungsi, atau bug...',
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: isDark ? const Color(0xFF4A5A70) : const Color(0xFFAAB3C5),
                        size: 18,
                      ),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, size: 16),
                              onPressed: () =>
                                  ref.read(dashboardSearchQueryProvider.notifier).state = '',
                            )
                          : null,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // New project button
                Consumer(
                  builder: (context, ref, _) => ElevatedButton.icon(
                    onPressed: () => ProjectDialogs.showCreateProject(context, ref),
                    icon: const Icon(Icons.add_rounded, size: 17),
                    label: const Text('Proyek Baru'),
                  ),
                ),
              ],
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const _SectionHeader({
    required this.title,
    required this.action,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: isDark ? Colors.white : const Color(0xFF0D1117),
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              action!,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }
}

class _Metric {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _Metric(this.label, this.value, this.icon, this.color);
}

class _MetricChip extends StatelessWidget {
  final _Metric m;
  final bool isDark;

  const _MetricChip({required this.m, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10, bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D0F16) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF1C2033) : const Color(0xFFE3E8F0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: m.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(m.icon, color: m.color, size: 14),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                m.value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: isDark ? Colors.white : const Color(0xFF0D1117),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                m.label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFF6B7A99) : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProjectRow extends StatefulWidget {
  final ProjectWithStats p;
  final bool isDark;
  final ThemeData theme;

  const _ProjectRow({required this.p, required this.isDark, required this.theme});

  @override
  State<_ProjectRow> createState() => _ProjectRowState();
}

class _ProjectRowState extends State<_ProjectRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final project = widget.p.project;
    final stats = widget.p.stats;
    final color = ProjectDialogs.getColor(project.color);
    final icon = ProjectDialogs.getIconData(project.icon);
    final progress = stats.progressPercentage / 100;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go('/projects/${project.id}'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _hovered
                ? (widget.isDark ? const Color(0xFF111520) : const Color(0xFFF5F8FF))
                : (widget.isDark ? const Color(0xFF0D0F16) : Colors.white),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hovered
                  ? (widget.isDark ? const Color(0xFF2A3350) : AppTheme.primaryColor.withValues(alpha: 0.25))
                  : (widget.isDark ? const Color(0xFF1C2033) : const Color(0xFFE3E8F0)),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 17),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        color: widget.isDark ? Colors.white : const Color(0xFF0D1117),
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 3,
                        backgroundColor: widget.isDark
                            ? const Color(0xFF1C2033)
                            : const Color(0xFFE3E8F0),
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${stats.progressPercentage.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  if (stats.bugCount > 0)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bug_report_rounded,
                            size: 11, color: AppTheme.statusFailed),
                        const SizedBox(width: 3),
                        Text(
                          '${stats.bugCount}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.statusFailed,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: widget.isDark
                    ? const Color(0xFF3A4255)
                    : const Color(0xFFCBD5E1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChartPanel extends StatelessWidget {
  final String title;
  final bool isDark;
  final ThemeData theme;
  final List<_ChartSegment> segments;

  const _ChartPanel({
    required this.title,
    required this.isDark,
    required this.theme,
    required this.segments,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D0F16) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF1C2033) : const Color(0xFFE3E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF6B7A99) : const Color(0xFF6B7280),
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 6,
            child: CustomPaint(painter: _StackedBarPainter(segments)),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: segments.where((s) => s.value > 0).map((seg) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(color: seg.color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${seg.label} (${seg.value})',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? action;
  final VoidCallback? onAction;
  final bool isDark;

  const _EmptyBox({
    required this.icon,
    required this.label,
    required this.action,
    required this.onAction,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D0F16) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF1C2033) : const Color(0xFFE3E8F0),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 32,
              color: isDark ? const Color(0xFF3A4255) : const Color(0xFFCBD5E1)),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFF6B7A99) : const Color(0xFF6B7280),
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: 14),
            TextButton(onPressed: onAction, child: Text(action!)),
          ],
        ],
      ),
    );
  }
}

class _SearchCategory extends StatelessWidget {
  final String label;
  final bool isDark;

  const _SearchCategory({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: isDark ? const Color(0xFF3A4255) : const Color(0xFFAAB3C5),
        ),
      ),
    );
  }
}

class _SearchRow extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String? subtitle;
  final bool isDark;
  final VoidCallback onTap;

  const _SearchRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.subtitle,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_SearchRow> createState() => _SearchRowState();
}

class _SearchRowState extends State<_SearchRow> {
  bool _h = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          color: _h
              ? (widget.isDark
                  ? const Color(0xFF111826)
                  : const Color(0xFFF5F8FF))
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              Icon(widget.icon, size: 14, color: widget.color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: widget.isDark ? Colors.white : const Color(0xFF0D1117),
                      ),
                    ),
                    if (widget.subtitle != null)
                      Text(
                        widget.subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: widget.isDark
                              ? const Color(0xFF6B7A99)
                              : const Color(0xFF6B7280),
                        ),
                      ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded, size: 13,
                  color: widget.isDark
                      ? const Color(0xFF3A4255)
                      : const Color(0xFFCBD5E1)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chart helpers
// ─────────────────────────────────────────────────────────────────────────────
class _ChartSegment {
  final String label;
  final int value;
  final Color color;
  const _ChartSegment(this.label, this.value, this.color);
}

class _StackedBarPainter extends CustomPainter {
  final List<_ChartSegment> segments;
  _StackedBarPainter(this.segments);

  @override
  void paint(Canvas canvas, Size size) {
    final int total = segments.fold(0, (s, e) => s + e.value);
    if (total == 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(3)),
        Paint()..color = const Color(0xFF1C2033),
      );
      return;
    }
    double x = 0;
    const r = 3.0;
    for (int i = 0; i < segments.length; i++) {
      final seg = segments[i];
      if (seg.value == 0) continue;
      final w = (seg.value / total) * size.width;
      final paint = Paint()..color = seg.color;
      final isFirst = i == segments.indexWhere((s) => s.value > 0);
      final isLast = i == segments.lastIndexWhere((s) => s.value > 0);
      final rect = Rect.fromLTWH(x, 0, w, size.height);
      if (isFirst && isLast) {
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(r)), paint);
      } else if (isFirst) {
        canvas.drawRRect(RRect.fromRectAndCorners(rect,
            topLeft: const Radius.circular(r), bottomLeft: const Radius.circular(r)), paint);
      } else if (isLast) {
        canvas.drawRRect(RRect.fromRectAndCorners(rect,
            topRight: const Radius.circular(r), bottomRight: const Radius.circular(r)), paint);
      } else {
        canvas.drawRect(rect, paint);
      }
      x += w;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
