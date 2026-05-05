import 'package:flutter/material.dart';
import '../models/time_record.dart';
import '../providers/time_provider.dart';

/// Simple, dependency-free bar chart for the two previous work weeks (Mon–Fri).
class WeeklyBarChart extends StatelessWidget {
  final TimeProvider provider;
  const WeeklyBarChart({required this.provider, super.key});

  @override
  Widget build(BuildContext context) {
    final values = _computeLastTwoWorkWeeks(provider.records);
    final labels = _buildLabels();
    final maxVal = values.isEmpty
        ? 0.0
        : values.reduce((a, b) => a > b ? a : b);
    const maxBarHeight = 120.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last 2 Weeks (Mon–Fri)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: maxBarHeight + 58,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(values.length, (i) {
                  final v = values[i];
                  final barHeight = maxVal > 0
                      ? (v / maxVal) * maxBarHeight
                      : 4.0;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${labels[i]}: ${v.toStringAsFixed(2)} h',
                            ),
                          ),
                        );
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${v.toStringAsFixed(1)}h',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: barHeight,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            labels[i],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<double> _computeLastTwoWorkWeeks(List<TimeRecord> records) {
    final now = DateTime.now();
    final currentWeekStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final firstWeekStart = currentWeekStart.subtract(const Duration(days: 14));

    final totals = List<double>.filled(10, 0.0);

    for (int index = 0; index < 10; index++) {
      final day = firstWeekStart.add(Duration(days: index + (index ~/ 5 * 2)));
      final start = DateTime(day.year, day.month, day.day);
      final end = start.add(const Duration(days: 1));

      final totalMinutes = records
          .where(
            (r) =>
                r.checkOut != null &&
                r.checkInTime.isAfter(
                  start.subtract(const Duration(milliseconds: 1)),
                ) &&
                r.checkInTime.isBefore(end),
          )
          .fold<int>(0, (sum, r) => sum + r.duration!.inMinutes);

      totals[index] = totalMinutes / 60.0;
    }

    return totals;
  }

  List<String> _buildLabels() {
    const shortDays = ['M', 'T', 'W', 'T', 'F'];
    return [for (final day in shortDays) day, for (final day in shortDays) day];
  }
}
