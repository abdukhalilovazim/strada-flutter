// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:pizza_strada/core/di/network_module.dart' as _i200;
import 'package:pizza_strada/core/network/api_client.dart' as _i745;
import 'package:pizza_strada/core/theme/theme_cubit.dart' as _i357;
import 'package:pizza_strada/features/auth/data/datasources/auth_remote_datasource.dart'
    as _i724;
import 'package:pizza_strada/features/auth/data/repositories/auth_repository_impl.dart'
    as _i788;
import 'package:pizza_strada/features/auth/domain/repositories/auth_repository.dart'
    as _i307;
import 'package:pizza_strada/features/auth/domain/usecases/confirm_otp_usecase.dart'
    as _i746;
import 'package:pizza_strada/features/auth/domain/usecases/get_me_usecase.dart'
    as _i619;
import 'package:pizza_strada/features/auth/domain/usecases/login_usecase.dart'
    as _i223;
import 'package:pizza_strada/features/auth/domain/usecases/update_profile_usecase.dart'
    as _i967;
import 'package:pizza_strada/features/auth/presentation/bloc/auth_cubit.dart'
    as _i100;
import 'package:pizza_strada/features/cart/presentation/bloc/cart_cubit.dart'
    as _i1058;
import 'package:pizza_strada/features/home/data/datasources/home_remote_datasource.dart'
    as _i972;
import 'package:pizza_strada/features/home/data/repositories/home_repository_impl.dart'
    as _i964;
import 'package:pizza_strada/features/home/domain/repositories/home_repository.dart'
    as _i929;
import 'package:pizza_strada/features/home/domain/usecases/home_usecases.dart'
    as _i918;
import 'package:pizza_strada/features/home/presentation/bloc/home_cubit.dart'
    as _i528;
import 'package:pizza_strada/features/loyalty/presentation/bloc/loyalty_cubit.dart'
    as _i421;
import 'package:pizza_strada/features/notifications/data/datasources/notification_remote_datasource.dart'
    as _i324;
import 'package:pizza_strada/features/notifications/data/repositories/notification_repository_impl.dart'
    as _i160;

import 'package:pizza_strada/features/notifications/domain/repositories/notification_repository.dart'
    as _i406;
import 'package:pizza_strada/features/notifications/domain/usecases/notification_usecases.dart'
    as _i912;
import 'package:pizza_strada/features/notifications/presentation/bloc/notifications_cubit.dart'
    as _i503;
import 'package:pizza_strada/features/orders/data/datasources/order_remote_datasource.dart'
    as _i168;
import 'package:pizza_strada/features/orders/data/repositories/order_repository_impl.dart'
    as _i124;
import 'package:pizza_strada/features/orders/domain/repositories/order_repository.dart'
    as _i414;
import 'package:pizza_strada/features/orders/domain/usecases/get_orders_usecase.dart'
    as _i576;
import 'package:pizza_strada/features/orders/presentation/bloc/order_cubit.dart'
    as _i539;
