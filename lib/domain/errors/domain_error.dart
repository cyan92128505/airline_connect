import 'package:freezed_annotation/freezed_annotation.dart';

part 'domain_error.freezed.dart';

@freezed
sealed class DomainError with _$DomainError {
  const DomainError._();

  const factory DomainError.validation({
    required String message,
    required String field,
  }) = ValidationError;

  const factory DomainError.business({
    required String message,
    required String code,
  }) = BusinessError;

  const factory DomainError.technical({
    required String message,
    Exception? exception,
  }) = TechnicalError;

  @override
  String get message => switch (this) {
    ValidationError(message: final msg) => msg,
    BusinessError(message: final msg) => msg,
    TechnicalError(message: final msg) => msg,
  };

  String get code => switch (this) {
    ValidationError(field: final field) => 'VALIDATION_$field',
    BusinessError(code: final code) => code,
    TechnicalError() => 'TECHNICAL_ERROR',
  };

  bool get isValidation => this is ValidationError;

  bool get isBusiness => this is BusinessError;

  bool get isTechnical => this is TechnicalError;
}
