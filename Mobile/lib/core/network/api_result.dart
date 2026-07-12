import 'failure.dart';

/// Normalized API result. Response parsing will be extended once backend
/// confirms the response contract.
class ApiResult<T> {
  const ApiResult._({this.data, this.failure});

  final T? data;
  final Failure? failure;

  bool get isSuccess => failure == null;
  bool get isFailure => failure != null;

  factory ApiResult.success(T data) => ApiResult._(data: data);

  factory ApiResult.failure(Failure failure) => ApiResult._(failure: failure);

  R when<R>({
    required R Function(T data) success,
    required R Function(Failure failure) failure,
  }) {
    if (isSuccess) {
      return success(data as T);
    }
    return failure(this.failure!);
  }
}
