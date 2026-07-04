class Attachment {
  final String id;
  final String? auditId;
  final String? bugId;
  final String fileName;
  final String originalFileName;
  final int fileSize;
  final String mimeType;
  final String storagePath;
  final DateTime createdAt;

  Attachment({
    required this.id,
    this.auditId,
    this.bugId,
    required this.fileName,
    required this.originalFileName,
    required this.fileSize,
    required this.mimeType,
    required this.storagePath,
    required this.createdAt,
  });

  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      id: json['id'] as String,
      auditId: json['audit_id'] as String?,
      bugId: json['bug_id'] as String?,
      fileName: json['file_name'] as String,
      originalFileName: json['original_file_name'] as String,
      fileSize: json['file_size'] as int,
      mimeType: json['mime_type'] as String,
      storagePath: json['storage_path'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'audit_id': auditId,
      'bug_id': bugId,
      'file_name': fileName,
      'original_file_name': originalFileName,
      'file_size': fileSize,
      'mime_type': mimeType,
      'storage_path': storagePath,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
