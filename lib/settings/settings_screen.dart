import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:habitflow/core/notification_service.dart';
import 'package:habitflow/core/theme_provider.dart';
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
  String _startWeekOn = 'Monday';

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
                  onPressed: () {
                    Navigator.pop(ctx);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Logged out successfully'),
                          backgroundColor: Color(0xFF15803D),
                        ),
                      );
                      context.go('/splash');
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
    final habits = await ref.read(habitRepositoryProvider).getAllHabits();
    final jsonList = habits.map((h) => HabitModel.fromEntity(h).toMap()).toList();
    final jsonString = const JsonEncoder.withIndent('  ').convert(jsonList);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exported JSON Backup'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: SelectableText(
              jsonString,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonString));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Backup copied to clipboard!')),
              );
            },
            child: const Text('Copy to Clipboard'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _importData(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Habits JSON'),
        content: SizedBox(
          width: 400,
          child: TextField(
            controller: controller,
            maxLines: 8,
            decoration: const InputDecoration(
              hintText: 'Paste JSON backup here...',
              border: OutlineInputBorder(),
            ),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final list = jsonDecode(controller.text) as List<dynamic>;
                final repo = ref.read(habitRepositoryProvider);
                for (final item in list) {
                  final model = HabitModel.fromMap(item as Map<String, dynamic>);
                  await repo.createHabit(model.toEntity());
                }
                await ref.read(habitsNotifierProvider.notifier).refresh();
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Successfully imported ${list.length} habits!')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Invalid JSON format: $e')),
                );
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentMode = ref.watch(themeModeProvider);

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
              subtitle: _notificationsEnabled ? 'Reminders Enabled' : 'Reminders Disabled',
              onTap: () async {
                final nextVal = !_notificationsEnabled;
                setState(() {
                  _notificationsEnabled = nextVal;
                });
                if (nextVal) {
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
                        nextVal
                            ? 'Habit reminders enabled'
                            : 'All habit reminders disabled',
                      ),
                      backgroundColor: nextVal ? const Color(0xFF15803D) : const Color(0xFF475569),
                    ),
                  );
                }
              },
            ),

            // 3. Start Week On
            _buildSettingsCard(
              isDark: isDark,
              icon: Icons.calendar_view_week_rounded,
              iconBg: const Color(0xFFF3E8FF),
              iconColor: const Color(0xFF9333EA),
              title: 'Start Week On',
              subtitle: _startWeekOn,
              onTap: () {
                setState(() {
                  _startWeekOn = _startWeekOn == 'Monday' ? 'Sunday' : 'Monday';
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Week now starts on $_startWeekOn')),
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
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
        ),
      ),
    );
  }
}
