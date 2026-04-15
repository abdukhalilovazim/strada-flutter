import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:pizza_strada/core/storage/secure_storage.dart';
import 'package:pizza_strada/features/home/domain/repositories/home_repository.dart';
import 'package:pizza_strada/features/splash/presentation/bloc/splash_state.dart';

@injectable
class SplashCubit extends Cubit<SplashState> {
  final HomeRepository _homeRepository;

  SplashCubit(this._homeRepository) : super(SplashInitial());

  /// Ilova ishga tushganda zaruriy sozlamalar va auth holatini tekshiradi.
  /// 
  /// 1. [HomeRepository.getSettings] orqali server sozlamalarini oladi.
  /// 2. [settings.canOrder] orqali buyurtma berish mumkinligini (ish vaqti) tekshiradi.
  Future<void> init() async {
    emit(SplashLoading());

    // Server sozlamalarini olish
    final settingsResult = await _homeRepository.getSettings();

    settingsResult.fold(
      (failure) {
        // API'dan kelgan aniq xato xabarini ko'rsatish
        final errorMessage = failure.message ?? 'Noma\'lum xato yuz berdi';
        debugPrint('❌ [SplashCubit] Settings xatosi: $errorMessage');
        emit(SplashFailure(errorMessage));
      },
      (settings) async {
        // Token mavjudligini tekshirish orqali auth holatini aniqlash
        final token = await SecureStorage.getToken();
        if (token != null && token.isNotEmpty) {
          emit(SplashAuthenticated());
        } else {
          emit(SplashUnauthenticated());
        }
      },
    );
  }
}
