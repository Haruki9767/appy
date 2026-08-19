import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
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
  late int  _focusDuration;
  late int  _shortBreak;
  late int  _longBreak;
  late bool _autoStartBreaks;
  late bool _autoStartFocus;
  late bool _soundEnabled;
  bool _isExporting = false;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _focusDuration   = StorageService.getSetting<int>('focusDuration', 25);
    _shortBreak      = StorageService.getSetting<int>('shortBreak', 5);
    _longBreak       = StorageService.getSetting<int>('longBreak', 15);
    _autoStartBreaks = StorageService.getSetting<bool>('autoStartBreaks', false);
    _autoStartFocus  = StorageService.getSetting<bool>('autoStartFocus', false);
    _soundEnabled    = StorageService.getSetting<bool>('soundEnabled', true);
  }

  // ── Save helpers ──────────────────────────────────────────────────────────

  Future<void> _saveDuration(String key, int value) async {
    await StorageService.setSetting(key, value);
    if (mounted) {
      final timer = context.read<TimerService>();
      if (key == 'focusDuration' &&
          timer.currentType == SessionType.focus &&
          timer.isIdle) {
        timer.switchType(SessionType.focus);
      }
    }
  }

  Future<void> _saveBool(String key, bool value) async =>
      StorageService.setSetting(key, value);

  // ── Reset ─────────────────────────────────────────────────────────────────

  void _showResetDialog() {
    // Capture messenger before the async gap (avoids use-after-dispose)
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset All Data?'),
        content: const Text(
          'This will permanently delete all session history, projects, '
          'achievements and statistics. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            onPressed: () async {
              Navigator.pop(ctx);
              await StorageService.clearAll();
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('All data has been reset'),
                  backgroundColor: AppTheme.successGreen,
                ),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  // ── Export ────────────────────────────────────────────────────────────────

  Future<void> _exportData() async {
    setState(() => _isExporting = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final jsonString = await StorageService.exportData();

      // Write to a temp file so share_plus can attach it
      final dir  = await getTemporaryDirectory();
      final file = File('${dir.path}/focusflow_backup.json');
      await file.writeAsString(jsonString);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json')],
        subject: 'FocusFlow Backup',
        text:    'FocusFlow data backup – ${DateTime.now().toLocal()}',
      );
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: AppTheme.errorRed,
        ));
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  // ── Import ────────────────────────────────────────────────────────────────

  Future<void> _importData() async {
    final messenger = ScaffoldMessenger.of(context);

    // Ask user to confirm before wiping existing data
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Backup?'),
        content: const Text(
          'Importing will replace ALL current data with the contents of the '
          'backup file. This cannot be undone.\n\nContinue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppTheme.focusRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isImporting = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type:          FileType.custom,
        allowedExtensions: ['json'],
        withData:      true,
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _isImporting = false);
        return;
      }

      final bytes = result.files.first.bytes;
      if (bytes == null) throw Exception('Could not read file');

      final jsonString = String.fromCharCodes(bytes);
      await StorageService.importData(jsonString);

      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Data imported successfully! Restart the app to see changes.'),
            backgroundColor: AppTheme.successGreen,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } on FormatException catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(
          content: Text('Invalid backup file: ${e.message}'),
          backgroundColor: AppTheme.errorRed,
        ));
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(
          content: Text('Import failed: $e'),
          backgroundColor: AppTheme.errorRed,
        ));
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

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

              // ── Timer durations ─────────────────────────────────────────
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

              // ── Preferences ─────────────────────────────────────────────
              _sectionTitle('Preferences'),
              const SizedBox(height: 16),
              _settingTile(
                'Auto-start breaks',
                'Start break timer automatically after focus',
                _autoStartBreaks,
                (v) { setState(() => _autoStartBreaks = v); _saveBool('autoStartBreaks', v); },
              ),
              _settingTile(
                'Auto-start focus',
                'Return to focus automatically after break',
                _autoStartFocus,
                (v) { setState(() => _autoStartFocus = v); _saveBool('autoStartFocus', v); },
              ),
              _settingTile(
                'Sound notifications',
                'Play sound when timer completes',
                _soundEnabled,
                (v) { setState(() => _soundEnabled = v); _saveBool('soundEnabled', v); },
              ),
              const SizedBox(height: 32),

              // ── Data ────────────────────────────────────────────────────
              _sectionTitle('Data'),
              const SizedBox(height: 16),

              // Export
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isExporting ? null : _exportData,
                  icon: _isExporting
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.upload_outlined, color: Colors.white),
                  label: Text(
                    _isExporting ? 'Exporting…' : 'Export Data',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.breakGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Import
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isImporting ? null : _importData,
                  icon: _isImporting
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.download_outlined, color: Colors.white),
                  label: Text(
                    _isImporting ? 'Importing…' : 'Import Data',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.longBreakPurple,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── About ───────────────────────────────────────────────────
              _sectionTitle('About'),
              const SizedBox(height: 16),
              _infoCard('Version', '1.0.0', Icons.info_outline),
              const SizedBox(height: 12),
              _infoCard('Developer', 'FocusFlow Team', Icons.code),
              const SizedBox(height: 32),

              // ── Danger zone ─────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _showResetDialog,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppTheme.errorRed),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Reset All Data',
                    style: TextStyle(
                        color: AppTheme.errorRed, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Widgets ───────────────────────────────────────────────────────────────

  Widget _sectionTitle(String t) => Text(
        t,
        style: const TextStyle(
            fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
      );

  Widget _durationCard(String title, int value, ValueChanged<int> onChange) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary)),
          Row(children: [
            IconButton(
              onPressed: () { if (value > 1) onChange(value - 1); },
              icon: const Icon(Icons.remove_circle_outline),
              color: AppTheme.textSecondary,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(8)),
              child: Text('$value min',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary)),
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

  Widget _settingTile(
      String title, String subtitle, bool value, ValueChanged<bool> onChange) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ]),
        ),
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
          Text(label,
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary)),
        ]),
      ]),
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      );
}
