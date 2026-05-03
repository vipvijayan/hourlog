import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/time_record.dart';

/// Shows a dialog to edit check-in and check-out times of a [TimeRecord].
/// Returns the updated [TimeRecord] on save, or null if cancelled.
Future<TimeRecord?> showEditRecordDialog(
  BuildContext context,
  TimeRecord record,
) {
  return showDialog<TimeRecord>(
    context: context,
    builder: (ctx) => _EditRecordDialog(record: record),
  );
}

class _EditRecordDialog extends StatefulWidget {
  final TimeRecord record;
  const _EditRecordDialog({required this.record});

  @override
  State<_EditRecordDialog> createState() => _EditRecordDialogState();
}

class _EditRecordDialogState extends State<_EditRecordDialog> {
  late DateTime _checkIn;
  DateTime? _checkOut;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkIn = widget.record.checkInTime;
    _checkOut = widget.record.checkOutTime;
  }

  Future<void> _pickDateTime({
    required DateTime initial,
    required void Function(DateTime picked) onPicked,
  }) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: now,
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;

    onPicked(
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
  }

  void _save() {
    if (_checkOut != null && !_checkOut!.isAfter(_checkIn)) {
      setState(() {
        _error = 'Check-out must be after check-in.';
      });
      return;
    }
    Navigator.pop(
      context,
      widget.record.copyWith(
        checkIn: _checkIn.millisecondsSinceEpoch,
        checkOut: _checkOut?.millisecondsSinceEpoch,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, yyyy  hh:mm a');
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Edit Time Entry'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TimeField(
            label: 'Check-in',
            value: fmt.format(_checkIn),
            onTap: () => _pickDateTime(
              initial: _checkIn,
              onPicked: (dt) => setState(() {
                _checkIn = dt;
                _error = null;
              }),
            ),
          ),
          const SizedBox(height: 12),
          _TimeField(
            label: 'Check-out',
            value: _checkOut != null ? fmt.format(_checkOut!) : 'Active — not yet',
            enabled: !widget.record.isActive,
            onTap: widget.record.isActive
                ? null
                : () => _pickDateTime(
                      initial: _checkOut ?? DateTime.now(),
                      onPicked: (dt) => setState(() {
                        _checkOut = dt;
                        _error = null;
                      }),
                    ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A73E8),
            foregroundColor: Colors.white,
          ),
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _TimeField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool enabled;

  const _TimeField({
    required this.label,
    required this.value,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFFF5F7FA) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled
                ? const Color(0xFF1A73E8).withValues(alpha: 0.35)
                : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: enabled
                        ? const Color(0xFF2D3748)
                        : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
            if (enabled)
              Icon(
                Icons.edit_outlined,
                size: 16,
                color: const Color(0xFF1A73E8).withValues(alpha: 0.7),
              ),
          ],
        ),
      ),
    );
  }
}
