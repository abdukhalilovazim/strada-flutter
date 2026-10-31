import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pizza_strada/core/di/injection.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';
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
  bool _minDurationPassed = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _splashCubit = getIt<SplashCubit>()..init();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();

    // Kamida 800ms animatsiya davomiyligi o'tgach tekshirish
    Future.delayed(const Duration(milliseconds: 800), () {
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
          backgroundColor: Colors.white, // Splash har doim oq (tema mustaqil)
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
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLogo(),
                          const SizedBox(height: 60),
                          if (hasError && errorMessage != null) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                errorMessage.tr(),
                                textAlign: TextAlign.center,
                                style: AppTextStyles.bodyMedium
                                    .copyWith(color: AppColors.error),
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () {
                                if (splashState is SplashFailure) {
                                  _splashCubit.init();
                                }
                                if (homeState is HomeFailure) {
                                  context.read<HomeCubit>().init();
                                }
                              },
                              child: Text('common.retry'.tr()),
                            ),
                          ] else ...[
                            SizedBox(
                              width: 32,
                              height: 32,
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                                strokeWidth: 3,
                                backgroundColor:
                                    AppColors.primary.withValues(alpha: 0.1),
                              ),
                            ),
                          ],
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

