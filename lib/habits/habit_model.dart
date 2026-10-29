import 'dart:convert';
import 'package:habitflow/core/database_constants.dart';
import 'package:habitflow/habits/habit.dart';

class HabitModel {
  final String id;
  final String name;
  final String? description;
  final String category;
  final String icon;
  final String colorHex;
  final String trackingType;
  final double targetValue;
  final String? unit;
  final String scheduleType;
  final String scheduledDays; // JSON string
  final String startDate; // ISO format
  final String? reminderTime;
  final int isArchived; // 0 or 1
  final int createdAt;
  final int updatedAt;

  const HabitModel({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    required this.icon,
    required this.colorHex,
    required this.trackingType,
    required this.targetValue,
    this.unit,
    required this.scheduleType,
    required this.scheduledDays,
    required this.startDate,
    this.reminderTime,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HabitModel.fromEntity(Habit habit) {
    return HabitModel(
      id: habit.id,
      name: habit.name,
      description: habit.description,
      category: habit.category,
      icon: habit.icon,
      colorHex: habit.colorHex,
      trackingType: habit.trackingType.name,
      targetValue: habit.targetValue,
      unit: habit.unit,
      scheduleType: habit.scheduleType.name,
      scheduledDays: jsonEncode(habit.scheduledDays),
      startDate: habit.startDate.toIso8601String().split('T').first,
      reminderTime: habit.reminderTime,
      isArchived: habit.isArchived ? 1 : 0,
      createdAt: habit.createdAt.millisecondsSinceEpoch,
      updatedAt: habit.updatedAt.millisecondsSinceEpoch,
    );
  }

  Habit toEntity() {
    List<int> parsedDays = [1, 2, 3, 4, 5, 6, 7];
    try {
      final decoded = jsonDecode(scheduledDays);
      if (decoded is List) {
        parsedDays = decoded.cast<int>();
      }
    } catch (_) {}

    return Habit(
      id: id,
      name: name,
      description: description,
      category: category,
      icon: icon,
      colorHex: colorHex,
      trackingType: HabitTrackingType.values.byName(trackingType),
      targetValue: targetValue,
      unit: unit,
      scheduleType: HabitScheduleType.values.byName(scheduleType),
      scheduledDays: parsedDays,
      startDate: DateTime.parse(startDate),
      reminderTime: reminderTime,
      isArchived: isArchived == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt),
    );
  }

  factory HabitModel.fromMap(Map<String, dynamic> map) {
    return HabitModel(
      id: map[DatabaseConstants.colHabitId] as String,
      name: map[DatabaseConstants.colHabitName] as String,
      description: map[DatabaseConstants.colHabitDescription] as String?,
      category: map[DatabaseConstants.colHabitCategory] as String,
      icon: map[DatabaseConstants.colHabitIcon] as String,
      colorHex: map[DatabaseConstants.colHabitColorHex] as String,
      trackingType: map[DatabaseConstants.colHabitTrackingType] as String,
      targetValue: (map[DatabaseConstants.colHabitTargetValue] as num).toDouble(),
      unit: map[DatabaseConstants.colHabitUnit] as String?,
      scheduleType: map[DatabaseConstants.colHabitScheduleType] as String,
      scheduledDays: map[DatabaseConstants.colHabitScheduledDays] as String,
      startDate: map[DatabaseConstants.colHabitStartDate] as String,
      reminderTime: map[DatabaseConstants.colHabitReminderTime] as String?,
      isArchived: map[DatabaseConstants.colHabitIsArchived] as int,
      createdAt: map[DatabaseConstants.colHabitCreatedAt] as int,
      updatedAt: map[DatabaseConstants.colHabitUpdatedAt] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      DatabaseConstants.colHabitId: id,
      DatabaseConstants.colHabitName: name,
      DatabaseConstants.colHabitDescription: description,
      DatabaseConstants.colHabitCategory: category,
      DatabaseConstants.colHabitIcon: icon,
      DatabaseConstants.colHabitColorHex: colorHex,
      DatabaseConstants.colHabitTrackingType: trackingType,
      DatabaseConstants.colHabitTargetValue: targetValue,
      DatabaseConstants.colHabitUnit: unit,
      DatabaseConstants.colHabitScheduleType: scheduleType,
      DatabaseConstants.colHabitScheduledDays: scheduledDays,
      DatabaseConstants.colHabitStartDate: startDate,
      DatabaseConstants.colHabitReminderTime: reminderTime,
      DatabaseConstants.colHabitIsArchived: isArchived,
      DatabaseConstants.colHabitCreatedAt: createdAt,
      DatabaseConstants.colHabitUpdatedAt: updatedAt,
    };
  }
}

