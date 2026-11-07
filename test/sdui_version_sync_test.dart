import 'package:flutter_test/flutter_test.dart';
import 'package:pizza_strada/core/sdui/sdui.dart';
import 'package:pizza_strada/features/home/presentation/bloc/home_cubit.dart';

void main() {
  group('SDUI Version Sync & Updating UI States Tests', () {
    test('HomeUpdatingUI state holds loading and success values correctly', () {
      const updatingState = HomeUpdatingUI(isSuccess: false);
      expect(updatingState.isSuccess, false);
      expect(updatingState.title, 'UI yangilanmoqda...');

      const successState = HomeUpdatingUI(isSuccess: true);
      expect(successState.isSuccess, true);

      expect(updatingState, isNot(equals(successState)));
    });

    test('SDUIPageUpdating state holds loading and success values correctly', () {
      const pageUpdating = SDUIPageUpdating(isSuccess: false);
      expect(pageUpdating.isSuccess, false);

      const pageSuccess = SDUIPageUpdating(isSuccess: true);
      expect(pageSuccess.isSuccess, true);

      expect(pageUpdating, isNot(equals(pageSuccess)));
    });

    test('SDUICacheManager hasVersionMismatch logic works as expected', () async {
      final cacheManager = SDUICacheManager();

      // Non-existent page has mismatch
      final isMismatch = await cacheManager.hasVersionMismatch('non_existent', 'uuid-123');
      expect(isMismatch, true);
    });
  });
}

