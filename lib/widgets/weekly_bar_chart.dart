import 'package:flutter/material.dart';
import '../models/time_record.dart';
import '../providers/time_provider.dart';

/// Simple, dependency-free bar chart for Mon–Fri of the previous calendar week.
class WeeklyBarChart extends StatelessWidget {
  final TimeProvider provider;
  const WeeklyBarChart({required this.provider, super.key});

  @override
  Widget build(BuildContext context) {
    final data = _computeLastWorkWeek(provider.records);
    final values = List<double>.generate(5, (i) => data[i] ?? 0.0);
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
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
              'Last Week (Mon–Fri)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: maxBarHeight + 48,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(5, (i) {
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
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            labels[i],
                            style: TextStyle(
                              fontSize: 12,
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

  /// Returns a map of dayIndex (0=Mon..4=Fri) -> hours for the previous calendar week (Mon..Fri)
  Map<int, double> _computeLastWorkWeek(List<TimeRecord> records) {
    final now = DateTime.now();
    final currentWeekStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final lastWeekMonday = currentWeekStart.subtract(const Duration(days: 7));

    final Map<int, double> totals = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0};

    for (int i = 0; i < 5; i++) {
      final day = lastWeekMonday.add(Duration(days: i));
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

      totals[i] = totalMinutes / 60.0;
    }

    return totals;
  }
}
