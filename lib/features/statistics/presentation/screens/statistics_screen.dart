import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Top Overview Cards (Completion Rate & Current Streak)
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.brightness == Brightness.dark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Row(
                          children: [
                            Icon(Icons.pie_chart, color: AppColors.primaryGreen, size: 20),
                            SizedBox(width: 8),
                            Text(
                              '78%',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        SizedBox(height: 6),
                        Text('Completion Rate', style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.brightness == Brightness.dark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Row(
                          children: [
                            Icon(Icons.local_fire_department, color: Color(0xFFF97316), size: 20),
                            SizedBox(width: 8),
                            Text(
                              '18',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        SizedBox(height: 6),
                        Text('Current Streak', style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Completion Trend Header & Graph Placeholder
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Completion Trend',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '78% avg',
                  style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 160,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.brightness == Brightness.dark
                      ? AppColors.borderDark
                      : AppColors.borderLight,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildTrendBar(40),
                  _buildTrendBar(60),
                  _buildTrendBar(80),
                  _buildTrendBar(50),
                  _buildTrendBar(100),
                  _buildTrendBar(90),
                  _buildTrendBar(75),
                  _buildTrendBar(85),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Habit Performance List
            const Text(
              'Habit Performance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildHabitPerformanceRow('Drink Water', 0.85, Icons.water_drop, const Color(0xFF2563EB)),
            const SizedBox(height: 12),
            _buildHabitPerformanceRow('Morning Exercise', 0.72, Icons.fitness_center, const Color(0xFFEA580C)),
            const SizedBox(height: 12),
            _buildHabitPerformanceRow('Read a Book', 0.60, Icons.menu_book, const Color(0xFF7C3AED)),
            const SizedBox(height: 12),
            _buildHabitPerformanceRow('Meditate', 0.90, Icons.self_improvement, const Color(0xFFD97706)),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendBar(double heightPercent) {
    return Container(
      width: 14,
      height: 120 * (heightPercent / 100),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }

  Widget _buildHabitPerformanceRow(String name, double completionRate, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ),
              Text(
                '${(completionRate * 100).toInt()}%',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: completionRate,
              backgroundColor: AppColors.borderLight,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
