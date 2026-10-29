import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:habitflow/habits/habit.dart';

class HabitOrderNotifier extends StateNotifier<List<String>> {
  static const String _prefKey = 'habit_custom_sort_order';

  HabitOrderNotifier() : super([]) {
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_prefKey);
      if (saved != null) {
        state = saved;
      }
    } catch (_) {}
  }

  Future<void> saveOrder(List<String> orderedIds) async {
    state = orderedIds;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefKey, orderedIds);
    } catch (_) {}
  }

  Future<void> reorder(int oldIndex, int newIndex, List<Habit> habits) async {
    final list = List<Habit>.from(habits);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);

    final orderedIds = list.map((h) => h.id).toList();
    await saveOrder(orderedIds);
  }

  List<Habit> sortHabits(List<Habit> habits) {
    if (state.isEmpty) return habits;
    final orderMap = <String, int>{};
    for (int i = 0; i < state.length; i++) {
      orderMap[state[i]] = i;
    }

    final sorted = List<Habit>.from(habits);
    sorted.sort((a, b) {
      final orderA = orderMap[a.id] ?? 999999;
      final orderB = orderMap[b.id] ?? 999999;
      if (orderA != orderB) {
        return orderA.compareTo(orderB);
      }
      return b.createdAt.compareTo(a.createdAt);
    });
    return sorted;
  }
}

final habitOrderProvider =
    StateNotifierProvider<HabitOrderNotifier, List<String>>((ref) {
  return HabitOrderNotifier();
});
