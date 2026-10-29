import 'package:flutter/material.dart';
import 'package:habitflow/habits/habit.dart';

class ProgressBottomSheet extends StatefulWidget {
  final Habit habit;
  final double currentProgress;
  final String dateSubtitle;

  const ProgressBottomSheet({
    Key? key,
    required this.habit,
    required this.currentProgress,
    required this.dateSubtitle,
  }) : super(key: key);

  static Future<double?> show(
    BuildContext context, {
    required Habit habit,
    required double currentProgress,
    required String dateSubtitle,
  }) {
    return showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ProgressBottomSheet(
        habit: habit,
        currentProgress: currentProgress,
        dateSubtitle: dateSubtitle,
      ),
    );
  }

  @override
  State<ProgressBottomSheet> createState() => _ProgressBottomSheetState();
}

class _ProgressBottomSheetState extends State<ProgressBottomSheet> {
  late double _progress;
  bool _isCustomTyping = false;
  String _typedString = '';

  @override
  void initState() {
    super.initState();
    _progress = widget.currentProgress;
    _typedString = _formatNumber(_progress);
  }

  void _addQuickIncrement(double delta) {
    setState(() {
      _progress += delta;
      if (_progress < 0) _progress = 0;
      _typedString = _formatNumber(_progress);
      _isCustomTyping = false;
    });
  }

  void _handleKeypadPress(String key) {
    setState(() {
      if (key == 'backspace') {
        if (_typedString.isNotEmpty) {
          _typedString = _typedString.substring(0, _typedString.length - 1);
          _progress = double.tryParse(_typedString) ?? 0.0;
        }
      } else {
        if (!_isCustomTyping) {
          _typedString = key;
          _isCustomTyping = true;
        } else {
          if (_typedString.length < 6) {
            _typedString += key;
          }
        }
        _progress = double.tryParse(_typedString) ?? _progress;
      }
    });
  }

  List<double> _getQuickIncrements() {
    if (widget.habit.trackingType == HabitTrackingType.duration) {
      return [5, 10, 15, 30];
    }
    final target = widget.habit.targetValue;
    if (target >= 1000) {
      return [250, 500, 750, 1000];
    } else if (target >= 100) {
      return [10, 25, 50, 100];
    } else {
      return [1, 2, 5, 10];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final target = widget.habit.targetValue;
    final percentage = target > 0 ? ((_progress / target) * 100).toInt() : 0;
    final unit = widget.habit.unit ?? '';
    final increments = _getQuickIncrements();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Drag Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title & Date Subtitle
              Text(
                'Update Progress',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.dateSubtitle,
                style: TextStyle(
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),

              // Progress Display (e.g. 1,500 / 2,000 ml • 75%)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    _formatNumber(_progress),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    ' / ${_formatNumber(target)} $unit',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$percentage%',
                      style: const TextStyle(
                        color: Color(0xFF15803D),
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Animated Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: target > 0 ? (_progress / target).clamp(0.0, 1.0) : 0,
                  minHeight: 10,
                  backgroundColor:
                      isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF15803D)),
                ),
              ),
              const SizedBox(height: 20),

              // Quick Increment Pills (Screen 10)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: increments.map((inc) {
                  return GestureDetector(
                    onTap: () => _addQuickIncrement(inc),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF16A34A).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        '+${_formatNumber(inc)}',
                        style: const TextStyle(
                          color: Color(0xFF15803D),
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),

              // Screen 10 Custom Numeric Keypad (1-9, 0, ⌫)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    _buildKeypadRow(['1', '2', '3'], isDark),
                    _buildKeypadRow(['4', '5', '6'], isDark),
                    _buildKeypadRow(['7', '8', '9'], isDark),
                    _buildKeypadRow(['', '0', 'backspace'], isDark),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Save Progress CTA Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF15803D),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context, _progress),
                  child: const Text(
                    'Save Progress',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypadRow(List<String> keys, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: keys.map((key) {
          if (key.isEmpty) {
            return const SizedBox(width: 70, height: 42);
          }
          if (key == 'backspace') {
            return InkWell(
              onTap: () => _handleKeypadPress('backspace'),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 70,
                height: 42,
                alignment: Alignment.center,
                child: Icon(
                  Icons.backspace_outlined,
                  size: 22,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            );
          }

          return InkWell(
            onTap: () => _handleKeypadPress(key),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 70,
              height: 42,
              alignment: Alignment.center,
              child: Text(
                key,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatNumber(double val) {
    if (val == val.roundToDouble()) {
      return val.toInt().toString();
    }
    return val.toStringAsFixed(1);
  }
}
