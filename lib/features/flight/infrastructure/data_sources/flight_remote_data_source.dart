import 'dart:convert';

import 'package:app/core/exceptions/domain_exception.dart';
import 'package:app/features/flight/domain/entities/flight.dart';
import 'package:app/features/flight/domain/enums/flight_status.dart';
import 'package:app/features/flight/domain/value_objects/flight_number.dart';
import 'package:http/http.dart' as http;
import 'package:timezone/timezone.dart' as tz;
import 'package:logger/logger.dart';

/// Remote data source interface for flight data
abstract class FlightRemoteDataSource {
  Future<List<Flight>> getFlights();
  Future<Flight?> getFlightByNumber(FlightNumber flightNumber);
  Future<List<Flight>> getFlightsByStatus(FlightStatus status);
  Future<void> updateFlightStatus(
    FlightNumber flightNumber,
    FlightStatus status,
  );
  Future<Map<FlightNumber, FlightStatus>> getStatusUpdates();
}

/// HTTP implementation of FlightRemoteDataSource
class FlightRemoteDataSourceImpl implements FlightRemoteDataSource {
  static final Logger _logger = Logger();

  final http.Client httpClient;
  final String baseUrl;

  FlightRemoteDataSourceImpl({required this.httpClient, required this.baseUrl});

  @override
  Future<List<Flight>> getFlights() async {
    try {
      _logger.d('Fetching flights from server');

      final response = await httpClient.get(
        Uri.parse('$baseUrl/flights'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        final flights = jsonList
            .map((json) => _flightFromJson(json))
            .where((flight) => flight != null)
            .cast<Flight>()
            .toList();

        _logger.d('Retrieved ${flights.length} flights from server');
        return flights;
      } else {
        throw InfrastructureException(
          'Failed to fetch flights: ${response.statusCode}',
          code: response.statusCode.toString(),
        );
      }
    } catch (e) {
      _logger.e('Error fetching flights from server', error: e);
      throw InfrastructureException('Network error: $e');
    }
  }

  @override
  Future<Flight?> getFlightByNumber(FlightNumber flightNumber) async {
    try {
      _logger.d('Fetching flight ${flightNumber.value} from server');

      final response = await httpClient.get(
        Uri.parse('$baseUrl/flights/${flightNumber.value}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return _flightFromJson(json);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw InfrastructureException(
          'Failed to fetch flight: ${response.statusCode}',
          code: response.statusCode.toString(),
        );
      }
    } catch (e) {
      _logger.e('Error fetching flight from server', error: e);
      throw InfrastructureException('Network error: $e');
    }
  }

  @override
  Future<List<Flight>> getFlightsByStatus(FlightStatus status) async {
    try {
      _logger.d('Fetching flights with status ${status.value} from server');

      final response = await httpClient.get(
        Uri.parse('$baseUrl/flights?status=${status.value}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        final flights = jsonList
            .map((json) => _flightFromJson(json))
            .where((flight) => flight != null)
            .cast<Flight>()
            .toList();

        return flights;
      } else {
        throw InfrastructureException(
          'Failed to fetch flights by status: ${response.statusCode}',
          code: response.statusCode.toString(),
        );
      }
    } catch (e) {
      _logger.e('Error fetching flights by status', error: e);
      throw InfrastructureException('Network error: $e');
    }
  }

  @override
  Future<void> updateFlightStatus(
    FlightNumber flightNumber,
    FlightStatus status,
  ) async {
    try {
      _logger.d(
        'Updating flight ${flightNumber.value} status to ${status.value}',
      );

      final response = await httpClient.put(
        Uri.parse('$baseUrl/flights/${flightNumber.value}/status'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'status': status.value}),
      );

      if (response.statusCode != 200) {
        throw InfrastructureException(
          'Failed to update flight status: ${response.statusCode}',
          code: response.statusCode.toString(),
        );
      }

      _logger.d('Flight status updated successfully');
    } catch (e) {
      _logger.e('Error updating flight status', error: e);
      throw InfrastructureException('Network error: $e');
    }
  }

  @override
  Future<Map<FlightNumber, FlightStatus>> getStatusUpdates() async {
    try {
      _logger.d('Fetching status updates from server');

      final response = await httpClient.get(
        Uri.parse('$baseUrl/flights/status-updates'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonMap = json.decode(response.body);
        final statusUpdates = <FlightNumber, FlightStatus>{};

        jsonMap.forEach((flightNumberStr, statusStr) {
          try {
            final flightNumber = FlightNumber.create(flightNumberStr);
            final status = FlightStatus.fromString(statusStr);
            statusUpdates[flightNumber] = status;
          } catch (e) {
            _logger.w('Invalid status update: $flightNumberStr -> $statusStr');
          }
        });

        _logger.d('Retrieved ${statusUpdates.length} status updates');
        return statusUpdates;
      } else {
        throw InfrastructureException(
          'Failed to fetch status updates: ${response.statusCode}',
          code: response.statusCode.toString(),
        );
      }
    } catch (e) {
      _logger.e('Error fetching status updates', error: e);
      throw InfrastructureException('Network error: $e');
    }
  }

  /// Convert JSON to Flight domain object
  Flight? _flightFromJson(Map<String, dynamic> json) {
    try {
      // This is a simplified conversion - in real implementation,
      // you would have proper DTOs and mapping logic
      return Flight.fromPersistence(
        flightNumber: json['flightNumber'],
        schedule: _scheduleFromJson(json['schedule']),
        status: FlightStatus.fromString(json['status']),
        aircraftType: json['aircraftType'],
        createdAt: DateTime.parse(json['createdAt']).toLocal() as tz.TZDateTime,
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt']).toLocal() as tz.TZDateTime
            : null,
      );
    } catch (e) {
      _logger.w('Failed to parse flight from JSON', error: e);
      return null;
    }
  }

  /// Convert JSON to FlightSchedule
  dynamic _scheduleFromJson(Map<String, dynamic> json) {
    // Placeholder - implement actual schedule parsing
    throw UnimplementedError('Schedule parsing not implemented');
  }
}
