import 'package:flutter/material.dart';
import 'package:habitflow/core/app_colors.dart';
import 'package:habitflow/habits/habit.dart';

class ScheduleResult {
  final HabitScheduleType scheduleType;
  final List<int> scheduledDays;

  const ScheduleResult({
    required this.scheduleType,
    required this.scheduledDays,
  });
}

class ScheduleBottomSheet extends StatefulWidget {
  final HabitScheduleType initialScheduleType;
  final List<int> initialScheduledDays;

  const ScheduleBottomSheet({
    Key? key,
    required this.initialScheduleType,
    required this.initialScheduledDays,
  }) : super(key: key);

  static Future<ScheduleResult?> show(
    BuildContext context, {
    HabitScheduleType scheduleType = HabitScheduleType.daily,
    List<int> scheduledDays = const [1, 2, 3, 4, 5, 6, 7],
  }) {
    return showModalBottomSheet<ScheduleResult>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => ScheduleBottomSheet(
        initialScheduleType: scheduleType,
        initialScheduledDays: scheduledDays,
      ),
    );
  }

  @override
  State<ScheduleBottomSheet> createState() => _ScheduleBottomSheetState();
}

class _ScheduleBottomSheetState extends State<ScheduleBottomSheet> {
  late HabitScheduleType _scheduleType;
  late List<int> _selectedDays;

  final List<Map<String, dynamic>> _days = [
    {'day': 1, 'label': 'Mon'},
    {'day': 2, 'label': 'Tue'},
    {'day': 3, 'label': 'Wed'},
    {'day': 4, 'label': 'Thu'},
    {'day': 5, 'label': 'Fri'},
    {'day': 6, 'label': 'Sat'},
    {'day': 7, 'label': 'Sun'},
  ];

  @override
  void initState() {
    super.initState();
    _scheduleType = widget.initialScheduleType;
    _selectedDays = List.from(widget.initialScheduledDays);
  }

  void _onOptionSelected(HabitScheduleType type) {
    setState(() {
      _scheduleType = type;
      if (type == HabitScheduleType.daily) {
        _selectedDays = [1, 2, 3, 4, 5, 6, 7];
      } else if (type == HabitScheduleType.weekdays) {
        _selectedDays = [1, 2, 3, 4, 5];
      }
    });
  }

  void _toggleCustomDay(int day) {
    setState(() {
      _scheduleType = HabitScheduleType.custom;
      if (_selectedDays.contains(day)) {
        if (_selectedDays.length > 1) {
          _selectedDays.remove(day);
        }
      } else {
        _selectedDays.add(day);
        _selectedDays.sort();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar: Title & Done CTA
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Days',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      ScheduleResult(
                        scheduleType: _scheduleType,
                        scheduledDays: _selectedDays,
                      ),
                    );
                  },
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Option 1: Every day
            _buildScheduleOptionTile(
              title: 'Every day',
              isSelected: _scheduleType == HabitScheduleType.daily,
              onTap: () => _onOptionSelected(HabitScheduleType.daily),
            ),
            const Divider(height: 1),

            // Option 2: Weekdays (Mon - Fri)
            _buildScheduleOptionTile(
              title: 'Weekdays (Mon - Fri)',
              isSelected: _scheduleType == HabitScheduleType.weekdays,
              onTap: () => _onOptionSelected(HabitScheduleType.weekdays),
            ),
            const Divider(height: 1),

            // Option 3: Custom days
            _buildScheduleOptionTile(
              title: 'Custom days',
              isSelected: _scheduleType == HabitScheduleType.custom,
              onTap: () {
                setState(() {
                  _scheduleType = HabitScheduleType.custom;
                });
              },
            ),
            const SizedBox(height: 12),

            // Weekday Selection Pills (Mon - Sun)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _days.map((d) {
                final dayInt = d['day'] as int;
                final isDaySelected = _selectedDays.contains(dayInt);

                return GestureDetector(
                  onTap: () => _toggleCustomDay(dayInt),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isDaySelected
                          ? AppColors.primaryGreen
                          : (theme.brightness == Brightness.dark
                              ? AppColors.surfaceVariantDark
                              : AppColors.surfaceVariantLight),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDaySelected ? AppColors.primaryGreen : AppColors.borderLight,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      d['label'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDaySelected
                            ? Colors.white
                            : (theme.brightness == Brightness.dark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleOptionTile({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppColors.primaryGreen)
          : const Icon(Icons.radio_button_unchecked, color: AppColors.borderLight),
    );
  }
}

