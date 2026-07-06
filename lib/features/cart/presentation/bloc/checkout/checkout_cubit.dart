import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:pizza_strada/core/network/graphql_client.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/checkout/checkout_state.dart';

class CheckoutCubit extends Cubit<CheckoutState> {
  final GraphQLClient _gqlClient;

  CheckoutCubit() : _gqlClient = buildGraphQLClient(), super(const CheckoutState());

  void setDeliveryType(bool isDelivery) {
    emit(state.copyWith(isDelivery: isDelivery));
  }

  void setBranch(String branchId) {
    emit(state.copyWith(branchId: branchId));
  }

  Future<void> setAddressAndCalculateDelivery(double lat, double lng, String address) async {
    emit(state.copyWith(lat: lat, lng: lng, address: address, loadingDelivery: true));
    try {
      const mutation = r'''
        mutation CalculateDeliveryPrice($latitude: Float!, $longitude: Float!) {
          calculateDeliveryPrice(latitude: $latitude, longitude: $longitude)
        }
      ''';
      final result = await _gqlClient.mutate(MutationOptions(
        document: gql(mutation),
        variables: {'latitude': lat, 'longitude': lng},
        operationName: 'CalculateDeliveryPrice',
      ));
      if (!result.hasException) {
        final price = double.tryParse(result.data?['calculateDeliveryPrice']?.toString() ?? '0') ?? 0;
        emit(state.copyWith(deliveryPrice: price, loadingDelivery: false));
      } else {
        emit(state.copyWith(loadingDelivery: false));
      }
    } catch (_) {
      emit(state.copyWith(loadingDelivery: false));
    }
  }

  void setPaymentMethod(String method) {
    emit(state.copyWith(selectedPaymentMethodKey: method));
  }

  void setChangeAmount(double? amount) {
    emit(state.copyWith(changeAmount: amount));
  }

  void setComment(String comment) {
    emit(state.copyWith(comment: comment));
  }

  void clearSubmitError() {
    emit(state.clearSubmitError());
  }

  void toggleLoyaltyPoints(bool use) {
    emit(state.copyWith(useLoyaltyPoints: use));
  }

  Future<void> applyPromo(String code, double subtotal) async {
    emit(state.copyWith(loadingPromo: true, promoError: null));
    try {
      const mutation = r'''
        mutation CheckPromoCode($promo_code: String!, $total_price: Int!) {
          checkPromoCode(promo_code: $promo_code, total_price: $total_price) {
            promo_code
            type
            value
          }
        }
      ''';
      final result = await _gqlClient.mutate(MutationOptions(
        document: gql(mutation),
        variables: {'promo_code': code, 'total_price': subtotal.toInt()},
        operationName: 'CheckPromoCode',
      ));
      if (result.hasException) {
        final msg = result.exception?.graphqlErrors.firstOrNull?.message ?? 'Promo xato';
        emit(state.copyWith(
          loadingPromo: false,
          promoError: msg,
          appliedPromoCode: null,
          promoType: null,
          promoValue: null,
        ));
      } else {
        final data = result.data?['checkPromoCode'];
        emit(state.copyWith(
          loadingPromo: false,
          appliedPromoCode: data?['promo_code'] as String?,
          promoType: data?['type'] as int?,
          promoValue: double.tryParse(data?['value']?.toString() ?? '0'),
          promoError: null,
        ));
      }
    } catch (e) {
      emit(state.copyWith(loadingPromo: false, promoError: e.toString()));
    }
  }

  void clearPromo() {
    emit(state.copyWith(
      appliedPromoCode: null,
      promoType: null,
      promoValue: null,
      promoError: null,
    ));
  }

  Future<void> submitOrder({
    required List<Map<String, dynamic>> products,
    required int usedPoints,
  }) async {
    emit(state.copyWith(isSubmitting: true, submitError: null));
    try {
      const mutation = r'''
        mutation CreateOrder(
          $type: Int!,
          $branch_id: Int,
          $latitude: Float,
          $longitude: Float,
          $address: String,
          $payment_method: Int!,
          $change: Int,
          $comment: String,
          $promo_code: String,
          $products: [OrderProductInput!]!
        ) {
          createOrder(
            type: $type,
            branch_id: $branch_id,
            latitude: $latitude,
            longitude: $longitude,
            address: $address,
            payment_method: $payment_method,
            change: $change,
            comment: $comment,
            promo_code: $promo_code,
            products: $products
          ) {
            order_id
            total_price
            payment_url
          }
        }
      ''';

      final vars = {
        'type': state.isDelivery ? 1 : 2, 
        'branch_id': state.isDelivery ? null : int.tryParse(state.branchId ?? ''),
        'latitude': state.isDelivery ? state.lat : null,
        'longitude': state.isDelivery ? state.lng : null,
        'address': state.isDelivery ? state.address : null,
        'payment_method': int.tryParse(state.selectedPaymentMethodKey) ?? 0,
        'change': state.changeAmount?.toInt(),
        'comment': state.comment,
        'promo_code': state.appliedPromoCode,
        'products': products,
      };

      final result = await _gqlClient.mutate(MutationOptions(
        document: gql(mutation),
        variables: vars,
        operationName: 'CreateOrder',
      ));

      if (result.hasException) {
        final msg = result.exception?.graphqlErrors.firstOrNull?.message ?? 'Server xatosi';
        emit(state.copyWith(isSubmitting: false, submitError: msg));
      } else {
        emit(state.copyWith(
          isSubmitting: false,
          successData: result.data?['createOrder'],
        ));
      }
    } catch (e) {
      emit(state.copyWith(isSubmitting: false, submitError: e.toString()));
    }
  }
}
