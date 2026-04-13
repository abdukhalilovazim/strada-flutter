import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pizza_strada/core/error/failures.dart';
import 'package:pizza_strada/features/auth/domain/entities/user_entity.dart';
import 'package:pizza_strada/features/auth/domain/repositories/auth_repository.dart';

@lazySingleton
class ConfirmOtpUseCase {
  final AuthRepository _repository;

  ConfirmOtpUseCase(this._repository);

  Future<Either<Failure, UserEntity>> call({required String phone, required int code}) {
    return _repository.confirmOtp(phone: phone, code: code);
  }
}
