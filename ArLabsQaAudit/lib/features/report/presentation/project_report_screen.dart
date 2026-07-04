import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../project/data/project_repository.dart';
import '../../project/data/project_tree_provider.dart';
import '../../project/domain/project_model.dart';
import '../data/report_repository.dart';
import '../domain/report_models.dart';
import 'widgets/report_charts.dart';
import 'widgets/report_preview_dialog.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state.dart';

final reportModuleFilterProvider = StateProvider.family<String, String>((ref, id) => 'All');
final reportFeatureFilterProvider = StateProvider.family<String, String>((ref, id) => 'All');
final reportAuditStatusFilterProvider = StateProvider.family<String, String>((ref, id) => 'All');
final reportBugSeverityFilterProvider = StateProvider.family<String, String>((ref, id) => 'All');
final reportBugStatusFilterProvider = StateProvider.family<String, String>((ref, id) => 'All');
final reportPriorityFilterProvider = StateProvider.family<String, String>((ref, id) => 'All');
final reportDateRangeFilterProvider = StateProvider.family<DateTimeRange?, String>((ref, id) => null);
final reportSearchQueryProvider = StateProvider.family<String, String>((ref, id) => '');

class ProjectReportScreen extends ConsumerWidget {
  final String projectId;

  const ProjectReportScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final treeAsync = ref.watch(projectTreeProvider(projectId));
    final projectsAsync = ref.watch(projectListProvider);

    // Watch filters
    final moduleFilter = ref.watch(reportModuleFilterProvider(projectId));
    final featureFilter = ref.watch(reportFeatureFilterProvider(projectId));
    final auditStatusFilter = ref.watch(reportAuditStatusFilterProvider(projectId));
    final bugSeverityFilter = ref.watch(reportBugSeverityFilterProvider(projectId));
    final bugStatusFilter = ref.watch(reportBugStatusFilterProvider(projectId));
    final priorityFilter = ref.watch(reportPriorityFilterProvider(projectId));
    final dateRange = ref.watch(reportDateRangeFilterProvider(projectId));
    final searchQuery = ref.watch(reportSearchQueryProvider(projectId));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: treeAsync.when(
        data: (treeData) {
          // Compile stats with current filters
          final repo = ref.watch(reportRepositoryProvider);
          final stats = repo.compileReportData(
            treeData,
            moduleFilter: moduleFilter,
            featureFilter: featureFilter,
            auditStatusFilter: auditStatusFilter,
            bugSeverityFilter: bugSeverityFilter,
            bugStatusFilter: bugStatusFilter,
            priorityFilter: priorityFilter,
            dateRange: dateRange,
          );

          // Get projects list for switching dropdown
          final projectsList = projectsAsync.maybeWhen(
            data: (list) => list,
            orElse: () => <ProjectWithStats>[],
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Breadcrumbs & Export Trigger Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () => context.go('/reports'),
                      icon: const Icon(Icons.arrow_back_rounded, size: 16),
                      label: const Text('Back to Reports'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => ReportPreviewDialog(
                            tree: treeData,
                            stats: stats,
                          ),
                        );
                      },
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Ekspor Laporan'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Project Selector / Title Row
                Row(
                  children: [
                    Text(
                      'Laporan Proyek:',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w400,
                        color: isDark ? const Color(0xFF6B7A99) : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (projectsList.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: projectId,
                            dropdownColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                            onChanged: (val) {
                              if (val != null) {
                                context.go('/reports/$val');
                              }
                            },
                            items: projectsList.map((p) {
                              return DropdownMenuItem(
                                value: p.project.id,
                                child: Text(p.project.name),
                              );
                            }).toList(),
                          ),
                        ),
                      )
                    else
                      Text(
                        treeData.project.name,
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
                const SizedBox(height: 24),

                // Filter & Search Controls Panel
                _buildFilterControls(context, ref, treeData),
                const SizedBox(height: 24),

                // Project Metrics Summary row
                _buildMetricsGrid(context, isDark, stats),
                const SizedBox(height: 32),

                // Analytics Charts (Audit distribution, Bug status distribution, Severity)
                _buildAnalyticsSection(context, isDark, stats),
                const SizedBox(height: 48),

                // Details Lists (Module / Feature Progress & Functions Table)
                _buildHierarchyDetails(context, isDark, treeData, searchQuery),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Gagal Memuat Laporan Proyek',
          description: err.toString(),
        ),
      ),
    );
  }

