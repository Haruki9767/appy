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
  
  // Initialize storage
  await StorageService.init();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TimerService()),
      ],
      child: MaterialApp(
        title: 'FocusFlow',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const TimerScreen(),
        routes: {
          '/statistics': (context) => const StatisticsScreen(),
          '/settings': (context) => const SettingsScreen(),
        },
      ),
    );
  }
}
