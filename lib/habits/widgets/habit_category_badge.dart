import 'package:flutter/material.dart';

class HabitCategoryBadge extends StatelessWidget {
  final String category;
  final double size;

  const HabitCategoryBadge({
    Key? key,
    required this.category,
    this.size = 46,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (category) {
      case 'Health':
        return _buildBadge(
          bgGradient: const [Color(0xFFE0F2FE), Color(0xFFBAE6FD)],
          iconColor: const Color(0xFF0284C7),
          icon: Icons.water_drop_rounded,
          accentColor: const Color(0xFF38BDF8),
        );
      case 'Fitness':
        return _buildBadge(
          bgGradient: const [Color(0xFFFFEDD5), Color(0xFFFED7AA)],
          iconColor: const Color(0xFFEA580C),
          icon: Icons.fitness_center_rounded,
          accentColor: const Color(0xFFFB923C),
        );
      case 'Learning':
        return _buildBadge(
          bgGradient: const [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
          iconColor: const Color(0xFFD97706),
          icon: Icons.menu_book_rounded,
          accentColor: const Color(0xFFFBBF24),
        );
      case 'Mindfulness':
        return _buildBadge(
          bgGradient: const [Color(0xFFEDE9FE), Color(0xFFDDD6FE)],
          iconColor: const Color(0xFF7C3AED),
          icon: Icons.spa_rounded,
          accentColor: const Color(0xFFA78BFA),
        );
      case 'Productivity':
        return _buildBadge(
          bgGradient: const [Color(0xFFDCFCE7), Color(0xFFBBF7D0)],
          iconColor: const Color(0xFF16A34A),
          icon: Icons.bolt_rounded,
          accentColor: const Color(0xFF4ADE80),
        );
      default:
        return _buildBadge(
          bgGradient: const [Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
          iconColor: const Color(0xFF64748B),
          icon: Icons.category_rounded,
          accentColor: const Color(0xFF94A3B8),
        );
    }
  }

  Widget _buildBadge({
    required List<Color> bgGradient,
    required Color iconColor,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: bgGradient,
        ),
        boxShadow: [
          BoxShadow(
            color: bgGradient.last.withOpacity(0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          icon,
          color: iconColor,
          size: size * 0.52,
        ),
      ),
    );
  }
}

