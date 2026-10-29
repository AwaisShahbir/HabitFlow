import 'package:intl/intl.dart';

/// Pure date calculation helpers ensuring consistent day comparisons
/// regardless of time, timezone offsets, or Daylight Saving Time changes.
class AppDateUtils {
  static final DateFormat _isoFormat = DateFormat('yyyy-MM-dd');

  /// Normalizes a DateTime to midnight (00:00:00.000) local time.
  static DateTime normalize(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Returns today's date normalized to midnight.
  static DateTime get today => normalize(DateTime.now());

  /// Formats date to 'YYYY-MM-DD' string.
  static String toIsoDateString(DateTime date) {
    return _isoFormat.format(date);
  }

  /// Parses 'YYYY-MM-DD' string to a normalized DateTime.
  static DateTime fromIsoDateString(String dateStr) {
    final parsed = _isoFormat.parseStrict(dateStr);
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  /// Checks if [date] is today.
  static bool isToday(DateTime date) {
    final n = normalize(date);
    final t = today;
    return n.year == t.year && n.month == t.month && n.day == t.day;
  }

  /// Checks if [date] is in the past (before today).
  static bool isPast(DateTime date) {
    return normalize(date).isBefore(today);
  }

  /// Checks if [date] is in the future (after today).
  static bool isFuture(DateTime date) {
    return normalize(date).isAfter(today);
  }

  /// Compares two dates by year, month, and day only.
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Returns 7 dates representing the week containing [referenceDate].
  /// Week starts on [startOnMonday] (Monday = 1, Sunday = 7).
  static List<DateTime> getWeekDates(DateTime referenceDate, {bool startOnMonday = true}) {
    final norm = normalize(referenceDate);
    final currentWeekday = norm.weekday; // 1 = Monday, 7 = Sunday

    int difference;
    if (startOnMonday) {
      difference = currentWeekday - 1;
    } else {
      difference = currentWeekday % 7; // Sunday is 0
    }

    final startOfWeek = norm.subtract(Duration(days: difference));
    return List.generate(7, (index) => startOfWeek.add(Duration(days: index)));
  }

  /// Returns all dates in the month of [year] and [month].
  static List<DateTime> getMonthDates(int year, int month) {
    final lastDay = DateTime(year, month + 1, 0);
    return List.generate(
      lastDay.day,
      (index) => DateTime(year, month, index + 1),
    );
  }
}

