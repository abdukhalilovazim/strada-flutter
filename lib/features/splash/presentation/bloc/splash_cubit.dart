import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:pizza_strada/core/storage/secure_storage.dart';
import 'package:pizza_strada/features/splash/presentation/bloc/splash_state.dart';
@injectable
class SplashCubit extends Cubit<SplashState> {
  SplashCubit() : super(SplashInitial());

  /// Ilova ishga tushganda token tekshiruvi va auth holatini aniqlaydi.
  Future<void> init() async {
    emit(SplashLoading());

    try {
      final token = await SecureStorage.getToken();
      if (token != null && token.isNotEmpty) {
        emit(SplashAuthenticated());
      } else {
        emit(SplashUnauthenticated());
      }
    } catch (e) {
      debugPrint('❌ [SplashCubit] Token tekshirishda xatolik: $e');
      emit(SplashUnauthenticated());
    }
  }
}
