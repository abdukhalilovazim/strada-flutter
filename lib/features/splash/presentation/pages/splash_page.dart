import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pizza_strada/core/storage/secure_storage.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 1800));
    if (mounted) {
      final token = await SecureStorage.getToken();
      if (!mounted) return;
      if (token != null && token.isNotEmpty) {
        context.go('/home');
      } else {
        context.go('/auth/login');
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo — asset yoki icon fallback
              _buildLogo(),
              const SizedBox(height: 48),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    // Logo asset mavjud bo'lsa ishlatiladi, aks holda icon
    return Image.asset(
      'assets/icons/logo.png',
      width: 200,
      height: 200,
      errorBuilder: (_, __, ___) => Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(Icons.local_pizza, color: Colors.white, size: 52),
          ),
          const SizedBox(height: 20),
          Text(
            'Pizza strada',
            style: AppTextStyles.h1.copyWith(color: AppColors.primary, letterSpacing: -0.5),
          ),
        ],
      ),
    );
  }
}
