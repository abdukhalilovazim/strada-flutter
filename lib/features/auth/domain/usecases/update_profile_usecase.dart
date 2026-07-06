import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pizza_strada/core/error/failures.dart';
import 'package:pizza_strada/features/auth/domain/entities/user_entity.dart';
import 'package:pizza_strada/features/auth/domain/repositories/auth_repository.dart';

@lazySingleton
class UpdateProfileUseCase {
  final AuthRepository _repository;

  UpdateProfileUseCase(this._repository);

  Future<Either<Failure, UserEntity>> call({required String fullName, String? birthdate}) async {
    return await _repository.updateProfile(fullName: fullName, birthdate: birthdate);
  }
}
