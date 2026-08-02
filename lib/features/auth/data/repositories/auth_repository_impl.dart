import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:pizza_strada/core/error/failures.dart';
import 'package:pizza_strada/core/utils/api_helper.dart';
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
    } on SocketException {
      return Left(const NetworkFailure(message: 'Internet aloqasi yo\'q'));
    } catch (e) {
      debugPrint('❌ [AuthRepo] login: $e');
      return Left(ApiHelper.fromException(e));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> confirmOtp({
    required String phone,
    required int code,
  }) async {
    try {
      return Right(await _remoteDataSource.confirmOtp(phone: phone, code: code));
    } on SocketException {
      return Left(const NetworkFailure(message: 'Internet aloqasi yo\'q'));
    } catch (e) {
      debugPrint('❌ [AuthRepo] confirmOtp: $e');
      return Left(ApiHelper.fromException(e));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getMe() async {
    try {
      return Right(await _remoteDataSource.getMe());
    } on SocketException {
      return Left(const NetworkFailure(message: 'Internet aloqasi yo\'q'));
    } catch (e) {
      debugPrint('❌ [AuthRepo] getMe: $e');
      return Left(ApiHelper.fromException(e));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> updateProfile({required String fullName, String? birthdate}) async {
    try {
      final userModel = await _remoteDataSource.updateProfile(fullName: fullName, birthdate: birthdate);
      return Right(userModel);
    } catch (e) {
      return Left(ApiHelper.fromException(e));
    }
  }
}

