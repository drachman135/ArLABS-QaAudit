class Feature {
  final String id;
  final String moduleId;
  final String name;
  final String? description;
  final int orderIndex;
  final DateTime createdAt;
  final DateTime updatedAt;

  Feature({
    required this.id,
    required this.moduleId,
    required this.name,
    this.description,
    required this.orderIndex,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Feature.fromJson(Map<String, dynamic> json) {
    return Feature(
      id: json['id'] as String,
      moduleId: json['module_id'] as String,
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
      'module_id': moduleId,
      'name': name,
      'description': description,
      'order_index': orderIndex,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Feature copyWith({
    String? name,
    String? description,
    int? orderIndex,
    DateTime? updatedAt,
  }) {
    return Feature(
      id: id,
      moduleId: moduleId,
      name: name ?? this.name,
      description: description ?? this.description,
      orderIndex: orderIndex ?? this.orderIndex,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
