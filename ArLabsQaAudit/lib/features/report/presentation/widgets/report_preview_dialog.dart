import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../project/data/project_tree_provider.dart';
import '../../domain/report_models.dart';
import '../../data/report_repository.dart';
import '../../data/export_service.dart';
import '../../../../core/utils/file_downloader.dart';
import '../../../../core/theme/app_theme.dart';

class ReportPreviewDialog extends ConsumerStatefulWidget {
  final ProjectTreeData tree;
  final ProjectReportData stats;

  const ReportPreviewDialog({
    Key? key,
    required this.tree,
    required this.stats,
  }) : super(key: key);

  @override
  ConsumerState<ReportPreviewDialog> createState() => _ReportPreviewDialogState();
}

class _ReportPreviewDialogState extends ConsumerState<ReportPreviewDialog> {
  bool _landscape = false;
  String _paperSize = 'A4';
  bool _isExporting = false;

  Future<void> _exportPdf() async {
    setState(() => _isExporting = true);
    try {
      final bytes = await ExportService.generateProjectPdf(
        tree: widget.tree,
        stats: widget.stats,
        landscape: _landscape,
        paperSize: _paperSize,
      );

      final filename = '${widget.tree.project.name.replaceAll(' ', '_')}_AuditReport.pdf';
      await downloadFile(
        bytes: bytes,
        filename: filename,
        mimeType: 'application/pdf',
      );

      // Log to database
      await ref.read(reportRepositoryProvider).logExport(
        projectId: widget.tree.project.id,
        exportType: 'Project Report',
        fileFormat: 'PDF',
      );
      
      // Refresh exports provider
      ref.invalidate(recentExportsProvider);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Laporan PDF berhasil diunduh.'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengekspor PDF: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportExcel() async {
    setState(() => _isExporting = true);
    try {
      final bytes = ExportService.generateProjectExcel(widget.tree, widget.stats);
      final filename = '${widget.tree.project.name.replaceAll(' ', '_')}_AuditReport.xlsx';
      
      await downloadFile(
        bytes: bytes,
        filename: filename,
        mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );

      await ref.read(reportRepositoryProvider).logExport(
        projectId: widget.tree.project.id,
        exportType: 'Project Report',
        fileFormat: 'Excel',
      );
      ref.invalidate(recentExportsProvider);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Laporan Excel (.xlsx) berhasil diunduh.'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengekspor Excel: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportCsv(String type) async {
    setState(() => _isExporting = true);
    try {
      final isBug = type == 'Bugs';
      final bytes = isBug
          ? ExportService.generateBugsCsv(widget.tree)
          : ExportService.generateAuditsCsv(widget.tree);

      final typeLabel = isBug ? 'BugsList' : 'AuditsList';
      final filename = '${widget.tree.project.name.replaceAll(' ', '_')}_$typeLabel.csv';

      await downloadFile(
        bytes: bytes,
        filename: filename,
        mimeType: 'text/csv',
      );

      await ref.read(reportRepositoryProvider).logExport(
        projectId: widget.tree.project.id,
        exportType: isBug ? 'Bug List' : 'Audit List',
        fileFormat: 'CSV',
      );
      ref.invalidate(recentExportsProvider);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Laporan CSV ($typeLabel) berhasil diunduh.'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengekspor CSV: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 800,
        height: 520,
        padding: const EdgeInsets.all(32),
        child: _isExporting
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Sedang mempersiapkan dan mendownload laporan...', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              )
            : Row(
                children: [
                  // Left Side — Interactive Preview mock
                  Expanded(
                    flex: 5,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('PRINTOUT PREVIEW', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                              Icon(_landscape ? Icons.landscape_rounded : Icons.portrait_rounded, size: 16, color: Colors.grey),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Simulated A4 sheet layout
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(height: 12, width: 140, color: AppTheme.primaryColor),
                                  const SizedBox(height: 8),
                                  Container(height: 8, width: 220, color: Colors.grey.withOpacity(0.2)),
                                  const SizedBox(height: 24),
                                  Container(height: 4, width: double.infinity, color: Colors.grey.withOpacity(0.2)),
                                  const SizedBox(height: 12),
                                  // Metric boxes row
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: List.generate(4, (index) => Container(
                                      height: 24,
                                      width: 44,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    )),
                                  ),
                                  const SizedBox(height: 24),
                                  // Progress bar
                                  Container(
                                    height: 6,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: FractionallySizedBox(
                                      alignment: Alignment.centerLeft,
                                      widthFactor: widget.stats.progress / 100,
                                      child: Container(color: AppTheme.statusPassed),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  // List block
                                  Expanded(
                                    child: Column(
                                      children: List.generate(3, (index) => Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: Row(
                                          children: [
                                            Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.grey)),
                                            const SizedBox(width: 8),
                                            Container(height: 6, width: 80, color: Colors.grey.withOpacity(0.2)),
                                            const Spacer(),
                                            Container(height: 6, width: 30, color: Colors.grey.withOpacity(0.2)),
                                          ],
                                        ),
                                      )),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: Text(
                              'Kertas: $_paperSize · ${_landscape ? "Landscape" : "Portrait"}',
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 32),
                  // Right Side — Export Control Panel
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Export Settings', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 24),

                        // Layout Orientation
                        const Text('Orientasi Halaman', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            ChoiceChip(
                              label: const Text('Portrait', style: TextStyle(fontSize: 12)),
                              selected: !_landscape,
                              onSelected: (_) => setState(() => _landscape = false),
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('Landscape', style: TextStyle(fontSize: 12)),
                              selected: _landscape,
                              onSelected: (_) => setState(() => _landscape = true),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Paper Size
                        const Text('Ukuran Kertas', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _paperSize,
                              isDense: true,
                              onChanged: (val) {
                                if (val != null) setState(() => _paperSize = val);
                              },
                              items: const [
                                DropdownMenuItem(value: 'A4', child: Text('A4 (210 x 297 mm)')),
                                DropdownMenuItem(value: 'Letter', child: Text('Letter (8.5 x 11 in)')),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        const Divider(),
                        const Spacer(),

                        // Export Actions
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _exportPdf,
                            icon: const Icon(Icons.picture_as_pdf_rounded),
                            label: const Text('Unduh PDF Report'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _exportExcel,
                            icon: const Icon(Icons.table_view_rounded),
                            label: const Text('Unduh Excel (.xlsx)'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF10B981),
                              side: const BorderSide(color: Color(0xFF10B981)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _exportCsv('Audits'),
                                child: const Text('CSV Audit', style: TextStyle(fontSize: 11)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _exportCsv('Bugs'),
                                child: const Text('CSV Bug', style: TextStyle(fontSize: 11)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
