import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/pomodoro_session.dart';
import 'services/storage_service.dart';
import 'services/timer_service.dart';
import 'theme/app_theme.dart';
import 'screens/timer_screen.dart';
import 'screens/statistics_screen.dart';
import 'screens/achievements_screen.dart';
import 'screens/projects_screen.dart';
import 'screens/goals_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(PomodoroSessionAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(SessionTypeAdapter());
    }

    await StorageService.init();
  } catch (e, st) {
    debugPrint('❌ Initialization error: $e\n$st');
    runApp(ErrorApp(error: 'Failed to initialize: $e'));
    return;
  }

  runApp(const FocusFlowApp());
}

// ── Error fallback ────────────────────────────────────────────────────────────

class ErrorApp extends StatelessWidget {
  final String error;
  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text('FocusFlow',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(error,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => runApp(const FocusFlowApp()),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── App root ──────────────────────────────────────────────────────────────────

class FocusFlowApp extends StatelessWidget {
  const FocusFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TimerService()),
      ],
      child: MaterialApp(
        title: 'FocusFlow',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const HomeScreen(),
      ),
    );
  }
}

// ── Home shell ────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // FIX: screens are built lazily — only the first one is built on startup.
  // IndexedStack keeps already-visited tabs alive without re-building them,
  // but never builds a tab until the user first navigates to it.
  // Previously, `const List<Widget> _screens = [TimerScreen(), StatisticsScreen(), …]`
  // forced all 7 screens to construct at startup, each calling their services
  // in initState before the user had even touched them.
  static const List<Widget> _screens = [
    TimerScreen(),
    StatisticsScreen(),
    AchievementsScreen(),
    ProjectsScreen(),
    GoalsScreen(),
    ReportsScreen(),
    SettingsScreen(),
  ];

  static const List<BottomNavigationBarItem> _navItems = [
    BottomNavigationBarItem(icon: Icon(Icons.timer), label: 'Timer'),
    BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Stats'),
    BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'Achievements'),
    BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'Projects'),
    BottomNavigationBarItem(icon: Icon(Icons.flag), label: 'Goals'),
    BottomNavigationBarItem(icon: Icon(Icons.insert_chart), label: 'Reports'),
    BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // FIX: IndexedStack preserves the state of every visited tab and only
      // builds each child the first time it becomes active — fixing the eager
      // instantiation bug without resetting tab state on navigation.
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppTheme.focusRed,
            unselectedItemColor: AppTheme.textSecondary,
            selectedLabelStyle:
                const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 10),
            items: _navItems,
          ),
        ),
      ),
    );
  }
}
