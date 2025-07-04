import '../../../core/exceptions/domain_exception.dart';

/// Flight number value object
/// Format: BR857, CI101, etc. (2-3 letters + 3-4 digits)
class FlightNumber {
  final String value;

  const FlightNumber(this.value);

  factory FlightNumber.create(String flightNumber) {
    _validateFormat(flightNumber);
    return FlightNumber(flightNumber.toUpperCase());
  }

  static void _validateFormat(String flightNumber) {
    if (flightNumber.isEmpty) {
      throw DomainException('Flight number cannot be empty');
    }

    final trimmed = flightNumber.trim().toUpperCase();

    if (trimmed.length < 5 || trimmed.length > 7) {
      throw DomainException('Flight number must be 5-7 characters long');
    }

    // Pattern: 2-3 letters followed by 3-4 digits
    final regex = RegExp(r'^[A-Z]{2,3}[0-9]{3,4}$');
    if (!regex.hasMatch(trimmed)) {
      throw DomainException(
        'Flight number must be 2-3 letters followed by 3-4 digits (e.g., BR857, CI101)',
      );
    }
  }

  /// Get airline code (letter part)
  String get airlineCode => value.replaceAll(RegExp(r'[0-9]'), '');

  /// Get flight sequence (number part)
  String get flightSequence => value.replaceAll(RegExp(r'[A-Z]'), '');

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FlightNumber && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'FlightNumber($value)';
}