  Widget _buildFilterControls(BuildContext context, WidgetRef ref, ProjectTreeData tree) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final moduleFilter = ref.watch(reportModuleFilterProvider(projectId));
    final featureFilter = ref.watch(reportFeatureFilterProvider(projectId));
    final auditStatusFilter = ref.watch(reportAuditStatusFilterProvider(projectId));
    final bugSeverityFilter = ref.watch(reportBugSeverityFilterProvider(projectId));
    final bugStatusFilter = ref.watch(reportBugStatusFilterProvider(projectId));
    final priorityFilter = ref.watch(reportPriorityFilterProvider(projectId));
    final dateRange = ref.watch(reportDateRangeFilterProvider(projectId));
    final searchQuery = ref.watch(reportSearchQueryProvider(projectId));

    // Get list of modules/features for dropdown
    final List<String> modulesList = ['All'];
    final List<String> featuresList = ['All'];

    for (final m in tree.modules) {
      modulesList.add(m.module.id);
      if (moduleFilter == 'All' || moduleFilter == m.module.id) {
        for (final f in m.features) {
          featuresList.add(f.feature.id);
        }
      }
    }

    String resolveModuleName(String id) {
      if (id == 'All') return 'Semua Modul';
      try {
        return tree.modules.firstWhere((m) => m.module.id == id).module.name;
      } catch (_) {
        return 'Modul';
      }
    }

