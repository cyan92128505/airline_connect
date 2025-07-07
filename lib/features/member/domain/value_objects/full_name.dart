import 'package:app/core/exceptions/domain_exception.dart';

class FullName {
  final String value;

  const FullName(this.value);

  factory FullName.create(String name) {
    _validateName(name);
    return FullName(name.trim());
  }

  static void _validateName(String name) {
    final trimmedName = name.trim();

    if (trimmedName.isEmpty) {
      throw DomainException('Full name cannot be empty');
    }

    if (trimmedName.length < 2) {
      throw DomainException('Full name must be at least 2 characters');
    }

    if (trimmedName.length > 50) {
      throw DomainException('Full name cannot exceed 50 characters');
    }

    final validNameRegex = RegExp(r"^[a-zA-Z\u4e00-\u9fff\s\-'.]+$");
    if (!validNameRegex.hasMatch(trimmedName)) {
      throw DomainException('Full name contains invalid characters');
    }
  }

  String get nameSuffix {
    if (value.length < 4) return value;
    return value.substring(value.length - 4);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FullName && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'FullName($value)';
}
