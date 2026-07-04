class ExportRecord {
  final String id;
  final String? projectId;
  final String? projectName;
  final String exportType;
  final String fileFormat;
  final DateTime createdAt;

  ExportRecord({
    required this.id,
    this.projectId,
    this.projectName,
    required this.exportType,
    required this.fileFormat,
    required this.createdAt,
  });

  factory ExportRecord.fromJson(Map<String, dynamic> json) {
    return ExportRecord(
      id: json['id'] as String,
      projectId: json['project_id'] as String?,
      projectName: json['projects']?['name'] as String?,
      exportType: json['export_type'] as String? ?? 'Unknown',
      fileFormat: json['file_format'] as String? ?? 'CSV',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class ProjectReportData {
  final String projectId;
  final String projectName;
  final String? projectDescription;
  
  final int totalModules;
  final int totalFeatures;
  final int totalFunctions;
  final int totalAudits;
  final int totalBugs;
  final double progress;

  // Audit Status
  final int auditPassed;
  final int auditFailed;
  final int auditWarning;
  final int auditSkipped;
  final int auditNotImplemented;
  final int auditNotTested;

  // Bug Severity
  final int bugCritical;
  final int bugHigh;
  final int bugMedium;
  final int bugLow;

  // Bug Status
  final int bugOpen;
  final int bugInProgress;
  final int bugReadyToTest;
  final int bugResolved;
  final int bugClosed;
  final int bugRejected;

  ProjectReportData({
    required this.projectId,
    required this.projectName,
    this.projectDescription,
    required this.totalModules,
    required this.totalFeatures,
    required this.totalFunctions,
    required this.totalAudits,
    required this.totalBugs,
    required this.progress,
    required this.auditPassed,
    required this.auditFailed,
    required this.auditWarning,
    required this.auditSkipped,
    required this.auditNotImplemented,
    required this.auditNotTested,
    required this.bugCritical,
    required this.bugHigh,
    required this.bugMedium,
    required this.bugLow,
    required this.bugOpen,
    required this.bugInProgress,
    required this.bugReadyToTest,
    required this.bugResolved,
    required this.bugClosed,
    required this.bugRejected,
  });

  factory ProjectReportData.empty(String id, String name) {
    return ProjectReportData(
      projectId: id,
      projectName: name,
      totalModules: 0,
      totalFeatures: 0,
      totalFunctions: 0,
      totalAudits: 0,
      totalBugs: 0,
      progress: 0.0,
      auditPassed: 0,
      auditFailed: 0,
      auditWarning: 0,
      auditSkipped: 0,
      auditNotImplemented: 0,
      auditNotTested: 0,
      bugCritical: 0,
      bugHigh: 0,
      bugMedium: 0,
      bugLow: 0,
      bugOpen: 0,
      bugInProgress: 0,
      bugReadyToTest: 0,
      bugResolved: 0,
      bugClosed: 0,
      bugRejected: 0,
    );
  }
}
