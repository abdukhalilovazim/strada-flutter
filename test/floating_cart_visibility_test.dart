import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pizza_strada/core/router/app_router.dart';
import 'package:pizza_strada/features/cart/domain/entities/cart_item_entity.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/cart_cubit.dart';
import 'package:pizza_strada/features/home/domain/entities/home_entities.dart';

void main() {
  testWidgets('Floating cart bar ONLY appears on HomePage (/home) when items in cart',
      (WidgetTester tester) async {
    final cartCubit = CartCubit();
    const testProduct = ProductEntity(
      slug: 'pizza-margarita',
      title: 'Margarita',
      description: 'Test',
      thumbnail: '',
      photo: '',
      price: 50000,
      variants: [],
      values: [],
    );

    // Populate cart with 1 item
    cartCubit.emit(const CartState(items: [
      CartItemEntity(
        product: testProduct,
        quantity: 1,
      ),
    ]));

    Widget makeTestWidget(String location) {
      return BlocProvider<CartCubit>.value(
        value: cartCubit,
        child: MaterialApp(
          home: MainScaffold(
            location: location,
            child: const SizedBox(),
          ),
        ),
      );
    }

    // 1. On /home -> Floating cart bar IS visible
    await tester.pumpWidget(makeTestWidget('/home'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.arrow_forward_ios_rounded), findsOneWidget);

    // 2. On /cart -> Floating cart bar is NOT visible
    await tester.pumpWidget(makeTestWidget('/cart'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.arrow_forward_ios_rounded), findsNothing);

    // 3. On /profile -> Floating cart bar is NOT visible
    await tester.pumpWidget(makeTestWidget('/profile'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.arrow_forward_ios_rounded), findsNothing);

    // 4. On /promotions -> Floating cart bar is NOT visible
    await tester.pumpWidget(makeTestWidget('/promotions'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.arrow_forward_ios_rounded), findsNothing);
  });
}

