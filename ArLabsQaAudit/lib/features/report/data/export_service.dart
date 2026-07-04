import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../domain/report_models.dart';
import '../../project/data/project_tree_provider.dart';

class ExportService {
  /// Generate CSV bytes for a list of bugs
  static Uint8List generateBugsCsv(ProjectTreeData tree) {
    final buffer = StringBuffer();
    // Headers
    buffer.writeln('ID,Project,Module,Feature,Function,Title,Severity,Status,Description,Steps to Reproduce,Expected Result,ActualResult,Reporter,Created At');

    for (final modNode in tree.modules) {
      for (final featNode in modNode.features) {
        for (final func in featNode.functions) {
          final audit = func.activeAudit;
          if (audit != null) {
            for (final bug in audit.bugs) {
              final row = [
                bug.id,
                tree.project.name,
                modNode.module.name,
                featNode.feature.name,
                func.name,
                _escapeCsv(bug.title),
                bug.severity,
                bug.status,
                _escapeCsv(bug.description),
                _escapeCsv(bug.stepsToReproduce ?? ''),
                _escapeCsv(bug.expectedResult ?? ''),
                _escapeCsv(bug.actualResult ?? ''),
                _escapeCsv(bug.assignedTo ?? ''),
                bug.createdAt.toIso8601String(),
              ];
              buffer.writeln(row.join(','));
            }
          }
        }
      }
    }
    return Uint8List.fromList(buffer.toString().codeUnits);
  }

  /// Generate CSV bytes for audit list
  static Uint8List generateAuditsCsv(ProjectTreeData tree) {
    final buffer = StringBuffer();
    // Headers
    buffer.writeln('ID,Project,Module,Feature,Function,Auditor,Status,Priority,Last Audited At,Notes');

    for (final modNode in tree.modules) {
      for (final featNode in modNode.features) {
        for (final func in featNode.functions) {
          final audit = func.activeAudit;
          final row = [
            audit?.id ?? '-',
            tree.project.name,
            modNode.module.name,
            featNode.feature.name,
            func.name,
            audit?.auditorName ?? '-',
            audit?.status ?? 'Not Tested',
            audit?.priority ?? 'None',
            audit?.lastAuditedAt.toIso8601String() ?? '-',
            _escapeCsv(audit?.notes ?? ''),
          ];
          buffer.writeln(row.join(','));
        }
      }
    }
    return Uint8List.fromList(buffer.toString().codeUnits);
  }

