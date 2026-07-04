import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/supabase_config.dart';
import '../domain/attachment_model.dart';
import '../../activity/data/activity_repository.dart';

class AttachmentRepository {
  final SupabaseClient _client;
  final Ref _ref;

  AttachmentRepository(this._client, this._ref);

  Future<List<Attachment>> getAttachments({String? auditId, String? bugId}) async {
    var query = _client.from('attachments').select();
    if (auditId != null) {
      query = query.eq('audit_id', auditId);
    } else if (bugId != null) {
      query = query.eq('bug_id', bugId);
    } else {
      return [];
    }

    final response = await query.order('created_at', ascending: true);
    return (response as List).map((json) => Attachment.fromJson(json)).toList();
  }

  Future<Attachment> uploadAttachment({
    String? auditId,
    String? bugId,
    required String originalFileName,
    required int fileSize,
    required String mimeType,
    required Uint8List fileBytes,
    required String projectId,
    required String parentName, // Name of the Bug or Function/Audit
  }) async {
    // 1. Generate unique file name
    final uniqueId = DateTime.now().millisecondsSinceEpoch.toString();
    final uniqueFileName = '${uniqueId}_${originalFileName.replaceAll(' ', '_')}';
    final storagePath = 'attachments/$uniqueFileName';

    // 2. Upload to Supabase Storage bucket 'attachments'
    await _client.storage.from('attachments').uploadBinary(
      uniqueFileName,
      fileBytes,
      fileOptions: FileOptions(contentType: mimeType),
    );

    // 3. Save attachment metadata in DB
    final response = await _client.from('attachments').insert({
      'audit_id': auditId,
      'bug_id': bugId,
      'file_name': uniqueFileName,
      'original_file_name': originalFileName,
      'file_size': fileSize,
      'mime_type': mimeType,
      'storage_path': storagePath,
    }).select().single();

    final attachment = Attachment.fromJson(response);

    // 4. Log activity
    final description = bugId != null
        ? 'Attachment "$originalFileName" berhasil diunggah pada Bug "$parentName"'
        : 'Attachment "$originalFileName" berhasil diunggah pada Audit fungsi "$parentName"';

    _ref.read(activityRepositoryProvider).logActivity(
      projectId: projectId,
      entityType: 'Attachment',
      entityId: attachment.id,
      entityName: originalFileName,
      action: 'Upload',
      description: description,
    );

    return attachment;
  }

  Future<void> deleteAttachment({
    required Attachment attachment,
    required String projectId,
    required String parentName,
    required bool isBug,
  }) async {
    // 1. Delete from Supabase Storage
    final fileName = attachment.fileName;
    await _client.storage.from('attachments').remove([fileName]);

    // 2. Delete from Database
    await _client.from('attachments').delete().eq('id', attachment.id);

    // 3. Log activity
    final description = isBug
        ? 'Attachment "${attachment.originalFileName}" dihapus dari Bug "$parentName"'
        : 'Attachment "${attachment.originalFileName}" dihapus dari Audit fungsi "$parentName"';

    _ref.read(activityRepositoryProvider).logActivity(
      projectId: projectId,
      entityType: 'Attachment',
      entityId: attachment.id,
      entityName: attachment.originalFileName,
      action: 'Delete',
      description: description,
    );
  }
}

final attachmentRepositoryProvider = Provider<AttachmentRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AttachmentRepository(client, ref);
});

// Riverpod Notifier for managing state of attachments for a specific parent (Audit or Bug)
class AttachmentsNotifier extends StateNotifier<AsyncValue<List<Attachment>>> {
  final AttachmentRepository _repository;
  final String? _auditId;
  final String? _bugId;

  AttachmentsNotifier({
    required AttachmentRepository repository,
    String? auditId,
    String? bugId,
  })  : _repository = repository,
        _auditId = auditId,
        _bugId = bugId,
        super(const AsyncValue.loading()) {
    loadAttachments();
  }

  Future<void> loadAttachments() async {
    state = const AsyncValue.loading();
    try {
      final list = await _repository.getAttachments(auditId: _auditId, bugId: _bugId);
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> upload({
    required String originalFileName,
    required int fileSize,
    required String mimeType,
    required Uint8List fileBytes,
    required String projectId,
    required String parentName,
  }) async {
    try {
      final attachment = await _repository.uploadAttachment(
        auditId: _auditId,
        bugId: _bugId,
        originalFileName: originalFileName,
        fileSize: fileSize,
        mimeType: mimeType,
        fileBytes: fileBytes,
        projectId: projectId,
        parentName: parentName,
      );

      state.whenData((list) {
        state = AsyncValue.data([...list, attachment]);
      });
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> delete({
    required Attachment attachment,
    required String projectId,
    required String parentName,
    required bool isBug,
  }) async {
    try {
      await _repository.deleteAttachment(
        attachment: attachment,
        projectId: projectId,
        parentName: parentName,
        isBug: isBug,
      );

      state.whenData((list) {
        state = AsyncValue.data(list.where((a) => a.id != attachment.id).toList());
      });
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// Parametrized provider family for Audit attachments
final auditAttachmentsProvider = StateNotifierProvider.family<AttachmentsNotifier, AsyncValue<List<Attachment>>, String>((ref, auditId) {
  final repo = ref.watch(attachmentRepositoryProvider);
  return AttachmentsNotifier(repository: repo, auditId: auditId);
});

// Parametrized provider family for Bug attachments
final bugAttachmentsProvider = StateNotifierProvider.family<AttachmentsNotifier, AsyncValue<List<Attachment>>, String>((ref, bugId) {
  final repo = ref.watch(attachmentRepositoryProvider);
  return AttachmentsNotifier(repository: repo, bugId: bugId);
});
