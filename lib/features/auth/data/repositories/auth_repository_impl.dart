import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:pizza_strada/core/error/failures.dart';
import 'package:pizza_strada/core/utils/graphql_helper.dart';
import 'package:pizza_strada/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:pizza_strada/features/auth/domain/entities/user_entity.dart';
import 'package:pizza_strada/features/auth/domain/repositories/auth_repository.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, bool>> login({
    required String fullName,
    required String phone,
  }) async {
    try {
      return Right(await _remoteDataSource.login(fullName: fullName, phone: phone));
    } on OperationException catch (e) {
      debugPrint('❌ [AuthRepo] login: $e');
      return Left(GraphQLHelper.toFailure(e));
    } on SocketException {
      return Left(const NetworkFailure(message: 'Internet aloqasi yo\'q'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> confirmOtp({
    required String phone,
    required int code,
  }) async {
    try {
      return Right(await _remoteDataSource.confirmOtp(phone: phone, code: code));
    } on OperationException catch (e) {
      debugPrint('❌ [AuthRepo] confirmOtp: $e');
      return Left(GraphQLHelper.toFailure(e));
    } on SocketException {
      return Left(const NetworkFailure(message: 'Internet aloqasi yo\'q'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
