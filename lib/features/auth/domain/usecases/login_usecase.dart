import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pizza_strada/core/error/failures.dart';
import 'package:pizza_strada/features/auth/domain/repositories/auth_repository.dart';

@lazySingleton
class LoginUseCase {
  final AuthRepository _repository;

  LoginUseCase(this._repository);

  Future<Either<Failure, bool>> call({required String fullName, required String phone}) {
    return _repository.login(fullName: fullName, phone: phone);
  }
}
