import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/flight/domain/value_objects/airport_code.dart';
import 'package:app/core/exceptions/domain_exception.dart';

void main() {
  group('AirportCode Value Object Tests', () {
    test('should create valid airport code', () {
      final airportCode = AirportCode.create('TPE');

      expect(airportCode.value, equals('TPE'));
      expect(airportCode.displayName, equals('台北桃園'));
    });

    test('should convert to uppercase', () {
      final airportCode = AirportCode.create('tpe');

      expect(airportCode.value, equals('TPE'));
    });

    test('should check if domestic airport', () {
      final domesticAirport = AirportCode.create('TPE');
      final internationalAirport = AirportCode.create('NRT');

      expect(domesticAirport.isDomestic, isTrue);
      expect(internationalAirport.isDomestic, isFalse);
    });

    test('should return display name for known airports', () {
      expect(AirportCode.create('TPE').displayName, equals('台北桃園'));
      expect(AirportCode.create('NRT').displayName, equals('東京成田'));
      expect(AirportCode.create('XXX').displayName, equals('XXX'));
    });

    test('should throw exception for invalid length', () {
      expect(() => AirportCode.create('TP'), throwsA(isA<DomainException>()));
    });

    test('should throw exception for non-letter characters', () {
      expect(() => AirportCode.create('T1E'), throwsA(isA<DomainException>()));
    });

    test('should throw exception for empty string', () {
      expect(() => AirportCode.create(''), throwsA(isA<DomainException>()));
    });
  });
}
