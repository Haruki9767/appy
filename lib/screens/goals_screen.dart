import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';
import '../services/statistics_service.dart';
import '../theme/app_theme.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  int _dailyGoal = 2;
  int _weeklyGoal = 10;
  int _monthlyGoal = 40;
  int _dailyMinutes = 0;
  int _weeklyMinutes = 0;
  int _monthlyMinutes = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final dailyGoal = await StorageService.getGoal('dailyGoal', 2);
    final weeklyGoal = await StorageService.getGoal('weeklyGoal', 10);
    final monthlyGoal = await StorageService.getGoal('monthlyGoal', 40);
    
    final stats = StatisticsService.getTotalStats();
    final weekStats = StatisticsService.getWeekStats();
    final monthStats = StatisticsService.getMonthStats();

    setState(() {
      _dailyGoal = dailyGoal;
      _weeklyGoal = weeklyGoal;
      _monthlyGoal = monthlyGoal;
      _dailyMinutes = stats['todayFocusMinutes'] ?? 0;
      _weeklyMinutes = weekStats['totalFocusMinutes'] ?? 0;
      _monthlyMinutes = monthStats['totalFocusMinutes'] ?? 0;
    });
  }

  Future<void> _updateGoal(String key, int value) async {
    await StorageService.setGoal(key, value);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Goals'),
        backgroundColor: AppTheme.backgroundColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildGoalCard(
              title: 'Daily Goal',
              icon: Icons.today,
              current: _dailyMinutes,
              target: _dailyGoal * 60,
              unit: 'minutes',
              color: AppTheme.focusRed,
              onUpdate: (value) => _updateGoal('dailyGoal', value),
            ),
            const SizedBox(height: 16),
            
            _buildGoalCard(
              title: 'Weekly Goal',
              icon: Icons.weekend,
              current: _weeklyMinutes,
              target: _weeklyGoal * 60,
              unit: 'minutes',
              color: AppTheme.breakGreen,
              onUpdate: (value) => _updateGoal('weeklyGoal', value),
            ),
            const SizedBox(height: 16),
            
            _buildGoalCard(
              title: 'Monthly Goal',
              icon: Icons.calendar_month,
              current: _monthlyMinutes,
              target: _monthlyGoal * 60,
              unit: 'minutes',
              color: AppTheme.longBreakPurple,
              onUpdate: (value) => _updateGoal('monthlyGoal', value),
            ),
            const SizedBox(height: 24),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📊 Progress Summary',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildProgressRow('Daily', _dailyMinutes, _dailyGoal * 60, AppTheme.focusRed),
                  _buildProgressRow('Weekly', _weeklyMinutes, _weeklyGoal * 60, AppTheme.breakGreen),
                  _buildProgressRow('Monthly', _monthlyMinutes, _monthlyGoal * 60, AppTheme.longBreakPurple),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard({
    required String title,
    required IconData icon,
    required int current,
    required int target,
    required String unit,
    required Color color,
    required Function(int) onUpdate,
  }) {
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    final isComplete = progress >= 1.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: isComplete 
            ? Border.all(color: AppTheme.successGreen, width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              if (isComplete)
                const Icon(
                  Icons.check_circle,
                  color: AppTheme.successGreen,
                  size: 24,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${(current / 60).toStringAsFixed(1)}h / ${(target / 60).toStringAsFixed(0)}h',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).round()}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isComplete ? AppTheme.successGreen : color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                isComplete ? AppTheme.successGreen : color,
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () {
                  final value = (target ~/ 60);
                  if (value > 1) onUpdate(value - 1);
                },
                color: AppTheme.textSecondary,
              ),
              Text(
                '${target ~/ 60}h',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () {
                  final value = (target ~/ 60);
                  if (value < 24) onUpdate(value + 1);
                },
                color: AppTheme.textSecondary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRow(String label, int current, int target, Color color) {
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    final isComplete = progress >= 1.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isComplete ? AppTheme.successGreen : color,
                ),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(progress * 100).round()}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isComplete ? AppTheme.successGreen : color,
            ),
          ),
        ],
      ),
    );
  }
}