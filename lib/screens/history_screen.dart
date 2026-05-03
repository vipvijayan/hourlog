import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/time_provider.dart';
import '../models/time_record.dart';
import '../utils/duration_formatter.dart';
import '../widgets/edit_record_dialog.dart';
import '../widgets/weekly_bar_chart.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Work History',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A73E8),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Consumer<TimeProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final groupedRecords = provider.recordsByDay;

          if (groupedRecords.isEmpty) {
            return _buildEmptyState();
          }

          final sortedDays = groupedRecords.keys.toList()
            ..sort((a, b) => b.compareTo(a));

          final weekTotal = provider.getTotalForCurrentWeek();
          final monthTotal = provider.getTotalForCurrentMonth();
          final avgPerMonth = provider.getAveragePerMonth();
          final avgPerYear = provider.getAveragePerYear();

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: sortedDays.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  children: [
                    _buildSummaryHeader(
                      context,
                      weekTotal,
                      monthTotal,
                      avgPerMonth,
                      avgPerYear,
                    ),
                    const SizedBox(height: 12),
                    WeeklyBarChart(provider: provider),
                    const SizedBox(height: 8),
                  ],
                );
              }
              final day = sortedDays[index - 1];
              final dayRecords = groupedRecords[day]!;
              final dayTotal = provider.getTotalForDay(day);
              return _DayGroup(
                day: day,
                records: dayRecords,
                dayTotal: dayTotal,
                onDelete: (id) => _confirmDelete(context, provider, id),
                onEdit: (record) => _confirmEdit(context, provider, record),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off, size: 72, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No records yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start by checking in on the home screen.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    TimeProvider provider,
    int id,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Record'),
        content: const Text('Are you sure you want to delete this record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await provider.deleteRecord(id);
    }
  }

  Future<void> _confirmEdit(
    BuildContext context,
    TimeProvider provider,
    TimeRecord record,
  ) async {
    final updated = await showEditRecordDialog(context, record);
    if (updated != null) {
      await provider.updateRecord(updated);
    }
  }

  Widget _buildSummaryHeader(BuildContext context, Duration weekTotal, Duration monthTotal, Duration avgPerMonth, Duration avgPerYear) {
    final primary = Theme.of(context).colorScheme.primary;
    return Card(
      color: primary,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _SummaryItem(
                    label: 'This Week',
                    value: formatDurationFull(weekTotal),
                    icon: Icons.date_range,
                  ),
                ),
                Container(width: 1, height: 40, color: Colors.white24),
                Expanded(
                  child: _SummaryItem(
                    label: 'This Month',
                    value: formatDurationFull(monthTotal),
                    icon: Icons.calendar_month,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _SummaryItem(
                    label: 'Avg /Month',
                    value: formatDurationFull(avgPerMonth),
                    icon: Icons.bar_chart,
                  ),
                ),
                Container(width: 1, height: 36, color: Colors.white24),
                Expanded(
                  child: _SummaryItem(
                    label: 'Avg /Year',
                    value: formatDurationFull(avgPerYear),
                    icon: Icons.insert_chart,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayGroup extends StatelessWidget {
  final DateTime day;
  final List<TimeRecord> records;
  final Duration dayTotal;
  final void Function(int id) onDelete;
  final void Function(TimeRecord record) onEdit;

  const _DayGroup({
    required this.day,
    required this.records,
    required this.dayTotal,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    String dayLabel;
    if (day == today) {
      dayLabel = 'Today';
    } else if (day == yesterday) {
      dayLabel = 'Yesterday';
    } else {
      dayLabel = DateFormat('EEEE, MMM d, yyyy').format(day);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, top: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dayLabel,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A73E8).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Total: ${formatDurationFull(dayTotal)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A73E8),
                  ),
                ),
              ),
            ],
          ),
        ),
        ...records.map((record) => _RecordTile(
              record: record,
              onDelete: () {
                if (record.id != null) onDelete(record.id!);
              },
              onEdit: () => onEdit(record),
            )),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _RecordTile extends StatelessWidget {
  final TimeRecord record;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _RecordTile({
    required this.record,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final checkInStr = DateFormat('hh:mm a').format(record.checkInTime);
    final checkOutStr = record.checkOutTime != null
        ? DateFormat('hh:mm a').format(record.checkOutTime!)
        : '—';
    final durationStr =
        record.duration != null ? formatDuration(record.duration!) : 'Active';
    final isActive = record.isActive;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: isActive ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: isActive
            ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5)
            : BorderSide.none,
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF1A73E8).withValues(alpha: 0.1)
                : Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isActive ? Icons.play_circle_fill : Icons.check_circle,
            color: isActive ? const Color(0xFF1A73E8) : Colors.green,
            size: 26,
          ),
        ),
        title: Row(
          children: [
            Icon(Icons.login, size: 14, color: Colors.grey.shade500),
            const SizedBox(width: 4),
            Text(
              checkInStr,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Color(0xFF2D3748),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.arrow_forward, size: 14, color: Colors.grey.shade400),
            ),
            Icon(Icons.logout, size: 14, color: Colors.grey.shade500),
            const SizedBox(width: 4),
            Text(
              checkOutStr,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isActive ? Colors.grey.shade500 : const Color(0xFF2D3748),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Icon(Icons.timer, size: 13, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(
                durationStr,
                style: TextStyle(
                  fontSize: 13,
                  color: isActive
                      ? const Color(0xFF1A73E8)
                      : Colors.grey.shade600,
                  fontWeight:
                      isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              if (isActive) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A73E8).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Active',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF1A73E8),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              color: const Color(0xFF1A73E8),
              tooltip: 'Edit',
              onPressed: onEdit,
            ),
            if (!isActive)
              IconButton(
                icon: Icon(Icons.delete_outline,
                    color: Colors.red.shade400, size: 20),
                tooltip: 'Delete',
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}
