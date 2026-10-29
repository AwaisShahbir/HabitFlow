import 'package:habitflow/core/database_constants.dart';
import 'package:habitflow/habits/habit_completion.dart';

class HabitCompletionModel {
  final String id;
  final String habitId;
  final String localDate;
  final double progressValue;
  final int isCompleted; // 0 or 1
  final int? completedAt;

  const HabitCompletionModel({
    required this.id,
    required this.habitId,
    required this.localDate,
    required this.progressValue,
    required this.isCompleted,
    this.completedAt,
  });

  factory HabitCompletionModel.fromEntity(HabitCompletion completion) {
    return HabitCompletionModel(
      id: completion.id,
      habitId: completion.habitId,
      localDate: completion.localDate,
      progressValue: completion.progressValue,
      isCompleted: completion.isCompleted ? 1 : 0,
      completedAt: completion.completedAt?.millisecondsSinceEpoch,
    );
  }

  HabitCompletion toEntity() {
    return HabitCompletion(
      id: id,
      habitId: habitId,
      localDate: localDate,
      progressValue: progressValue,
      isCompleted: isCompleted == 1,
      completedAt: completedAt != null
          ? DateTime.fromMillisecondsSinceEpoch(completedAt!)
          : null,
    );
  }

  factory HabitCompletionModel.fromMap(Map<String, dynamic> map) {
    return HabitCompletionModel(
      id: map[DatabaseConstants.colCompletionId] as String,
      habitId: map[DatabaseConstants.colCompletionHabitId] as String,
      localDate: map[DatabaseConstants.colCompletionLocalDate] as String,
      progressValue: (map[DatabaseConstants.colCompletionProgressValue] as num).toDouble(),
      isCompleted: map[DatabaseConstants.colCompletionIsCompleted] as int,
      completedAt: map[DatabaseConstants.colCompletionCompletedAt] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      DatabaseConstants.colCompletionId: id,
      DatabaseConstants.colCompletionHabitId: habitId,
      DatabaseConstants.colCompletionLocalDate: localDate,
      DatabaseConstants.colCompletionProgressValue: progressValue,
      DatabaseConstants.colCompletionIsCompleted: isCompleted,
      DatabaseConstants.colCompletionCompletedAt: completedAt,
    };
  }
}

