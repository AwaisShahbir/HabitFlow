import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:habitflow/core/app_settings_provider.dart';
import 'package:habitflow/core/habit_order_service.dart';
import 'package:habitflow/core/sound_service.dart';
import 'package:habitflow/habits/habit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HabitOrderNotifier Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('sortHabits sorts according to custom IDs order', () {
      final notifier = HabitOrderNotifier();
      final now = DateTime.now();

      final h1 = Habit(
        id: 'h1',
        name: 'Habit 1',
        startDate: now,
        createdAt: now,
        updatedAt: now,
      );
      final h2 = Habit(
        id: 'h2',
        name: 'Habit 2',
        startDate: now,
        createdAt: now,
        updatedAt: now,
      );
      final h3 = Habit(
        id: 'h3',
        name: 'Habit 3',
        startDate: now,
        createdAt: now,
        updatedAt: now,
      );

      notifier.state = ['h3', 'h1', 'h2'];

      final sorted = notifier.sortHabits([h1, h2, h3]);
      expect(sorted.map((h) => h.id).toList(), equals(['h3', 'h1', 'h2']));
    });

    test('reorder updates list order correctly', () async {
      final notifier = HabitOrderNotifier();
      final now = DateTime.now();

      final h1 = Habit(id: 'h1', name: 'H1', startDate: now, createdAt: now, updatedAt: now);
      final h2 = Habit(id: 'h2', name: 'H2', startDate: now, createdAt: now, updatedAt: now);
      final h3 = Habit(id: 'h3', name: 'H3', startDate: now, createdAt: now, updatedAt: now);

      await notifier.reorder(0, 3, [h1, h2, h3]);
      expect(notifier.state, equals(['h2', 'h3', 'h1']));
    });
  });

  group('SoundEffectsNotifier Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({'sound_effects_enabled': true});
    });

    test('initial state defaults to true or saved preference', () {
      final notifier = SoundEffectsNotifier();
      expect(notifier.state, isTrue);
    });

    test('toggle switches state correctly', () async {
      final notifier = SoundEffectsNotifier();
      await notifier.toggle();
      expect(notifier.state, isFalse);
      await notifier.toggle();
      expect(notifier.state, isTrue);
    });
  });

  group('StartWeekOnNotifier Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({'settings_start_week_on': 'Monday'});
    });

    test('initial state defaults to Monday or saved preference', () {
      final notifier = StartWeekOnNotifier();
      expect(notifier.state, equals('Monday'));
      expect(notifier.startOnMonday, isTrue);
    });

    test('setDay updates day and startOnMonday flag', () async {
      final notifier = StartWeekOnNotifier();
      await notifier.setDay('Sunday');
      expect(notifier.state, equals('Sunday'));
      expect(notifier.startOnMonday, isFalse);
    });

    test('toggle flips between Monday and Sunday', () async {
      final notifier = StartWeekOnNotifier();
      await notifier.toggle();
      expect(notifier.state, equals('Sunday'));
      await notifier.toggle();
      expect(notifier.state, equals('Monday'));
    });
  });
}

