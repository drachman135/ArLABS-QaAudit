import '../../bug/domain/bug_model.dart';

class Audit {
  final String id;
  final String functionId;
  final String status;
  final String? priority;
  final String? notes;
  final String? auditorName;
  final DateTime lastAuditedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Bug> bugs;

  Audit({
    required this.id,
    required this.functionId,
    required this.status,
    this.priority,
    this.notes,
    this.auditorName,
    required this.lastAuditedAt,
    required this.createdAt,
    required this.updatedAt,
    this.bugs = const [],
  });

  factory Audit.fromJson(Map<String, dynamic> json) {
    final List<Bug> parsedBugs = [];
    if (json['bugs'] != null) {
      for (final bugJson in json['bugs'] as List) {
        final bug = Bug.fromJson(bugJson as Map<String, dynamic>);
        if (bug.deletedAt == null) {
          parsedBugs.add(bug);
        }
      }
    }

    return Audit(
      id: json['id'] as String,
      functionId: json['function_id'] as String,
      status: json['status'] as String? ?? 'Not Tested',
      priority: json['priority'] as String?,
      notes: json['notes'] as String?,
      auditorName: json['auditor_name'] as String?,
      lastAuditedAt: DateTime.parse(json['last_audited_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      bugs: parsedBugs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'function_id': functionId,
      'status': status,
      'priority': priority,
      'notes': notes,
      'auditor_name': auditorName,
      'last_audited_at': lastAuditedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'bugs': bugs.map((b) => b.toJson()).toList(),
    };
  }

  Audit copyWith({
    String? id,
    String? functionId,
    String? status,
    String? priority,
    String? notes,
    String? auditorName,
    DateTime? lastAuditedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Bug>? bugs,
  }) {
    return Audit(
      id: id ?? this.id,
      functionId: functionId ?? this.functionId,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      notes: notes ?? this.notes,
      auditorName: auditorName ?? this.auditorName,
      lastAuditedAt: lastAuditedAt ?? this.lastAuditedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      bugs: bugs ?? this.bugs,
    );
  }
}
