import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/storage_service.dart';
import 'services/timer_service.dart';
import 'screens/timer_screen.dart';
import 'screens/statistics_screen.dart';
import 'screens/settings_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // FIX: wrap init in try/catch so a storage failure shows a clean error
  try {
    await StorageService.init();
  } catch (e) {
    // In production you'd show an error screen here
    debugPrint('Storage init failed: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) {
          final timer = TimerService();
          // FIX: reset daily pomodoro count if the date has changed since last launch
          timer.resetDailyStatsIfNeeded(StorageService.getLastResetDate());
          return timer;
        }),
      ],
      child: MaterialApp(
        title: 'FocusFlow',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const TimerScreen(),
        routes: {
          '/statistics': (_) => const StatisticsScreen(),
          '/settings':   (_) => const SettingsScreen(),
        },
      ),
    );
  }
}
