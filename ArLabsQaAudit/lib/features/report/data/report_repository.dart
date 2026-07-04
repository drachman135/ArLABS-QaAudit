import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_config.dart';
import '../domain/report_models.dart';
import '../../project/domain/project_model.dart';
import '../../project/data/project_repository.dart';
import '../../project/data/project_tree_provider.dart';

class ReportRepository {
  final SupabaseClient _client;
  final List<ExportRecord> _localExports = [];

  ReportRepository(this._client);

  Future<void> logExport({
    String? projectId,
    required String exportType,
    required String fileFormat,
  }) async {
    try {
      await _client.from('exports').insert({
        'project_id': projectId,
        'export_type': exportType,
        'file_format': fileFormat,
      });
    } catch (_) {
      // Local fallback
      _localExports.add(ExportRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        projectId: projectId,
        exportType: exportType,
        fileFormat: fileFormat,
        createdAt: DateTime.now(),
      ));
    }
  }

  Future<List<ExportRecord>> getRecentExports() async {
    try {
      final response = await _client
          .from('exports')
          .select('*, projects(name)')
          .order('created_at', ascending: false)
          .limit(10);
      return (response as List).map((json) => ExportRecord.fromJson(json)).toList();
    } catch (_) {
      return _localExports.reversed.toList();
    }
  }

  ProjectReportData compileReportData(ProjectTreeData tree, {
    String? moduleFilter,
    String? featureFilter,
    String? auditStatusFilter,
    String? bugSeverityFilter,
    String? bugStatusFilter,
    String? priorityFilter,
    DateTimeRange? dateRange,
  }) {
    int totalModules = tree.modules.length;
    int totalFeatures = 0;
    int totalFunctions = 0;
    int totalAudits = 0;
    int totalBugs = 0;

    int auditPassed = 0;
    int auditFailed = 0;
    int auditWarning = 0;
    int auditSkipped = 0;
    int auditNotImplemented = 0;
    int auditNotTested = 0;

    int bugCritical = 0;
    int bugHigh = 0;
    int bugMedium = 0;
    int bugLow = 0;

    int bugOpen = 0;
    int bugInProgress = 0;
    int bugReadyToTest = 0;
    int bugResolved = 0;
    int bugClosed = 0;
    int bugRejected = 0;

    for (final modNode in tree.modules) {
      if (moduleFilter != null && moduleFilter != 'All' && modNode.module.id != moduleFilter) {
        continue;
      }
      
      totalFeatures += modNode.features.length;

      for (final featNode in modNode.features) {
        if (featureFilter != null && featureFilter != 'All' && featNode.feature.id != featureFilter) {
          continue;
        }

        for (final func in featNode.functions) {
          final audit = func.activeAudit;
          final status = audit?.status ?? 'Not Tested';
          final priority = audit?.priority ?? 'None';
          final auditDate = audit?.lastAuditedAt;

          // Apply filters
          if (auditStatusFilter != null && auditStatusFilter != 'All' && status != auditStatusFilter) {
            continue;
          }
          if (priorityFilter != null && priorityFilter != 'All') {
            if (priorityFilter == 'None' && audit?.priority != null) continue;
            if (priorityFilter != 'None' && priority != priorityFilter) continue;
          }
          if (dateRange != null && auditDate != null) {
            if (auditDate.isBefore(dateRange.start) || auditDate.isAfter(dateRange.end)) {
              continue;
            }
          }

          totalFunctions++;
          if (audit != null) {
            totalAudits++;
            switch (status) {
              case 'Passed':
                auditPassed++;
                break;
              case 'Failed':
                auditFailed++;
                break;
              case 'Warning':
                auditWarning++;
                break;
              case 'Skipped':
                auditSkipped++;
                break;
              case 'Not Implemented':
                auditNotImplemented++;
                break;
              default:
                auditNotTested++;
                break;
            }

            for (final bug in audit.bugs) {
              final bugDate = bug.createdAt;

              // Apply Bug Filters
              if (bugSeverityFilter != null && bugSeverityFilter != 'All' && bug.severity != bugSeverityFilter) {
                continue;
              }
              if (bugStatusFilter != null && bugStatusFilter != 'All' && bug.status != bugStatusFilter) {
                continue;
              }
              if (dateRange != null && (bugDate.isBefore(dateRange.start) || bugDate.isAfter(dateRange.end))) {
                continue;
              }

              totalBugs++;
              switch (bug.severity) {
                case 'Critical':
                  bugCritical++;
                  break;
                case 'High':
                  bugHigh++;
                  break;
                case 'Medium':
                  bugMedium++;
                  break;
                case 'Low':
                  bugLow++;
                  break;
              }

              switch (bug.status) {
                case 'Open':
                  bugOpen++;
                  break;
                case 'In Progress':
                  bugInProgress++;
                  break;
                case 'Ready To Test':
                  bugReadyToTest++;
                  break;
                case 'Resolved':
                  bugResolved++;
                  break;
                case 'Closed':
                  bugClosed++;
                  break;
                case 'Rejected':
                  bugRejected++;
                  break;
              }
            }
          } else {
            auditNotTested++;
          }
        }
      }
    }

    final double progress = totalFunctions > 0
        ? ((totalFunctions - auditNotTested) / totalFunctions * 100.0)
        : 0.0;

    return ProjectReportData(
      projectId: tree.project.id,
      projectName: tree.project.name,
      projectDescription: tree.project.description,
      totalModules: totalModules,
      totalFeatures: totalFeatures,
      totalFunctions: totalFunctions,
      totalAudits: totalAudits,
      totalBugs: totalBugs,
      progress: progress,
      auditPassed: auditPassed,
      auditFailed: auditFailed,
      auditWarning: auditWarning,
      auditSkipped: auditSkipped,
      auditNotImplemented: auditNotImplemented,
      auditNotTested: auditNotTested,
      bugCritical: bugCritical,
      bugHigh: bugHigh,
      bugMedium: bugMedium,
      bugLow: bugLow,
      bugOpen: bugOpen,
      bugInProgress: bugInProgress,
      bugReadyToTest: bugReadyToTest,
      bugResolved: bugResolved,
      bugClosed: bugClosed,
      bugRejected: bugRejected,
    );
  }

  ProjectReportData compileFromProjectWithStats(ProjectWithStats p) {
    int totalModules = p.rawModulesJson.length;
    int totalFeatures = 0;
    int totalFunctions = 0;
    int totalAudits = 0;
    int totalBugs = 0;

    int auditPassed = p.stats.passedCount;
    int auditFailed = p.stats.failedCount;
    int auditWarning = p.stats.warningCount;
    int auditSkipped = p.stats.skippedCount;
    int auditNotImplemented = p.stats.notImplementedCount;
    int auditNotTested = p.stats.notTestedCount;

    int bugCritical = p.stats.criticalBugs;
    int bugHigh = p.stats.highBugs;
    int bugMedium = p.stats.mediumBugs;
    int bugLow = p.stats.lowBugs;

    int bugOpen = 0;
    int bugInProgress = 0;
    int bugReadyToTest = 0;
    int bugResolved = 0;
    int bugClosed = 0;
    int bugRejected = 0;

    for (final mod in p.rawModulesJson) {
      final features = mod['features'] as List? ?? [];
      totalFeatures += features.length;
      for (final feat in features) {
        final funcs = feat['functions'] as List? ?? [];
        for (final func in funcs) {
          final audits = func['audits'] as List? ?? [];
          if (audits.isNotEmpty) {
            totalFunctions++;
            totalAudits++;
            final activeAudit = audits.first;
            final bugs = activeAudit['bugs'] as List? ?? [];
            for (final bug in bugs) {
              totalBugs++;
              final status = bug['status'] as String? ?? 'Open';
              switch (status) {
                case 'Open': bugOpen++; break;
                case 'In Progress': bugInProgress++; break;
                case 'Ready To Test': bugReadyToTest++; break;
                case 'Resolved': bugResolved++; break;
                case 'Closed': bugClosed++; break;
                case 'Rejected': bugRejected++; break;
              }
            }
          } else {
            totalFunctions++;
          }
        }
      }
    }

    return ProjectReportData(
      projectId: p.project.id,
      projectName: p.project.name,
      projectDescription: p.project.description,
      totalModules: totalModules,
      totalFeatures: totalFeatures,
      totalFunctions: totalFunctions,
      totalAudits: totalAudits,
      totalBugs: totalBugs,
      progress: p.stats.progressPercentage,
      auditPassed: auditPassed,
      auditFailed: auditFailed,
      auditWarning: auditWarning,
      auditSkipped: auditSkipped,
      auditNotImplemented: auditNotImplemented,
      auditNotTested: auditNotTested,
      bugCritical: bugCritical,
      bugHigh: bugHigh,
      bugMedium: bugMedium,
      bugLow: bugLow,
      bugOpen: bugOpen,
      bugInProgress: bugInProgress,
      bugReadyToTest: bugReadyToTest,
      bugResolved: bugResolved,
      bugClosed: bugClosed,
      bugRejected: bugRejected,
    );
  }
}

// State management providers
final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ReportRepository(client);
});

final recentExportsProvider = FutureProvider<List<ExportRecord>>((ref) async {
  final repo = ref.watch(reportRepositoryProvider);
  return repo.getRecentExports();
});

final projectReportDataProvider = Provider.family<AsyncValue<ProjectReportData>, String>((ref, projectId) {
  final treeState = ref.watch(projectTreeProvider(projectId));
  final repo = ref.watch(reportRepositoryProvider);
  return treeState.when(
    data: (tree) => AsyncValue.data(repo.compileReportData(tree)),
    loading: () => const AsyncValue.loading(),
    error: (err, st) => AsyncValue.error(err, st),
  );
});

final globalReportDataProvider = Provider<AsyncValue<List<ProjectReportData>>>((ref) {
  final repo = ref.watch(reportRepositoryProvider);
  final projectsState = ref.watch(projectListProvider);

  return projectsState.when(
    data: (list) {
      final reports = list.map((p) => repo.compileFromProjectWithStats(p)).toList();
      return AsyncValue.data(reports);
    },
    loading: () => const AsyncValue.loading(),
    error: (err, st) => AsyncValue.error(err, st),
  );
});
