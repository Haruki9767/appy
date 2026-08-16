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
    // Initialize Hive
    await Hive.initFlutter();
    print('✅ Hive initialized');
    
    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(PomodoroSessionAdapter());
      print('✅ PomodoroSessionAdapter registered');
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(SessionTypeAdapter());
      print('✅ SessionTypeAdapter registered');
    }
    
    // Initialize Storage
    await StorageService.init();
    print('✅ StorageService initialized');
    
  } catch (e, stacktrace) {
    print('❌ Initialization error: $e');
    print('Stacktrace: $stacktrace');
    runApp(ErrorApp(error: 'Failed to initialize: $e'));
    return;
  }
  
  runApp(const FocusFlowApp());
}

// Error screen if initialization fails
class ErrorApp extends StatelessWidget {
  final String error;
  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'FocusFlow',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Restart the app
                    runApp(const FocusFlowApp());
                  },
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
        initialRoute: '/',
        routes: {
          '/': (context) => const HomeScreen(),
          '/statistics': (context) => const StatisticsScreen(),
          '/achievements': (context) => const AchievementsScreen(),
          '/projects': (context) => const ProjectsScreen(),
          '/goals': (context) => const GoalsScreen(),
          '/reports': (context) => const ReportsScreen(),
          '/settings': (context) => const SettingsScreen(),
        },
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = const [
    TimerScreen(),
    StatisticsScreen(),
    AchievementsScreen(),
    ProjectsScreen(),
    GoalsScreen(),
    ReportsScreen(),
    SettingsScreen(),
  ];

  final List<BottomNavigationBarItem> _bottomNavItems = const [
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
      body: _screens[_currentIndex],
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
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppTheme.focusRed,
            unselectedItemColor: AppTheme.textSecondary,
            selectedLabelStyle: const TextStyle(
              fontSize: 10, 
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(fontSize: 10),
            items: _bottomNavItems,
          ),
        ),
      ),
    );
  }
}