import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// 🧭 Declarative SDUI Bottom Navigation Bar Item
class SDUIBottomNavItem extends Equatable {
  final String id;
  final String route;
  final String label;
  final String? labelUz;
  final String? labelRu;
  final String? labelEn;
  final String icon;
  final String? badge;
  final bool showBadge;

  const SDUIBottomNavItem({
    required this.id,
    required this.route,
    required this.label,
    this.labelUz,
    this.labelRu,
    this.labelEn,
    required this.icon,
    this.badge,
    this.showBadge = false,
  });

  /// Dynamically returns label matching the current BuildContext locale
  String getLocalizedLabel(BuildContext context) {
    final lang = context.locale.languageCode;
    if (lang == 'uz' && labelUz != null && labelUz!.isNotEmpty) return labelUz!;
    if (lang == 'ru' && labelRu != null && labelRu!.isNotEmpty) return labelRu!;
    if (lang == 'en' && labelEn != null && labelEn!.isNotEmpty) return labelEn!;
    final trKey = 'nav.$id';
    final trVal = trKey.tr();
    if (trVal != trKey) return trVal;
    return label;
  }

  factory SDUIBottomNavItem.fromJson(Map<String, dynamic> json, {String locale = 'uz'}) {
    final uz = json['label_uz']?.toString();
    final ru = json['label_ru']?.toString();
    final en = json['label_en']?.toString();
    final label = json['label_$locale']?.toString() ??
        uz ??
        json['label']?.toString() ??
        json['id']?.toString() ??
        '';

    return SDUIBottomNavItem(
      id: json['id']?.toString() ?? '',
      route: json['route']?.toString() ?? '/home',
      label: label,
      labelUz: uz,
      labelRu: ru,
      labelEn: en,
      icon: json['icon']?.toString() ?? 'home',
      badge: json['badge']?.toString(),
      showBadge: json['show_badge'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'route': route,
        'label': label,
        if (labelUz != null) 'label_uz': labelUz,
        if (labelRu != null) 'label_ru': labelRu,
        if (labelEn != null) 'label_en': labelEn,
        'icon': icon,
        if (badge != null) 'badge': badge,
        'show_badge': showBadge,
      };

  static List<SDUIBottomNavItem> defaultItems({String locale = 'uz'}) {
    final isRu = locale.toLowerCase().startsWith('ru');
    return [
      SDUIBottomNavItem(
        id: 'home',
        route: '/home',
        label: isRu ? 'Главная' : 'Asosiy',
        labelUz: 'Asosiy',
        labelRu: 'Главная',
        labelEn: 'Home',
        icon: 'home',
      ),
      SDUIBottomNavItem(
        id: 'promotions',
        route: '/promotions',
        label: isRu ? 'Акции' : 'Aksiyalar',
        labelUz: 'Aksiyalar',
        labelRu: 'Акции',
        labelEn: 'Promotions',
        icon: 'percent',
        badge: '%',
      ),
      SDUIBottomNavItem(
        id: 'cart',
        route: '/cart',
        label: isRu ? 'Корзина' : 'Savat',
        labelUz: 'Savat',
        labelRu: 'Корзина',
        labelEn: 'Cart',
        icon: 'cart',
        showBadge: true,
      ),
      SDUIBottomNavItem(
        id: 'orders',
        route: '/orders',
        label: isRu ? 'Заказы' : 'Buyurtmalar',
        labelUz: 'Buyurtmalar',
        labelRu: 'Заказы',
        labelEn: 'Orders',
        icon: 'receipt',
      ),
      SDUIBottomNavItem(
        id: 'profile',
        route: '/profile',
        label: isRu ? 'Профиль' : 'Profil',
        labelUz: 'Profil',
        labelRu: 'Профиль',
        labelEn: 'Profile',
        icon: 'profile',
      ),
    ];
  }

  @override
  List<Object?> get props => [id, route, label, labelUz, labelRu, labelEn, icon, badge, showBadge];
}
