import '../../function/domain/function_model.dart';

class AuditStatistics {
  final int totalCount;
  final int auditedCount;
  final int passedCount;
  final int failedCount;
  final int warningCount;
  final int skippedCount;
  final int notImplementedCount;
  final int notTestedCount;
  
  // Bug count fields
  final int bugCount;
  final int criticalBugs;
  final int highBugs;
  final int mediumBugs;
  final int lowBugs;

  AuditStatistics({
    required this.totalCount,
    required this.auditedCount,
    required this.passedCount,
    required this.failedCount,
    required this.warningCount,
    required this.skippedCount,
    required this.notImplementedCount,
    required this.notTestedCount,
    required this.bugCount,
    required this.criticalBugs,
    required this.highBugs,
    required this.mediumBugs,
    required this.lowBugs,
  });

  double get progressPercentage {
    if (totalCount == 0) return 0.0;
    return (auditedCount / totalCount) * 100.0;
  }

  factory AuditStatistics.empty() {
    return AuditStatistics(
      totalCount: 0,
      auditedCount: 0,
      passedCount: 0,
      failedCount: 0,
      warningCount: 0,
      skippedCount: 0,
      notImplementedCount: 0,
      notTestedCount: 0,
      bugCount: 0,
      criticalBugs: 0,
      highBugs: 0,
      mediumBugs: 0,
      lowBugs: 0,
    );
  }

  factory AuditStatistics.calculate(List<AppFunction> functions) {
    int passed = 0;
    int failed = 0;
    int warning = 0;
    int skipped = 0;
    int notImplemented = 0;
    int notTested = 0;

    int bugs = 0;
    int critical = 0;
    int high = 0;
    int medium = 0;
    int low = 0;

    for (final func in functions) {
      final status = func.activeAudit?.status ?? 'Not Tested';
      switch (status) {
        case 'Passed':
          passed++;
          break;
        case 'Failed':
          failed++;
          break;
        case 'Warning':
          warning++;
          break;
        case 'Skipped':
          skipped++;
          break;
        case 'Not Implemented':
          notImplemented++;
          break;
        default:
          notTested++;
          break;
      }

      if (func.activeAudit != null) {
        for (final bug in func.activeAudit!.bugs) {
          bugs++;
          switch (bug.severity) {
            case 'Critical':
              critical++;
              break;
            case 'High':
              high++;
              break;
            case 'Medium':
              medium++;
              break;
            case 'Low':
              low++;
              break;
          }
        }
      }
    }

    final total = functions.length;
    final audited = passed + failed + warning + skipped + notImplemented;

    return AuditStatistics(
      totalCount: total,
      auditedCount: audited,
      passedCount: passed,
      failedCount: failed,
      warningCount: warning,
      skippedCount: skipped,
      notImplementedCount: notImplemented,
      notTestedCount: notTested,
      bugCount: bugs,
      criticalBugs: critical,
      highBugs: high,
      mediumBugs: medium,
      lowBugs: low,
    );
  }
}
