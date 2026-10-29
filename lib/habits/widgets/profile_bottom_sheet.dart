import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitflow/core/user_profile_provider.dart';
import 'package:habitflow/habits/widgets/plant_data.dart';

class ProfileBottomSheet extends ConsumerStatefulWidget {
  const ProfileBottomSheet({Key? key}) : super(key: key);

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ProfileBottomSheet(),
    );
  }

  @override
  ConsumerState<ProfileBottomSheet> createState() => _ProfileBottomSheetState();
}

class _ProfileBottomSheetState extends ConsumerState<ProfileBottomSheet> {
  late final TextEditingController _nameController;
  late String _selectedType;
  late String _selectedKey;
  late int _selectedBgColor;

  final List<int> _palette = const [
    0xFFDCFCE7, // Emerald
    0xFFDBEAFE, // Blue
    0xFFFEF3C7, // Amber
    0xFFF3E8FF, // Purple
    0xFFFFE4E6, // Rose
    0xFFE0E7FF, // Indigo
  ];

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileProvider);
    _nameController = TextEditingController(text: profile.name);
    _selectedType = profile.avatarType;
    _selectedKey = profile.avatarKey;
    _selectedBgColor = profile.avatarBgColor;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    HapticFeedback.lightImpact();
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    await ref.read(userProfileProvider.notifier).updateProfile(
          name: name,
          avatarType: _selectedType,
          avatarKey: _selectedKey,
          avatarBgColor: _selectedBgColor,
        );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile updated for $name!'),
          backgroundColor: const Color(0xFF15803D),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Drag Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),

            // Title
            Text(
              'Customize Profile',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 18),

            // Live Avatar Preview
            _buildLivePreview(isDark),
            const SizedBox(height: 20),

            // Name Input Field
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Your Name',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                hintText: 'Enter your name...',
                prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFF16A34A)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 20),
                  onPressed: () => _nameController.clear(),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF16A34A), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Avatar Options Label
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Choose Your Avatar',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Avatars Grid / Wrap
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: kPresetAvatarOptions.map((opt) {
                final isSelected = opt.key == _selectedKey;

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedKey = opt.key;
                      _selectedType = opt.type;
                      _selectedBgColor = opt.defaultBg;
                    });
                  },
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF16A34A)
                            : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        width: isSelected ? 3 : 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF16A34A).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: ClipOval(
                      child: _buildOptionContent(opt),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Background Color Palette (if icon or emoji selected)
            if (_selectedType != 'preset') ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Avatar Background Color',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _palette.map((colorVal) {
                  final isSelected = _selectedBgColor == colorVal;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedBgColor = colorVal;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Color(colorVal),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? const Color(0xFF16A34A) : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, size: 18, color: Color(0xFF15803D))
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _saveProfile,
                child: const Text(
                  'Save Profile',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLivePreview(bool isDark) {
    Widget content;
    if (_selectedType == 'preset' && _selectedKey == 'default') {
      content = Image.memory(
        kAvatarBytes,
        width: 84,
        height: 84,
        fit: BoxFit.cover,
      );
    } else if (_selectedType == 'icon') {
      final match = kPresetAvatarOptions.firstWhere(
        (o) => o.key == _selectedKey,
        orElse: () => kPresetAvatarOptions[1],
      );
      content = Container(
        color: Color(_selectedBgColor),
        alignment: Alignment.center,
        child: Icon(
          match.icon ?? Icons.eco_rounded,
          size: 46,
          color: const Color(0xFF15803D),
        ),
      );
    } else {
      final match = kPresetAvatarOptions.firstWhere(
        (o) => o.key == _selectedKey,
        orElse: () => kPresetAvatarOptions[9],
      );
      content = Container(
        color: Color(_selectedBgColor),
        alignment: Alignment.center,
        child: Text(
          match.emoji ?? '🌿',
          style: const TextStyle(fontSize: 42),
        ),
      );
    }

    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF16A34A).withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFF16A34A), width: 3),
      ),
      child: ClipOval(child: content),
    );
  }

  Widget _buildOptionContent(PresetAvatarOption opt) {
    if (opt.type == 'preset') {
      return Image.memory(
        kAvatarBytes,
        fit: BoxFit.cover,
      );
    } else if (opt.type == 'icon') {
      return Container(
        color: Color(opt.defaultBg),
        alignment: Alignment.center,
        child: Icon(opt.icon, size: 28, color: const Color(0xFF15803D)),
      );
    } else {
      return Container(
        color: Color(opt.defaultBg),
        alignment: Alignment.center,
        child: Text(opt.emoji ?? '🌿', style: const TextStyle(fontSize: 26)),
      );
    }
  }
}
