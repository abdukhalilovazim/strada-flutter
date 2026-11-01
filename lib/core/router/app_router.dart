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
import 'package:pizza_strada/features/home/domain/entities/home_entities.dart';
import 'package:pizza_strada/features/home/presentation/pages/home_page.dart';
import 'package:pizza_strada/features/home/presentation/pages/product_detail_page.dart';
import 'package:pizza_strada/features/orders/domain/entities/order_entity.dart';
import 'package:pizza_strada/features/orders/presentation/pages/order_detail_page.dart';
import 'package:pizza_strada/features/orders/presentation/pages/orders_page.dart';
import 'package:pizza_strada/features/profile/presentation/pages/profile_page.dart';
import 'package:pizza_strada/features/splash/presentation/pages/splash_page.dart';

/// Main scaffold with bottom navigation bar.
/// Style: Laravel mobile-bottom-appbar — flat white/dark bg, icon+label, active=primary red.
class MainScaffold extends StatelessWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentIndex = _calculateSelectedIndex(context);
    final String location = GoRouterState.of(context).matchedLocation;
    final bool isCartPage = location.startsWith('/cart');

    return Scaffold(
      body: SafeArea(bottom: false, child: child),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Luxury Floating Sticky Cart Bar ──
          if (!isCartPage)
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

          // ── Frosted Glassmorphism Bottom Nav Bar ──
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.darkSurface : Colors.white).withValues(alpha: 0.88),
                  border: Border(
                    top: BorderSide(
                      color: isDark ? AppColors.neutral800 : const Color(0xFFE9ECEF),
                      width: 1,
                    ),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    height: 62,
                    child: Row(
                  children: [
                    _NavItem(
                      index: 0,
                      currentIndex: currentIndex,
                      icon: Icons.local_pizza_outlined,
                      activeIcon: Icons.local_pizza_rounded,
                      label: 'nav.home'.tr(),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        GoRouter.of(context).go('/home');
                      },
                    ),
                    _NavItemWithBadge(
                      index: 1,
                      currentIndex: currentIndex,
                      icon: Icons.shopping_bag_outlined,
                      activeIcon: Icons.shopping_bag_rounded,
                      label: 'nav.cart'.tr(),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        GoRouter.of(context).go('/cart');
                      },
                    ),
                    _NavItem(
                      index: 2,
                      currentIndex: currentIndex,
                      icon: Icons.receipt_long_outlined,
                      activeIcon: Icons.receipt_long_rounded,
                      label: 'nav.orders'.tr(),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        GoRouter.of(context).go('/orders');
                      },
                    ),
                    _NavItem(
                      index: 3,
                      currentIndex: currentIndex,
                      icon: Icons.person_outline_rounded,
                      activeIcon: Icons.person_rounded,
                      label: 'nav.profile'.tr(),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        GoRouter.of(context).go('/profile');
                      },
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

  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/cart')) return 1;
    if (location.startsWith('/orders')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }
}

/// Single nav item — icon + label, active = primary red.
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
    final color = isActive
        ? AppColors.primary
        : (isDark ? AppColors.neutral500 : const Color(0xFF64748B));

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 62,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSlide(
                offset: isActive ? const Offset(0, -0.08) : Offset.zero,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isActive ? activeIcon : icon,
                  size: 22,
                  color: color,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  fontSize: 10.5,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Nav item with cart badge overlay.
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
    final color = isActive
        ? AppColors.primary
        : (isDark ? AppColors.neutral500 : const Color(0xFF64748B));

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 62,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              BlocBuilder<CartCubit, CartState>(
                builder: (context, cartState) {
                  final count = cartState.items.length;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AnimatedSlide(
                        offset: isActive ? const Offset(0, -0.08) : Offset.zero,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          isActive ? activeIcon : icon,
                          size: 22,
                          color: color,
                        ),
                      ),
                      if (count > 0)
                        Positioned(
                          top: -4,
                          right: -8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.darkSurface
                                    : Colors.white,
                                width: 2,
                              ),
                            ),
                            child: Text(
                              '$count',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  fontSize: 10.5,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
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
        return OtpPage(phone: state.extra as String? ?? '');
      },
    ),
    ShellRoute(
      builder: (_, __, child) => MainScaffold(child: child),
      routes: [
        GoRoute(path: '/home',    builder: (_, __) => const HomePage()),
        GoRoute(path: '/cart',    builder: (_, __) => const CartPage()),
        GoRoute(path: '/orders',  builder: (_, __) => const OrdersPage()),
        GoRoute(path: '/profile', builder: (_, __) => const ProfilePage()),
      ],
    ),
    GoRoute(
      path: '/product/:slug',
      builder: (_, s) => ProductDetailPage(
        slug: s.pathParameters['slug']!,
        product: s.extra as ProductEntity?,
      ),
    ),
    GoRoute(
      path: '/checkout',
      builder: (_, __) => const CheckoutPage(),
    ),
    GoRoute(path: '/map-picker', builder: (_, __) => const MapPickerPage()),
    GoRoute(
      path: '/order/:id',
      builder: (_, s) => OrderDetailPage(
        orderId: s.pathParameters['id']!,
        order: s.extra as OrderEntity?,
      ),
    ),
  ],
);