  /// Generate Excel (.xlsx) file bytes for Project Reports
  static Uint8List generateProjectExcel(ProjectTreeData tree, ProjectReportData stats) {
    CellValue? val(dynamic value) {
      if (value == null) return null;
      if (value is String) return TextCellValue(value);
      if (value is int) return IntCellValue(value);
      if (value is double) return DoubleCellValue(value);
      if (value is bool) return BoolCellValue(value);
      return TextCellValue(value.toString());
    }

    final excel = Excel.createExcel();
    final Sheet sheet = excel[excel.getDefaultSheet() ?? 'Summary'];

    // 1. Summary Block
    sheet.appendRow([val('QA Audit Project Summary Report - ${tree.project.name}')]);
    sheet.appendRow([]);
    sheet.appendRow([val('Metric'), val('Count / Value')]);
    sheet.appendRow([val('Total Modules'), val(stats.totalModules)]);
    sheet.appendRow([val('Total Features'), val(stats.totalFeatures)]);
    sheet.appendRow([val('Total Functions'), val(stats.totalFunctions)]);
    sheet.appendRow([val('Total Audits'), val(stats.totalAudits)]);
    sheet.appendRow([val('Total Bugs'), val(stats.totalBugs)]);
    sheet.appendRow([val('Overall Progress'), val('${stats.progress.toStringAsFixed(1)}%')]);

    sheet.appendRow([]);
    sheet.appendRow([val('Audit Status Summary')]);
    sheet.appendRow([val('Passed'), val(stats.auditPassed)]);
    sheet.appendRow([val('Failed'), val(stats.auditFailed)]);
    sheet.appendRow([val('Warning'), val(stats.auditWarning)]);
    sheet.appendRow([val('Skipped'), val(stats.auditSkipped)]);
    sheet.appendRow([val('Not Implemented'), val(stats.auditNotImplemented)]);
    sheet.appendRow([val('Not Tested'), val(stats.auditNotTested)]);

    sheet.appendRow([]);
    sheet.appendRow([val('Bug Severity Summary')]);
    sheet.appendRow([val('Critical'), val(stats.bugCritical)]);
    sheet.appendRow([val('High'), val(stats.bugHigh)]);
    sheet.appendRow([val('Medium'), val(stats.bugMedium)]);
    sheet.appendRow([val('Low'), val(stats.bugLow)]);

    // 2. Audit Details Sheet
    final Sheet auditSheet = excel['Audits'];
    auditSheet.appendRow(['Module', 'Feature', 'Function', 'Status', 'Priority', 'Auditor', 'Last Audited', 'Notes'].map((e) => val(e)).toList());
    for (final modNode in tree.modules) {
      for (final featNode in modNode.features) {
        for (final func in featNode.functions) {
          final a = func.activeAudit;
          auditSheet.appendRow([
            modNode.module.name,
            featNode.feature.name,
            func.name,
            a?.status ?? 'Not Tested',
            a?.priority ?? 'None',
            a?.auditorName ?? '-',
            a?.lastAuditedAt.toIso8601String() ?? '-',
            a?.notes ?? '',
          ].map((e) => val(e)).toList());
        }
      }
    }

    // 3. Bug Details Sheet
    final Sheet bugSheet = excel['Bugs'];
    bugSheet.appendRow(['Bug ID', 'Function', 'Title', 'Severity', 'Status', 'Description', 'Assigned To', 'Created At'].map((e) => val(e)).toList());
    for (final modNode in tree.modules) {
      for (final featNode in modNode.features) {
        for (final func in featNode.functions) {
          final a = func.activeAudit;
          if (a != null) {
            for (final bug in a.bugs) {
              bugSheet.appendRow([
                bug.id,
                func.name,
                bug.title,
                bug.severity,
                bug.status,
                bug.description,
                bug.assignedTo ?? 'Unassigned',
                bug.createdAt.toIso8601String(),
              ].map((e) => val(e)).toList());
            }
          }
        }
      }
    }

    final bytes = excel.save();
    return Uint8List.fromList(bytes ?? []);
  }

