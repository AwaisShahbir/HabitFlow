import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StartWeekOnNotifier extends StateNotifier<String> {
  static const String _prefKey = 'settings_start_week_on';

  StartWeekOnNotifier() : super('Monday') {
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getString(_prefKey);
      if (val != null && (val == 'Monday' || val == 'Sunday')) {
        state = val;
      }
    } catch (_) {}
  }

  Future<void> setDay(String day) async {
    if (day != 'Monday' && day != 'Sunday') return;
    state = day;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, day);
    } catch (_) {}
  }

  Future<void> toggle() async {
    final next = state == 'Monday' ? 'Sunday' : 'Monday';
    await setDay(next);
  }

  bool get startOnMonday => state == 'Monday';
}

final startWeekOnProvider =
    StateNotifierProvider<StartWeekOnNotifier, String>((ref) {
  return StartWeekOnNotifier();
});
