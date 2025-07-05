import 'package:app/core/exceptions/domain_exception.dart';

/// Member number value object
/// Format: AA123456 (2 letters + 6 digits)
class MemberNumber {
  final String value;

  const MemberNumber(this.value);

  factory MemberNumber.create(String memberNumber) {
    _validateFormat(memberNumber);
    return MemberNumber(memberNumber.toUpperCase());
  }

  static void _validateFormat(String memberNumber) {
    if (memberNumber.isEmpty) {
      throw DomainException('Member number cannot be empty');
    }

    if (memberNumber.length != 8) {
      throw DomainException('Member number must be 8 characters long');
    }

    final regex = RegExp(r'^[A-Za-z]{2}[0-9]{6}$');
    if (!regex.hasMatch(memberNumber)) {
      throw DomainException(
        'Member number must be in format: 2 letters + 6 digits (e.g., AA123456)',
      );
    }
  }

  /// Get airline code (first 2 letters)
  String get airlineCode => value.substring(0, 2);

  /// Get member sequence (last 6 digits)
  String get memberSequence => value.substring(2);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MemberNumber && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'MemberNumber($value)';
}
