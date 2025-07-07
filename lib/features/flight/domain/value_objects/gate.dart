import 'package:app/core/exceptions/domain_exception.dart';

/// Gate value object
/// Examples: A12, B5, C24, T1A15
class Gate {
  final String value;

  const Gate(this.value);

  /// Create gate with validation
  factory Gate.create(String gateNumber) {
    _validateFormat(gateNumber);
    return Gate(gateNumber.toUpperCase().trim());
  }

  /// Validate gate format
  static void _validateFormat(String gateNumber) {
    final trimmed = gateNumber.trim();

    if (trimmed.isEmpty) {
      throw DomainException('Gate number cannot be empty');
    }

    if (trimmed.length > 10) {
      throw DomainException('Gate number cannot exceed 10 characters');
    }

    // Allow letters, numbers, and common gate formats
    final regex = RegExp(r'^[A-Za-z0-9]+$');
    if (!regex.hasMatch(trimmed)) {
      throw DomainException('Gate number can only contain letters and numbers');
    }
  }

  /// Get terminal from gate (if applicable)
  String? get terminal {
    // Extract terminal for common formats like T1A15, T2B5
    final terminalMatch = RegExp(r'^(T\d+)').firstMatch(value);
    return terminalMatch?.group(1);
  }

  /// Get gate section (letter part)
  String? get section {
    final sectionMatch = RegExp(r'([A-Z]+)').firstMatch(value);
    return sectionMatch?.group(1);
  }

  /// Get gate number (digit part)
  String? get number {
    final numberMatch = RegExp(r'(\d+)').firstMatch(value);
    return numberMatch?.group(1);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Gate && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Gate($value)';
}
