import 'package:flutter/material.dart';
import 'package:habitflow/core/app_colors.dart';

class ReminderResult {
  final bool enabled;
  final String? reminderTime; // "09:40 AM"
  final List<int> repeatDays;

  const ReminderResult({
    required this.enabled,
    this.reminderTime,
    required this.repeatDays,
  });
}

class ReminderBottomSheet extends StatefulWidget {
  final bool initialEnabled;
  final String? initialTime;
  final List<int> initialRepeatDays;

  const ReminderBottomSheet({
    Key? key,
    this.initialEnabled = true,
    this.initialTime = '09:40 AM',
    this.initialRepeatDays = const [1, 2, 3, 4, 5, 6, 7],
  }) : super(key: key);

  static Future<ReminderResult?> show(
    BuildContext context, {
    bool enabled = true,
    String? time = '09:40 AM',
    List<int> repeatDays = const [1, 2, 3, 4, 5, 6, 7],
  }) {
    return showModalBottomSheet<ReminderResult>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => ReminderBottomSheet(
        initialEnabled: enabled,
        initialTime: time,
        initialRepeatDays: repeatDays,
      ),
    );
  }

  @override
  State<ReminderBottomSheet> createState() => _ReminderBottomSheetState();
}

class _ReminderBottomSheetState extends State<ReminderBottomSheet> {
  late bool _enabled;
  late int _selectedHour;
  late int _selectedMinute;
  late String _selectedPeriod;
  late List<int> _selectedDays;

  final List<Map<String, dynamic>> _days = [
    {'day': 1, 'label': 'M'},
    {'day': 2, 'label': 'T'},
    {'day': 3, 'label': 'W'},
    {'day': 4, 'label': 'T'},
    {'day': 5, 'label': 'F'},
    {'day': 6, 'label': 'S'},
    {'day': 7, 'label': 'S'},
  ];

  @override
  void initState() {
    super.initState();
    _enabled = widget.initialEnabled;
    _selectedHour = 9;
    _selectedMinute = 40;
    _selectedPeriod = 'AM';
    _selectedDays = List.from(widget.initialRepeatDays);

    if (widget.initialTime != null && widget.initialTime!.isNotEmpty) {
      try {
        final parts = widget.initialTime!.split(' ');
        final timeParts = parts[0].split(':');
        _selectedHour = int.parse(timeParts[0]);
        _selectedMinute = int.parse(timeParts[1]);
        if (parts.length > 1) {
          _selectedPeriod = parts[1];
        }
      } catch (_) {}
    }
  }

  String get _formattedTime {
    final hStr = _selectedHour.toString().padLeft(2, '0');
    final mStr = _selectedMinute.toString().padLeft(2, '0');
    return '$hStr:$mStr $_selectedPeriod';
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
            // Header: Title & Done CTA
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Set Reminder',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      ReminderResult(
                        enabled: _enabled,
                        reminderTime: _enabled ? _formattedTime : null,
                        repeatDays: _selectedDays,
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

            // Enable Reminder Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Enable Reminder',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Switch(
                  value: _enabled,
                  activeColor: AppColors.primaryGreen,
                  onChanged: (val) {
                    setState(() {
                      _enabled = val;
                    });
                  },
                ),
              ],
            ),
            const Divider(),

            if (_enabled) ...[
              const SizedBox(height: 12),
              const Text(
                'Time',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondaryLight),
              ),
              const SizedBox(height: 12),

              // Interactive Time Selector Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.dark
                      ? AppColors.surfaceVariantDark
                      : AppColors.surfaceVariantLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Hour Spinner / Display
                    _buildTimeSpinner(
                      value: _selectedHour,
                      min: 1,
                      max: 12,
                      onChanged: (val) => setState(() => _selectedHour = val),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(':', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                    ),
                    // Minute Spinner / Display
                    _buildTimeSpinner(
                      value: _selectedMinute,
                      min: 0,
                      max: 59,
                      isMinute: true,
                      onChanged: (val) => setState(() => _selectedMinute = val),
                    ),
                    const SizedBox(width: 20),
                    // AM / PM Switcher
                    Column(
                      children: [
                        _buildPeriodButton('AM'),
                        const SizedBox(height: 6),
                        _buildPeriodButton('PM'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Repeat Days Selector
              const Text(
                'Repeat',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondaryLight),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _days.map((d) {
                  final dayInt = d['day'] as int;
                  final isSelected = _selectedDays.contains(dayInt);

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          if (_selectedDays.length > 1) _selectedDays.remove(dayInt);
                        } else {
                          _selectedDays.add(dayInt);
                          _selectedDays.sort();
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryGreen : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? AppColors.primaryGreen : AppColors.borderLight,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        d['label'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSpinner({
    required int value,
    required int min,
    required int max,
    bool isMinute = false,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_drop_up),
          onPressed: () {
            final next = value + (isMinute ? 5 : 1);
            onChanged(next > max ? min : next);
          },
        ),
        Text(
          value.toString().padLeft(2, '0'),
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_drop_down),
          onPressed: () {
            final prev = value - (isMinute ? 5 : 1);
            onChanged(prev < min ? max : prev);
          },
        ),
      ],
    );
  }

  Widget _buildPeriodButton(String period) {
    final isSelected = _selectedPeriod == period;
    return GestureDetector(
      onTap: () => setState(() => _selectedPeriod = period),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          period,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppColors.textSecondaryLight,
          ),
        ),
      ),
    );
  }
}

