import 'package:equatable/equatable.dart';

class HabitCompletion extends Equatable {
  final String id;
  final String habitId;
  final String localDate; // 'YYYY-MM-DD'
  final double progressValue;
  final bool isCompleted;
  final DateTime? completedAt;

  const HabitCompletion({
    required this.id,
    required this.habitId,
    required this.localDate,
    required this.progressValue,
    required this.isCompleted,
    this.completedAt,
  });

  HabitCompletion copyWith({
    String? id,
    String? habitId,
    String? localDate,
    double? progressValue,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return HabitCompletion(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      localDate: localDate ?? this.localDate,
      progressValue: progressValue ?? this.progressValue,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        habitId,
        localDate,
        progressValue,
        isCompleted,
        completedAt,
      ];
}

