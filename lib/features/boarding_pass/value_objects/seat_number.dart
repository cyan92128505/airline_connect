import '../../../core/exceptions/domain_exception.dart';

/// Seat number value object
/// Supports formats like: 1A, 12B, 45F, etc.
class SeatNumber {
  final String value;

  const SeatNumber(this.value);

  factory SeatNumber.create(String seatNumber) {
    _validateFormat(seatNumber);
    return SeatNumber(seatNumber.toUpperCase().trim());
  }

  static void _validateFormat(String seatNumber) {
    final trimmed = seatNumber.trim();

    if (trimmed.isEmpty) {
      throw DomainException('Seat number cannot be empty');
    }

    if (trimmed.length < 2 || trimmed.length > 4) {
      throw DomainException('Seat number must be 2-4 characters long');
    }

    // Pattern: 1-3 digits followed by 1 letter
    final regex = RegExp(r'^[1-9][0-9]{0,2}[A-Za-z]$');
    if (!regex.hasMatch(trimmed)) {
      throw DomainException(
        'Seat number must be in format: row number (1-999) + letter (A-Z)',
      );
    }

    final seatLetter = trimmed.substring(trimmed.length - 1).toUpperCase();
    const validLetters = [
      'A',
      'B',
      'C',
      'D',
      'E',
      'F',
      'G',
      'H',
      'J',
      'K',
      'L',
    ];

    if (!validLetters.contains(seatLetter)) {
      throw DomainException('Invalid seat letter: $seatLetter');
    }
  }

  int get rowNumber {
    final numberPart = value.substring(0, value.length - 1);
    return int.parse(numberPart);
  }

  String get seatLetter => value.substring(value.length - 1);

  bool get isWindowSeat {
    const windowSeats = ['A', 'F', 'K'];
    return windowSeats.contains(seatLetter);
  }

  bool get isAisleSeat {
    const aisleSeats = ['C', 'D', 'G', 'H'];
    return aisleSeats.contains(seatLetter);
  }

  bool get isMiddleSeat {
    const middleSeats = ['B', 'E', 'J'];
    return middleSeats.contains(seatLetter);
  }

  /// Get seat position description
  String get positionDescription {
    if (isWindowSeat) return '靠窗';
    if (isAisleSeat) return '靠走道';
    if (isMiddleSeat) return '中間';
    return '未知';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SeatNumber && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'SeatNumber($value)';
}
