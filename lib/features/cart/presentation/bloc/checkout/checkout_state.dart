import 'package:equatable/equatable.dart';

class CheckoutState extends Equatable {
  final bool isDelivery;
  final String? branchId;
  final double? lat;
  final double? lng;
  final String? address;
  
  final double deliveryPrice;
  final bool loadingDelivery;

  final String? appliedPromoCode;
  final int? promoType;
  final double? promoValue;
  final String? promoError;
  final bool loadingPromo;

  final bool useLoyaltyPoints;

  final String selectedPaymentMethodKey;
  final double? changeAmount;
  final String comment;

  final bool isSubmitting;
  final String? submitError;
  final Map<String, dynamic>? successData;

  const CheckoutState({
    this.isDelivery = true,
    this.branchId,
    this.lat,
    this.lng,
    this.address,
    this.deliveryPrice = 0,
    this.loadingDelivery = false,
    this.appliedPromoCode,
    this.promoType,
    this.promoValue,
    this.promoError,
    this.loadingPromo = false,
    this.useLoyaltyPoints = false,
    this.selectedPaymentMethodKey = 'cash',
    this.changeAmount,
    this.comment = '',
    this.isSubmitting = false,
    this.submitError,
    this.successData,
  });

  CheckoutState copyWith({
    bool? isDelivery,
    String? branchId,
    double? lat,
    double? lng,
    String? address,
    double? deliveryPrice,
    bool? loadingDelivery,
    String? appliedPromoCode,
    int? promoType,
    double? promoValue,
    String? promoError,
    bool? loadingPromo,
    bool? useLoyaltyPoints,
    String? selectedPaymentMethodKey,
    double? changeAmount,
    String? comment,
    bool? isSubmitting,
    String? submitError,
    Map<String, dynamic>? successData,
  }) {
    return CheckoutState(
      isDelivery: isDelivery ?? this.isDelivery,
      branchId: branchId ?? this.branchId,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      address: address ?? this.address,
      deliveryPrice: deliveryPrice ?? this.deliveryPrice,
      loadingDelivery: loadingDelivery ?? this.loadingDelivery,
      appliedPromoCode: appliedPromoCode ?? this.appliedPromoCode,
      promoType: promoType ?? this.promoType,
      promoValue: promoValue ?? this.promoValue,
      promoError: promoError, // Set explicitly to clear errors if needed, but normally handled by Cubit
      loadingPromo: loadingPromo ?? this.loadingPromo,
      useLoyaltyPoints: useLoyaltyPoints ?? this.useLoyaltyPoints,
      selectedPaymentMethodKey: selectedPaymentMethodKey ?? this.selectedPaymentMethodKey,
      changeAmount: changeAmount ?? this.changeAmount,
      comment: comment ?? this.comment,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitError: submitError,
      successData: successData ?? this.successData,
    );
  }

  // Clear specific fields
  CheckoutState clearPromoError() => copyWith(promoError: null);
  CheckoutState clearSubmitError() => copyWith(submitError: null);

  @override
  List<Object?> get props => [
        isDelivery,
        branchId,
        lat,
        lng,
        address,
        deliveryPrice,
        loadingDelivery,
        appliedPromoCode,
        promoType,
        promoValue,
        promoError,
        loadingPromo,
        useLoyaltyPoints,
        selectedPaymentMethodKey,
        changeAmount,
        comment,
        isSubmitting,
        submitError,
        successData,
      ];
}
