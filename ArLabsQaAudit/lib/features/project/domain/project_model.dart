import '../../audit/domain/audit_statistics.dart';

class Project {
  final String id;
  final String name;
  final String? description;
  final String color;
  final String icon;
  final String status; // Active / Archived
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  Project({
    required this.id,
    required this.name,
    this.description,
    required this.color,
    required this.icon,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      color: json['color'] as String? ?? '#6366F1',
      icon: json['icon'] as String? ?? 'folder_outlined',
      status: json['status'] as String? ?? 'Active',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color': color,
      'icon': icon,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  Project copyWith({
    String? name,
    String? description,
    String? color,
    String? icon,
    String? status,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Project(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}

class ProjectWithStats {
  final Project project;
  final AuditStatistics stats;
  final List<dynamic> rawModulesJson;

  ProjectWithStats({
    required this.project,
    required this.stats,
    this.rawModulesJson = const [],
  });

  bool matchesSearchQuery(String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    
    // 1. Check Project details
    if (project.name.toLowerCase().contains(q) ||
        (project.description != null && project.description!.toLowerCase().contains(q))) {
      return true;
    }
    
    // 2. Check nested Modules
    for (final mod in rawModulesJson) {
      if (mod is! Map<String, dynamic>) continue;
      final modName = mod['name'] as String? ?? '';
      final modDesc = mod['description'] as String? ?? '';
      if (modName.toLowerCase().contains(q) || modDesc.toLowerCase().contains(q)) {
        return true;
      }
      
      // 3. Check nested Features
      final features = mod['features'] as List? ?? [];
      for (final feat in features) {
        if (feat is! Map<String, dynamic>) continue;
        final featName = feat['name'] as String? ?? '';
        final featDesc = feat['description'] as String? ?? '';
        if (featName.toLowerCase().contains(q) || featDesc.toLowerCase().contains(q)) {
          return true;
        }
        
        // 4. Check nested Functions
        final functions = feat['functions'] as List? ?? [];
        for (final func in functions) {
          if (func is! Map<String, dynamic>) continue;
          final funcName = func['name'] as String? ?? '';
          final funcDesc = func['description'] as String? ?? '';
          if (funcName.toLowerCase().contains(q) || funcDesc.toLowerCase().contains(q)) {
            return true;
          }
        }
      }
    }
    return false;
  }
}
