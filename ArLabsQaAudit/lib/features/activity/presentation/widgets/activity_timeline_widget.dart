import 'package:flutter/material.dart';
import '../../domain/activity_model.dart';

class ActivityTimelineWidget extends StatelessWidget {
  final List<Activity> activities;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const ActivityTimelineWidget({
    Key? key,
    required this.activities,
    this.shrinkWrap = false,
    this.physics,
  }) : super(key: key);

  IconData _getActivityIcon(String action) {
    switch (action) {
      case 'Create':
        return Icons.add_circle_outline_rounded;
      case 'Update':
      case 'Update Status':
      case 'Update Priority':
      case 'Update Notes':
      case 'Change Status':
      case 'Change Severity':
        return Icons.edit_note_rounded;
      case 'Delete':
        return Icons.delete_outline_rounded;
      case 'Archive':
        return Icons.archive_outlined;
      case 'Restore':
        return Icons.unarchive_outlined;
      case 'Reorder':
        return Icons.reorder_rounded;
      case 'Upload':
        return Icons.upload_file_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  Color _getActivityColor(String action) {
    switch (action) {
      case 'Create':
        return const Color(0xFF10B981); // Green
      case 'Update':
      case 'Update Status':
      case 'Update Priority':
      case 'Update Notes':
      case 'Change Status':
      case 'Change Severity':
        return const Color(0xFF3B82F6); // Blue
      case 'Delete':
        return const Color(0xFFEF4444); // Red
      case 'Archive':
        return const Color(0xFFF59E0B); // Amber
      case 'Restore':
        return const Color(0xFF14B8A6); // Teal
      case 'Reorder':
        return const Color(0xFF8B5CF6); // Purple
      case 'Upload':
        return const Color(0xFF06B6D4); // Cyan
      default:
        return const Color(0xFF64748B); // Slate
    }
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) {
      return 'Baru saja';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} menit lalu';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} jam lalu';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} hari lalu';
    } else {
      final localDt = dt.toLocal();
      return '${localDt.day.toString().padLeft(2, '0')}/${localDt.month.toString().padLeft(2, '0')}/${localDt.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (activities.isEmpty) {
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
                Icon(Icons.history_rounded, color: Colors.grey, size: 36),
                SizedBox(height: 12),
                Text(
                  'Belum ada riwayat aktivitas.',
                  style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 4),
                Text(
                  'Seluruh aktivitas pembuatan, pembaruan, dan penghapusan akan tercatat di sini.',
                  style: TextStyle(color: Colors.grey, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final act = activities[index];
        final icon = _getActivityIcon(act.action);
        final color = _getActivityColor(act.action);
        final isLast = index == activities.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Timeline Column (Dot & Line)
              Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: color.withOpacity(0.3), width: 1),
                    ),
                    child: Icon(icon, color: color, size: 16),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                      ),
                    ),
                ],
              ),
              // Activity Card Content
              Expanded(
                child: Container(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: color.withOpacity(0.2)),
                            ),
                            child: Text(
                              '${act.entityType} ${act.action}',
                              style: TextStyle(
                                fontSize: 9,
                                color: color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            _formatTimeAgo(act.createdAt),
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        act.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Entitas: ${act.entityName}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
