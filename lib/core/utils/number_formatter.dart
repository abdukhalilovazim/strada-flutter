/// Number formatter for displaying prices in Uzbek format.
/// Example: 97000 → "97 000"
class NumberFormatter {
  /// Formats an integer as "97 000 so'm" style string (space-separated thousands).
  static String formatSum(num amount) {
    final str = amount.toInt().toString();
    final buffer = StringBuffer();
    final offset = str.length % 3;
    for (int i = 0; i < str.length; i++) {
      if (i != 0 && (i - offset) % 3 == 0) buffer.write(' ');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }
}
