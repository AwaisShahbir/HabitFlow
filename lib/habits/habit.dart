import 'package:equatable/equatable.dart';
import 'package:habitflow/core/app_date_utils.dart';

enum HabitTrackingType {
  binary, // Done / Not Done
  numeric, // Numeric progress (e.g., 2000 ml)
  duration, // Duration in minutes (e.g., 20 mins)
}

enum HabitScheduleType {
  daily, // Every day
  weekdays, // Monday to Friday
  custom, // Specific selected days
}

class Habit extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String category;
  final String icon;
  final String colorHex;
  final HabitTrackingType trackingType;
  final double targetValue;
  final String? unit;
  final HabitScheduleType scheduleType;
  final List<int> scheduledDays; // 1 = Monday, 7 = Sunday
  final DateTime startDate;
  final String? reminderTime; // "09:00"
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Habit({
    required this.id,
    required this.name,
    this.description,
    this.category = 'Health',
    this.icon = 'water_drop',
    this.colorHex = '#16A34A',
    this.trackingType = HabitTrackingType.binary,
    this.targetValue = 1.0,
    this.unit,
    this.scheduleType = HabitScheduleType.daily,
    this.scheduledDays = const [1, 2, 3, 4, 5, 6, 7],
    required this.startDate,
    this.reminderTime,
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Determines whether the habit is scheduled on a given [date].
  bool isScheduledFor(DateTime date) {
    final normalizedDate = AppDateUtils.normalize(date);
    final normalizedStart = AppDateUtils.normalize(startDate);

    // Habit cannot be scheduled prior to its start date
    if (normalizedDate.isBefore(normalizedStart)) {
      return false;
    }

    // Archived habits do not generate new scheduled dates in the future
    if (isArchived && AppDateUtils.isFuture(normalizedDate)) {
      return false;
    }

    switch (scheduleType) {
      case HabitScheduleType.daily:
        return true;
      case HabitScheduleType.weekdays:
        return normalizedDate.weekday >= 1 && normalizedDate.weekday <= 5;
      case HabitScheduleType.custom:
        return scheduledDays.contains(normalizedDate.weekday);
    }
  }

  Habit copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? icon,
    String? colorHex,
    HabitTrackingType? trackingType,
    double? targetValue,
    String? unit,
    HabitScheduleType? scheduleType,
    List<int>? scheduledDays,
    DateTime? startDate,
    String? reminderTime,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      colorHex: colorHex ?? this.colorHex,
      trackingType: trackingType ?? this.trackingType,
      targetValue: targetValue ?? this.targetValue,
      unit: unit ?? this.unit,
      scheduleType: scheduleType ?? this.scheduleType,
      scheduledDays: scheduledDays ?? this.scheduledDays,
      startDate: startDate ?? this.startDate,
      reminderTime: reminderTime ?? this.reminderTime,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        category,
        icon,
        colorHex,
        trackingType,
        targetValue,
        unit,
        scheduleType,
        scheduledDays,
        startDate,
        reminderTime,
        isArchived,
        createdAt,
        updatedAt,
      ];
}

