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

  /// Formats phone number into "+999 99 999 99 99" format.
  /// Example: "+998662211177" → "+998 66 221 11 77"
  static String formatPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 12) {
      return '+${digits.substring(0, 3)} ${digits.substring(3, 5)} ${digits.substring(5, 8)} ${digits.substring(8, 10)} ${digits.substring(10, 12)}';
    } else if (digits.length == 9) {
      return '+998 ${digits.substring(0, 2)} ${digits.substring(2, 5)} ${digits.substring(5, 7)} ${digits.substring(7, 9)}';
    }
    return phone.startsWith('+') ? phone : '+$phone';
  }
}
