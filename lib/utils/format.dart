/// Small display-format helpers shared by screens and the CSV export.

/// Formats a score/total number: whole numbers without decimals
/// (8 -> "8"), fractions with two decimals (7.5 -> "7.50").
String formatScore(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }
  return value.toStringAsFixed(2);
}

/// Formats a countdown / elapsed seconds value as mm:ss (or h:mm:ss).
String formatClock(int totalSeconds) {
  final s = totalSeconds < 0 ? 0 : totalSeconds;
  final h = s ~/ 3600;
  final m = (s % 3600) ~/ 60;
  final sec = s % 60;
  String two(int n) => n.toString().padLeft(2, '0');
  if (h > 0) {
    return '$h:${two(m)}:${two(sec)}';
  }
  return '${two(m)}:${two(sec)}';
}

/// Human-friendly time used, e.g. "1 min 20 sec" or "45 sec".
String formatTimeUsed(int totalSeconds) {
  final s = totalSeconds < 0 ? 0 : totalSeconds;
  if (s < 60) {
    return '$s sec';
  }
  final m = s ~/ 60;
  final sec = s % 60;
  if (sec == 0) {
    return '$m min';
  }
  return '$m min $sec sec';
}
