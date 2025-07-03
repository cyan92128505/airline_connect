import 'package:uuid/uuid.dart';
import '../../../core/exceptions/domain_exception.dart';

class MemberId {
  final String value;

  const MemberId(this.value);

  factory MemberId.generate() {
    return MemberId(const Uuid().v4());
  }

  factory MemberId.fromString(String id) {
    if (id.isEmpty) {
      throw DomainException('Member ID cannot be empty');
    }

    final uuidRegex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );

    if (!uuidRegex.hasMatch(id)) {
      throw DomainException('Invalid member ID format');
    }

    return MemberId(id);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MemberId && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'MemberId($value)';
}
