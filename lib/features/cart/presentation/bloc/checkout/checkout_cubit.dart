import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pizza_strada/core/network/api_client.dart';
import 'package:pizza_strada/core/services/analytics_service.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/checkout/checkout_state.dart';

import 'package:pizza_strada/core/di/injection.dart';
import 'package:pizza_strada/features/orders/domain/repositories/order_repository.dart';

class CheckoutCubit extends Cubit<CheckoutState> {
  final ApiClient _apiClient;
  final OrderRepository _orderRepository;

  CheckoutCubit({ApiClient? apiClient, OrderRepository? orderRepository})
      : _apiClient = apiClient ?? ApiClient(),
        _orderRepository = orderRepository ?? getIt<OrderRepository>(),
        super(const CheckoutState());

  /// Yetkazib berish turini o'zgartirish.
  /// Pickup ga o'tganda delivery narxi avtomatik sifirlanadi.
  void setDeliveryType(bool isDelivery) {
    if (isDelivery) {
      emit(state.copyWith(isDelivery: true));
    } else {
      // Pickup rejimida delivery narxini sifirlaymiz
      emit(CheckoutState(
        isDelivery: false,
        branchId: state.branchId,
        branchTitle: state.branchTitle,
        lat: state.lat,
        lng: state.lng,
        address: state.address,
        deliveryPrice: 0,
        appliedPromoCode: state.appliedPromoCode,
        promoType: state.promoType,
        promoValue: state.promoValue,
        selectedPaymentMethodKey: state.selectedPaymentMethodKey,
        changeAmount: state.changeAmount,
        comment: state.comment,
      ));
    }
  }

  void setBranch(String branchId, {String? branchTitle}) {
    emit(state.copyWith(branchId: branchId, branchTitle: branchTitle));
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

  Future<void> applyPromo(String code, double subtotal) async {
    emit(state.copyWith(loadingPromo: true, promoError: null));
    try {
      final response = await _apiClient.post(
        'promo-code/check',
        body: {'promo_code': code, 'total_price': subtotal.toInt()},
      );
      final data = response as Map<String, dynamic>?;
      final promoVal = double.tryParse(data?['value']?.toString() ?? '0') ?? 0;
      AnalyticsService.instance.logPromoApplied(code: code, discount: promoVal);
      emit(state.copyWith(
        loadingPromo: false,
        appliedPromoCode: (data?['code'] ?? data?['promo_code']) as String?,
        promoType: data?['type'] as int?,
        promoValue: promoVal,
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
  }) async {
    emit(state.copyWith(isSubmitting: true, submitError: null));
    final vars = {
        'type': state.isDelivery ? 0 : 1, 
        'branch_id': state.isDelivery ? null : int.tryParse(state.branchId ?? ''),
        'latitude': state.isDelivery ? state.lat : null,
        'longitude': state.isDelivery ? state.lng : null,
        'address': state.isDelivery ? state.address : null,
        'payment_method': (state.selectedPaymentMethodKey == '1' || state.selectedPaymentMethodKey == 'payme') ? 1 : 0,
        'change': state.changeAmount?.toInt(),
        'comment': state.comment,
        'promo_code': state.appliedPromoCode,
        'products': products,
      };

    final result = await _orderRepository.createOrder(vars);
    result.fold(
      (failure) => emit(state.copyWith(
        isSubmitting: false,
        submitError: failure.messageKey,
      )),
      (data) => emit(state.copyWith(
        isSubmitting: false,
        successData: data,
      )),
    );
  }

  void resetAfterOrder() {
    emit(CheckoutState(
      isDelivery: state.isDelivery,
      branchId: state.branchId,
      branchTitle: state.branchTitle,
      lat: state.lat,
      lng: state.lng,
      address: state.address,
      deliveryPrice: state.deliveryPrice,
    ));
  }
}

