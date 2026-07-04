import 'package:flutter/material.dart';

class ActivityFilterBar extends StatefulWidget {
  final Function({
    String? entityType,
    String? action,
    DateTimeRange? dateRange,
  }) onChanged;

  const ActivityFilterBar({
    Key? key,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<ActivityFilterBar> createState() => _ActivityFilterBarState();
}

class _ActivityFilterBarState extends State<ActivityFilterBar> {
  String _entityType = 'All';
  String _action = 'All';
  DateTimeRange? _dateRange;

  final List<String> _entityTypes = [
    'All',
    'Project',
    'Module',
    'Feature',
    'Function',
    'Audit',
    'Bug',
    'Attachment',
  ];

  final List<String> _actions = [
    'All',
    'Create',
    'Update',
    'Delete',
    'Archive',
    'Restore',
    'Reorder',
    'Upload',
  ];

  void _onChanged() {
    widget.onChanged(
      entityType: _entityType == 'All' ? null : _entityType,
      action: _action == 'All' ? null : _action,
      dateRange: _dateRange,
    );
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2025),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _dateRange,
    );

    if (picked != null) {
      setState(() {
        _dateRange = picked;
      });
      _onChanged();
    }
  }

  void _clearFilters() {
    setState(() {
      _entityType = 'All';
      _action = 'All';
      _dateRange = null;
    });
    _onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasFilters = _entityType != 'All' || _action != 'All' || _dateRange != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        alignment: WrapAlignment.start,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _buildDropdown(
            label: 'Tipe Entitas',
            value: _entityType,
            items: _entityTypes,
            onChanged: (val) {
              if (val != null) {
                setState(() => _entityType = val);
                _onChanged();
              }
            },
          ),
          _buildDropdown(
            label: 'Aksi',
            value: _action,
            items: _actions,
            onChanged: (val) {
              if (val != null) {
                setState(() => _action = val);
                _onChanged();
              }
            },
          ),
          OutlinedButton.icon(
            onPressed: _pickDateRange,
            icon: const Icon(Icons.date_range_rounded, size: 14),
            label: Text(
              _dateRange == null
                  ? 'Pilih Tanggal'
                  : '${_formatDate(_dateRange!.start)} - ${_formatDate(_dateRange!.end)}',
              style: const TextStyle(fontSize: 12),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              side: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
              ),
            ),
          ),
          if (hasFilters)
            TextButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.clear_rounded, size: 14, color: Colors.redAccent),
              label: const Text(
                'Reset Filter',
                style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isDense: true,
              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
              onChanged: onChanged,
              items: items.map((val) {
                return DropdownMenuItem<String>(
                  value: val,
                  child: Text(val),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
