import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:habitflow/habits/widgets/plant_data.dart';

/// User profile data model
class UserProfile {
  final String name;
  final String avatarType; // 'preset' | 'emoji' | 'icon'
  final String avatarKey;  // 'default' | 'botanical' | 'zen' | 'runner' | 'rocket' | 'coffee' | 'scholar' | 'lion' | '🔥' | '🌿' ...
  final int avatarBgColor; // Color value as int (0xFF...)

  const UserProfile({
    this.name = 'Alex',
    this.avatarType = 'preset',
    this.avatarKey = 'default',
    this.avatarBgColor = 0xFFDCFCE7,
  });

  UserProfile copyWith({
    String? name,
    String? avatarType,
    String? avatarKey,
    int? avatarBgColor,
  }) {
    return UserProfile(
      name: name ?? this.name,
      avatarType: avatarType ?? this.avatarType,
      avatarKey: avatarKey ?? this.avatarKey,
      avatarBgColor: avatarBgColor ?? this.avatarBgColor,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'avatarType': avatarType,
      'avatarKey': avatarKey,
      'avatarBgColor': avatarBgColor,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      name: map['name'] as String? ?? 'Alex',
      avatarType: map['avatarType'] as String? ?? 'preset',
      avatarKey: map['avatarKey'] as String? ?? 'default',
      avatarBgColor: map['avatarBgColor'] as int? ?? 0xFFDCFCE7,
    );
  }
}

/// Persistent StateNotifier for UserProfile
class UserProfileNotifier extends StateNotifier<UserProfile> {
  static const _storageKey = 'habitflow_user_profile_v1';

  UserProfileNotifier() : super(const UserProfile()) {
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);
      if (jsonStr != null) {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        state = UserProfile.fromMap(map);
      }
    } catch (_) {
      // Keep default on error
    }
  }

  Future<void> _persist(UserProfile newProfile) async {
    state = newProfile;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(newProfile.toMap()));
    } catch (_) {}
  }

  Future<void> updateName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    await _persist(state.copyWith(name: trimmed));
  }

  Future<void> updateAvatar({
    required String type,
    required String key,
    int? bgColor,
  }) async {
    await _persist(state.copyWith(
      avatarType: type,
      avatarKey: key,
      avatarBgColor: bgColor ?? state.avatarBgColor,
    ));
  }

  Future<void> updateProfile({
    String? name,
    String? avatarType,
    String? avatarKey,
    int? avatarBgColor,
  }) async {
    await _persist(state.copyWith(
      name: name?.trim().isNotEmpty == true ? name!.trim() : state.name,
      avatarType: avatarType,
      avatarKey: avatarKey,
      avatarBgColor: avatarBgColor,
    ));
  }
}

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile>((ref) {
  return UserProfileNotifier();
});

/// Curated preset avatar definition
class PresetAvatarOption {
  final String key;
  final String label;
  final String type; // 'preset' | 'emoji' | 'icon'
  final IconData? icon;
  final String? emoji;
  final int defaultBg;

  const PresetAvatarOption({
    required this.key,
    required this.label,
    required this.type,
    this.icon,
    this.emoji,
    this.defaultBg = 0xFFDCFCE7,
  });
}

