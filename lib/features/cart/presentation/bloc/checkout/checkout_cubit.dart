import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pizza_strada/core/network/api_client.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/checkout/checkout_state.dart';

class CheckoutCubit extends Cubit<CheckoutState> {
  final ApiClient _apiClient;

  CheckoutCubit({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient(),
        super(const CheckoutState());

  void setDeliveryType(bool isDelivery) {
    emit(state.copyWith(isDelivery: isDelivery));
  }

  void setBranch(String branchId) {
    emit(state.copyWith(branchId: branchId));
  }

  Future<void> setAddressAndCalculateDelivery(double lat, double lng, String address) async {
    emit(state.copyWith(lat: lat, lng: lng, address: address, loadingDelivery: true));
    try {
      final response = await _apiClient.post(
        'delivery-price',
        body: {'latitude': lat, 'longitude': lng},
      );
      final price = double.tryParse(response?.toString() ?? '0') ?? 0;
      emit(state.copyWith(deliveryPrice: price, loadingDelivery: false));
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
      final response = await _apiClient.post(
        'promo-code/check',
        body: {'promo_code': code, 'total_price': subtotal.toInt()},
      );
      final data = response as Map<String, dynamic>?;
      emit(state.copyWith(
        loadingPromo: false,
        appliedPromoCode: (data?['code'] ?? data?['promo_code']) as String?,
        promoType: data?['type'] as int?,
        promoValue: double.tryParse(data?['value']?.toString() ?? '0'),
        promoError: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        loadingPromo: false,
        promoError: e is ApiException ? e.message : e.toString(),
        appliedPromoCode: null,
        promoType: null,
        promoValue: null,
      ));
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
      final vars = {
        'type': state.isDelivery ? 0 : 1, 
        'branch_id': state.isDelivery ? null : int.tryParse(state.branchId ?? ''),
        'latitude': state.isDelivery ? state.lat : null,
        'longitude': state.isDelivery ? state.lng : null,
        'address': state.isDelivery ? state.address : null,
        'payment_method': int.tryParse(state.selectedPaymentMethodKey) ?? 0,
        'change': state.changeAmount?.toInt(),
        'comment': state.comment,
        'promo_code': state.appliedPromoCode,
        'loyalty_points_used': usedPoints,
        'products': products,
      };

      final response = await _apiClient.post('orders', body: vars);
      emit(state.copyWith(
        isSubmitting: false,
        successData: response,
      ));
    } catch (e) {
      final msg = e is ApiException ? e.message : e.toString();
      emit(state.copyWith(isSubmitting: false, submitError: msg));
    }
  }
}

