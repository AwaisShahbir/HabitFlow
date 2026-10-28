import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_date_utils.dart';

class HistoryCalendarScreen extends StatefulWidget {
  const HistoryCalendarScreen({Key? key}) : super(key: key);

  @override
  State<HistoryCalendarScreen> createState() => _HistoryCalendarScreenState();
}

class _HistoryCalendarScreenState extends State<HistoryCalendarScreen> {
  DateTime _currentMonth = DateTime(2026, 10);
  DateTime _selectedDay = AppDateUtils.today;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daysInMonth = AppDateUtils.getMonthDates(_currentMonth.year, _currentMonth.month);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Month Header with Prev/Next Navigation
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      setState(() {
                        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
                      });
                    },
                  ),
                  Text(
                    '${_getMonthName(_currentMonth.month)} ${_currentMonth.year}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () {
                      setState(() {
                        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
                      });
                    },
                  ),
                ],
              ),
            ),

            // Weekday labels (Mon, Tue, Wed...)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                    .map((d) => SizedBox(
                          width: 32,
                          child: Text(
                            d,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textSecondaryLight,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 8),

            // Monthly Calendar Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: daysInMonth.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.0,
                ),
                itemBuilder: (context, index) {
                  final date = daysInMonth[index];
                  final isSelected = AppDateUtils.isSameDay(date, _selectedDay);
                  final isToday = AppDateUtils.isToday(date);
                  final isCompletedMock = index % 3 != 0;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDay = date;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryGreen
                            : (theme.brightness == Brightness.dark
                                ? AppColors.surfaceDark
                                : Colors.white),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isToday
                              ? AppColors.primaryGreen
                              : (isSelected ? AppColors.primaryGreen : Colors.transparent),
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            date.day.toString(),
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : (theme.brightness == Brightness.dark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                          if (!isSelected) ...[
                            const SizedBox(height: 2),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isCompletedMock ? AppColors.accentGreen : AppColors.error,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),

            // Selected Day Inspection Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${AppDateUtils.toIsoDateString(_selectedDay)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const Text('3/5 Completed', style: TextStyle(color: AppColors.textSecondaryLight)),
                ],
              ),
            ),

            // Habits recorded on this day
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildInspectionTile('Drink Water', '2,000 / 2,000 ml', true),
                  _buildInspectionTile('Morning Exercise', '30 / 30 mins', true),
                  _buildInspectionTile('Read a Book', '20 mins', false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInspectionTile(String title, String progress, bool isDone) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(progress),
        trailing: Icon(
          isDone ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isDone ? AppColors.primaryGreen : AppColors.textMutedLight,
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}
