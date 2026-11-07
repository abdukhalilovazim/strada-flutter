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
  final String? promoTypeString;
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
  final String? recipientName;
  final String? recipientPhone;

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
    this.promoTypeString,
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
    this.noUtensils = false,
    this.courierNote,
    this.recipientName,
    this.recipientPhone,
    this.isSubmitting = false,
    this.submitError,
    this.successData,
  });

  /// Chegirma turi foizda ekanligini tekshirish
  /// Backend PromoTypeEnum: PERCENT = 1, FIXED = 0
  bool get isPercentagePromo {
    if (promoType == 1) return true;
    if (promoTypeString != null) {
      final s = promoTypeString!.toLowerCase().trim();
      if (s == 'percent' || s == 'percentage' || s == '1') return true;
    }
    return false;
  }

  /// Subtotal hisobga olingan holda aniq chegirma summasini hisoblash
  double calculateDiscount(double subtotal) {
    if (promoValue == null || promoValue! <= 0) return 0.0;
    if (isPercentagePromo) {
      return (subtotal * (promoValue! / 100.0)).clamp(0.0, subtotal);
    }
    return promoValue!.clamp(0.0, subtotal);
  }

  double get discountAmount => promoValue ?? 0.0;

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
    if (recipientName != null && recipientName!.trim().isNotEmpty) {
      final phonePart = (recipientPhone != null && recipientPhone!.trim().isNotEmpty)
          ? ' (${recipientPhone!.trim()})'
          : '';
      parts.add('Qabul qiluvchi: ${recipientName!.trim()}$phonePart');
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
    String? promoTypeString,
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
    String? recipientName,
    String? recipientPhone,
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
      promoTypeString: promoTypeString ?? this.promoTypeString,
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
      recipientName: recipientName ?? this.recipientName,
      recipientPhone: recipientPhone ?? this.recipientPhone,
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
        promoTypeString,
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
        recipientName,
        recipientPhone,
        isSubmitting,
        submitError,
        successData,
      ];
}
