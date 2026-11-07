import 'package:equatable/equatable.dart';

class CheckoutState extends Equatable {
  final bool isDelivery;
  final String? branchId;
  final String? branchTitle;
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

  final String selectedPaymentMethodKey;
  final double? changeAmount;
  final String comment;

  // Address details & delivery preferences
  final String? entrance;
  final String? floor;
  final String? apartment;
  final String? doorPhone;
  final bool noUtensils;
  final String? courierNote;

  final bool isSubmitting;
  final String? submitError;
  final Map<String, dynamic>? successData;

  const CheckoutState({
    this.isDelivery = true,
    this.branchId,
    this.branchTitle,
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
    this.selectedPaymentMethodKey = 'cash',
    this.changeAmount,
    this.comment = '',
    this.entrance,
    this.floor,
    this.apartment,
    this.doorPhone,
    this.noUtensils = true,
    this.courierNote,
    this.isSubmitting = false,
    this.submitError,
    this.successData,
  });

  /// Combined comments for order payload (Podyezd, Qavat, Xonadon, Domofon, Salfetka, Izoh)
  String get fullComment {
    final parts = <String>[];
    if (entrance != null && entrance!.trim().isNotEmpty) {
      parts.add('Podyezd: ${entrance!.trim()}');
    }
    if (floor != null && floor!.trim().isNotEmpty) {
      parts.add('Qavat: ${floor!.trim()}');
    }
    if (apartment != null && apartment!.trim().isNotEmpty) {
      parts.add('Xonadon: ${apartment!.trim()}');
    }
    if (doorPhone != null && doorPhone!.trim().isNotEmpty) {
      parts.add('Domofon: ${doorPhone!.trim()}');
    }
    if (noUtensils) {
      parts.add('Qoshiq va salfetka kerak emas');
    }
    if (courierNote != null && courierNote!.trim().isNotEmpty) {
      parts.add('Izoh: ${courierNote!.trim()}');
    }
    if (comment.trim().isNotEmpty && !parts.any((p) => p.contains(comment.trim()))) {
      parts.add(comment.trim());
    }
    return parts.join(', ');
  }

  CheckoutState copyWith({
    bool? isDelivery,
    String? branchId,
    String? branchTitle,
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
    String? selectedPaymentMethodKey,
    double? changeAmount,
    String? comment,
    String? entrance,
    String? floor,
    String? apartment,
    String? doorPhone,
    bool? noUtensils,
    String? courierNote,
    bool? isSubmitting,
    String? submitError,
    Map<String, dynamic>? successData,
  }) {
    return CheckoutState(
      isDelivery: isDelivery ?? this.isDelivery,
      branchId: branchId ?? this.branchId,
      branchTitle: branchTitle ?? this.branchTitle,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      address: address ?? this.address,
      deliveryPrice: deliveryPrice ?? this.deliveryPrice,
      loadingDelivery: loadingDelivery ?? this.loadingDelivery,
      appliedPromoCode: appliedPromoCode ?? this.appliedPromoCode,
      promoType: promoType ?? this.promoType,
      promoValue: promoValue ?? this.promoValue,
      promoError: promoError,
      loadingPromo: loadingPromo ?? this.loadingPromo,
      selectedPaymentMethodKey: selectedPaymentMethodKey ?? this.selectedPaymentMethodKey,
      changeAmount: changeAmount ?? this.changeAmount,
      comment: comment ?? this.comment,
      entrance: entrance ?? this.entrance,
      floor: floor ?? this.floor,
      apartment: apartment ?? this.apartment,
      doorPhone: doorPhone ?? this.doorPhone,
      noUtensils: noUtensils ?? this.noUtensils,
      courierNote: courierNote ?? this.courierNote,
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
        branchTitle,
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
        selectedPaymentMethodKey,
        changeAmount,
        comment,
        entrance,
        floor,
        apartment,
        doorPhone,
        noUtensils,
        courierNote,
        isSubmitting,
        submitError,
        successData,
      ];
}
