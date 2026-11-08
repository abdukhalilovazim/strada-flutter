import 'package:easy_localization/easy_localization.dart';
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
        super(const CheckoutState()) {
    loadSettings();
  }

  /// Backend settings orqali can_order va buyurtma holatini yuklash
  Future<void> loadSettings() async {
    emit(state.copyWith(isSettingsLoading: true));
    try {
      final response = await _apiClient.get('settings');
      if (response is Map<String, dynamic>) {
        final rawCanOrder = response['can_order'];
        final canOrder = rawCanOrder == true || rawCanOrder == 1 || rawCanOrder == '1';
        final canOrderMsg = response['can_order_message']?.toString();
        emit(state.copyWith(
          canOrder: canOrder,
          canOrderMessage: canOrderMsg,
          isSettingsLoading: false,
        ));
      } else {
        emit(state.copyWith(isSettingsLoading: false));
      }
    } catch (_) {
      emit(state.copyWith(isSettingsLoading: false));
    }
  }

  /// Yetkazib berish turini o'zgartirish.
  /// Pickup ga o'tganda delivery narxi avtomatik sifirlanadi.
  void setDeliveryType(bool isDelivery) {
    if (isDelivery) {
      emit(state.copyWith(isDelivery: true, showLocationError: false));
    } else {
      // Pickup rejimida delivery narxini sifirlaymiz
      emit(state.copyWith(
        isDelivery: false,
        showLocationError: false,
        deliveryPrice: 0,
      ));
    }
  }

  void setOrderType(bool isDelivery) => setDeliveryType(isDelivery);

  void setBranch(String branchId, {String? branchTitle}) {
    emit(state.copyWith(
      branchId: branchId,
      branchTitle: branchTitle,
      showLocationError: false,
    ));
  }

  void setLocationError(bool hasError) {
    emit(state.copyWith(showLocationError: hasError));
  }

  Future<void> setAddressAndCalculateDelivery(double lat, double lng, String address) async {
    emit(state.copyWith(
      lat: lat,
      lng: lng,
      address: address,
      showLocationError: false,
      loadingDelivery: true,
    ));
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

  void setAddressDetails({
    String? entrance,
    String? floor,
    String? apartment,
    String? doorPhone,
  }) {
    emit(state.copyWith(
      entrance: entrance ?? state.entrance,
      floor: floor ?? state.floor,
      apartment: apartment ?? state.apartment,
      doorPhone: doorPhone ?? state.doorPhone,
    ));
  }

  void setCourierPreferences({
    String? note,
    bool? noUtensils,
  }) {
    emit(state.copyWith(
      courierNote: note ?? state.courierNote,
      noUtensils: noUtensils ?? state.noUtensils,
    ));
  }

  void clearSubmitError() {
    emit(state.clearSubmitError());
  }

  void applyPromoCode(String code) {
    emit(state.copyWith(appliedPromoCode: code.trim(), promoError: null));
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

      final rawType = data?['type'];
      int? parsedType;
      String? parsedTypeString;

      if (rawType is int) {
        parsedType = rawType;
        parsedTypeString = rawType == 1 ? 'percent' : 'fixed';
      } else if (rawType != null) {
        final s = rawType.toString().toLowerCase().trim();
        parsedTypeString = s;
        if (s == 'percent' || s == 'percentage' || s == '1') {
          parsedType = 1;
        } else if (s == 'fixed' || s == '0') {
          parsedType = 0;
        } else {
          parsedType = int.tryParse(s);
        }
      }

      AnalyticsService.instance.logPromoApplied(code: code, discount: promoVal);
      emit(state.copyWith(
        loadingPromo: false,
        appliedPromoCode: (data?['code'] ?? data?['promo_code']) as String?,
        promoType: parsedType,
        promoTypeString: parsedTypeString,
        promoValue: promoVal,
        promoError: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        loadingPromo: false,
        promoError: e is ApiException ? e.message : e.toString(),
        appliedPromoCode: null,
        promoType: null,
        promoTypeString: null,
        promoValue: null,
      ));
    }
  }

  void clearPromo() {
    emit(state.clearPromo());
  }

  void setRecipient({String? name, String? phone}) {
    emit(state.copyWith(
      recipientName: name,
      recipientPhone: phone,
    ));
  }

  Future<void> submitOrder({
    required List<Map<String, dynamic>> products,
    List<Map<String, dynamic>>? coupons,
    String? commentOverride,
  }) async {
    if (!state.canOrder) {
      emit(state.copyWith(
        isSubmitting: false,
        submitError: state.canOrderMessage ?? 'checkout.ordering_suspended'.tr(),
      ));
      return;
    }

    emit(state.copyWith(isSubmitting: true, submitError: null));
    final effectiveComment = commentOverride ??
        (state.fullComment.isNotEmpty
            ? state.fullComment
            : (state.comment.isNotEmpty ? state.comment : null));

    final vars = {
      'type': state.isDelivery ? 0 : 1,
      'branch_id': state.isDelivery ? null : int.tryParse(state.branchId ?? ''),
      'latitude': state.isDelivery ? state.lat : null,
      'longitude': state.isDelivery ? state.lng : null,
      'address': state.isDelivery ? state.address : null,
      'payment_method': (state.selectedPaymentMethodKey == '1' || state.selectedPaymentMethodKey == 'payme') ? 1 : 0,
      'change': null,
      'comment': effectiveComment,
      'promo_code': state.appliedPromoCode,
      'products': products,
      if (coupons != null && coupons.isNotEmpty) 'coupons': coupons,
    };

    final result = await _orderRepository.createOrder(vars);
    result.fold(
      (failure) => emit(state.copyWith(
        isSubmitting: false,
        submitError: failure.messageKey,
      )),
      (data) {
        final orderId = data['id']?.toString() ?? '';
        final totalAmount = double.tryParse(data['total_price']?.toString() ?? '') ?? 0;
        AnalyticsService.instance.logOrderPlaced(
          orderId: orderId,
          totalAmount: totalAmount,
          paymentMethod: (state.selectedPaymentMethodKey == '1' || state.selectedPaymentMethodKey == 'payme') ? 'payme' : 'cash',
          isDelivery: state.isDelivery,
          itemsCount: products.length,
        );
        emit(state.copyWith(
          isSubmitting: false,
          successData: data,
        ));
      },
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
      canOrder: state.canOrder,
      canOrderMessage: state.canOrderMessage,
    ));
  }
}

