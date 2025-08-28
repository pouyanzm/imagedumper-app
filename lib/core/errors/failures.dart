import 'package:equatable/equatable.dart';

/// Abstract base class for all failures
abstract class Failure extends Equatable {
  final String message;
  final int? code;

  const Failure({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

/// Network-related failures
class NetworkFailure extends Failure {
  const NetworkFailure({required super.message, super.code});
}

/// Server-related failures
class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.code});
}

/// Cache-related failures
class CacheFailure extends Failure {
  const CacheFailure({required super.message, super.code});
}

/// Validation-related failures
class ValidationFailure extends Failure {
  const ValidationFailure({required super.message, super.code});
}

/// Permission-related failures
class PermissionFailure extends Failure {
  const PermissionFailure({required super.message, super.code});
}

/// File operation failures
class FileFailure extends Failure {
  const FileFailure({required super.message, super.code});
}

/// Socket connection failures
class SocketFailure extends Failure {
  const SocketFailure({required super.message, super.code});
}
