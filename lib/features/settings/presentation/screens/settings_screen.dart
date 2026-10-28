import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  void _showResetConfirmationBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_forever, color: AppColors.error, size: 40),
              ),
              const SizedBox(height: 16),
              const Text(
                'Reset All Data',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'This will permanently delete all your habits, progress, settings, and reminders. This action cannot be undone.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 14),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All local data was successfully reset.')),
                  );
                },
                child: const Text('Reset All Data'),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondaryLight)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            _buildSettingsTile(
              icon: Icons.palette_outlined,
              iconBg: const Color(0xFFE0E7FF),
              iconColor: const Color(0xFF4F46E5),
              title: 'Appearance',
              subtitle: 'Light / Dark / System',
              onTap: () {},
            ),
            _buildSettingsTile(
              icon: Icons.notifications_none,
              iconBg: const Color(0xFFFEF3C7),
              iconColor: const Color(0xFFD97706),
              title: 'Notifications',
              subtitle: 'Manage reminders',
              onTap: () {},
            ),
            _buildSettingsTile(
              icon: Icons.calendar_view_week_outlined,
              iconBg: const Color(0xFFDCFCE7),
              iconColor: const Color(0xFF16A34A),
              title: 'Start Week On',
              subtitle: 'Monday',
              onTap: () {},
            ),
            _buildSettingsTile(
              icon: Icons.file_upload_outlined,
              iconBg: const Color(0xFFDBEAFE),
              iconColor: const Color(0xFF2563EB),
              title: 'Export Data',
              subtitle: 'Backup your habits to JSON',
              onTap: () {},
            ),
            _buildSettingsTile(
              icon: Icons.file_download_outlined,
              iconBg: const Color(0xFFF3E8FF),
              iconColor: const Color(0xFF9333EA),
              title: 'Import Data',
              subtitle: 'Restore from backup',
              onTap: () {},
            ),
            _buildSettingsTile(
              icon: Icons.info_outline,
              iconBg: const Color(0xFFF1F5F9),
              iconColor: const Color(0xFF64748B),
              title: 'About',
              subtitle: 'Version 1.0.0',
              onTap: () {},
            ),
            const SizedBox(height: 20),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFFEE2E2)),
              ),
              tileColor: const Color(0xFFFEF2F2),
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text(
                'Reset All Data',
                style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
              ),
              onTap: () => _showResetConfirmationBottomSheet(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondaryLight),
        onTap: onTap,
      ),
    );
  }
}