  /// Generate high-fidelity PDF report
  static Future<Uint8List> generateProjectPdf({
    required ProjectTreeData tree,
    required ProjectReportData stats,
    bool landscape = false,
    String paperSize = 'A4',
  }) async {
    final pdf = pw.Document();

    final format = paperSize.toLowerCase() == 'letter'
        ? (landscape ? PdfPageFormat.letter.landscape : PdfPageFormat.letter)
        : (landscape ? PdfPageFormat.a4.landscape : PdfPageFormat.a4);

    final font = pw.Font.helvetica();
    final boldFont = pw.Font.helveticaBold();

    // Color definitions
    final primaryColor = PdfColor.fromHex('1E3A8A'); // Blue
    final greyColor = PdfColor.fromHex('64748B');
    final passedColor = PdfColor.fromHex('10B981'); // Emerald
    final failedColor = PdfColor.fromHex('EF4444'); // Red
    final warningColor = PdfColor.fromHex('F59E0B'); // Orange
    final infoColor = PdfColor.fromHex('06B6D4'); // Cyan

    // Page 1: cover/summary
    pdf.addPage(
      pw.Page(
        pageFormat: format,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('ARLABS QA AUDIT SYSTEM', style: pw.TextStyle(font: boldFont, fontSize: 10, color: greyColor)),
                  pw.Text(DateTime.now().toLocal().toString().split('.')[0], style: pw.TextStyle(font: font, fontSize: 10, color: greyColor)),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Divider(thickness: 1, color: primaryColor),
              pw.SizedBox(height: 24),

              // Title
              pw.Text('LAPORAN HASIL QA AUDIT', style: pw.TextStyle(font: boldFont, fontSize: 24, color: primaryColor)),
              pw.SizedBox(height: 6),
              pw.Text('Proyek: ${tree.project.name}', style: pw.TextStyle(font: boldFont, fontSize: 16)),
              if (tree.project.description != null && tree.project.description!.isNotEmpty) ...[
                pw.SizedBox(height: 8),
                pw.Text(tree.project.description!, style: pw.TextStyle(font: font, fontSize: 11, color: greyColor)),
              ],

              pw.SizedBox(height: 36),

              // Summary Cards layout
              pw.Text('RINGKASAN PROYEK', style: pw.TextStyle(font: boldFont, fontSize: 14, color: primaryColor)),
              pw.SizedBox(height: 12),
              
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _pdfStatCard('Total Modul', stats.totalModules.toString(), font, boldFont),
                  _pdfStatCard('Total Fitur', stats.totalFeatures.toString(), font, boldFont),
                  _pdfStatCard('Total Fungsi', stats.totalFunctions.toString(), font, boldFont),
                  _pdfStatCard('Total Bug', stats.totalBugs.toString(), font, boldFont),
                ],
              ),

              pw.SizedBox(height: 24),

              // Progress Bar
              pw.Text('Progres Audit Keseluruhan: ${stats.progress.toStringAsFixed(1)}%', style: pw.TextStyle(font: boldFont, fontSize: 12)),
              pw.SizedBox(height: 6),
              pw.Container(
                height: 10,
                width: double.infinity,
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('E2E8F0'),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                ),
                child: pw.Row(
                  children: [
                    pw.Container(
                      width: (format.width - 80) * (stats.progress / 100),
                      decoration: pw.BoxDecoration(
                        color: passedColor,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 32),

              // Distributions
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Audit Status
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('DISTRIBUSI STATUS AUDIT', style: pw.TextStyle(font: boldFont, fontSize: 11, color: primaryColor)),
                        pw.SizedBox(height: 8),
                        _pdfDistributionRow('Passed', stats.auditPassed, stats.totalFunctions, passedColor, font, boldFont),
                        _pdfDistributionRow('Failed', stats.auditFailed, stats.totalFunctions, failedColor, font, boldFont),
                        _pdfDistributionRow('Warning', stats.auditWarning, stats.totalFunctions, warningColor, font, boldFont),
                        _pdfDistributionRow('Skipped', stats.auditSkipped, stats.totalFunctions, infoColor, font, boldFont),
                        _pdfDistributionRow('Not Implemented', stats.auditNotImplemented, stats.totalFunctions, greyColor, font, boldFont),
                        _pdfDistributionRow('Not Tested', stats.auditNotTested, stats.totalFunctions, PdfColor.fromHex('94A3B8'), font, boldFont),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 40),
                  // Bug Severity
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('TINGKAT KEPARAHAN BUG', style: pw.TextStyle(font: boldFont, fontSize: 11, color: primaryColor)),
                        pw.SizedBox(height: 8),
                        _pdfDistributionRow('Critical', stats.bugCritical, stats.totalBugs, PdfColor.fromHex('7F1D1D'), font, boldFont),
                        _pdfDistributionRow('High', stats.bugHigh, stats.totalBugs, failedColor, font, boldFont),
                        _pdfDistributionRow('Medium', stats.bugMedium, stats.totalBugs, warningColor, font, boldFont),
                        _pdfDistributionRow('Low', stats.bugLow, stats.totalBugs, passedColor, font, boldFont),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Page 2: Audit Detail Tables
    final List<pw.TableRow> auditRows = [
      pw.TableRow(
        decoration: pw.BoxDecoration(color: primaryColor),
        children: [
          _pdfHeaderCell('Modul', boldFont),
          _pdfHeaderCell('Fitur', boldFont),
          _pdfHeaderCell('Fungsi', boldFont),
          _pdfHeaderCell('Status', boldFont),
          _pdfHeaderCell('Prioritas', boldFont),
        ],
      )
    ];

    for (final modNode in tree.modules) {
      for (final featNode in modNode.features) {
        for (final func in featNode.functions) {
          final a = func.activeAudit;
          auditRows.add(
            pw.TableRow(
              children: [
                _pdfTableCell(modNode.module.name, font),
                _pdfTableCell(featNode.feature.name, font),
                _pdfTableCell(func.name, font),
                _pdfTableCell(a?.status ?? 'Not Tested', font),
                _pdfTableCell(a?.priority ?? 'None', font),
              ],
            ),
          );
        }
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: format,
        header: (pw.Context context) {
          return pw.Text('DETAIL AUDIT FUNGSI', style: pw.TextStyle(font: boldFont, fontSize: 12, color: primaryColor));
        },
        build: (pw.Context context) {
          return [
            pw.SizedBox(height: 12),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColor.fromHex('E2E8F0'), width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(3),
                3: const pw.FlexColumnWidth(2),
                4: const pw.FlexColumnWidth(1),
              },
              children: auditRows,
            ),
          ];
        },
      ),
    );

    // Page 3: Bug Detail List
    final List<pw.TableRow> bugRows = [
      pw.TableRow(
        decoration: pw.BoxDecoration(color: primaryColor),
        children: [
          _pdfHeaderCell('Fungsi', boldFont),
          _pdfHeaderCell('Judul Bug', boldFont),
          _pdfHeaderCell('Severity', boldFont),
          _pdfHeaderCell('Status', boldFont),
          _pdfHeaderCell('Deskripsi', boldFont),
        ],
      )
    ];

    bool hasBugs = false;
    for (final modNode in tree.modules) {
      for (final featNode in modNode.features) {
        for (final func in featNode.functions) {
          final a = func.activeAudit;
          if (a != null && a.bugs.isNotEmpty) {
            hasBugs = true;
            for (final bug in a.bugs) {
              bugRows.add(
                pw.TableRow(
                  children: [
                    _pdfTableCell(func.name, font),
                    _pdfTableCell(bug.title, font),
                    _pdfTableCell(bug.severity, font),
                    _pdfTableCell(bug.status, font),
                    _pdfTableCell(bug.description, font),
                  ],
                ),
              );
            }
          }
        }
      }
    }

    if (hasBugs) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: format,
          header: (pw.Context context) {
            return pw.Text('DETAIL BUG YANG DITEMUKAN', style: pw.TextStyle(font: boldFont, fontSize: 12, color: primaryColor));
          },
          build: (pw.Context context) {
            return [
              pw.SizedBox(height: 12),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColor.fromHex('E2E8F0'), width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(3),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FlexColumnWidth(2),
                  4: const pw.FlexColumnWidth(4),
                },
                children: bugRows,
              ),
            ];
          },
        ),
      );
    }

    return pdf.save();
  }

  static pw.Widget _pdfStatCard(String title, String val, pw.Font font, pw.Font boldFont) {
    return pw.Container(
      width: 100,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('F8FAFC'),
        border: pw.Border.all(color: PdfColor.fromHex('E2E8F0'), width: 1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(font: font, fontSize: 9, color: PdfColor.fromHex('64748B'))),
          pw.SizedBox(height: 6),
          pw.Text(val, style: pw.TextStyle(font: boldFont, fontSize: 18, color: PdfColor.fromHex('0F172A'))),
        ],
      ),
    );
  }

  static pw.Widget _pdfDistributionRow(String label, int val, int total, PdfColor color, pw.Font font, pw.Font boldFont) {
    final pct = total > 0 ? (val / total * 100) : 0.0;
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(label, style: pw.TextStyle(font: font, fontSize: 9)),
              pw.Text('$val (${pct.toStringAsFixed(0)}%)', style: pw.TextStyle(font: boldFont, fontSize: 9)),
            ],
          ),
          pw.SizedBox(height: 3),
          pw.Container(
            height: 4,
            width: double.infinity,
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('F1F5F9'),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
            ),
            child: pw.Row(
              children: [
                if (pct > 0)
                  pw.Container(
                    width: 160 * (pct / 100),
                    decoration: pw.BoxDecoration(
                      color: color,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _pdfHeaderCell(String label, pw.Font boldFont) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        label,
        style: pw.TextStyle(font: boldFont, fontSize: 9, color: PdfColor.fromHex('FFFFFF')),
      ),
    );
  }

  static pw.Widget _pdfTableCell(String val, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        val,
        style: pw.TextStyle(font: font, fontSize: 9),
      ),
    );
  }

  static String _escapeCsv(String val) {
    if (val.contains(',') || val.contains('"') || val.contains('\n')) {
      return '"${val.replaceAll('"', '""')}"';
    }
    return val;
  }
}
