import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/habit.dart';

class AddHabitScreen extends StatefulWidget {
  const AddHabitScreen({Key? key}) : super(key: key);

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _targetController = TextEditingController(text: '1');
  final _unitController = TextEditingController(text: 'times');

  String _selectedCategory = 'Health';
  HabitTrackingType _trackingType = HabitTrackingType.binary;
  HabitScheduleType _scheduleType = HabitScheduleType.daily;
  List<int> _customDays = [1, 2, 3, 4, 5, 6, 7];
  String? _reminderTime;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Health', 'icon': Icons.favorite, 'color': AppColors.categoryHealth},
    {'name': 'Fitness', 'icon': Icons.fitness_center, 'color': AppColors.categoryFitness},
    {'name': 'Learning', 'icon': Icons.menu_book, 'color': AppColors.categoryLearning},
    {'name': 'Productivity', 'icon': Icons.bolt, 'color': AppColors.categoryProductivity},
    {'name': 'Mindfulness', 'icon': Icons.self_improvement, 'color': AppColors.categoryMindfulness},
    {'name': 'Personal', 'icon': Icons.person, 'color': AppColors.categoryPersonal},
    {'name': 'Other', 'icon': Icons.category, 'color': AppColors.categoryOther},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _targetController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  void _saveHabit() {
    if (_formKey.currentState?.validate() ?? false) {
      // Habit validated!
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Habit "${_nameController.text.trim()}" created successfully!'),
          backgroundColor: AppColors.primaryGreen,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Habit'),
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
              // Habit Name Field
              const Text(
                'Habit Name *',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                maxLength: 60,
                decoration: const InputDecoration(
                  hintText: 'e.g., Drink Water, Read Book',
                ),
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

              // Description Field
              const Text(
                'Description (Optional)',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Add some notes or motivation...',
                ),
              ),
              const SizedBox(height: 20),

              // Category Selector
              const Text(
                'Category',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
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
                            Icon(cat['icon'] as IconData, size: 16, color: isSelected ? Colors.white : cat['color'] as Color),
                            const SizedBox(width: 6),
                            Text(cat['name'] as String),
                          ],
                        ),
                        selectedColor: AppColors.primaryGreen,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textPrimaryLight,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                        onSelected: (val) {
                          setState(() {
                            _selectedCategory = cat['name'] as String;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),

              // Tracking Type Switcher
              const Text(
                'Tracking Type',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
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
                          const Text('Target Value *', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _targetController,
                            keyboardType: TextInputKeypad,
                            decoration: const InputDecoration(hintText: 'e.g. 2000'),
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
                          const Text('Unit', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _unitController,
                            decoration: const InputDecoration(hintText: 'e.g. ml, mins'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],

              // Schedule Configuration Section
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_month, color: AppColors.primaryGreen),
                title: const Text('Schedule', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(_scheduleType == HabitScheduleType.daily ? 'Every day' : 'Custom weekdays'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // Opens Schedule Bottom Sheet
                },
              ),
              const Divider(),

              // Reminder Configuration Section
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.notifications_active, color: AppColors.primaryGreen),
                title: const Text('Reminder', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(_reminderTime ?? 'Off'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // Opens Reminder Bottom Sheet
                },
              ),
              const SizedBox(height: 32),

              // Save Habit Button
              ElevatedButton(
                onPressed: _saveHabit,
                child: const Text('Save Habit'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  TextInputType get TextInputKeypad => const TextInputType.numberWithOptions(decimal: true);
}
