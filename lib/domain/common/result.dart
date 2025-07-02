import 'package:freezed_annotation/freezed_annotation.dart';
import '../errors/domain_error.dart';

part 'result.freezed.dart';

@freezed
sealed class Result<T> with _$Result<T> {
  const Result._();

  const factory Result.success(T value) = Success<T>;
  const factory Result.failure(DomainError error) = Failure<T>;

  bool get isSuccess => this is Success<T>;

  bool get isFailure => this is Failure<T>;

  T getOrThrow() {
    return switch (this) {
      Success(value: final value) => value,
      Failure(error: final error) => throw Exception(error.message),
    };
  }

  T getOrDefault(T defaultValue) {
    return switch (this) {
      Success(value: final value) => value,
      Failure() => defaultValue,
    };
  }

  DomainError? get error {
    return switch (this) {
      Success() => null,
      Failure(error: final error) => error,
    };
  }

  Result<U> map<U>(U Function(T) mapper) {
    return switch (this) {
      Success(value: final value) => Result.success(mapper(value)),
      Failure(error: final error) => Result.failure(error),
    };
  }

  Result<U> flatMap<U>(Result<U> Function(T) mapper) {
    return switch (this) {
      Success(value: final value) => mapper(value),
      Failure(error: final error) => Result.failure(error),
    };
  }

  U fold<U>(U Function(DomainError) onFailure, U Function(T) onSuccess) {
    return switch (this) {
      Success(value: final value) => onSuccess(value),
      Failure(error: final error) => onFailure(error),
    };
  }
}
