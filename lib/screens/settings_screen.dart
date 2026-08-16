import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../services/timer_service.dart';
import '../theme/app_theme.dart';
import '../models/pomodoro_session.dart';
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // FIX: read actual saved values on init instead of hardcoding
  late int _focusDuration;
  late int _shortBreak;
  late int _longBreak;
  late bool _autoStartBreaks;
  late bool _autoStartFocus;
  late bool _soundEnabled;

  @override
  void initState() {
    super.initState();
    _focusDuration  = StorageService.getSetting<int>('focusDuration', 25);
    _shortBreak     = StorageService.getSetting<int>('shortBreak', 5);
    _longBreak      = StorageService.getSetting<int>('longBreak', 15);
    _autoStartBreaks = StorageService.getSetting<bool>('autoStartBreaks', false);
    _autoStartFocus  = StorageService.getSetting<bool>('autoStartFocus', false);
    _soundEnabled    = StorageService.getSetting<bool>('soundEnabled', true);
  }

  Future<void> _saveDuration(String key, int value) async {
    await StorageService.setSetting(key, value);
    // Also update TimerService if it's the current mode
    if (mounted) {
      final timer = context.read<TimerService>();
      if (key == 'focusDuration' && timer.currentType == SessionType.focus && timer.isIdle) {
        timer.switchType(SessionType.focus);
      }
    }
  }

  Future<void> _saveBool(String key, bool value) async {
    await StorageService.setSetting(key, value);
  }

  void _showResetDialog() {
    // FIX: capture ScaffoldMessenger BEFORE opening dialog
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset All Data?'),
        content: const Text(
          'This will delete all session history and statistics. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // close dialog first
              await StorageService.clearAll(); // FIX: actually reset data
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('All data has been reset'),
                  backgroundColor: AppTheme.successGreen,
                ),
              );
            },
            child: const Text('Reset', style: TextStyle(color: AppTheme.errorRed)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Timer Duration'),
              const SizedBox(height: 16),
              _durationCard('🍅 Focus Session', _focusDuration, (v) {
                setState(() => _focusDuration = v);
                _saveDuration('focusDuration', v);
              }),
              const SizedBox(height: 12),
              _durationCard('☕ Short Break', _shortBreak, (v) {
                setState(() => _shortBreak = v);
                _saveDuration('shortBreak', v);
              }),
              const SizedBox(height: 12),
              _durationCard('🌿 Long Break', _longBreak, (v) {
                setState(() => _longBreak = v);
                _saveDuration('longBreak', v);
              }),
              const SizedBox(height: 32),
              _sectionTitle('Preferences'),
              const SizedBox(height: 16),
              _settingTile('Auto-start breaks', 'Start break timer automatically after focus', _autoStartBreaks, (v) {
                setState(() => _autoStartBreaks = v);
                _saveBool('autoStartBreaks', v);
              }),
              _settingTile('Auto-start focus', 'Return to focus automatically after break', _autoStartFocus, (v) {
                setState(() => _autoStartFocus = v);
                _saveBool('autoStartFocus', v);
              }),
              _settingTile('Sound notifications', 'Play sound when timer completes', _soundEnabled, (v) {
                setState(() => _soundEnabled = v);
                _saveBool('soundEnabled', v);
              }),
              const SizedBox(height: 32),
              _sectionTitle('About'),
              const SizedBox(height: 16),
              _infoCard('Version', '1.0.0', Icons.info_outline),
              const SizedBox(height: 12),
              _infoCard('Developer', 'FocusFlow Team', Icons.code),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _showResetDialog,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppTheme.errorRed),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Reset All Data',
                      style: TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary));

  Widget _durationCard(String title, int value, ValueChanged<int> onChange) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
          Row(children: [
            IconButton(
              onPressed: () { if (value > 1) onChange(value - 1); },
              icon: const Icon(Icons.remove_circle_outline),
              color: AppTheme.textSecondary,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: AppTheme.backgroundColor, borderRadius: BorderRadius.circular(8)),
              child: Text('$value min',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            ),
            IconButton(
              onPressed: () { if (value < 120) onChange(value + 1); },
              icon: const Icon(Icons.add_circle_outline),
              color: AppTheme.textSecondary,
            ),
          ]),
        ],
      ),
    );
  }

  Widget _settingTile(String title, String subtitle, bool value, ValueChanged<bool> onChange) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        ])),
        Switch(value: value, onChanged: onChange, activeTrackColor: AppTheme.focusRed),
      ]),
    );
  }

  Widget _infoCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Row(children: [
        Icon(icon, color: AppTheme.focusRed),
        const SizedBox(width: 16),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
        ]),
      ]),
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
  );
}
