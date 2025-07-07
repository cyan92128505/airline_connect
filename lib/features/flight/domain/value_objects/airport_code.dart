import 'package:app/core/exceptions/domain_exception.dart';

/// Airport code value object (IATA format)
/// Examples: TPE, NRT, LAX, JFK
class AirportCode {
  final String value;

  const AirportCode(this.value);

  /// Create airport code with validation
  factory AirportCode.create(String airportCode) {
    _validateFormat(airportCode);
    return AirportCode(airportCode.toUpperCase().trim());
  }

  /// Validate airport code format
  static void _validateFormat(String airportCode) {
    final trimmed = airportCode.trim();

    if (trimmed.isEmpty) {
      throw DomainException('Airport code cannot be empty');
    }

    if (trimmed.length != 3) {
      throw DomainException('Airport code must be exactly 3 characters');
    }

    final regex = RegExp(r'^[A-Za-z]{3}$');
    if (!regex.hasMatch(trimmed)) {
      throw DomainException('Airport code must contain only letters');
    }
  }

  /// Get display name for common airports
  String get displayName {
    switch (value) {
      case 'TPE':
        return '台北桃園';
      case 'TSA':
        return '台北松山';
      case 'KHH':
        return '高雄小港';
      case 'NRT':
        return '東京成田';
      case 'HND':
        return '東京羽田';
      case 'ICN':
        return '首爾仁川';
      case 'HKG':
        return '香港';
      case 'SIN':
        return '新加坡';
      case 'LAX':
        return '洛杉磯';
      case 'JFK':
        return '紐約甘迺迪';
      default:
        return value; // Return code if no mapping available
    }
  }

  /// Check if this is a domestic Taiwan airport
  bool get isDomestic {
    const domesticCodes = [
      'TPE',
      'TSA',
      'KHH',
      'RMQ',
      'TXG',
      'CYI',
      'TTT',
      'GNI',
      'MZG',
      'LZN',
    ];
    return domesticCodes.contains(value);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AirportCode && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'AirportCode($value)';
}
