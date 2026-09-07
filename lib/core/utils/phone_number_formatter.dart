import 'package:flutter/services.dart';

/// O'zbekiston telefon raqamlarini formatlash klassi.
/// Format: `(90) 123-45-67` (prefix bilan: `+998 (90) 123-45-67`)
class PhoneNumberFormatter extends TextInputFormatter {
  const PhoneNumberFormatter();

  /// Raqamni `(XX) XXX-XX-XX` ko'rinishida formatlash
  static String format(String phone) {
    String digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('998') && digits.length > 9) {
      digits = digits.substring(3);
    }
    if (digits.length > 9) {
      digits = digits.substring(0, 9);
    }

    if (digits.isEmpty) return '';

    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 0) buffer.write('(');
      buffer.write(digits[i]);
      if (i == 1) buffer.write(') ');
      if (i == 4) buffer.write('-');
      if (i == 6) buffer.write('-');
    }
    return buffer.toString();
  }

  /// To'liq xalqaro format: `+998 (90) 123-45-67`
  static String formatFull(String phone) {
    final formatted = format(phone);
    if (formatted.isEmpty) return '+998';
    return '+998 $formatted';
  }

  /// Faqat 9 ta raqamni ajratib olish (masalan: `997775443`)
  static String extractDigits(String phone) {
    String digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('998') && digits.length > 9) {
      digits = digits.substring(3);
    }
    if (digits.length > 9) {
      digits = digits.substring(0, 9);
    }
    return digits;
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text;
    String digits = text.replaceAll(RegExp(r'\D'), '');

    // Maxsus belgilar ustida backspace bosilganda oldingi raqamni o'chirish
    if (newValue.text.length < oldValue.text.length) {
      final oldDigits = oldValue.text.replaceAll(RegExp(r'\D'), '');
      if (digits == oldDigits && digits.isNotEmpty) {
        digits = digits.substring(0, digits.length - 1);
      }
    }

    if (digits.startsWith('998') && digits.length > 9) {
      digits = digits.substring(3);
    }
    if (digits.length > 9) {
      digits = digits.substring(0, 9);
    }

    final formatted = format(digits);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
