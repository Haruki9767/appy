import 'package:flutter/material.dart';
import '../services/statistics_service.dart';
import '../theme/app_theme.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final todayStats = StatisticsService.getTodayStats();
    final weekStats = StatisticsService.getWeekStats();
    final totalStats = StatisticsService.getTotalStats();
    final last7Days = StatisticsService.getLast7DaysData();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Today'),
              const SizedBox(height: 16),
              _buildStatsCard(
                context,
                [
                  _StatItem(
                    icon: '🍅',
                    value: todayStats['focusSessions'].toString(),
                    label: 'Focus Sessions',
                  ),
                  _StatItem(
                    icon: '⏱️',
                    value: todayStats['totalFocusMinutes'].toString(),
                    label: 'Focus Minutes',
                  ),
                  _StatItem(
                    icon: '☕',
                    value: todayStats['breakSessions'].toString(),
                    label: 'Breaks Taken',
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _buildSectionTitle('This Week'),
              const SizedBox(height: 16),
              _buildWeekChart(context, last7Days),
              const SizedBox(height: 16),
              _buildStatsCard(
                context,
                [
                  _StatItem(
                    icon: '📊',
                    value: weekStats['focusSessions'].toString(),
                    label: 'Total Sessions',
                  ),
                  _StatItem(
                    icon: '⏱️',
                    value: weekStats['totalFocusMinutes'].toString(),
                    label: 'Total Minutes',
                  ),
                  _StatItem(
                    icon: '📈',
                    value: weekStats['dailyAverage'].toString(),
                    label: 'Daily Average',
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _buildSectionTitle('All Time'),
              const SizedBox(height: 16),
              _buildStatsCard(
                context,
                [
                  _StatItem(
                    icon: '🎯',
                    value: totalStats['totalFocusSessions'].toString(),
                    label: 'Total Sessions',
                  ),
                  _StatItem(
                    icon: '⏰',
                    value: totalStats['totalFocusHours'].toString(),
                    label: 'Total Hours',
                  ),
                  _StatItem(
                    icon: '🏆',
                    value: (totalStats['totalFocusSessions'] ~/ 4).toString(),
                    label: 'Achievements',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context, List<_StatItem> items) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((item) {
          return Expanded(
            child: Column(
              children: [
                Text(item.icon, style: const TextStyle(fontSize: 32)),
                const SizedBox(height: 8),
                Text(
                  item.value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWeekChart(BuildContext context, List<Map<String, dynamic>> data) {
    final maxSessions = data.map((d) => d['focusSessions'] as int).reduce((a, b) => a > b ? a : b);
    final chartHeight = maxSessions > 0 ? 150.0 : 100.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Daily Focus Sessions',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: chartHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: data.map((dayData) {
                final sessions = dayData['focusSessions'] as int;
                final barHeight = maxSessions > 0 ? (sessions / maxSessions) * (chartHeight - 40) : 10.0;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (sessions > 0)
                          Text(
                            sessions.toString(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.focusRed,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Container(
                          height: barHeight.clamp(10.0, chartHeight - 40),
                          decoration: BoxDecoration(
                            gradient: AppTheme.getFocusGradient(),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          dayData['dayName'],
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppTheme.textSecondary,
                          ),
                        ),
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
  final String icon;
  final String value;
  final String label;

  _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });
}
