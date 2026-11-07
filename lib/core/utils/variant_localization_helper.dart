import 'package:easy_localization/easy_localization.dart';

/// 🍕 Helper for localizing dynamic pizza sizes and variant titles (Medium, Big, Mega, etc.)
class VariantLocalizationHelper {
  const VariantLocalizationHelper._();

  /// Returns localized full title (e.g. "Medium (30 cm)" -> "O'rtacha (30 cm)")
  static String localize(String? rawTitle) {
    if (rawTitle == null || rawTitle.trim().isEmpty) return '';

    final trimmed = rawTitle.trim();
    String mainPart = trimmed;
    String? subtitlePart;

    if (trimmed.contains('(')) {
      final parts = trimmed.split('(');
      mainPart = parts.first.trim();
      subtitlePart = '(${parts.sublist(1).join('(').trim()}';
    }

    final lower = mainPart.toLowerCase();
    String localizedMain;

    if (lower == 'medium') {
      localizedMain = 'product.size_medium'.tr();
    } else if (lower == 'big' || lower == 'large') {
      localizedMain = 'product.size_big'.tr();
    } else if (lower == 'mega') {
      localizedMain = 'product.size_mega'.tr();
    } else if (lower == 'small') {
      localizedMain = 'product.size_small'.tr();
    } else if (lower == 'standard') {
      localizedMain = 'product.size_standard'.tr();
    } else {
      localizedMain = mainPart;
    }

    if (subtitlePart != null) {
      return '$localizedMain $subtitlePart';
    }
    return localizedMain;
  }

  /// Extracts cleanly the variant size title (without parentheses) and localizes it.
  static String localizeMainTitle(String? rawTitle) {
    if (rawTitle == null || rawTitle.trim().isEmpty) return '';
    final trimmed = rawTitle.trim();
    final mainPart = trimmed.contains('(') ? trimmed.split('(').first.trim() : trimmed;
    final lower = mainPart.toLowerCase();

    if (lower == 'medium') {
      return 'product.size_medium'.tr();
    } else if (lower == 'big' || lower == 'large') {
      return 'product.size_big'.tr();
    } else if (lower == 'mega') {
      return 'product.size_mega'.tr();
    } else if (lower == 'small') {
      return 'product.size_small'.tr();
    } else if (lower == 'standard') {
      return 'product.size_standard'.tr();
    }
    return mainPart;
  }
}

