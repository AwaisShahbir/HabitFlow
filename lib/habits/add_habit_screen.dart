import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:habitflow/core/notification_service.dart';
import 'package:habitflow/core/app_colors.dart';
import 'package:habitflow/habits/habit.dart';
import 'package:habitflow/habits/habit_providers.dart';
import 'package:habitflow/habits/widgets/reminder_bottom_sheet.dart';
import 'package:habitflow/habits/widgets/schedule_bottom_sheet.dart';

class AddHabitScreen extends ConsumerStatefulWidget {
  final Habit? habitToEdit;

  const AddHabitScreen({Key? key, this.habitToEdit}) : super(key: key);

  @override
  ConsumerState<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends ConsumerState<AddHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _targetController;
  late final TextEditingController _unitController;

  late String _selectedCategory;
  late HabitTrackingType _trackingType;
  late HabitScheduleType _scheduleType;
  late List<int> _scheduledDays;
  String? _reminderTime;
  late String _colorHex;
  late String _icon;

  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'Health',
      'icon': Icons.favorite,
      'color': AppColors.categoryHealth,
      'colorHex': '#EF4444'
    },
    {
      'name': 'Fitness',
      'icon': Icons.fitness_center,
      'color': AppColors.categoryFitness,
      'colorHex': '#F97316'
    },
    {
      'name': 'Learning',
      'icon': Icons.menu_book,
      'color': AppColors.categoryLearning,
      'colorHex': '#3B82F6'
    },
    {
      'name': 'Productivity',
      'icon': Icons.bolt,
      'color': AppColors.categoryProductivity,
      'colorHex': '#EAB308'
    },
    {
      'name': 'Mindfulness',
      'icon': Icons.self_improvement,
      'color': AppColors.categoryMindfulness,
      'colorHex': '#8B5CF6'
    },
    {
      'name': 'Personal',
      'icon': Icons.person,
      'color': AppColors.categoryPersonal,
      'colorHex': '#06B6D4'
    },
    {
      'name': 'Other',
      'icon': Icons.category,
      'color': AppColors.categoryOther,
      'colorHex': '#64748B'
    },
  ];

  @override
  void initState() {
    super.initState();
    final h = widget.habitToEdit;
    _nameController = TextEditingController(text: h?.name ?? '');
    _descController = TextEditingController(text: h?.description ?? '');
    _targetController = TextEditingController(
      text: h != null
          ? (h.targetValue == h.targetValue.roundToDouble()
              ? h.targetValue.toInt().toString()
              : h.targetValue.toString())
          : '1',
    );
    _unitController = TextEditingController(text: h?.unit ?? 'times');

    _selectedCategory = h?.category ?? 'Health';
    _trackingType = h?.trackingType ?? HabitTrackingType.binary;
    _scheduleType = h?.scheduleType ?? HabitScheduleType.daily;
    _scheduledDays =
        h != null ? List.from(h.scheduledDays) : [1, 2, 3, 4, 5, 6, 7];
    _reminderTime = h?.reminderTime;
    _colorHex = h?.colorHex ?? '#16A34A';
    _icon = h?.icon ?? 'water_drop';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _targetController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  String get _scheduleSubtitle {
    switch (_scheduleType) {
      case HabitScheduleType.daily:
        return 'Every day';
      case HabitScheduleType.weekdays:
        return 'Weekdays (Mon - Fri)';
      case HabitScheduleType.custom:
        const daysMap = {
          1: 'Mon',
          2: 'Tue',
          3: 'Wed',
          4: 'Thu',
          5: 'Fri',
          6: 'Sat',
          7: 'Sun'
        };
        return _scheduledDays.map((d) => daysMap[d] ?? '').join(', ');
    }
  }

  Future<void> _openScheduleSheet() async {
    final result = await ScheduleBottomSheet.show(
      context,
      scheduleType: _scheduleType,
      scheduledDays: _scheduledDays,
    );
    if (result != null) {
      setState(() {
        _scheduleType = result.scheduleType;
        _scheduledDays = result.scheduledDays;
      });
    }
  }

  Future<void> _openReminderSheet() async {
    await NotificationService().requestPermissions();
    if (!mounted) return;
    final result = await ReminderBottomSheet.show(
      context,
      enabled: _reminderTime != null,
      time: _reminderTime ?? '09:00 AM',
      repeatDays: _scheduledDays,
    );
    if (result != null) {
      setState(() {
        _reminderTime = result.enabled ? result.reminderTime : null;
      });
    }
  }

  Future<void> _saveHabit() async {
    if (!_formKey.currentState!.validate()) return;

    final trimmedName = _nameController.text.trim();
    final targetVal = _trackingType == HabitTrackingType.binary
        ? 1.0
        : (double.tryParse(_targetController.text.trim()) ?? 1.0);

    final now = DateTime.now();

    if (widget.habitToEdit != null) {
      // Update existing habit (preserving historical start date and createdAt)
      final updated = widget.habitToEdit!.copyWith(
        name: trimmedName,
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        category: _selectedCategory,
        icon: _icon,
        colorHex: _colorHex,
        trackingType: _trackingType,
        targetValue: targetVal,
        unit: _unitController.text.trim().isEmpty
            ? null
            : _unitController.text.trim(),
        scheduleType: _scheduleType,
        scheduledDays: _scheduledDays,
        reminderTime: _reminderTime,
        updatedAt: now,
      );

      await ref.read(habitsNotifierProvider.notifier).updateHabit(updated);

      if (updated.reminderTime != null) {
        await NotificationService().scheduleHabitReminder(
          habitId: updated.id,
          habitName: updated.name,
          timeString: updated.reminderTime!,
          scheduledDays: updated.scheduledDays,
        );
      } else {
        await NotificationService().cancelHabitReminder(updated.id);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Updated "${updated.name}" successfully!'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
        context.pop();
      }
    } else {
      // Create new habit
      final newHabit = Habit(
        id: const Uuid().v4(),
        name: trimmedName,
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        category: _selectedCategory,
        icon: _icon,
        colorHex: _colorHex,
        trackingType: _trackingType,
        targetValue: targetVal,
        unit: _unitController.text.trim().isEmpty
            ? null
            : _unitController.text.trim(),
        scheduleType: _scheduleType,
        scheduledDays: _scheduledDays,
        startDate: DateTime(now.year, now.month, now.day),
        reminderTime: _reminderTime,
        isArchived: false,
        createdAt: now,
        updatedAt: now,
      );

      await ref.read(habitsNotifierProvider.notifier).addHabit(newHabit);

      if (newHabit.reminderTime != null) {
        await NotificationService().scheduleHabitReminder(
          habitId: newHabit.id,
          habitName: newHabit.name,
          timeString: newHabit.reminderTime!,
          scheduledDays: newHabit.scheduledDays,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Created "${newHabit.name}" successfully!'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.habitToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Habit' : 'Add New Habit'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // Habit Name
              const Text('Habit Name *',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                maxLength: 60,
                decoration: const InputDecoration(
                    hintText: 'e.g., Drink Water, Read a Book'),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a habit name';
                  }
                  if (val.trim().length > 60) {
                    return 'Habit name cannot exceed 60 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              const Text('Description (Optional)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descController,
                maxLines: 2,
                decoration: const InputDecoration(
                    hintText: 'Stay hydrated for energy and focus...'),
              ),
              const SizedBox(height: 20),

              // Category Selector
              const Text('Category',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.map((cat) {
                    final isSelected = _selectedCategory == cat['name'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: isSelected,
                        label: Row(
                          children: [
                            Icon(cat['icon'] as IconData,
                                size: 16,
                                color: isSelected
                                    ? Colors.white
                                    : cat['color'] as Color),
                            const SizedBox(width: 6),
                            Text(cat['name'] as String),
                          ],
                        ),
                        selectedColor: AppColors.primaryGreen,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (theme.brightness == Brightness.dark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight),
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                        onSelected: (val) {
                          setState(() {
                            _selectedCategory = cat['name'] as String;
                            _colorHex = cat['colorHex'] as String;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),

              // Tracking Type Switcher
              const Text('Tracking Type',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 10),
              SegmentedButton<HabitTrackingType>(
                segments: const [
                  ButtonSegment(
                    value: HabitTrackingType.binary,
                    label: Text('Done/Undo'),
                    icon: Icon(Icons.check_circle_outline),
                  ),
                  ButtonSegment(
                    value: HabitTrackingType.numeric,
                    label: Text('Numeric'),
                    icon: Icon(Icons.numbers),
                  ),
                  ButtonSegment(
                    value: HabitTrackingType.duration,
                    label: Text('Duration'),
                    icon: Icon(Icons.timer_outlined),
                  ),
                ],
                selected: {_trackingType},
                onSelectionChanged: (set) {
                  setState(() {
                    _trackingType = set.first;
                    if (_trackingType == HabitTrackingType.numeric) {
                      _targetController.text = '2000';
                      _unitController.text = 'ml';
                    } else if (_trackingType == HabitTrackingType.duration) {
                      _targetController.text = '20';
                      _unitController.text = 'mins';
                    } else {
                      _targetController.text = '1';
                      _unitController.text = 'times';
                    }
                  });
                },
              ),
              const SizedBox(height: 20),

              // Target Configuration if Numeric or Duration
              if (_trackingType != HabitTrackingType.binary) ...[
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Daily Target *',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _targetController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration:
                                const InputDecoration(hintText: 'e.g. 2000'),
                            validator: (val) {
                              final numVal = double.tryParse(val ?? '');
                              if (numVal == null || numVal <= 0) {
                                return 'Must be > 0';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Unit',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _unitController,
                            decoration: const InputDecoration(
                                hintText: 'e.g. ml, mins'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],

              // Schedule Setting
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_month,
                    color: AppColors.primaryGreen),
                title: const Text('Schedule',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(_scheduleSubtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: _openScheduleSheet,
              ),
              const Divider(),

              // Reminder Setting
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.notifications_active,
                    color: AppColors.primaryGreen),
                title: const Text('Reminder',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(_reminderTime ?? 'Off'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _openReminderSheet,
              ),
              const SizedBox(height: 32),

              // Save CTA Button
              ElevatedButton(
                onPressed: _saveHabit,
                child: Text(isEditing ? 'Save Changes' : 'Save Habit'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