    String resolveFeatureName(String id) {
      if (id == 'All') return 'Semua Fitur';
      try {
        for (final m in tree.modules) {
          for (final f in m.features) {
            if (f.feature.id == id) return f.feature.name;
          }
        }
      } catch (_) {}
      return 'Fitur';
    }

    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.2) : const Color(0xFFF8FAFC),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? const Color(0xFF334155).withValues(alpha: 0.4) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Row 1: Search & Date Range Picker
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    onChanged: (val) => ref.read(reportSearchQueryProvider(projectId).notifier).state = val,
                    controller: TextEditingController(text: searchQuery)..selection = TextSelection.fromPosition(TextPosition(offset: searchQuery.length)),
                    decoration: InputDecoration(
                      hintText: 'Cari modul, fitur, atau fungsi...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 18),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2025),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                      initialDateRange: dateRange,
                    );
                    if (picked != null) {
                      ref.read(reportDateRangeFilterProvider(projectId).notifier).state = picked;
                    }
                  },
                  icon: const Icon(Icons.date_range_rounded, size: 16),
                  label: Text(
                    dateRange == null
                        ? 'Filter Tanggal'
                        : '${dateRange.start.day}/${dateRange.start.month}/${dateRange.start.year} - ${dateRange.end.day}/${dateRange.end.month}/${dateRange.end.year}',
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                if (dateRange != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => ref.read(reportDateRangeFilterProvider(projectId).notifier).state = null,
                    icon: const Icon(Icons.clear_rounded, size: 16),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Row 2: Filtering Dropdowns
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                _buildFilterDropdown(
                  context: context,
                  label: 'Modul',
                  value: moduleFilter,
                  items: modulesList,
                  onChanged: (val) {
                    ref.read(reportModuleFilterProvider(projectId).notifier).state = val!;
                    ref.read(reportFeatureFilterProvider(projectId).notifier).state = 'All'; // reset feature
                  },
                  resolveLabel: resolveModuleName,
                ),
                _buildFilterDropdown(
                  context: context,
                  label: 'Fitur',
                  value: featureFilter,
                  items: featuresList,
                  onChanged: (val) => ref.read(reportFeatureFilterProvider(projectId).notifier).state = val!,
                  resolveLabel: resolveFeatureName,
                ),
                _buildFilterDropdown(
                  context: context,
                  label: 'Status Audit',
                  value: auditStatusFilter,
                  items: ['All', 'Not Tested', 'Passed', 'Failed', 'Warning', 'Not Implemented', 'Skipped'],
                  onChanged: (val) => ref.read(reportAuditStatusFilterProvider(projectId).notifier).state = val!,
                  resolveLabel: (id) => id == 'All' ? 'Semua Status Audit' : id,
                ),
                _buildFilterDropdown(
                  context: context,
                  label: 'Severity Bug',
                  value: bugSeverityFilter,
                  items: ['All', 'Critical', 'High', 'Medium', 'Low'],
                  onChanged: (val) => ref.read(reportBugSeverityFilterProvider(projectId).notifier).state = val!,
                  resolveLabel: (id) => id == 'All' ? 'Semua Severity' : id,
                ),
                _buildFilterDropdown(
                  context: context,
                  label: 'Status Bug',
                  value: bugStatusFilter,
                  items: ['All', 'Open', 'In Progress', 'Ready To Test', 'Resolved', 'Closed', 'Rejected'],
                  onChanged: (val) => ref.read(reportBugStatusFilterProvider(projectId).notifier).state = val!,
                  resolveLabel: (id) => id == 'All' ? 'Semua Status Bug' : id,
                ),
                _buildFilterDropdown(
                  context: context,
                  label: 'Prioritas',
                  value: priorityFilter,
                  items: ['All', 'P0', 'P1', 'P2', 'P3', 'None'],
                  onChanged: (val) => ref.read(reportPriorityFilterProvider(projectId).notifier).state = val!,
                  resolveLabel: (id) => id == 'All' ? 'Semua Prioritas' : id,
                ),
                if (moduleFilter != 'All' ||
                    featureFilter != 'All' ||
                    auditStatusFilter != 'All' ||
                    bugSeverityFilter != 'All' ||
                    bugStatusFilter != 'All' ||
                    priorityFilter != 'All' ||
                    dateRange != null ||
                    searchQuery.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      ref.read(reportModuleFilterProvider(projectId).notifier).state = 'All';
                      ref.read(reportFeatureFilterProvider(projectId).notifier).state = 'All';
                      ref.read(reportAuditStatusFilterProvider(projectId).notifier).state = 'All';
                      ref.read(reportBugSeverityFilterProvider(projectId).notifier).state = 'All';
                      ref.read(reportBugStatusFilterProvider(projectId).notifier).state = 'All';
                      ref.read(reportPriorityFilterProvider(projectId).notifier).state = 'All';
                      ref.read(reportDateRangeFilterProvider(projectId).notifier).state = null;
                      ref.read(reportSearchQueryProvider(projectId).notifier).state = '';
                    },
                    icon: const Icon(Icons.clear_rounded, size: 14, color: Colors.redAccent),
                    label: const Text('Reset Filter', style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdown({
    required BuildContext context,
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required String Function(String) resolveLabel,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: items.contains(value) ? value : 'All',
              isDense: true,
              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
              onChanged: onChanged,
              items: items.map((id) {
                return DropdownMenuItem(
                  value: id,
                  child: Text(resolveLabel(id)),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(BuildContext context, bool isDark, ProjectReportData stats) {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisExtent: 100,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      children: [
        _buildMetricCard(context, 'Modul', stats.totalModules.toString(), Icons.view_module_rounded, const Color(0xFFD97706), isDark),
        _buildMetricCard(context, 'Fitur', stats.totalFeatures.toString(), Icons.extension_rounded, AppTheme.statusPassed, isDark),
        _buildMetricCard(context, 'Fungsi', stats.totalFunctions.toString(), Icons.code_rounded, const Color(0xFF7C3AED), isDark),
        _buildMetricCard(context, 'Audits', stats.totalAudits.toString(), Icons.check_circle_rounded, const Color(0xFF0891B2), isDark),
        _buildMetricCard(context, 'Bugs', stats.totalBugs.toString(), Icons.bug_report_rounded, const Color(0xFFEF4444), isDark),
        _buildProgressCard(context, 'Progress Proyek', stats.progress, isDark),
      ],
    );
  }

  Widget _buildMetricCard(BuildContext context, String label, String value, IconData icon, Color color, bool isDark) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF0D0F16) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: isDark ? const Color(0xFF1C2033) : const Color(0xFFE3E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(fontSize: 10, color: isDark ? const Color(0xFF6B7A99) : const Color(0xFF6B7280)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(BuildContext context, String label, double progress, bool isDark) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF0D0F16) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: isDark ? const Color(0xFF1C2033) : const Color(0xFFE3E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                value: progress / 100,
                strokeWidth: 4,
                backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                color: AppTheme.statusPassed,
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${progress.toStringAsFixed(1)}%',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.statusPassed),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(fontSize: 10, color: isDark ? const Color(0xFF6B7A99) : const Color(0xFF6B7280)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsSection(BuildContext context, bool isDark, ProjectReportData stats) {
    // Prepare segments
    final List<ChartSegment> auditSegments = [
      ChartSegment('Lulus', stats.auditPassed, AppTheme.statusPassed),
      ChartSegment('Gagal', stats.auditFailed, AppTheme.statusFailed),
      ChartSegment('Peringatan', stats.auditWarning, AppTheme.statusWarning),
      ChartSegment('Dilewati', stats.auditSkipped, AppTheme.statusSkipped),
      ChartSegment('Belum Diimplementasi', stats.auditNotImplemented, AppTheme.statusNotImplemented),
      ChartSegment('Belum Diuji', stats.auditNotTested, AppTheme.statusNotTested),
    ];

    final List<ChartSegment> severitySegments = [
      ChartSegment('Kritis', stats.bugCritical, AppTheme.severityCritical),
      ChartSegment('Tinggi', stats.bugHigh, AppTheme.severityHigh),
      ChartSegment('Sedang', stats.bugMedium, AppTheme.severityMedium),
      ChartSegment('Rendah', stats.bugLow, AppTheme.severityLow),
    ];

    final List<ChartSegment> bugStatusSegments = [
      ChartSegment('Terbuka', stats.bugOpen, AppTheme.primaryColor),
      ChartSegment('Dikerjakan', stats.bugInProgress, const Color(0xFF7C3AED)),
      ChartSegment('Siap Uji', stats.bugReadyToTest, AppTheme.statusWarning),
      ChartSegment('Selesai', stats.bugResolved, AppTheme.statusPassed),
      ChartSegment('Ditutup', stats.bugClosed, const Color(0xFF475569)),
      ChartSegment('Ditolak', stats.bugRejected, AppTheme.statusFailed),
    ];

    return Wrap(
      spacing: 24,
      runSpacing: 24,
      children: [
        _buildChartCard(context, 'Distribusi Status Audit', auditSegments, isDark),
        _buildChartCard(context, 'Tingkat Keparahan Bug', severitySegments, isDark),
        _buildChartCard(context, 'Status Distribusi Bug', bugStatusSegments, isDark),
      ],
    );
  }

  Widget _buildChartCard(BuildContext context, String title, List<ChartSegment> segments, bool isDark) {
    final theme = Theme.of(context);
    final total = segments.map((s) => s.value).fold(0, (a, b) => a + b);

    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF0D0F16) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isDark ? const Color(0xFF1C2033) : const Color(0xFFE3E8F0)),
      ),
      child: Container(
        width: 340,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Row(
              children: [
                ReportDonutChart(segments: segments),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: segments.map((seg) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: seg.color),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                total > 0 ? '${seg.label} (${(seg.value / total * 100).toStringAsFixed(0)}%)' : seg.label,
                                style: const TextStyle(fontSize: 10, overflow: TextOverflow.ellipsis),
                              ),
                            ),
                            Text(
                              '${seg.value}',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHierarchyDetails(BuildContext context, bool isDark, ProjectTreeData tree, String query) {
    final theme = Theme.of(context);
    final term = query.toLowerCase();

    // Compile filtered modules list to show structure
    final List<Widget> children = [];

    for (final modNode in tree.modules) {
      final List<Widget> featureWidgets = [];

      for (final featNode in modNode.features) {
        final List<DataRow> rows = [];

        for (final func in featNode.functions) {
          // Search match
          if (query.isNotEmpty) {
            final matches = modNode.module.name.toLowerCase().contains(term) ||
                featNode.feature.name.toLowerCase().contains(term) ||
                func.name.toLowerCase().contains(term);
            if (!matches) continue;
          }

          final audit = func.activeAudit;
          final status = audit?.status ?? 'Not Tested';
          final bugCount = audit?.bugs.length ?? 0;
          final lastAuditedAt = audit?.lastAuditedAt;

          rows.add(
            DataRow(
              cells: [
                DataCell(Text(func.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: _getStatusColor(status).withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      _getStatusLabel(status),
                      style: TextStyle(color: _getStatusColor(status), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                DataCell(Text(audit?.priority ?? 'None', style: const TextStyle(fontSize: 12))),
                DataCell(Text(
                  lastAuditedAt != null
                      ? '${lastAuditedAt.day}/${lastAuditedAt.month}/${lastAuditedAt.year}'
                      : '-',
                  style: const TextStyle(fontSize: 12),
                )),
                DataCell(
                  Row(
                    children: [
                      if (bugCount > 0) ...[
                        const Icon(Icons.bug_report_rounded, size: 14, color: Color(0xFFEF4444)),
                        const SizedBox(width: 4),
                        Text('$bugCount Bugs', style: const TextStyle(fontSize: 11, color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
                      ] else
                        const Text('-', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        if (rows.isNotEmpty) {
          featureWidgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: ExpansionTile(
                initiallyExpanded: true,
                title: Text(
                  'Fitur: ${featNode.feature.name}',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 32,
                      columns: const [
                        DataColumn(label: Text('Nama Fungsi', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Status Audit', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Prioritas', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Audit Terakhir', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Bug Terlapor', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: rows,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }

      if (featureWidgets.isNotEmpty) {
        children.add(
          Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 32),
            color: isDark ? const Color(0xFF0D0F16) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: isDark ? const Color(0xFF1C2033) : const Color(0xFFE3E8F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Modul: ${modNode.module.name}',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                  ),
                  const SizedBox(height: 16),
                  ...featureWidgets,
                ],
              ),
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detail Progres Struktur Proyek',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (children.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 48.0),
              child: Text(
                'Tidak ada data fungsi atau modul yang sesuai dengan pencarian.',
                style: TextStyle(color: isDark ? Colors.grey : Colors.black54),
              ),
            ),
          )
        else
          ...children,
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Passed': return AppTheme.statusPassed;
      case 'Failed': return AppTheme.statusFailed;
      case 'Warning': return AppTheme.statusWarning;
      case 'Skipped': return AppTheme.statusSkipped;
      case 'Not Implemented': return AppTheme.statusNotImplemented;
      default: return AppTheme.statusNotTested;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'Passed': return 'Lulus';
      case 'Failed': return 'Gagal';
      case 'Warning': return 'Peringatan';
      case 'Skipped': return 'Dilewati';
      case 'Not Implemented': return 'Belum Diimplementasi';
      default: return 'Belum Diuji';
    }
  }
}
