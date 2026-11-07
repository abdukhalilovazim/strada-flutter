import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// 🧭 Declarative SDUI Bottom Navigation Bar Item
class SDUIBottomNavItem extends Equatable {
  final String id;
  final String route;
  final String label;
  final String icon;
  final String? badge;
  final bool showBadge;

  const SDUIBottomNavItem({
    required this.id,
    required this.route,
    required this.label,
    required this.icon,
    this.badge,
    this.showBadge = false,
  });

  /// Dynamically returns label matching the current BuildContext locale
  String getLocalizedLabel(BuildContext context) {
    if (label.isNotEmpty) return label;
    final trKey = 'nav.$id';
    final trVal = trKey.tr();
    if (trVal != trKey) return trVal;
    return id;
  }

  factory SDUIBottomNavItem.fromJson(Map<String, dynamic> json, {String locale = 'uz'}) {
    final label = json['label']?.toString() ??
        json['label_$locale']?.toString() ??
        json['label_uz']?.toString() ??
        json['id']?.toString() ??
        '';

    return SDUIBottomNavItem(
      id: json['id']?.toString() ?? '',
      route: json['route']?.toString() ?? '/home',
      label: label,
      icon: json['icon']?.toString() ?? 'home',
      badge: json['badge']?.toString(),
      showBadge: json['show_badge'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'route': route,
        'label': label,
        'icon': icon,
        if (badge != null) 'badge': badge,
        'show_badge': showBadge,
      };

  static List<SDUIBottomNavItem> defaultItems({String locale = 'uz'}) {
    final isRu = locale.toLowerCase().startsWith('ru');
    final isEn = locale.toLowerCase().startsWith('en');
    return [
      SDUIBottomNavItem(
        id: 'home',
        route: '/home',
        label: isRu ? 'Главная' : (isEn ? 'Home' : 'Asosiy'),
        icon: 'home',
      ),
      SDUIBottomNavItem(
        id: 'promotions',
        route: '/promotions',
        label: isRu ? 'Акции' : (isEn ? 'Promos' : 'Aksiyalar'),
        icon: 'percent',
        badge: '%',
      ),
      SDUIBottomNavItem(
        id: 'cart',
        route: '/cart',
        label: isRu ? 'Корзина' : (isEn ? 'Cart' : 'Savat'),
        icon: 'cart',
        showBadge: true,
      ),
      SDUIBottomNavItem(
        id: 'orders',
        route: '/orders',
        label: isRu ? 'Заказы' : (isEn ? 'Orders' : 'Buyurtmalar'),
        icon: 'receipt',
      ),
      SDUIBottomNavItem(
        id: 'profile',
        route: '/profile',
        label: isRu ? 'Профиль' : (isEn ? 'Profile' : 'Profil'),
        icon: 'profile',
      ),
    ];
  }

  @override
  List<Object?> get props => [id, route, label, icon, badge, showBadge];
}
