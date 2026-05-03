import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'providers/time_provider.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
import 'widgets/edit_record_dialog.dart';
import 'dart:io' show Platform;

const _kStartScreen = String.fromEnvironment('START_SCREEN', defaultValue: 'home');

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(
    ChangeNotifierProvider(create: (_) => TimeProvider(), child: const MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HourLog',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A73E8)),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: _kStartScreen == 'history'
          ? const HistoryScreen()
          : _kStartScreen == 'edit'
              ? const _EditScreenLauncher()
              : const HomeScreen(),
    );
  }
}

class _EditScreenLauncher extends StatefulWidget {
  const _EditScreenLauncher({super.key});

  @override
  State<_EditScreenLauncher> createState() => _EditScreenLauncherState();
}

class _EditScreenLauncherState extends State<_EditScreenLauncher> {
  bool _dialogShown = false;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TimeProvider>(context);

    if (!_dialogShown && !provider.isLoading && provider.records.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        _dialogShown = true;
        await showEditRecordDialog(context, provider.records.first);
      });
    }

    return const HomeScreen();
  }
}