import 'package:pizza_strada/features/splash/presentation/bloc/splash_cubit.dart'
    as _i74;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    final networkModule = _$NetworkModule();
    gh.factory<_i74.SplashCubit>(() => _i74.SplashCubit());
    gh.lazySingleton<_i745.ApiClient>(() => networkModule.client);
    gh.lazySingleton<_i357.ThemeCubit>(() => _i357.ThemeCubit());
    gh.lazySingleton<_i1058.CartCubit>(() => _i1058.CartCubit());
    gh.lazySingleton<_i724.AuthRemoteDataSource>(
        () => _i724.AuthRemoteDataSourceImpl(gh<_i745.ApiClient>()));
    gh.lazySingleton<_i324.NotificationRemoteDataSource>(
        () => _i324.NotificationRemoteDataSourceImpl(gh<_i745.ApiClient>()));
    gh.lazySingleton<_i168.OrderRemoteDataSource>(
        () => _i168.OrderRemoteDataSourceImpl(gh<_i745.ApiClient>()));
    gh.lazySingleton<_i421.LoyaltyCubit>(
        () => _i421.LoyaltyCubit(apiClient: gh<_i745.ApiClient>()));
    gh.lazySingleton<_i414.OrderRepository>(
        () => _i124.OrderRepositoryImpl(gh<_i168.OrderRemoteDataSource>()));
    gh.lazySingleton<_i406.NotificationRepository>(() =>
        _i160.NotificationRepositoryImpl(
            gh<_i324.NotificationRemoteDataSource>()));
    gh.lazySingleton<_i972.HomeRemoteDataSource>(
        () => _i972.HomeRemoteDataSourceImpl(gh<_i745.ApiClient>()));
    gh.lazySingleton<_i912.GetNotificationsUseCase>(() =>
        _i912.GetNotificationsUseCase(gh<_i406.NotificationRepository>()));
    gh.lazySingleton<_i912.MarkAllNotificationsReadUseCase>(() =>
        _i912.MarkAllNotificationsReadUseCase(
            gh<_i406.NotificationRepository>()));
    gh.lazySingleton<_i912.MarkNotificationReadUseCase>(() =>
        _i912.MarkNotificationReadUseCase(gh<_i406.NotificationRepository>()));
    gh.lazySingleton<_i929.HomeRepository>(
        () => _i964.HomeRepositoryImpl(gh<_i972.HomeRemoteDataSource>()));
    gh.lazySingleton<_i307.AuthRepository>(
        () => _i788.AuthRepositoryImpl(gh<_i724.AuthRemoteDataSource>()));
    gh.lazySingleton<_i576.GetOrdersUseCase>(
        () => _i576.GetOrdersUseCase(gh<_i414.OrderRepository>()));
    gh.lazySingleton<_i503.NotificationsCubit>(() => _i503.NotificationsCubit(
          gh<_i912.GetNotificationsUseCase>(),
          gh<_i912.MarkAllNotificationsReadUseCase>(),
          gh<_i912.MarkNotificationReadUseCase>(),
        ));
    gh.factory<_i539.OrderCubit>(
        () => _i539.OrderCubit(gh<_i576.GetOrdersUseCase>()));
    gh.lazySingleton<_i746.ConfirmOtpUseCase>(
        () => _i746.ConfirmOtpUseCase(gh<_i307.AuthRepository>()));
    gh.lazySingleton<_i619.GetMeUseCase>(
        () => _i619.GetMeUseCase(gh<_i307.AuthRepository>()));
    gh.lazySingleton<_i223.LoginUseCase>(
        () => _i223.LoginUseCase(gh<_i307.AuthRepository>()));
    gh.lazySingleton<_i967.UpdateProfileUseCase>(
        () => _i967.UpdateProfileUseCase(gh<_i307.AuthRepository>()));
    gh.lazySingleton<_i918.GetCategoriesUseCase>(
        () => _i918.GetCategoriesUseCase(gh<_i929.HomeRepository>()));
    gh.lazySingleton<_i918.GetProductsUseCase>(
        () => _i918.GetProductsUseCase(gh<_i929.HomeRepository>()));
    gh.lazySingleton<_i918.GetSettingsUseCase>(
        () => _i918.GetSettingsUseCase(gh<_i929.HomeRepository>()));
    gh.lazySingleton<_i918.GetSlidersUseCase>(
        () => _i918.GetSlidersUseCase(gh<_i929.HomeRepository>()));
    gh.lazySingleton<_i918.GetStoriesUseCase>(
        () => _i918.GetStoriesUseCase(gh<_i929.HomeRepository>()));
    gh.factory<_i100.AuthCubit>(() => _i100.AuthCubit(
          gh<_i223.LoginUseCase>(),
          gh<_i746.ConfirmOtpUseCase>(),
        ));
    gh.factory<_i528.HomeCubit>(() => _i528.HomeCubit(
          gh<_i918.GetCategoriesUseCase>(),
          gh<_i918.GetStoriesUseCase>(),
          gh<_i918.GetProductsUseCase>(),
        ));
    return this;
  }
}

class _$NetworkModule extends _i200.NetworkModule {}
