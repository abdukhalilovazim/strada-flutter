import 'package:dartz/dartz.dart';
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
        // Tarmoq xatosi yoki server xatosi bo'lganda
        emit(SplashFailure('Xizmatga bog\'lanib bo\'lmadi. Internetni tekshiring.'));
      },
      (settings) async {
        // Ilova ish vaqtini (can_order) tekshirish
        if (!settings.canOrder) {
          emit(const SplashMaintenance('Hozirda buyurtmalar qabul qilinmaydi. Ish vaqti: 09:00 - 23:00'));
          return;
        }

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
