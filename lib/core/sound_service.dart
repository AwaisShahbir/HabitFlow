import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundEffectsNotifier extends StateNotifier<bool> {
  static const String _prefKey = 'sound_effects_enabled';

  SoundEffectsNotifier() : super(true) {
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool(_prefKey) ?? true;
      state = enabled;
    } catch (_) {}
  }

  Future<void> toggle() async {
    final next = !state;
    state = next;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, next);
    } catch (_) {}
    if (next) {
      playCompletion();
    }
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, enabled);
    } catch (_) {}
  }

  void playCompletion() {
    if (!state) return;
    try {
      SystemSound.play(SystemSoundType.click);
      HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  void playCelebrate() {
    if (!state) return;
    try {
      SystemSound.play(SystemSoundType.click);
      HapticFeedback.heavyImpact();
    } catch (_) {}
  }
}

final soundEffectsProvider =
    StateNotifierProvider<SoundEffectsNotifier, bool>((ref) {
  return SoundEffectsNotifier();
});

