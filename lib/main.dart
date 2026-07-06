import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pizza_strada/core/di/injection.dart';
import 'package:pizza_strada/core/router/app_router.dart';
import 'package:pizza_strada/core/theme/app_theme.dart';
import 'package:pizza_strada/core/theme/theme_cubit.dart';
import 'package:pizza_strada/core/utils/device_info_helper.dart';
import 'package:pizza_strada/core/storage/shared_prefs.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/cart_cubit.dart';
import 'package:pizza_strada/features/home/presentation/bloc/home_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Catch unhandled asynchronous errors globally (e.g. stream timeouts on background resume)
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('🚨 [Unhandled Async Error]: $error\n$stack');
    return true; // Prevents application crash
  };
  
  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Ekran faqat portrait (tik) holatda ishlaydi
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await DeviceInfoHelper.init();
  await SharedPrefs.init();
  await EasyLocalization.ensureInitialized();
  await configureDependencies();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('uz'), Locale('ru'), Locale('en')],
      path: 'lib/l10n',
      fallbackLocale: const Locale('uz'),
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => getIt<CartCubit>()),
          BlocProvider(create: (context) => getIt<HomeCubit>()..init()),
          BlocProvider(create: (context) => getIt<ThemeCubit>()),
        ],
        child: BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, themeMode) => MyApp(themeMode: themeMode),
        ),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final ThemeMode themeMode;
  const MyApp({super.key, required this.themeMode});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Pizza strada',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      routerConfig: appRouter,
    );
  }
}
