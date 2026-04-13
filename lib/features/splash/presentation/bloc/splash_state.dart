import 'package:equatable/equatable.dart';

abstract class SplashState extends Equatable {
  const SplashState();

  @override
  List<Object?> get props => [];
}

class SplashInitial extends SplashState {}

class SplashLoading extends SplashState {}

class SplashAuthenticated extends SplashState {}

class SplashUnauthenticated extends SplashState {}

class SplashMaintenance extends SplashState {
  final String message;
  const SplashMaintenance(this.message);

  @override
  List<Object?> get props => [message];
}

class SplashFailure extends SplashState {
  final String error;
  const SplashFailure(this.error);

  @override
  List<Object?> get props => [error];
}
