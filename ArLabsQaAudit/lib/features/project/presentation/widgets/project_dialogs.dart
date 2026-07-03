import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/project_model.dart';
import '../../data/project_repository.dart';

class ProjectDialogs {
  static const List<Map<String, dynamic>> availableColors = [
    {'name': 'Indigo', 'value': '#6366F1', 'color': Color(0xFF6366F1)},
    {'name': 'Emerald', 'value': '#10B981', 'color': Color(0xFF10B981)},
    {'name': 'Amber', 'value': '#F59E0B', 'color': Color(0xFFF59E0B)},
    {'name': 'Rose', 'value': '#F43F5E', 'color': Color(0xFFF43F5E)},
    {'name': 'Cyan', 'value': '#06B6D4', 'color': Color(0xFF06B6D4)},
    {'name': 'Violet', 'value': '#8B5CF6', 'color': Color(0xFF8B5CF6)},
  ];

  static const List<Map<String, dynamic>> availableIcons = [
    {'name': 'Folder', 'value': 'folder_outlined', 'icon': Icons.folder_outlined},
    {'name': 'Code', 'value': 'code', 'icon': Icons.code_rounded},
    {'name': 'Mobile', 'value': 'phone_android', 'icon': Icons.phone_android_rounded},
    {'name': 'Web', 'value': 'language', 'icon': Icons.language_rounded},
    {'name': 'API', 'value': 'api', 'icon': Icons.api_rounded},
    {'name': 'Cloud', 'value': 'cloud_outlined', 'icon': Icons.cloud_queue_rounded},
  ];

  static IconData getIconData(String value) {
    final match = availableIcons.firstWhere((i) => i['value'] == value, orElse: () => availableIcons.first);
    return match['icon'] as IconData;
  }

  static Color getColor(String hex) {
    final hexCode = hex.replaceAll('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  }

  static void showCreateProject(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const _CreateProjectDialog(),
    );
  }

  static void showEditProject(BuildContext context, WidgetRef ref, Project project) {
    showDialog(
      context: context,
      builder: (context) => _EditProjectDialog(project: project),
    );
  }

  static void showArchiveProject(BuildContext context, WidgetRef ref, Project project) {
    final isArchived = project.status == 'Archived';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isArchived ? 'Unarchive Project' : 'Archive Project'),
        content: Text('Are you sure you want to ${isArchived ? 'unarchive' : 'archive'} "${project.name}"?'),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(projectListProvider.notifier).archiveProject(project.id, !isArchived);
              Navigator.pop(context);
            },
            child: Text(isArchived ? 'Unarchive' : 'Archive'),
          ),
        ],
      ),
    );
  }

  static void showDeleteProject(BuildContext context, WidgetRef ref, Project project, {VoidCallback? onDeleteSuccess}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project (Soft Delete)'),
        content: Text('Are you sure you want to delete "${project.name}"? This project can be restored later.'),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () {
              ref.read(projectListProvider.notifier).softDelete(project.id);
              Navigator.pop(context);
              if (onDeleteSuccess != null) onDeleteSuccess();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _CreateProjectDialog extends ConsumerStatefulWidget {
  const _CreateProjectDialog();

  @override
  ConsumerState<_CreateProjectDialog> createState() => _CreateProjectDialogState();
}

class _CreateProjectDialogState extends ConsumerState<_CreateProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  
  String selectedColor = ProjectDialogs.availableColors.first['value'];
  String selectedIcon = ProjectDialogs.availableIcons.first['value'];

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('New Project'),
      content: SizedBox(
        width: 450,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Project Name',
                    hintText: 'e.g., Mobile App Audit',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Project name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Describe this project...',
                  ),
                ),
                const SizedBox(height: 20),
                Text('Accent Color', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: ProjectDialogs.availableColors.map((colorMap) {
                    final hex = colorMap['value'];
                    final color = colorMap['color'] as Color;
                    final isSelected = selectedColor == hex;
                    return InkWell(
                      onTap: () => setState(() => selectedColor = hex),
                      borderRadius: BoxShape.circle.hashCode == 0 ? null : BorderRadius.circular(100),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 2.5)
                              : null,
                          boxShadow: isSelected
                              ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8, spreadRadius: 2)]
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                Text('Project Icon', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: ProjectDialogs.availableIcons.map((iconMap) {
                    final val = iconMap['value'];
                    final icon = iconMap['icon'] as IconData;
                    final isSelected = selectedIcon == val;
                    return InkWell(
                      onTap: () => setState(() => selectedIcon = val),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primary.withOpacity(0.12)
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          icon,
                          color: isSelected ? theme.colorScheme.primary : theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              ref.read(projectListProvider.notifier).addProject(
                    name: _nameController.text.trim(),
                    description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
                    color: selectedColor,
                    icon: selectedIcon,
                  );
              Navigator.pop(context);
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}

class _EditProjectDialog extends ConsumerStatefulWidget {
  final Project project;

  const _EditProjectDialog({required this.project});

  @override
  ConsumerState<_EditProjectDialog> createState() => _EditProjectDialogState();
}

class _EditProjectDialogState extends ConsumerState<_EditProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  
  late String selectedColor;
  late String selectedIcon;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project.name);
    _descController = TextEditingController(text: widget.project.description ?? '');
    selectedColor = widget.project.color;
    selectedIcon = widget.project.icon;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Edit Project'),
      content: SizedBox(
        width: 450,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Project Name',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Project name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                  ),
                ),
                const SizedBox(height: 20),
                Text('Accent Color', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: ProjectDialogs.availableColors.map((colorMap) {
                    final hex = colorMap['value'];
                    final color = colorMap['color'] as Color;
                    final isSelected = selectedColor == hex;
                    return InkWell(
                      onTap: () => setState(() => selectedColor = hex),
                      borderRadius: BorderRadius.circular(100),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 2.5)
                              : null,
                          boxShadow: isSelected
                              ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8, spreadRadius: 2)]
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                Text('Project Icon', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: ProjectDialogs.availableIcons.map((iconMap) {
                    final val = iconMap['value'];
                    final icon = iconMap['icon'] as IconData;
                    final isSelected = selectedIcon == val;
                    return InkWell(
                      onTap: () => setState(() => selectedIcon = val),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primary.withOpacity(0.12)
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          icon,
                          color: isSelected ? theme.colorScheme.primary : theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              ref.read(projectListProvider.notifier).editProject(
                    widget.project.copyWith(
                      name: _nameController.text.trim(),
                      description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
                      color: selectedColor,
                      icon: selectedIcon,
                      updatedAt: DateTime.now(),
                    ),
                  );
              Navigator.pop(context);
            }
          },
          child: const Text('Save Changes'),
        ),
      ],
    );
  }
}
