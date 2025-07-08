import 'package:app/core/exceptions/domain_exception.dart';
import 'package:uuid/uuid.dart';

class PassId {
  final String value;

  const PassId(this.value);

  factory PassId.generate() {
    // Generate with 'BP' prefix for boarding pass
    final uuid = const Uuid()
        .v4()
        .replaceAll('-', '')
        .substring(0, 8)
        .toUpperCase();
    return PassId('BP$uuid');
  }

  factory PassId.fromString(String id) {
    if (id.isEmpty) {
      throw DomainException('Pass ID cannot be empty');
    }
    final trimedID = id.trim();
    if (!trimedID.startsWith('BP')) {
      throw DomainException('Pass ID must start with "BP"');
    }

    if (trimedID.length != 10) {
      throw DomainException(
        'Pass ID must be 10 characters long (BP + 8 chars)',
      );
    }

    final regex = RegExp(r'^BP[A-Z0-9]{8}$');
    if (!regex.hasMatch(trimedID)) {
      throw DomainException('Invalid pass ID format');
    }

    return PassId(trimedID);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PassId && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'PassId($value)';
}
