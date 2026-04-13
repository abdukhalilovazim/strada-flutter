import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:pizza_strada/features/auth/domain/entities/user_entity.dart';
import 'package:pizza_strada/features/auth/domain/usecases/confirm_otp_usecase.dart';
import 'package:pizza_strada/features/auth/domain/usecases/login_usecase.dart';
import 'package:pizza_strada/core/storage/secure_storage.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthOtpSent extends AuthState { final String phone; const AuthOtpSent(this.phone); @override List<Object?> get props => [phone]; }
class AuthSuccess extends AuthState { final UserEntity user; const AuthSuccess(this.user); @override List<Object?> get props => [user]; }
class AuthFailure extends AuthState { final String message; const AuthFailure(this.message); @override List<Object?> get props => [message]; }

@injectable
class AuthCubit extends Cubit<AuthState> {
  final LoginUseCase _loginUseCase;
  final ConfirmOtpUseCase _confirmOtpUseCase;

  AuthCubit(this._loginUseCase, this._confirmOtpUseCase) : super(AuthInitial());

  Future<void> login({required String fullName, required String phone}) async {
    emit(AuthLoading());
    final result = await _loginUseCase(fullName: fullName, phone: phone);
    result.fold(
      (failure) => emit(AuthFailure(failure.messageKey)),
      (success) => emit(AuthOtpSent(phone)),
    );
  }

  Future<void> confirmOtp({required String phone, required int code}) async {
    emit(AuthLoading());
    final result = await _confirmOtpUseCase(phone: phone, code: code);
    result.fold(
      (failure) => emit(AuthFailure(failure.messageKey)),
      (user) async {
        await SecureStorage.saveToken(user.token);
        await SecureStorage.saveUserInfo(name: user.fullName, phone: user.phone);
        emit(AuthSuccess(user));
      },
    );
  }
  Future<String?> getToken() => SecureStorage.getToken();
}
