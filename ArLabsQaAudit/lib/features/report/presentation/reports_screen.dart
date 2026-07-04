import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/report_repository.dart';
import '../domain/report_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String _searchQuery = '';
  String _sortOption = 'Name'; // Name, Progress (Desc), Progress (Asc), Bugs (Desc)

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final globalStatsAsync = ref.watch(globalReportDataProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Reports & Analytics Dashboard',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ringkasan data proyek, progres audit, dan status bug secara realtime.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 32),

            globalStatsAsync.when(
              data: (List<ProjectReportData> dataList) {
                if (dataList.isEmpty) {
                  return EmptyState(
                    icon: Icons.analytics_outlined,
                    title: 'Belum Ada Data Laporan',
                    description: 'Silakan buat proyek dan lakukan audit fungsi terlebih dahulu.',
                  );
                }

                // Compute overall totals
                int totalProjects = dataList.length;
                int totalModules = 0;
                int totalFeatures = 0;
                int totalFunctions = 0;
                int totalAudits = 0;
                int totalBugs = 0;
                int totalAuditedFunctions = 0;

                for (final d in dataList) {
                  totalModules += d.totalModules;
                  totalFeatures += d.totalFeatures;
                  totalFunctions += d.totalFunctions;
                  totalAudits += d.totalAudits;
                  totalBugs += d.totalBugs;
                  totalAuditedFunctions += (d.totalFunctions - d.auditNotTested);
                }

                final double overallProgress = totalFunctions > 0
                    ? (totalAuditedFunctions / totalFunctions * 100)
                    : 0.0;

                // Apply search
                var filteredList = dataList.where((d) =>
                    d.projectName.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

                // Apply sorting
                if (_sortOption == 'Name') {
                  filteredList.sort((a, b) => a.projectName.toLowerCase().compareTo(b.projectName.toLowerCase()));
                } else if (_sortOption == 'Progress (Desc)') {
                  filteredList.sort((a, b) => b.progress.compareTo(a.progress));
                } else if (_sortOption == 'Progress (Asc)') {
                  filteredList.sort((a, b) => a.progress.compareTo(b.progress));
                } else if (_sortOption == 'Bugs (Desc)') {
                  filteredList.sort((a, b) => b.totalBugs.compareTo(a.totalBugs));
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Cards Grid
                    _buildSummaryGrid(
                      context: context,
                      isDark: isDark,
                      totalProjects: totalProjects,
                      totalModules: totalModules,
                      totalFeatures: totalFeatures,
                      totalFunctions: totalFunctions,
                      totalAudits: totalAudits,
                      totalBugs: totalBugs,
                      overallProgress: overallProgress,
                    ),
                    const SizedBox(height: 48),

                    // Title Project Listing
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Laporan Per Proyek',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        _buildControls(context),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Projects List Cards
                    if (filteredList.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 48.0),
                          child: Text(
                            'Tidak ada proyek yang sesuai dengan pencarian Anda.',
                            style: TextStyle(color: isDark ? Colors.grey : Colors.black54),
                          ),
                        ),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 450,
                          mainAxisExtent: 220,
                          crossAxisSpacing: 24,
                          mainAxisSpacing: 24,
                        ),
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          return _buildProjectReportCard(context, filteredList[index], isDark);
                        },
                      ),
                  ],
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 100.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => EmptyState(
                icon: Icons.error_outline_rounded,
                title: 'Gagal Memuat Laporan',
                description: err.toString(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryGrid({
    required BuildContext context,
    required bool isDark,
    required int totalProjects,
    required int totalModules,
    required int totalFeatures,
    required int totalFunctions,
    required int totalAudits,
    required int totalBugs,
    required double overallProgress,
  }) {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 260,
        mainAxisExtent: 110,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      children: [
        _buildMetricCard(context, 'Total Proyek', totalProjects.toString(), Icons.folder_rounded, AppTheme.primaryColor, isDark),
        _buildMetricCard(context, 'Total Modul', totalModules.toString(), Icons.view_module_rounded, const Color(0xFFD97706), isDark),
        _buildMetricCard(context, 'Total Fitur', totalFeatures.toString(), Icons.extension_rounded, AppTheme.statusPassed, isDark),
        _buildMetricCard(context, 'Total Fungsi', totalFunctions.toString(), Icons.code_rounded, const Color(0xFF7C3AED), isDark),
        _buildMetricCard(context, 'Total Audit', totalAudits.toString(), Icons.check_circle_rounded, const Color(0xFF0891B2), isDark),
        _buildMetricCard(context, 'Total Bug', totalBugs.toString(), Icons.bug_report_rounded, const Color(0xFFEF4444), isDark),
        _buildProgressCard(context, 'Overall Progress', overallProgress, isDark),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF0D0F16) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isDark ? const Color(0xFF1C2033) : const Color(0xFFE3E8F0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? const Color(0xFF6B7A99) : const Color(0xFF6B7280),
                  ),
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
        side: BorderSide(
          color: isDark ? const Color(0xFF1C2033) : const Color(0xFFE3E8F0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                value: progress / 100,
                strokeWidth: 5,
                backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                color: AppTheme.statusPassed,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${progress.toStringAsFixed(1)}%',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.statusPassed,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? const Color(0xFF6B7A99) : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        // Search
        SizedBox(
          width: 240,
          height: 36,
          child: TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Cari nama proyek...',
              prefixIcon: const Icon(Icons.search_rounded, size: 16),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Sort Dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _sortOption,
              isDense: true,
              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _sortOption = val);
                }
              },
              items: const [
                DropdownMenuItem(value: 'Name', child: Text('Urutkan: Nama')),
                DropdownMenuItem(value: 'Progress (Desc)', child: Text('Progress: Tinggi - Rendah')),
                DropdownMenuItem(value: 'Progress (Asc)', child: Text('Progress: Rendah - Tinggi')),
                DropdownMenuItem(value: 'Bugs (Desc)', child: Text('Bugs: Terbanyak')),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProjectReportCard(BuildContext context, ProjectReportData stats, bool isDark) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF0D0F16) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? const Color(0xFF1C2033) : const Color(0xFFE3E8F0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name
            Text(
              stats.projectName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // Progress bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Progress Audit', style: TextStyle(fontSize: 11, color: Colors.grey)),
                Text('${stats.progress.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: stats.progress / 100,
                minHeight: 5,
                backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                color: AppTheme.statusPassed,
              ),
            ),
            const SizedBox(height: 18),

            // Grid statistics
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMiniStat('Modul', stats.totalModules.toString()),
                _buildMiniStat('Fitur', stats.totalFeatures.toString()),
                _buildMiniStat('Fungsi', stats.totalFunctions.toString()),
                _buildMiniStat('Bugs', stats.totalBugs.toString(), isRed: stats.totalBugs > 0),
              ],
            ),

            const Spacer(),
            const Divider(),
            const SizedBox(height: 4),

            // View Details Button
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => context.go('/reports/${stats.projectId}'),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                  label: const Text('Buka Laporan', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String val, {bool isRed = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(val, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isRed ? const Color(0xFFEF4444) : null)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
      ],
    );
  }
}
