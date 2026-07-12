import 'package:equatable/equatable.dart';

enum FailureType {
  network,
  unauthorized,
  forbidden,
  notFound,
  validation,
  server,
  unknown,
}

class Failure extends Equatable {
  const Failure({
    required this.message,
    this.type = FailureType.unknown,
    this.statusCode,
  });

  final String message;
  final FailureType type;
  final int? statusCode;

  @override
  List<Object?> get props => [message, type, statusCode];
}
