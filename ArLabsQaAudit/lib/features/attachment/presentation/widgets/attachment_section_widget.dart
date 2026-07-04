import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/attachment_repository.dart';
import '../../domain/attachment_model.dart';
import '../../../../core/utils/link_launcher.dart';

class AttachmentSectionWidget extends ConsumerStatefulWidget {
  final String? auditId;
  final String? bugId;
  final String projectId;
  final String parentName;

  const AttachmentSectionWidget({
    Key? key,
    this.auditId,
    this.bugId,
    required this.projectId,
    required this.parentName,
  }) : super(key: key);

  @override
  ConsumerState<AttachmentSectionWidget> createState() => _AttachmentSectionWidgetState();
}

class _AttachmentSectionWidgetState extends ConsumerState<AttachmentSectionWidget> {
  bool _isUploading = false;
  String? _uploadStatus;

  Future<void> _pickAndUpload() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'pdf', 'txt', 'log'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final fileBytes = file.bytes;
      if (fileBytes == null) {
        throw Exception('Gagal membaca data file.');
      }

      setState(() {
        _isUploading = true;
        _uploadStatus = 'Mengunggah "${file.name}"...';
      });

      final isBug = widget.bugId != null;
      final provider = isBug
          ? bugAttachmentsProvider(widget.bugId!)
          : auditAttachmentsProvider(widget.auditId!);

      await ref.read(provider.notifier).upload(
            originalFileName: file.name,
            fileSize: file.size,
            mimeType: _getMimeType(file.extension ?? ''),
            fileBytes: fileBytes,
            projectId: widget.projectId,
            parentName: widget.parentName,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File "${file.name}" berhasil diunggah.'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengunggah file: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadStatus = null;
        });
      }
    }
  }

  String _getMimeType(String ext) {
    switch (ext.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      case 'txt':
        return 'text/plain';
      case 'log':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }

  IconData _getFileIcon(String mimeType) {
    if (mimeType.startsWith('image/')) {
      return Icons.image_outlined;
    } else if (mimeType == 'application/pdf') {
      return Icons.picture_as_pdf_outlined;
    } else if (mimeType.startsWith('text/')) {
      return Icons.description_outlined;
    } else {
      return Icons.insert_drive_file_outlined;
    }
  }

  Color _getFileColor(String mimeType) {
    if (mimeType.startsWith('image/')) {
      return Colors.blue;
    } else if (mimeType == 'application/pdf') {
      return Colors.red;
    } else if (mimeType.startsWith('text/')) {
      return Colors.teal;
    } else {
      return Colors.grey;
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }

  Future<void> _deleteAttachment(Attachment attachment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Lampiran'),
        content: Text('Apakah Anda yakin ingin menghapus "${attachment.originalFileName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final isBug = widget.bugId != null;
      final provider = isBug
          ? bugAttachmentsProvider(widget.bugId!)
          : auditAttachmentsProvider(widget.auditId!);

      await ref.read(provider.notifier).delete(
            attachment: attachment,
            projectId: widget.projectId,
            parentName: widget.parentName,
            isBug: isBug,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lampiran berhasil dihapus.'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus lampiran: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _previewOrDownload(Attachment attachment) {
    // Construct public storage URL
    final client = Supabase.instance.client;
    final publicUrl = client.storage.from('attachments').getPublicUrl(attachment.fileName);
    launchLink(publicUrl);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final isBug = widget.bugId != null;
    final provider = isBug
        ? bugAttachmentsProvider(widget.bugId!)
        : auditAttachmentsProvider(widget.auditId!);

    final attachmentsAsync = ref.watch(provider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Lampiran & Dokumen',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _pickAndUpload,
              icon: _isUploading
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.upload_file_rounded, size: 16),
              label: Text(_isUploading ? 'Mengunggah...' : 'Unggah File'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_isUploading && _uploadStatus != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _uploadStatus!,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
        attachmentsAsync.when(
          data: (attachments) {
            if (attachments.isEmpty) {
              return Card(
                elevation: 0,
                color: isDark ? const Color(0xFF1E293B).withOpacity(0.15) : const Color(0xFFF8FAFC),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: isDark ? const Color(0xFF334155).withOpacity(0.4) : const Color(0xFFE2E8F0)),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32.0, horizontal: 16),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.cloud_queue_rounded, color: Colors.grey, size: 36),
                        SizedBox(height: 12),
                        Text(
                          'Belum ada lampiran pendukung.',
                          style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Unggah gambar, PDF, log, atau dokumen teks di sini.',
                          style: TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: attachments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final att = attachments[index];
                final fileIcon = _getFileIcon(att.mimeType);
                final fileColor = _getFileColor(att.mimeType);

                return Card(
                  elevation: 0,
                  color: isDark ? const Color(0xFF1E293B).withOpacity(0.1) : const Color(0xFFF8FAFC),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: isDark ? const Color(0xFF334155).withOpacity(0.3) : const Color(0xFFE2E8F0)),
                  ),
                  child: ListTile(
                    dense: true,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: fileColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(fileIcon, color: fileColor, size: 20),
                    ),
                    title: Text(
                      att.originalFileName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${_formatBytes(att.fileSize)} • ${_formatDate(att.createdAt)}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.visibility_outlined, size: 18),
                          tooltip: 'Pratinjau / Unduh',
                          onPressed: () => _previewOrDownload(att),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline_rounded, size: 18, color: theme.colorScheme.error),
                          tooltip: 'Hapus Lampiran',
                          onPressed: () => _deleteAttachment(att),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, st) => Text('Error loading attachments: $err', style: const TextStyle(color: Colors.redAccent)),
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    final localDt = dt.toLocal();
    final day = localDt.day.toString().padLeft(2, '0');
    final month = localDt.month.toString().padLeft(2, '0');
    final year = localDt.year;
    final hour = localDt.hour.toString().padLeft(2, '0');
    final minute = localDt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}
