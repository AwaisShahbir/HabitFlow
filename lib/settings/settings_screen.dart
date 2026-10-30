import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:habitflow/core/notification_service.dart';
import 'package:habitflow/core/sound_service.dart';
import 'package:habitflow/core/app_settings_provider.dart';
import 'package:habitflow/core/theme_provider.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:habitflow/core/user_profile_provider.dart';
import 'package:habitflow/habits/habit_completion_model.dart';
import 'package:habitflow/habits/widgets/profile_bottom_sheet.dart';
import 'package:habitflow/habits/habit_model.dart';
import 'package:habitflow/habits/habit_providers.dart';
import 'package:habitflow/habits/widgets/plant_data.dart';
import 'package:habitflow/onboarding/onboarding_assets.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreference();
  }

  Future<void> _loadNotificationPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('habit_reminders_enabled') ?? true;
      if (mounted) {
        setState(() {
          _notificationsEnabled = enabled;
        });
      }
    } catch (_) {}
  }

  Future<void> _setNotificationsEnabled(bool val) async {
    setState(() {
      _notificationsEnabled = val;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('habit_reminders_enabled', val);
    } catch (_) {}

    if (val) {
      await NotificationService().requestPermissions();
      final habits = await ref.read(habitRepositoryProvider).getAllHabits();
      for (final h in habits) {
        if (h.reminderTime != null) {
          await NotificationService().scheduleHabitReminder(
            habitId: h.id,
            habitName: h.name,
            timeString: h.reminderTime!,
            scheduledDays: h.scheduledDays,
          );
        }
      }
    } else {
      await NotificationService().cancelAllReminders();
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            val ? 'Habit reminders enabled' : 'All habit reminders disabled',
          ),
          backgroundColor:
              val ? const Color(0xFF15803D) : const Color(0xFF475569),
        ),
      );
    }
  }

  void _showStartWeekBottomSheet(BuildContext context) {
    final currentDay = ref.read(startWeekOnProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Start Week On',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Select the first day of the week for your dashboard and calendar',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 16),
                _buildDayOptionTile(
                  context,
                  title: 'Monday',
                  subtitle: 'International standard (ISO 8601)',
                  isSelected: currentDay == 'Monday',
                  onTap: () async {
                    await ref.read(startWeekOnProvider.notifier).setDay('Monday');
                    if (context.mounted) Navigator.pop(ctx);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Week now starts on Monday'),
                          backgroundColor: Color(0xFF15803D),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 10),
                _buildDayOptionTile(
                  context,
                  title: 'Sunday',
                  subtitle: 'Common in Americas & Asia',
                  isSelected: currentDay == 'Sunday',
                  onTap: () async {
                    await ref.read(startWeekOnProvider.notifier).setDay('Sunday');
                    if (context.mounted) Navigator.pop(ctx);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Week now starts on Sunday'),
                          backgroundColor: Color(0xFF15803D),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDayOptionTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF166534).withOpacity(0.3) : const Color(0xFFDCFCE7))
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF15803D)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? const Color(0xFF15803D)
                          : (isDark ? Colors.white : const Color(0xFF0F172A)),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF15803D),
                size: 22,
              )
            else
              Icon(
                Icons.circle_outlined,
                color: isDark ? const Color(0xFF64748B) : const Color(0xFFCBD5E1),
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  void _showAppearanceBottomSheet(BuildContext context) {
    final currentMode = ref.read(themeModeProvider);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Appearance',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildThemeOption(
                  ctx,
                  title: 'Light Theme',
                  icon: Icons.light_mode_rounded,
                  mode: ThemeMode.light,
                  isSelected: currentMode == ThemeMode.light,
                ),
                const Divider(),
                _buildThemeOption(
                  ctx,
                  title: 'Dark Theme',
                  icon: Icons.dark_mode_rounded,
                  mode: ThemeMode.dark,
                  isSelected: currentMode == ThemeMode.dark,
                ),
                const Divider(),
                _buildThemeOption(
                  ctx,
                  title: 'System Default',
                  icon: Icons.brightness_auto_rounded,
                  mode: ThemeMode.system,
                  isSelected: currentMode == ThemeMode.system,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(
    BuildContext context, {
    required String title,
    required IconData icon,
    required ThemeMode mode,
    required bool isSelected,
  }) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? const Color(0xFF15803D) : const Color(0xFF64748B)),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFF15803D)) : null,
      onTap: () {
        ref.read(themeModeProvider.notifier).setThemeMode(mode);
        Navigator.pop(context);
      },
    );
  }

  void _showResetConfirmationBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Drag Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Screen 15 Exact 3D Red Trash Bin Illustration
              SizedBox(
                width: 140,
                height: 120,
                child: Image.memory(
                  kTrashBinBytes,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                'Reset All Data',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10),

              // Subtitle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'This will permanently delete all your habits, progress, settings and reminders. This action cannot be undone.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Reset Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await NotificationService().cancelAllReminders();
                    final repo = ref.read(habitRepositoryProvider);
                    await repo.resetAllData();
                    await ref.read(habitsNotifierProvider.notifier).refresh();
                    ref.invalidate(dateCompletionsNotifierProvider);
                    ref.invalidate(appAnalyticsProvider);

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('All data was successfully reset.'),
                          backgroundColor: Color(0xFFDC2626),
                        ),
                      );
                    }
                  },
                  child: const Text(
                    'Reset All Data',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Cancel Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLogoutConfirmationBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Drag Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // Logout Icon Circle
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF3B1E2B) : const Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.logout_rounded,
                  size: 40,
                  color: Color(0xFFDC2626),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                'Log Out',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10),

              // Subtitle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Are you sure you want to log out of HabitFlow? You will return to the welcome screen.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Log Out Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    try {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('has_completed_onboarding', false);
                    } catch (_) {}
                    await ref.read(userProfileProvider.notifier).resetProfile();
                    await NotificationService().cancelAllReminders();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Logged out successfully'),
                          backgroundColor: Color(0xFF15803D),
                        ),
                      );
                      context.go('/onboarding');
                    }
                  },
                  child: const Text(
                    'Log Out',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Cancel Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _exportData(BuildContext context) async {
    final habits = await ref.read(habitRepositoryProvider).getAllHabits(includeArchived: true);
    final completions = await ref.read(habitRepositoryProvider).getAllCompletions();
    final profile = ref.read(userProfileProvider);

    final backupPayload = {
      'app': 'HabitFlow',
      'version': 1,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'profile': profile.toMap(),
      'habits': habits.map((h) => HabitModel.fromEntity(h).toMap()).toList(),
      'completions': completions.map((c) => HabitCompletionModel.fromEntity(c).toMap()).toList(),
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(backupPayload);

    if (!mounted) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF9C3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.file_upload_outlined, color: Color(0xFFCA8A04), size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Export Data Backup',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Full snapshot of habits, streaks & history',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Statistics summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildBackupStat('Habits', '${habits.length}', Icons.check_circle_outline, const Color(0xFF16A34A)),
                    _buildBackupStat('Logs', '${completions.length}', Icons.history, const Color(0xFF2563EB)),
                    _buildBackupStat('Profile', profile.name, Icons.person_outline, const Color(0xFF9333EA)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Share / Save File Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.share_rounded),
                  label: const Text('Share / Save Backup File', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    try {
                      final tempDir = await getTemporaryDirectory();
                      final nowStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
                      final file = File('${tempDir.path}/habitflow_backup_$nowStr.json');
                      await file.writeAsString(jsonString);
                      await Share.shareXFiles(
                        [XFile(file.path)],
                        subject: 'HabitFlow Backup ($nowStr)',
                        text: 'HabitFlow complete data backup including habits, completions, and user profile.',
                      );
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to share file: $e')),
                        );
                      }
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Copy to Clipboard Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                    side: BorderSide(color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.copy_rounded, size: 20),
                  label: const Text('Copy JSON to Clipboard', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: jsonString));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Complete JSON backup copied to clipboard!'),
                        backgroundColor: Color(0xFF15803D),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _importData(BuildContext context) {
    final controller = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (bottomContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(bottomContext).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFDBEAFE),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(Icons.file_download_outlined, color: Color(0xFF2563EB), size: 26),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Import Data Backup',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Restore habits, streaks & history',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Textfield with Paste Button
                      Stack(
                        children: [
                          TextField(
                            controller: controller,
                            maxLines: 7,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            decoration: InputDecoration(
                              hintText: 'Paste backup JSON here...',
                              hintStyle: TextStyle(
                                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                              ),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                ),
                              ),
                              contentPadding: const EdgeInsets.all(16),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: TextButton.icon(
                              style: TextButton.styleFrom(
                                backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                minimumSize: Size.zero,
                              ),
                              icon: const Icon(Icons.paste_rounded, size: 14),
                              label: const Text('Paste', style: TextStyle(fontSize: 12)),
                              onPressed: () async {
                                final data = await Clipboard.getData('text/plain');
                                if (data?.text != null && data!.text!.isNotEmpty) {
                                  controller.text = data.text!;
                                  setModalState(() {});
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Import Options (Merge vs Replace All)
                      Row(
                        children: [
                          // Option 1: Merge
                          Expanded(
                            child: SizedBox(
                              height: 50,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                                  side: BorderSide(
                                    color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                                  ),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                onPressed: () => _executeImport(context, controller.text, replaceAll: false, ctxToClose: ctx),
                                child: const Text('Merge Existing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Option 2: Clean Restore
                          Expanded(
                            child: SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF16A34A),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                onPressed: () => _executeImport(context, controller.text, replaceAll: true, ctxToClose: ctx),
                                child: const Text('Restore All', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _executeImport(
    BuildContext context,
    String rawJson, {
    required bool replaceAll,
    required BuildContext ctxToClose,
  }) async {
    final text = rawJson.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please paste a backup JSON payload first.')),
      );
      return;
    }

    try {
      final decoded = jsonDecode(text);
      List<dynamic> habitListRaw = [];
      List<dynamic> completionListRaw = [];
      Map<String, dynamic>? profileRaw;

      if (decoded is Map<String, dynamic>) {
        if (decoded['habits'] is List) {
          habitListRaw = decoded['habits'] as List<dynamic>;
        }
        if (decoded['completions'] is List) {
          completionListRaw = decoded['completions'] as List<dynamic>;
        }
        if (decoded['profile'] is Map<String, dynamic>) {
          profileRaw = decoded['profile'] as Map<String, dynamic>;
        }
      } else if (decoded is List) {
        habitListRaw = decoded;
      }

      if (habitListRaw.isEmpty && completionListRaw.isEmpty) {
        throw const FormatException('No valid habits or completions found in backup.');
      }

      final repo = ref.read(habitRepositoryProvider);

      if (replaceAll) {
        await repo.resetAllData();
      }

      // Upsert habits
      int habitsImported = 0;
      for (final item in habitListRaw) {
        if (item is Map<String, dynamic>) {
          final model = HabitModel.fromMap(item);
          await repo.upsertHabit(model.toEntity());
          habitsImported++;
        }
      }

      // Upsert completions
      int completionsImported = 0;
      for (final item in completionListRaw) {
        if (item is Map<String, dynamic>) {
          final model = HabitCompletionModel.fromMap(item);
          await repo.recordProgress(model.toEntity());
          completionsImported++;
        }
      }

      // Restore user profile if present
      if (profileRaw != null) {
        final profile = UserProfile.fromMap(profileRaw);
        await ref.read(userProfileProvider.notifier).updateProfile(
          name: profile.name,
          avatarType: profile.avatarType,
          avatarKey: profile.avatarKey,
          avatarBgColor: profile.avatarBgColor,
        );
      }

      // Refresh providers
      await ref.read(habitsNotifierProvider.notifier).refresh();
      ref.invalidate(dateCompletionsNotifierProvider);
      ref.invalidate(appAnalyticsProvider);

      if (Navigator.canPop(ctxToClose)) {
        Navigator.pop(ctxToClose);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF15803D),
            content: Text(
              'Successfully restored $habitsImported habit(s) and $completionsImported progress log(s)!',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFDC2626),
          content: Text('Invalid backup JSON: $e'),
        ),
      );
    }
  }

  Widget _buildBackupStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentMode = ref.watch(themeModeProvider);
    final userProfile = ref.watch(userProfileProvider);

    String themeLabel = 'Light';
    if (currentMode == ThemeMode.dark) themeLabel = 'Dark';
    if (currentMode == ThemeMode.system) themeLabel = 'System Default';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            // 0. User Profile Header Card
            _buildProfileHeaderCard(context, isDark: isDark, profile: userProfile),

            // 1. Appearance (Screen 14)
            _buildSettingsCard(
              isDark: isDark,
              icon: Icons.palette_outlined,
              iconBg: const Color(0xFFDCFCE7),
              iconColor: const Color(0xFF16A34A),
              title: 'Appearance',
              subtitle: '$themeLabel / Light / Dark / System',
              onTap: () => _showAppearanceBottomSheet(context),
            ),

            // 2. Notifications
            _buildSettingsCard(
              isDark: isDark,
              icon: Icons.notifications_none_rounded,
              iconBg: const Color(0xFFFEF3C7),
              iconColor: const Color(0xFFD97706),
              title: 'Notifications',
              subtitle: _notificationsEnabled
                  ? 'Daily reminders enabled'
                  : 'Reminders disabled',
              trailing: Switch(
                value: _notificationsEnabled,
                activeColor: const Color(0xFF15803D),
                onChanged: (val) => _setNotificationsEnabled(val),
              ),
              onTap: () => _setNotificationsEnabled(!_notificationsEnabled),
            ),

            // 2a. Send Test Notification (Dedicated quick test button)
            _buildSettingsCard(
              isDark: isDark,
              icon: Icons.notification_add_rounded,
              iconBg: const Color(0xFFDCFCE7),
              iconColor: const Color(0xFF15803D),
              title: 'Send Test Notification',
              subtitle: 'Tap to trigger an instant reminder alert',
              onTap: () async {
                HapticFeedback.lightImpact();
                await NotificationService().showInstantNotification(
                  title: 'HabitFlow Reminder 🌿',
                  body: 'Notifications are working! Keep your daily streak alive.',
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Test notification sent! Check your notification bar.'),
                      backgroundColor: Color(0xFF15803D),
                    ),
                  );
                }
              },
            ),

            // 2b. Sound & Haptic Feedback
            Builder(
              builder: (ctx) {
                final soundEnabled = ref.watch(soundEffectsProvider);
                return _buildSettingsCard(
                  isDark: isDark,
                  icon: Icons.volume_up_rounded,
                  iconBg: const Color(0xFFDCFCE7),
                  iconColor: const Color(0xFF16A34A),
                  title: 'Sound & Haptic Feedback',
                  subtitle: soundEnabled ? 'Audio click & haptics enabled' : 'Muted',
                  trailing: Switch(
                    value: soundEnabled,
                    activeColor: const Color(0xFF15803D),
                    onChanged: (_) {
                      ref.read(soundEffectsProvider.notifier).toggle();
                    },
                  ),
                  onTap: () {
                    ref.read(soundEffectsProvider.notifier).toggle();
                  },
                );
              },
            ),

            // 3. Start Week On
            Builder(
              builder: (ctx) {
                final startWeekOn = ref.watch(startWeekOnProvider);
                return _buildSettingsCard(
                  isDark: isDark,
                  icon: Icons.calendar_view_week_rounded,
                  iconBg: const Color(0xFFF3E8FF),
                  iconColor: const Color(0xFF9333EA),
                  title: 'Start Week On',
                  subtitle: startWeekOn,
                  onTap: () => _showStartWeekBottomSheet(context),
                );
              },
            ),

            // 4. Export Data
            _buildSettingsCard(
              isDark: isDark,
              icon: Icons.file_upload_outlined,
              iconBg: const Color(0xFFFEF9C3),
              iconColor: const Color(0xFFCA8A04),
              title: 'Export Data',
              subtitle: 'Backup your habits to JSON',
              onTap: () => _exportData(context),
            ),

            // 5. Import Data
            _buildSettingsCard(
              isDark: isDark,
              icon: Icons.file_download_outlined,
              iconBg: const Color(0xFFDBEAFE),
              iconColor: const Color(0xFF2563EB),
              title: 'Import Data',
              subtitle: 'Restore from backup',
              onTap: () => _importData(context),
            ),

            // 6. Onboarding & Tour
            _buildSettingsCard(
              isDark: isDark,
              icon: Icons.auto_awesome_rounded,
              iconBg: const Color(0xFFE0E7FF),
              iconColor: const Color(0xFF4F46E5),
              title: 'App Intro & Tour',
              subtitle: 'Replay onboarding & features guide',
              onTap: () => context.push('/onboarding'),
            ),

            // 7. About
            _buildSettingsCard(
              isDark: isDark,
              customLeading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF16A34A).withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    kSplashLogoBytes,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              title: 'About HabitFlow',
              subtitle: 'Version 1.0.0 • Build Better Habits',
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'HabitFlow',
                  applicationVersion: '1.0.0',
                  applicationIcon: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF16A34A).withOpacity(0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.memory(
                        kSplashLogoBytes,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  applicationLegalese: 'Crafted with Clean Architecture & Riverpod.',
                );
              },
            ),

            // 8. Reset All Data (Screen 14 & Screen 15)
            _buildSettingsCard(
              isDark: isDark,
              icon: Icons.delete_outline_rounded,
              iconBg: const Color(0xFFFEE2E2),
              iconColor: const Color(0xFFDC2626),
              title: 'Reset All Data',
              subtitle: 'Clear all habits & history',
              isDestructive: true,
              onTap: () => _showResetConfirmationBottomSheet(context),
            ),

            // 9. Log Out
            _buildSettingsCard(
              isDark: isDark,
              icon: Icons.logout_rounded,
              iconBg: const Color(0xFFF1F5F9),
              iconColor: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF475569),
              title: 'Log Out',
              subtitle: 'Sign out of HabitFlow',
              onTap: () => _showLogoutConfirmationBottomSheet(context),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeaderCard(
    BuildContext context, {
    required bool isDark,
    required UserProfile profile,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFFF0FDF4), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFBBF7D0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF16A34A).withOpacity(isDark ? 0.1 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => ProfileBottomSheet.show(context),
        borderRadius: BorderRadius.circular(20),
        child: Row(
          children: [
            UserAvatarWidget(
              size: 58,
              showEditBadge: true,
              onTap: () => ProfileBottomSheet.show(context),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          profile.name,
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Active',
                          style: TextStyle(
                            color: Color(0xFF16A34A),
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Tap to customize name & avatar',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.edit_outlined,
                size: 18,
                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard({
    required bool isDark,
    IconData? icon,
    Color? iconBg,
    Color? iconColor,
    Widget? customLeading,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDestructive
              ? (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2))
              : (isDark ? const Color(0xFF2D3B4E) : const Color(0xFFF1F5F1)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        onTap: onTap,
        leading: customLeading ??
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg ?? Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDestructive
                ? const Color(0xFFDC2626)
                : (isDark ? Colors.white : const Color(0xFF0F172A)),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        trailing: trailing ??
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
      ),
    );
  }
}
