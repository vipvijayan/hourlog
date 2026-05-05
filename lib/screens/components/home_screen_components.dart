import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/time_record.dart';
import '../../utils/duration_formatter.dart';

class HomeAppBar extends StatelessWidget {
  final VoidCallback onHistoryTap;

  const HomeAppBar({super.key, required this.onHistoryTap});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF1A73E8),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(20, 0, 10, 14),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'HourLog',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.history, color: Colors.white),
              tooltip: 'History',
              onPressed: onHistoryTap,
            ),
          ],
        ),
      ),
    );
  }
}

class StatusCard extends StatefulWidget {
  final bool isCheckedIn;
  final TimeRecord? activeRecord;
  final Animation<double> pulseAnimation;
  final VoidCallback onEdit;

  const StatusCard({
    super.key,
    required this.isCheckedIn,
    required this.activeRecord,
    required this.pulseAnimation,
    required this.onEdit,
  });

  @override
  State<StatusCard> createState() => _StatusCardState();
}

class _StatusCardState extends State<StatusCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateTimer();
  }

  @override
  void didUpdateWidget(covariant StatusCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCheckedIn != oldWidget.isCheckedIn ||
        widget.activeRecord?.checkInTime !=
            oldWidget.activeRecord?.checkInTime) {
      _updateTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateTimer() {
    _timer?.cancel();
    if (widget.isCheckedIn && widget.activeRecord != null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, MMMM d').format(now);
    final colorScheme = Theme.of(context).colorScheme;
    final cardColor = widget.isCheckedIn
        ? colorScheme.primary
        : colorScheme.surface;
    final textColor = widget.isCheckedIn
        ? colorScheme.onPrimary
        : colorScheme.onSurface;
    final elapsed = widget.activeRecord != null
        ? now.difference(widget.activeRecord!.checkInTime)
        : Duration.zero;

    return Card(
      color: cardColor,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dateStr,
              style: TextStyle(
                color: textColor.withValues(alpha: 0.85),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ScaleTransition(
                  scale: widget.isCheckedIn
                      ? widget.pulseAnimation
                      : const AlwaysStoppedAnimation(1.0),
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: widget.isCheckedIn
                          ? Colors.greenAccent
                          : Colors.grey.shade400,
                      shape: BoxShape.circle,
                      boxShadow: widget.isCheckedIn
                          ? [
                              BoxShadow(
                                color: Colors.greenAccent.withValues(
                                  alpha: 0.6,
                                ),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : [],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  widget.isCheckedIn ? 'Currently Working' : 'Not Checked In',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (widget.isCheckedIn && widget.activeRecord != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Since ${DateFormat('hh:mm a').format(widget.activeRecord!.checkInTime)}',
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.85),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onEdit,
                    child: Icon(
                      Icons.edit_outlined,
                      size: 15,
                      color: textColor.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Duration ${formatDurationFull(elapsed)}',
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.85),
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class CheckButton extends StatelessWidget {
  final bool isCheckedIn;
  final VoidCallback onPressed;

  const CheckButton({
    super.key,
    required this.isCheckedIn,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: isCheckedIn
              ? Theme.of(context).colorScheme.error
              : Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
        ),
        icon: Icon(isCheckedIn ? Icons.logout : Icons.login, size: 22),
        label: Text(
          isCheckedIn ? 'Check Out' : 'Check In',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        onPressed: onPressed,
      ),
    );
  }
}

class SummarySection extends StatelessWidget {
  final Duration todayTotal;
  final Duration weekTotal;
  final Duration monthTotal;

  const SummarySection({
    super.key,
    required this.todayTotal,
    required this.weekTotal,
    required this.monthTotal,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Summary',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: SummaryCard(
                label: 'Today',
                value: formatDurationFull(todayTotal),
                icon: Icons.today,
                color: const Color(0xFF1A73E8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SummaryCard(
                label: 'This Week',
                value: formatDurationFull(weekTotal),
                icon: Icons.date_range,
                color: const Color(0xFF34A853),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SummaryCard(
                label: 'This Month',
                value: formatDurationFull(monthTotal),
                icon: Icons.calendar_month,
                color: const Color(0xFFFBBC04),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const SummaryCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
