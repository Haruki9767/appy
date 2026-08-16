import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/statistics_service.dart';
import '../theme/app_theme.dart';
import '../utils/helpers.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final todayStats = StatisticsService.getTodayStats();
    final weekStats = StatisticsService.getWeekStats();
    final totalStats = StatisticsService.getTotalStats();
    final last7Days = StatisticsService.getLast7DaysData();
    final streak = StatisticsService.getStreak();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        backgroundColor: AppTheme.backgroundColor,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Today'),
              const SizedBox(height: 16),
              _statsCard([
                _StatItem('🍅', todayStats['focusSessions'].toString(), 'Focus Sessions'),
                _StatItem('⏱️', todayStats['totalFocusMinutes'].toString(), 'Focus Minutes'),
                _StatItem('🔥', streak.toString(), 'Day Streak'),
              ]),
              const SizedBox(height: 32),
              
              _sectionTitle('This Week'),
              const SizedBox(height: 16),
              _weekChart(last7Days),
              const SizedBox(height: 16),
              _statsCard([
                _StatItem('📊', weekStats['focusSessions'].toString(), 'Total Sessions'),
                _StatItem('⏱️', weekStats['totalFocusMinutes'].toString(), 'Total Minutes'),
                _StatItem('📈', (weekStats['dailyAverage'] as double).toStringAsFixed(1), 'Daily Avg'),
              ]),
              const SizedBox(height: 32),
              
              _sectionTitle('All Time'),
              const SizedBox(height: 16),
              _statsCard([
                _StatItem('🎯', totalStats['totalFocusSessions'].toString(), 'Total Sessions'),
                _StatItem('⏰', (totalStats['totalFocusHours'] as double).toStringAsFixed(1), 'Total Hours'),
                _StatItem('📅', totalStats['totalSessions'].toString(), 'All Sessions'),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary));

  Widget _statsCard(List<_StatItem> items) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((item) => Expanded(
          child: Column(children: [
            Text(item.icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(item.value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            const SizedBox(height: 4),
            Text(item.label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ]),
        )).toList(),
      ),
    );
  }

  Widget _weekChart(List<Map<String, dynamic>> data) {
    final maxSessions = data
        .map((d) => d['focusSessions'] as int)
        .fold(0, (a, b) => a > b ? a : b);
    const chartHeight = 150.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          const Text('Daily Focus Sessions',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          const SizedBox(height: 20),
          SizedBox(
            height: chartHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: data.map((d) {
                final sessions = d['focusSessions'] as int;
                final barH = maxSessions > 0
                    ? ((sessions / maxSessions) * (chartHeight - 40)).clamp(10.0, chartHeight - 40)
                    : 10.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (sessions > 0) Text(sessions.toString(),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.focusRed)),
                        const SizedBox(height: 4),
                        Container(
                          height: barH,
                          decoration: BoxDecoration(
                            gradient: AppTheme.getFocusGradient(),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(d['dayName'] as String,
                            style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem {
  final String icon, value, label;
  const _StatItem(this.icon, this.value, this.label);
}