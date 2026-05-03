import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/time_provider.dart';
import '../widgets/edit_record_dialog.dart';
import 'history_screen.dart';
import 'components/home_screen_components.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TimeProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleCheckAction(TimeProvider provider) async {
    if (provider.isCheckedIn) {
      final confirmed = await _showConfirmDialog(
        title: 'Check Out',
        message: 'Are you sure you want to check out?',
        confirmLabel: 'Check Out',
        confirmColor: Colors.red.shade600,
      );
      if (confirmed == true) {
        final success = await provider.checkOut();
        if (success && mounted) {
          _showSnackBar('Checked out successfully!', Colors.green);
        }
      }
    } else {
      final success = await provider.checkIn();
      if (success && mounted) {
        _showSnackBar('Checked in successfully!', Colors.blue);
      }
    }
  }

  Future<void> _handleEditActive(TimeProvider provider) async {
    final active = provider.activeRecord;
    if (active == null) return;
    final updated = await showEditRecordDialog(context, active);
    if (updated != null && mounted) {
      final success = await provider.updateRecord(updated);
      if (success && mounted) {
        _showSnackBar('Check-in time updated!', Colors.green);
      }
    }
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Consumer<TimeProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Show errors as a snackbar (one-time)
          if (provider.error != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && provider.error != null) {
                _showSnackBar(provider.error!, Colors.red.shade600);
                provider.clearError();
              }
            });
          }

          final todayTotal = provider.getTotalForDay(DateTime.now());
          final weekTotal = provider.getTotalForCurrentWeek();
          final monthTotal = provider.getTotalForCurrentMonth();

          return CustomScrollView(
            slivers: [
              HomeAppBar(
                onHistoryTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider.value(
                      value: provider,
                      child: const HistoryScreen(),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      StatusCard(
                        isCheckedIn: provider.isCheckedIn,
                        activeRecord: provider.activeRecord,
                        pulseAnimation: _pulseAnimation,
                        onEdit: () => _handleEditActive(provider),
                      ),
                      const SizedBox(height: 28),
                      CheckButton(
                        isCheckedIn: provider.isCheckedIn,
                        onPressed: () => _handleCheckAction(provider),
                      ),
                      const SizedBox(height: 32),
                      SummarySection(
                        todayTotal: todayTotal,
                        weekTotal: weekTotal,
                        monthTotal: monthTotal,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
