class Activity {
  final String id;
  final String projectId;
  final String entityType; // Project, Module, Feature, Function, Audit, Bug, Attachment
  final String entityId;
  final String entityName;
  final String action; // Create, Update, Delete, Archive, Restore, Reorder, Update Status, Update Priority, Update Notes, Upload
  final String description;
  final DateTime createdAt;

  Activity({
    required this.id,
    required this.projectId,
    required this.entityType,
    required this.entityId,
    required this.entityName,
    required this.action,
    required this.description,
    required this.createdAt,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      entityType: json['entity_type'] as String,
      entityId: json['entity_id'] as String,
      entityName: json['entity_name'] as String,
      action: json['action'] as String,
      description: json['description'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project_id': projectId,
      'entity_type': entityType,
      'entity_id': entityId,
      'entity_name': entityName,
      'action': action,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
