import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pizza_strada/core/di/injection.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';
import 'package:pizza_strada/core/widgets/pizza_slice_loader.dart';
import 'package:pizza_strada/features/home/presentation/bloc/home_cubit.dart';
import 'package:pizza_strada/features/splash/presentation/bloc/splash_cubit.dart';
import 'package:pizza_strada/features/splash/presentation/bloc/splash_state.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late final SplashCubit _splashCubit;
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;
  bool _minDurationPassed = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _splashCubit = getIt<SplashCubit>()..init();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _scaleAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();

    // Pitsaning chiqib-kirish animatsiyasi to'liq zavq bilan ko'rinishi uchun (1.8s)
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) {
        _minDurationPassed = true;
        _checkAndNavigate();
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _splashCubit.close();
    super.dispose();
  }

  void _checkAndNavigate() {
    if (!mounted || _navigated) return;
    if (!_minDurationPassed) return;

    final splashState = _splashCubit.state;
    final homeState = context.read<HomeCubit>().state;

    final isAuthChecked = splashState is SplashAuthenticated || splashState is SplashUnauthenticated;
    final isHomeReady = homeState is HomeLoaded;

    if (isAuthChecked && isHomeReady) {
      _navigated = true;
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _splashCubit,
      child: MultiBlocListener(
        listeners: [
          BlocListener<SplashCubit, SplashState>(
            bloc: _splashCubit,
            listener: (context, state) => _checkAndNavigate(),
          ),
          BlocListener<HomeCubit, HomeState>(
            listener: (context, state) => _checkAndNavigate(),
          ),
        ],
        child: Scaffold(
          backgroundColor: Colors.white,
          body: BlocBuilder<HomeCubit, HomeState>(
            builder: (context, homeState) {
              return BlocBuilder<SplashCubit, SplashState>(
                bloc: _splashCubit,
                builder: (context, splashState) {
                  final hasError = splashState is SplashFailure || homeState is HomeFailure;
                  final errorMessage = splashState is SplashFailure
                      ? splashState.error
                      : (homeState is HomeFailure ? homeState.message : null);

                  return FadeTransition(
                    opacity: _fadeAnim,
                    child: ScaleTransition(
                      scale: _scaleAnim,
                      child: Stack(
                        children: [
                          // 🌟 Markazdagi nafis orqa nur (ambient glow)
                          Center(
                            child: Container(
                              width: 240,
                              height: 240,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    AppColors.primary.withValues(alpha: 0.08),
                                    const Color(0xFFFFA000).withValues(alpha: 0.04),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.55, 1.0],
                                ),
                              ),
                            ),
                          ),

                          // 🍕 Asosiy mazmun: Pitsa va Brend nomi
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // 🍕 1 dona maxsus realistik animatsion pitsa
                                  const PizzaSliceLoader(
                                    size: 176,
                                    sliceCount: 6,
                                    duration: Duration(milliseconds: 1900),
                                  ),
                                  const SizedBox(height: 32),

                                  // Brend nomi
                                  Text(
                                    'STRADA PIZZA',
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.h2.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 24,
                                      letterSpacing: 3.5,
                                    ),
                                  ),
                                  const SizedBox(height: 6),

                                  // Nafis shior
                                  Text(
                                    'Har bir bo\'lagida haqiqiy lazzat',
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.neutral500,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.4,
                                    ),
                                  ),

                                  // Xatolik bo'lsa
                                  if (hasError && errorMessage != null) ...[
                                    const SizedBox(height: 28),
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppColors.error.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: AppColors.error.withValues(alpha: 0.2),
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            errorMessage.tr(),
                                            textAlign: TextAlign.center,
                                            style: AppTextStyles.bodySmall.copyWith(
                                              color: AppColors.error,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          ElevatedButton(
                                            onPressed: () {
                                              if (splashState is SplashFailure) {
                                                _splashCubit.init();
                                              }
                                              if (homeState is HomeFailure) {
                                                context.read<HomeCubit>().init();
                                              }
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.primary,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 20,
                                                vertical: 8,
                                              ),
                                            ),
                                            child: Text('common.retry'.tr()),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),

                          // ⏳ Pastki qismdagi nafis yuklanish matni
                          if (!hasError)
                            Positioned(
                              bottom: 40,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          AppColors.primary.withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'common.loading'.tr(),
                                      style: AppTextStyles.bodyExtraSmall.copyWith(
                                        color: AppColors.neutral400,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
