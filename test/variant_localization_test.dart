import 'package:flutter_test/flutter_test.dart';
import 'package:pizza_strada/core/utils/variant_localization_helper.dart';

void main() {
  group('VariantLocalizationHelper Tests', () {
    test('localizes main titles without parentheses', () {
      expect(VariantLocalizationHelper.localizeMainTitle('Medium (30 cm)'), isNotEmpty);
      expect(VariantLocalizationHelper.localizeMainTitle('Big (35 cm)'), isNotEmpty);
      expect(VariantLocalizationHelper.localizeMainTitle('Mega (40 cm)'), isNotEmpty);
    });

    test('handles empty or null gracefully', () {
      expect(VariantLocalizationHelper.localize(null), '');
      expect(VariantLocalizationHelper.localize(''), '');
      expect(VariantLocalizationHelper.localizeMainTitle(null), '');
      expect(VariantLocalizationHelper.localizeMainTitle(''), '');
    });
  });
}

