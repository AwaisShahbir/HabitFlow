import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:habitflow/core/user_profile_provider.dart';
import 'package:habitflow/onboarding/onboarding_assets.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
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
    0xFFF1F5F9, // Slate
  ];

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileProvider);
    // If the name is the default placeholder 'Alex', provide an empty input so the user types their name fresh
    _nameController = TextEditingController(
      text: profile.name == 'Alex' ? '' : profile.name,
    );
    _selectedType = profile.avatarType;
    _selectedKey = profile.avatarKey;
    _selectedBgColor = profile.avatarBgColor;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _completeSetup({bool skipped = false}) async {
    HapticFeedback.lightImpact();

    final inputName = _nameController.text.trim();
    final chosenName = inputName.isNotEmpty
        ? inputName
        : (skipped ? ref.read(userProfileProvider).name : 'Friend');

    await ref.read(userProfileProvider.notifier).updateProfile(
          name: chosenName,
          avatarType: _selectedType,
          avatarKey: _selectedKey,
          avatarBgColor: _selectedBgColor,
        );

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_completed_onboarding', true);
    } catch (_) {}

    if (mounted) {
      context.go('/main/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final previewProfile = UserProfile(
      name: _nameController.text.trim().isEmpty ? 'You' : _nameController.text.trim(),
      avatarType: _selectedType,
      avatarKey: _selectedKey,
      avatarBgColor: _selectedBgColor,
    );

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Stack(
          children: [
            // Ambient Floating Leaves
            Positioned.fill(
              child: Opacity(
                opacity: isDark ? 0.03 : 0.05,
                child: Image.memory(
                  kFloatingLeavesAccentBytes,
                  fit: BoxFit.cover,
                ),
              ),
            ),

            Column(
              children: [
                // Top App Bar: Back & Skip
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                          size: 20,
                        ),
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/onboarding');
                          }
                        },
                      ),
                      TextButton(
                        onPressed: () => _completeSetup(skipped: true),
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 8),

                        // Title & Subtitle
                        Text(
                          'What should we call you?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Personalize your HabitFlow journey with your name and favorite avatar.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Big Live Avatar Preview
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF16A34A).withOpacity(0.35),
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF16A34A).withOpacity(isDark ? 0.25 : 0.15),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: _buildLargePreview(previewProfile),
                        ),
                        const SizedBox(height: 24),

                        // Name Input Card
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: TextField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              icon: const Icon(
                                Icons.person_outline_rounded,
                                color: Color(0xFF16A34A),
                                size: 24,
                              ),
                              hintText: 'Enter your name (e.g. Awais)',
                              hintStyle: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                              ),
                              border: InputBorder.none,
                              suffixIcon: _nameController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                      onPressed: () {
                                        _nameController.clear();
                                        setState(() {});
                                      },
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Avatar Selector Section
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'CHOOSE YOUR AVATAR',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 80,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: kPresetAvatarOptions.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final option = kPresetAvatarOptions[index];
                              final isSelected = _selectedType == option.type && _selectedKey == option.key;

                              return GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    _selectedType = option.type;
                                    _selectedKey = option.key;
                                    _selectedBgColor = option.defaultBg;
                                  });
                                },
                                child: Column(
                                  children: [
                                    Container(
                                      width: 54,
                                      height: 54,
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
                                                  color: const Color(0xFF16A34A).withOpacity(0.35),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: ClipOval(
                                        child: Container(
                                          color: Color(option.defaultBg),
                                          alignment: Alignment.center,
                                          child: _buildAvatarOptionThumbnail(option),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      option.label,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                        color: isSelected
                                            ? const Color(0xFF16A34A)
                                            : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Background Palette Section
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'BACKGROUND ACCENT',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: Color(colorVal),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF16A34A)
                                        : (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                                    width: isSelected ? 3 : 1.5,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(
                                        Icons.check_rounded,
                                        size: 20,
                                        color: Color(0xFF15803D),
                                      )
                                    : null,
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),

                // Bottom Action Button
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () => _completeSetup(skipped: false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        shadowColor: const Color(0xFF16A34A).withOpacity(0.4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _nameController.text.trim().isNotEmpty
                                ? 'Continue as ${_nameController.text.trim()}'
                                : 'Continue to Dashboard',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLargePreview(UserProfile profile) {
    if (profile.avatarType == 'icon' || profile.avatarType == 'preset') {
      final match = kPresetAvatarOptions.firstWhere(
        (o) => o.key == profile.avatarKey,
        orElse: () => kPresetAvatarOptions.first,
      );
      return ClipOval(
        child: Container(
          width: 88,
          height: 88,
          color: Color(profile.avatarBgColor),
          alignment: Alignment.center,
          child: Icon(
            match.icon ?? Icons.eco_rounded,
            size: 44,
            color: const Color(0xFF15803D),
          ),
        ),
      );
    } else if (profile.avatarType == 'emoji') {
      final match = kPresetAvatarOptions.firstWhere(
        (o) => o.key == profile.avatarKey,
        orElse: () => kPresetAvatarOptions[9],
      );
      return ClipOval(
        child: Container(
          width: 88,
          height: 88,
          color: Color(profile.avatarBgColor),
          alignment: Alignment.center,
          child: Text(
            match.emoji ?? '🌿',
            style: const TextStyle(fontSize: 44),
          ),
        ),
      );
    }
    return ClipOval(
      child: Container(
        width: 88,
        height: 88,
        color: const Color(0xFFE2E8F0),
        child: const Icon(Icons.person, size: 48, color: Color(0xFF15803D)),
      ),
    );
  }

  Widget _buildAvatarOptionThumbnail(PresetAvatarOption option) {
    if (option.type == 'icon' || option.type == 'preset') {
      return Icon(
        option.icon ?? Icons.eco_rounded,
        size: 26,
        color: const Color(0xFF15803D),
      );
    } else {
      return Text(
        option.emoji ?? '🌿',
        style: const TextStyle(fontSize: 24),
      );
    }
  }
}
