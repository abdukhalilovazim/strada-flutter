import 'package:dartz/dartz.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:pizza_strada/core/error/failures.dart';
import 'package:pizza_strada/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:pizza_strada/features/auth/domain/entities/user_entity.dart';
import 'package:pizza_strada/features/auth/domain/repositories/auth_repository.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, bool>> login({required String fullName, required String phone}) async {
    try {
      final result = await _remoteDataSource.login(fullName: fullName, phone: phone);
      return Right(result);
    } catch (e) {
      String? errorMessage;
      if (e is OperationException && e.graphqlErrors.isNotEmpty) {
        errorMessage = e.graphqlErrors.first.message;
      }
      return Left(ServerFailure(message: errorMessage));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> confirmOtp({required String phone, required int code}) async {
    try {
      final userModel = await _remoteDataSource.confirmOtp(phone: phone, code: code);
      return Right(userModel);
    } catch (e) {
      String? errorMessage;
      if (e is OperationException && e.graphqlErrors.isNotEmpty) {
        errorMessage = e.graphqlErrors.first.message;
      }
      return Left(ServerFailure(message: errorMessage));
    }
  }
}
