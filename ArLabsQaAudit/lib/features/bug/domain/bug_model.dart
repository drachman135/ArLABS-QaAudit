class Bug {
  final String id;
  final String auditId;
  final String title;
  final String description;
  final String severity; // Critical, High, Medium, Low
  final String status;   // Open, In Progress, Ready To Test, Resolved, Closed, Rejected
  final String? stepsToReproduce;
  final String? expectedResult;
  final String? actualResult;
  final String? assignedTo;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  // Joined metadata fields for ease of display on global lists
  final String? projectName;
  final String? moduleName;
  final String? featureName;
  final String? functionName;
  final String? functionId;
  final String? projectId;
  final String? moduleId;
  final String? featureId;

  Bug({
    required this.id,
    required this.auditId,
    required this.title,
    required this.description,
    required this.severity,
    required this.status,
    this.stepsToReproduce,
    this.expectedResult,
    this.actualResult,
    this.assignedTo,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.projectName,
    this.moduleName,
    this.featureName,
    this.functionName,
    this.functionId,
    this.projectId,
    this.moduleId,
    this.featureId,
  });

  factory Bug.fromJson(Map<String, dynamic> json) {
    final auditJson = json['audits'] as Map<String, dynamic>?;
    final functionJson = auditJson?['functions'] as Map<String, dynamic>?;
    final featureJson = functionJson?['features'] as Map<String, dynamic>?;
    final moduleJson = featureJson?['modules'] as Map<String, dynamic>?;
    final projectJson = moduleJson?['projects'] as Map<String, dynamic>?;

    return Bug(
      id: json['id'] as String,
      auditId: json['audit_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      severity: json['severity'] as String? ?? 'Medium',
      status: json['status'] as String? ?? 'Open',
      stepsToReproduce: json['steps_to_reproduce'] as String?,
      expectedResult: json['expected_result'] as String?,
      actualResult: json['actual_result'] as String?,
      assignedTo: json['assigned_to'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at'] as String) : null,
      projectName: projectJson?['name'] as String?,
      moduleName: moduleJson?['name'] as String?,
      featureName: featureJson?['name'] as String?,
      functionName: functionJson?['name'] as String?,
      functionId: functionJson?['id'] as String?,
      projectId: projectJson?['id'] as String?,
      moduleId: moduleJson?['id'] as String?,
      featureId: featureJson?['id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'audit_id': auditId,
      'title': title,
      'description': description,
      'severity': severity,
      'status': status,
      'steps_to_reproduce': stepsToReproduce,
      'expected_result': expectedResult,
      'actual_result': actualResult,
      'assigned_to': assignedTo,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (deletedAt != null) 'deleted_at': deletedAt!.toIso8601String(),
    };
  }

  Bug copyWith({
    String? id,
    String? auditId,
    String? title,
    String? description,
    String? severity,
    String? status,
    String? stepsToReproduce,
    String? expectedResult,
    String? actualResult,
    String? assignedTo,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? projectName,
    String? moduleName,
    String? featureName,
    String? functionName,
    String? functionId,
    String? projectId,
    String? moduleId,
    String? featureId,
  }) {
    return Bug(
      id: id ?? this.id,
      auditId: auditId ?? this.auditId,
      title: title ?? this.title,
      description: description ?? this.description,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      stepsToReproduce: stepsToReproduce ?? this.stepsToReproduce,
      expectedResult: expectedResult ?? this.expectedResult,
      actualResult: actualResult ?? this.actualResult,
      assignedTo: assignedTo ?? this.assignedTo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      projectName: projectName ?? this.projectName,
      moduleName: moduleName ?? this.moduleName,
      featureName: featureName ?? this.featureName,
      functionName: functionName ?? this.functionName,
      functionId: functionId ?? this.functionId,
      projectId: projectId ?? this.projectId,
      moduleId: moduleId ?? this.moduleId,
      featureId: featureId ?? this.featureId,
    );
  }
}
