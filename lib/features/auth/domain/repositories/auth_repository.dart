import 'package:dartz/dartz.dart';
import 'package:pizza_strada/core/error/failures.dart';
import 'package:pizza_strada/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, bool>> login({required String fullName, required String phone});
  Future<Either<Failure, UserEntity>> confirmOtp({required String phone, required int code});
}
