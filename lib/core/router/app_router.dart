import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pizza_strada/core/constants/app_constants.dart';
import 'package:pizza_strada/core/services/analytics_service.dart';
import 'package:pizza_strada/core/storage/secure_storage.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';
import 'package:pizza_strada/core/utils/number_formatter.dart';
import 'package:pizza_strada/features/auth/presentation/pages/login_page.dart';
import 'package:pizza_strada/features/auth/presentation/pages/otp_page.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/cart_cubit.dart';
import 'package:pizza_strada/features/cart/presentation/pages/cart_page.dart';
import 'package:pizza_strada/features/cart/presentation/pages/checkout_page.dart';
import 'package:pizza_strada/features/cart/presentation/pages/map_picker_page.dart';
import 'package:pizza_strada/features/home/data/models/home_models.dart';
import 'package:pizza_strada/features/home/domain/entities/home_entities.dart';
import 'package:pizza_strada/features/home/presentation/bloc/home_cubit.dart';
import 'package:pizza_strada/features/home/presentation/pages/home_page.dart';
import 'package:pizza_strada/features/home/presentation/pages/product_detail_page.dart';
import 'package:pizza_strada/features/orders/data/models/order_model.dart';
import 'package:pizza_strada/features/orders/domain/entities/order_entity.dart';
import 'package:pizza_strada/features/orders/presentation/pages/order_detail_page.dart';
import 'package:pizza_strada/features/orders/presentation/pages/orders_page.dart';
import 'package:pizza_strada/features/notifications/presentation/pages/notifications_page.dart';
import 'package:pizza_strada/features/profile/presentation/pages/profile_page.dart';
import 'package:pizza_strada/features/profile/presentation/pages/branches_page.dart';
import 'package:pizza_strada/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:pizza_strada/features/profile/presentation/pages/saved_addresses_page.dart';
import 'package:pizza_strada/features/promotions/presentation/pages/promotions_page.dart';
import 'package:pizza_strada/features/splash/presentation/pages/splash_page.dart';

class _BottomNavItemDef {
  final String route;
  final IconData icon;
  final IconData activeIcon;
  final String labelKey;
  final bool isCart;

  const _BottomNavItemDef({
    required this.route,
    required this.icon,
    required this.activeIcon,
    required this.labelKey,
    this.isCart = false,
  });
}

/// Main scaffold with bottom navigation bar.
/// Style: Clean Native Flutter mobile appbar — flat white/dark bg, icon+label, active=primary red.
class MainScaffold extends StatelessWidget {
  final Widget child;
  final String? location;
  const MainScaffold({
    super.key,
    required this.child,
    this.location,
  });

