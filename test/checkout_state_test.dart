import 'package:flutter_test/flutter_test.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/checkout/checkout_state.dart';

void main() {
  group('CheckoutState & fullComment tests', () {
    test('Default state has empty fullComment when default noUtensils is false or true', () {
      const state = CheckoutState(noUtensils: false);
      expect(state.fullComment, isEmpty);
    });

    test('fullComment includes address details correctly', () {
      const state = CheckoutState(
        entrance: '2',
        floor: '4',
        apartment: '18',
        doorPhone: '18K',
        noUtensils: true,
        courierNote: 'Qo\'ng\'iroq qilmang',
      );

      final comment = state.fullComment;
      expect(comment, contains('Podyezd: 2'));
      expect(comment, contains('Qavat: 4'));
      expect(comment, contains('Xonadon: 18'));
      expect(comment, contains('Domofon: 18K'));
      expect(comment, contains('Qoshiq va salfetka kerak emas'));
      expect(comment, contains('Izoh: Qo\'ng\'iroq qilmang'));
    });

    test('fullComment handles optional/partial details without empty entries', () {
      const state = CheckoutState(
        apartment: '42',
        noUtensils: false,
      );

      expect(state.fullComment, 'Xonadon: 42');
    });

    test('copyWith updates address details and preferences correctly', () {
      var state = const CheckoutState();
      state = state.copyWith(
        entrance: '1',
        floor: '3',
        apartment: '12',
        doorPhone: '12',
        noUtensils: false,
        courierNote: 'Kuryer tez kelsin',
      );

      expect(state.entrance, '1');
      expect(state.floor, '3');
      expect(state.apartment, '12');
      expect(state.doorPhone, '12');
      expect(state.noUtensils, isFalse);
      expect(state.courierNote, 'Kuryer tez kelsin');
      expect(state.fullComment, 'Podyezd: 1, Qavat: 3, Xonadon: 12, Domofon: 12, Izoh: Kuryer tez kelsin');
    });
  });
}

