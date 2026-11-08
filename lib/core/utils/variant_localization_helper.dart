import 'package:easy_localization/easy_localization.dart';

/// 🍕 Helper for localizing dynamic pizza sizes and variant titles (Medium, Big, Mega, etc.)
class VariantLocalizationHelper {
  const VariantLocalizationHelper._();

  /// Check whether the variant title is a generic/default "size" placeholder
  static bool isSize(String? rawTitle) {
    if (rawTitle == null || rawTitle.trim().isEmpty) return false;
    final lower = rawTitle.trim().toLowerCase();
    if (lower == 'size' || lower == 'размер' || lower == "o'lcham" || lower == 'size ()') {
      return true;
    }
    final mainPart = lower.contains('(') ? lower.split('(').first.trim() : lower;
    return mainPart == 'size' || mainPart == 'размер' || mainPart == "o'lcham";
  }

  /// Returns localized full title (e.g. "Medium (30 cm)" -> "O'rtacha (30 cm)")
  /// NEVER returns 'size' or 'Size'.
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

    // Agar variant "size" bo'lsa, uni hech qayerda ko'rsatma!
    if (lower == 'size' || lower == 'размер' || lower == "o'lcham") {
      if (subtitlePart != null && subtitlePart.trim() != '()') {
        return subtitlePart;
      }
      return '';
    }

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
  /// NEVER returns 'size' or 'Size'.
  static String localizeMainTitle(String? rawTitle) {
    if (rawTitle == null || rawTitle.trim().isEmpty) return '';
    final trimmed = rawTitle.trim();
    final mainPart = trimmed.contains('(') ? trimmed.split('(').first.trim() : trimmed;
    final lower = mainPart.toLowerCase();

    if (lower == 'size' || lower == 'размер' || lower == "o'lcham") {
      return '';
    }

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

