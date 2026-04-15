import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pizza_strada/core/constants/app_constants.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';
import 'package:pizza_strada/core/storage/secure_storage.dart';
import 'package:pizza_strada/core/theme/app_icons.dart';
import 'package:pizza_strada/features/auth/presentation/pages/login_page.dart';
import 'package:pizza_strada/features/auth/presentation/pages/otp_page.dart';
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

// Placeholder pages for minor routes

class MainScaffold extends StatelessWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(bottom: false, child: child),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: _calculateSelectedIndex(context),
            onTap: (index) => _onItemTapped(index, context),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.neutral400,
            elevation: 0,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            selectedLabelStyle: AppTextStyles.labelSmall.copyWith(fontSize: 11, fontWeight: FontWeight.w600),
            unselectedLabelStyle: AppTextStyles.labelSmall.copyWith(fontSize: 11, fontWeight: FontWeight.w500),
            items: [
              BottomNavigationBarItem(
                icon: const Icon(AppIcons.home, size: 24),
                activeIcon: const Icon(AppIcons.homeActive, size: 24),
                label: 'nav.home'.tr(),
              ),
              BottomNavigationBarItem(
                icon: const Icon(AppIcons.cart, size: 24),
                activeIcon: const Icon(AppIcons.cartActive, size: 24),
                label: 'nav.cart'.tr(),
              ),
              BottomNavigationBarItem(
                icon: const Icon(AppIcons.orders, size: 24),
                activeIcon: const Icon(AppIcons.ordersActive, size: 24),
                label: 'nav.orders'.tr(),
              ),
              BottomNavigationBarItem(
                icon: const Icon(AppIcons.profile, size: 24),
                activeIcon: const Icon(AppIcons.profileActive, size: 24),
                label: 'nav.profile'.tr(),
              ),
            ],
          ),
        ),
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

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0: GoRouter.of(context).go('/home'); break;
      case 1: GoRouter.of(context).go('/cart'); break;
      case 2: GoRouter.of(context).go('/orders'); break;
      case 3: GoRouter.of(context).go('/profile'); break;
    }
  }
}

final appRouter = GoRouter(
  navigatorKey: AppConstants.navigatorKey,
  initialLocation: '/splash',
  redirect: (context, state) async {
    final token = await SecureStorage.getToken();
    final onAuth = state.matchedLocation.startsWith('/auth');
    if (token == null && !onAuth && state.matchedLocation != '/splash') {
      return '/auth/login';
    }
    if (token != null && onAuth) return '/home';
    return null;
  },
  routes: [
    GoRoute(path: '/splash', builder: (_, __) => const SplashPage()),
    GoRoute(path: '/auth/login', builder: (_, __) => const LoginPage()),
    GoRoute(
      path: '/auth/otp',
      builder: (_, state) => OtpPage(phone: state.extra as String),
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
    GoRoute(path: '/checkout',   builder: (_, __) => const CheckoutPage()),
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
