class Module {
  final String id;
  final String projectId;
  final String name;
  final String? description;
  final int orderIndex;
  final DateTime createdAt;
  final DateTime updatedAt;

  Module({
    required this.id,
    required this.projectId,
    required this.name,
    this.description,
    required this.orderIndex,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Module.fromJson(Map<String, dynamic> json) {
    return Module(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      orderIndex: json['order_index'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project_id': projectId,
      'name': name,
      'description': description,
      'order_index': orderIndex,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Module copyWith({
    String? name,
    String? description,
    int? orderIndex,
    DateTime? updatedAt,
  }) {
    return Module(
      id: id,
      projectId: projectId,
      name: name ?? this.name,
      description: description ?? this.description,
      orderIndex: orderIndex ?? this.orderIndex,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
