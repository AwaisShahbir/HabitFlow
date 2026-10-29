import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitflow/core/user_profile_provider.dart';
import 'package:habitflow/habits/habit.dart';
import 'package:habitflow/habits/habit_completion.dart';
import 'package:habitflow/habits/habit_completion_model.dart';
import 'package:habitflow/habits/habit_model.dart';

void main() {
  group('UserProfile Model Tests', () {
    test('Default profile has sensible values', () {
      const profile = UserProfile();
      expect(profile.name, equals('Alex'));
      expect(profile.avatarType, equals('preset'));
      expect(profile.avatarKey, equals('default'));
      expect(profile.avatarBgColor, equals(0xFFDCFCE7));
    });

    test('Serialization toMap and fromMap round-trips cleanly', () {
      const original = UserProfile(
        name: 'Awais',
        avatarType: 'icon',
        avatarKey: 'botanical',
        avatarBgColor: 0xFFF3E8FF,
      );

      final map = original.toMap();
      final reconstructed = UserProfile.fromMap(map);

      expect(reconstructed.name, equals('Awais'));
      expect(reconstructed.avatarType, equals('icon'));
      expect(reconstructed.avatarKey, equals('botanical'));
      expect(reconstructed.avatarBgColor, equals(0xFFF3E8FF));
    });

    test('copyWith updates specified fields only', () {
      const profile = UserProfile(name: 'Sarah');
      final updated = profile.copyWith(name: 'Sarah Connor', avatarKey: 'runner');

      expect(updated.name, equals('Sarah Connor'));
      expect(updated.avatarKey, equals('runner'));
      expect(updated.avatarType, equals(profile.avatarType));
      expect(updated.avatarBgColor, equals(profile.avatarBgColor));
    });
  });

  group('Full Backup & Restore Payload Tests', () {
    test('Serializes and deserializes habits and completion history', () {
      final now = DateTime.now();
      final habit = Habit(
        id: 'test_h1',
        name: 'Morning Meditation',
        category: 'Mindfulness',
        trackingType: HabitTrackingType.duration,
        targetValue: 15,
        unit: 'minutes',
        scheduleType: HabitScheduleType.daily,
        startDate: now,
        createdAt: now,
        updatedAt: now,
      );

      final completion = HabitCompletion(
        id: 'test_c1',
        habitId: 'test_h1',
        localDate: '2026-10-29',
        progressValue: 15,
        isCompleted: true,
        completedAt: now,
      );

      const profile = UserProfile(
        name: 'Awais',
        avatarType: 'icon',
        avatarKey: 'zen',
      );

      final backupPayload = {
        'app': 'HabitFlow',
        'version': 1,
        'exportedAt': now.toUtc().toIso8601String(),
        'profile': profile.toMap(),
        'habits': [HabitModel.fromEntity(habit).toMap()],
        'completions': [HabitCompletionModel.fromEntity(completion).toMap()],
      };

      final jsonStr = jsonEncode(backupPayload);
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;

      expect(decoded['app'], equals('HabitFlow'));
      expect(decoded['version'], equals(1));

      // Reconstruct profile
      final restoredProfile = UserProfile.fromMap(decoded['profile'] as Map<String, dynamic>);
      expect(restoredProfile.name, equals('Awais'));
      expect(restoredProfile.avatarKey, equals('zen'));

      // Reconstruct habit
      final habitList = decoded['habits'] as List<dynamic>;
      expect(habitList.length, equals(1));
      final restoredHabit = HabitModel.fromMap(habitList.first as Map<String, dynamic>).toEntity();
      expect(restoredHabit.id, equals('test_h1'));
      expect(restoredHabit.name, equals('Morning Meditation'));
      expect(restoredHabit.targetValue, equals(15));

      // Reconstruct completion
      final compList = decoded['completions'] as List<dynamic>;
      expect(compList.length, equals(1));
      final restoredCompletion = HabitCompletionModel.fromMap(compList.first as Map<String, dynamic>).toEntity();
      expect(restoredCompletion.id, equals('test_c1'));
      expect(restoredCompletion.habitId, equals('test_h1'));
      expect(restoredCompletion.isCompleted, isTrue);
    });
  });
}