  static const _navItems = [
    _BottomNavItemDef(
      route: '/home',
      icon: Icons.local_pizza_outlined,
      activeIcon: Icons.local_pizza_rounded,
      labelKey: 'nav.home',
    ),
    _BottomNavItemDef(
      route: '/promotions',
      icon: Icons.discount_outlined,
      activeIcon: Icons.discount_rounded,
      labelKey: 'nav.promotions',
    ),
    _BottomNavItemDef(
      route: '/cart',
      icon: Icons.shopping_bag_outlined,
      activeIcon: Icons.shopping_bag_rounded,
      labelKey: 'nav.cart',
      isCart: true,
    ),
    _BottomNavItemDef(
      route: '/profile',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      labelKey: 'nav.profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String effectiveLocation = '';
    try {
      effectiveLocation = GoRouterState.of(context).uri.path;
    } catch (_) {}
    if (effectiveLocation.isEmpty) {
      effectiveLocation = location ?? '/home';
    }
    final bool isHomePage = (effectiveLocation == '/home' || effectiveLocation == '/') && !effectiveLocation.startsWith('/cart');
    final currentIndex = _calculateSelectedIndex(effectiveLocation);

    return Scaffold(
      body: SafeArea(bottom: false, child: child),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Luxury Floating Sticky Cart Bar (ONLY on HomePage) ──
          if (isHomePage)
            BlocBuilder<CartCubit, CartState>(
              builder: (context, cartState) {
                if (cartState.items.isEmpty) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.38),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          GoRouter.of(context).go('/cart');
                        },
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          height: 52,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.22),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.shopping_bag_outlined,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '${'cart.items_suffix'.tr(namedArgs: {'count': cartState.totalQuantity.toString()})} • ${NumberFormatter.formatSum(cartState.subtotal)} ${'common.currency'.tr()}',
                                  style: AppTextStyles.labelMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                'cart.floating_cart'.tr(),
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Colors.white,
                                size: 13,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

          // ── Frosted Glassmorphism Native Bottom Nav Bar ──
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.darkSurface : Colors.white).withValues(alpha: 0.92),
                  border: Border(
                    top: BorderSide(
                      color: isDark ? AppColors.neutral800 : const Color(0xFFE9ECEF),
                      width: 1,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    height: 62,
                    child: Row(
                      children: [
                        for (int i = 0; i < _navItems.length; i++)
                          _buildNavItem(
                            context: context,
                            item: _navItems[i],
                            index: i,
                            currentIndex: currentIndex,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required _BottomNavItemDef item,
    required int index,
    required int currentIndex,
  }) {
    if (item.isCart) {
      return _NavItemWithBadge(
        index: index,
        currentIndex: currentIndex,
        icon: item.icon,
        activeIcon: item.activeIcon,
        label: item.labelKey.tr(),
        onTap: () {
          HapticFeedback.selectionClick();
          GoRouter.of(context).go(item.route);
        },
      );
    }

    return _NavItem(
      index: index,
      currentIndex: currentIndex,
      icon: item.icon,
      activeIcon: item.activeIcon,
      label: item.labelKey.tr(),
      onTap: () {
        HapticFeedback.selectionClick();
        GoRouter.of(context).go(item.route);
      },
    );
  }

  static int _calculateSelectedIndex(String location) {
    if (location.startsWith('/orders') || location.startsWith('/order')) {
      final profileIndex = _navItems.indexWhere((it) => it.route == '/profile');
      if (profileIndex != -1) return profileIndex;
    }
    for (int i = 0; i < _navItems.length; i++) {
      if (location.startsWith(_navItems[i].route)) return i;
    }
    return 0;
  }
}

/// Single nav item with smooth pill capsule indicator and bold typography
class _NavItem extends StatelessWidget {
  final int index;
  final int currentIndex;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final VoidCallback onTap;

  const _NavItem({
    required this.index,
    required this.currentIndex,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = index == currentIndex;

    final activeColor = AppColors.primary;
    final inactiveColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 60,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    padding: EdgeInsets.symmetric(
                      horizontal: isActive ? 16 : 4,
                      vertical: isActive ? 4 : 2,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? activeColor.withValues(alpha: isDark ? 0.22 : 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      isActive ? activeIcon : icon,
                      size: 22,
                      color: isActive ? activeColor : inactiveColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: AppTextStyles.labelSmall.copyWith(
                  fontSize: 10.5,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                  color: isActive ? activeColor : inactiveColor,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Nav item with cart badge overlay and animated capsule indicator.
class _NavItemWithBadge extends StatelessWidget {
  final int index;
  final int currentIndex;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final VoidCallback onTap;

  const _NavItemWithBadge({
    required this.index,
    required this.currentIndex,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = index == currentIndex;

    final activeColor = AppColors.primary;
    final inactiveColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 60,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              BlocBuilder<CartCubit, CartState>(
                builder: (context, cartState) {
                  final count = cartState.items.length;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        padding: EdgeInsets.symmetric(
                          horizontal: isActive ? 16 : 4,
                          vertical: isActive ? 4 : 2,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? activeColor.withValues(alpha: isDark ? 0.22 : 0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          isActive ? activeIcon : icon,
                          size: 22,
                          color: isActive ? activeColor : inactiveColor,
                        ),
                      ),
                      if (count > 0)
                        Positioned(
                          top: -2,
                          right: isActive ? 8 : -4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark ? AppColors.darkSurface : Colors.white,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.4),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Text(
                              '$count',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: AppTextStyles.labelSmall.copyWith(
                  fontSize: 10.5,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                  color: isActive ? activeColor : inactiveColor,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final appRouter = GoRouter(
  navigatorKey: AppConstants.navigatorKey,
  initialLocation: '/splash',
  observers: [AppAnalyticsObserver()],
  redirect: (context, state) async {
    final token = await SecureStorage.getToken();
    final onAuth = state.matchedLocation.startsWith('/auth');
    if (token != null && onAuth) return '/home';
    return null;
  },
  routes: [
    GoRoute(path: '/splash', builder: (_, __) => const SplashPage()),
    GoRoute(path: '/auth/login', builder: (_, __) => const LoginPage()),
    GoRoute(
      path: '/auth/otp',
      builder: (_, state) {
        if (state.extra is Map<String, dynamic>) {
          final data = state.extra as Map<String, dynamic>;
          return OtpPage(
            phone: data['phone'] as String? ?? '',
            fullName: data['fullName'] as String? ?? '',
          );
        }
        return OtpPage(phone: state.extra is String ? state.extra as String : '');
      },
    ),
    ShellRoute(
      builder: (_, state, child) => MainScaffold(
        location: state.matchedLocation,
        child: child,
      ),
      routes: [
        GoRoute(path: '/home',       builder: (_, __) => const HomePage()),
        GoRoute(path: '/promotions', builder: (_, __) => const PromotionsPage()),
        GoRoute(path: '/cart',       builder: (_, __) => const CartPage()),
        GoRoute(path: '/orders',     builder: (_, __) => const OrdersPage()),
        GoRoute(path: '/profile',    builder: (_, __) => const ProfilePage()),
      ],
    ),
    GoRoute(
      path: '/product/:slug',
      builder: (context, s) {
        final slug = s.pathParameters['slug'] ?? '';
        ProductEntity? product;

        if (s.extra is ProductEntity) {
          product = s.extra as ProductEntity;
        } else if (s.extra is Map<String, dynamic>) {
          try {
            product = ProductModel.fromJson(s.extra as Map<String, dynamic>);
          } catch (_) {
            product = null;
          }
        }

        if ((product == null || product.description == null || product.description!.isEmpty) && slug.isNotEmpty) {
          try {
            final homeState = context.read<HomeCubit>().state;
            if (homeState is HomeLoaded) {
              product = homeState.fullProducts.firstWhere((p) => p.slug == slug);
            }
          } catch (_) {}
        }

        return ProductDetailPage(
          slug: slug,
          product: product,
        );
      },
    ),
    GoRoute(
      path: '/checkout',
      builder: (_, __) => const CheckoutPage(),
    ),
    GoRoute(path: '/branches', builder: (_, __) => const BranchesPage()),
    GoRoute(path: '/profile/edit', builder: (_, __) => const EditProfilePage()),
    GoRoute(path: '/saved-addresses', builder: (_, __) => const SavedAddressesPage()),
    GoRoute(path: '/locations', builder: (_, __) => const SavedAddressesPage()),
    GoRoute(
      path: '/map-picker',
      builder: (_, s) {
        final extra = s.extra as Map<String, dynamic>?;
        return MapPickerPage(
          initialLat: (extra?['lat'] as num?)?.toDouble(),
          initialLng: (extra?['lng'] as num?)?.toDouble(),
          useMyLocation: (extra?['useMyLocation'] as bool?) ?? false,
        );
      },
    ),
    GoRoute(path: '/notifications', builder: (_, __) => const NotificationsPage()),
    GoRoute(
      path: '/order/:id',
      builder: (_, s) {
        OrderEntity? order;
        if (s.extra is OrderEntity) {
          order = s.extra as OrderEntity;
        } else if (s.extra is Map<String, dynamic>) {
          try {
            order = OrderModel.fromJson(s.extra as Map<String, dynamic>);
          } catch (_) {
            order = null;
          }
        }
        return OrderDetailPage(
          orderId: s.pathParameters['id']!,
          order: order,
        );
      },
    ),
  ],
);