const List<PresetAvatarOption> kPresetAvatarOptions = [
  PresetAvatarOption(
    key: 'default',
    label: 'Illustrated',
    type: 'preset',
    defaultBg: 0xFFE2E8F0,
  ),
  PresetAvatarOption(
    key: 'botanical',
    label: 'Sprout',
    type: 'icon',
    icon: Icons.eco_rounded,
    defaultBg: 0xFFDCFCE7,
  ),
  PresetAvatarOption(
    key: 'zen',
    label: 'Mindfulness',
    type: 'icon',
    icon: Icons.self_improvement_rounded,
    defaultBg: 0xFFF3E8FF,
  ),
  PresetAvatarOption(
    key: 'runner',
    label: 'Fitness',
    type: 'icon',
    icon: Icons.directions_run_rounded,
    defaultBg: 0xFFFFEDD5,
  ),
  PresetAvatarOption(
    key: 'rocket',
    label: 'Focus',
    type: 'icon',
    icon: Icons.rocket_launch_rounded,
    defaultBg: 0xFFDBEAFE,
  ),
  PresetAvatarOption(
    key: 'scholar',
    label: 'Learning',
    type: 'icon',
    icon: Icons.auto_stories_rounded,
    defaultBg: 0xFFFEF3C7,
  ),
  PresetAvatarOption(
    key: 'coffee',
    label: 'Routine',
    type: 'icon',
    icon: Icons.local_cafe_rounded,
    defaultBg: 0xFFFFE4E6,
  ),
  PresetAvatarOption(
    key: 'star',
    label: 'Achiever',
    type: 'icon',
    icon: Icons.star_rounded,
    defaultBg: 0xFFFEF9C3,
  ),
  // Emojis
  PresetAvatarOption(
    key: 'emoji_lion',
    label: 'Discipline',
    type: 'emoji',
    emoji: '🦁',
    defaultBg: 0xFFFFEDD5,
  ),
  PresetAvatarOption(
    key: 'emoji_leaf',
    label: 'Growth',
    type: 'emoji',
    emoji: '🌿',
    defaultBg: 0xFFDCFCE7,
  ),
  PresetAvatarOption(
    key: 'emoji_fire',
    label: 'Streak',
    type: 'emoji',
    emoji: '🔥',
    defaultBg: 0xFFFEE2E2,
  ),
  PresetAvatarOption(
    key: 'emoji_target',
    label: 'Goals',
    type: 'emoji',
    emoji: '🎯',
    defaultBg: 0xFFDBEAFE,
  ),
  PresetAvatarOption(
    key: 'emoji_meditate',
    label: 'Calm',
    type: 'emoji',
    emoji: '🧘',
    defaultBg: 0xFFF3E8FF,
  ),
  PresetAvatarOption(
    key: 'emoji_bolt',
    label: 'Energy',
    type: 'emoji',
    emoji: '⚡',
    defaultBg: 0xFFFEF3C7,
  ),
];

/// Reusable User Avatar Widget that renders according to active UserProfile
class UserAvatarWidget extends ConsumerWidget {
  final double size;
  final VoidCallback? onTap;
  final bool showEditBadge;

  const UserAvatarWidget({
    Key? key,
    this.size = 44,
    this.onTap,
    this.showEditBadge = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget avatarContent;

    if (profile.avatarType == 'preset' && profile.avatarKey == 'default') {
      avatarContent = Image.memory(
        kAvatarBytes,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallbackIcon(),
      );
    } else if (profile.avatarType == 'icon') {
      final match = kPresetAvatarOptions.firstWhere(
        (o) => o.key == profile.avatarKey,
        orElse: () => kPresetAvatarOptions[1],
      );
      avatarContent = Container(
        color: Color(profile.avatarBgColor),
        alignment: Alignment.center,
        child: Icon(
          match.icon ?? Icons.eco_rounded,
          size: size * 0.55,
          color: const Color(0xFF15803D),
        ),
      );
    } else if (profile.avatarType == 'emoji') {
      final match = kPresetAvatarOptions.firstWhere(
        (o) => o.key == profile.avatarKey,
        orElse: () => kPresetAvatarOptions[9],
      );
      avatarContent = Container(
        color: Color(profile.avatarBgColor),
        alignment: Alignment.center,
        child: Text(
          match.emoji ?? '🌿',
          style: TextStyle(fontSize: size * 0.52),
        ),
      );
    } else {
      avatarContent = _fallbackIcon();
    }

    Widget avatarBox = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
          width: 2,
        ),
      ),
      child: ClipOval(child: avatarContent),
    );

    if (showEditBadge) {
      avatarBox = Stack(
        clipBehavior: Clip.none,
        children: [
          avatarBox,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.35,
              height: size * 0.35,
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(
                Icons.edit,
                color: Colors.white,
                size: size * 0.2,
              ),
            ),
          ),
        ],
      );
    }

    if (onTap != null) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: avatarBox,
      );
    }

    return avatarBox;
  }

  Widget _fallbackIcon() {
    return Container(
      color: const Color(0xFFE2E8F0),
      alignment: Alignment.center,
      child: Icon(
        Icons.person_rounded,
        color: const Color(0xFF15803D),
        size: size * 0.6,
      ),
    );
  }
}

