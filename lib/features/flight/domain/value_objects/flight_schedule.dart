import 'package:app/core/exceptions/domain_exception.dart';
import 'package:timezone/timezone.dart';
import 'airport_code.dart';
import 'gate.dart';

/// Flight schedule value object
/// Contains all time-related and location information for a flight
class FlightSchedule {
  final TZDateTime departureTime;
  final TZDateTime boardingTime;
  final AirportCode departure;
  final AirportCode arrival;
  final Gate gate;

  const FlightSchedule({
    required this.departureTime,
    required this.boardingTime,
    required this.departure,
    required this.arrival,
    required this.gate,
  });

  factory FlightSchedule.create({
    required TZDateTime departureTime,
    required TZDateTime boardingTime,
    required String departureAirport,
    required String arrivalAirport,
    required String gateNumber,
  }) {
    _validateTimes(departureTime, boardingTime);
    _validateAirports(departureAirport, arrivalAirport);

    return FlightSchedule(
      departureTime: departureTime,
      boardingTime: boardingTime,
      departure: AirportCode.create(departureAirport),
      arrival: AirportCode.create(arrivalAirport),
      gate: Gate.create(gateNumber),
    );
  }

  FlightSchedule delay(Duration delayDuration) {
    return FlightSchedule(
      departureTime: departureTime.add(delayDuration),
      boardingTime: boardingTime.add(delayDuration),
      departure: departure,
      arrival: arrival,
      gate: gate,
    );
  }

  FlightSchedule updateGate(String newGate) {
    return FlightSchedule(
      departureTime: departureTime,
      boardingTime: boardingTime,
      departure: departure,
      arrival: arrival,
      gate: Gate.create(newGate),
    );
  }

  FlightSchedule updateDepartureTime(TZDateTime newDepartureTime) {
    // Maintain 1-hour boarding window
    final newBoardingTime = newDepartureTime.subtract(const Duration(hours: 1));

    return FlightSchedule(
      departureTime: newDepartureTime,
      boardingTime: newBoardingTime,
      departure: departure,
      arrival: arrival,
      gate: gate,
    );
  }

  Duration get flightPreparationTime {
    return departureTime.difference(boardingTime);
  }

  bool isInBoardingWindow() {
    final now = TZDateTime.now(local);
    return now.isAfter(boardingTime) && now.isBefore(departureTime);
  }

  bool get hasDeparted {
    return TZDateTime.now(local).isAfter(departureTime);
  }

  static void _validateTimes(
    TZDateTime departureTime,
    TZDateTime boardingTime,
  ) {
    if (boardingTime.isAfter(departureTime)) {
      throw DomainException('Boarding time cannot be after departure time');
    }

    final now = TZDateTime.now(local);
    if (departureTime.isBefore(now)) {
      throw DomainException('Departure time cannot be in the past');
    }

    final timeDifference = departureTime.difference(boardingTime);
    if (timeDifference.inMinutes < 30) {
      throw DomainException(
        'Boarding must start at least 30 minutes before departure',
      );
    }

    if (timeDifference.inHours > 4) {
      throw DomainException(
        'Boarding cannot start more than 4 hours before departure',
      );
    }
  }

  static void _validateAirports(String departure, String arrival) {
    if (departure.trim().toUpperCase() == arrival.trim().toUpperCase()) {
      throw DomainException('Departure and arrival airports must be different');
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FlightSchedule &&
        other.departureTime == departureTime &&
        other.boardingTime == boardingTime &&
        other.departure == departure &&
        other.arrival == arrival &&
        other.gate == gate;
  }

  @override
  int get hashCode =>
      Object.hash(departureTime, boardingTime, departure, arrival, gate);

  @override
  String toString() {
    return 'FlightSchedule(${departure.value} -> ${arrival.value}, '
        'boarding: ${boardingTime.toString()}, departure: ${departureTime.toString()}, '
        'gate: ${gate.value})';
  }
}
