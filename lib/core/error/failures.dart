import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String? message;
  const Failure({this.message});

  @override
  List<Object?> get props => [message];

  String get messageKey => message ?? 'error_server';
}

class ServerFailure extends Failure {
  const ServerFailure({super.message});
}

class NetworkFailure extends Failure {
  const NetworkFailure({super.message});
  @override
  String get messageKey => message ?? 'error_network';
}
