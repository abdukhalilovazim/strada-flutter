import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pizza_strada/core/theme/app_theme.dart';

void main() {
  testWidgets('ElevatedButton and OutlinedButton in Row layout without infinite width constraint error',
      (WidgetTester tester) async {
    // Tests both Light and Dark themes
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: Center(
              child: Row(
                children: [
                  const Expanded(child: TextField()),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {},
                      child: Text('cart.apply'.tr()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () {},
                      child: Text('common.cancel'.tr()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Verify that no layout exceptions occurred and both buttons are rendered
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);
    }
  });
}
