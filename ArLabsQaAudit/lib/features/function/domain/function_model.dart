import '../../audit/domain/audit_model.dart';

class AppFunction {
  final String id;
  final String featureId;
  final String name;
  final String? description;
  final int orderIndex;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Audit? activeAudit;

  AppFunction({
    required this.id,
    required this.featureId,
    required this.name,
    this.description,
    required this.orderIndex,
    required this.createdAt,
    required this.updatedAt,
    this.activeAudit,
  });

  factory AppFunction.fromJson(Map<String, dynamic> json) {
    Audit? activeAudit;
    if (json['audits'] != null) {
      if (json['audits'] is List && (json['audits'] as List).isNotEmpty) {
        activeAudit = Audit.fromJson((json['audits'] as List).first as Map<String, dynamic>);
      } else if (json['audits'] is Map) {
        activeAudit = Audit.fromJson(json['audits'] as Map<String, dynamic>);
      }
    }

    return AppFunction(
      id: json['id'] as String,
      featureId: json['feature_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      orderIndex: json['order_index'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      activeAudit: activeAudit,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'feature_id': featureId,
      'name': name,
      'description': description,
      'order_index': orderIndex,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (activeAudit != null) 'audits': activeAudit!.toJson(),
    };
  }

  AppFunction copyWith({
    String? name,
    String? description,
    int? orderIndex,
    DateTime? updatedAt,
    Audit? activeAudit,
  }) {
    return AppFunction(
      id: id,
      featureId: featureId,
      name: name ?? this.name,
      description: description ?? this.description,
      orderIndex: orderIndex ?? this.orderIndex,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      activeAudit: activeAudit ?? this.activeAudit,
    );
  }
}

