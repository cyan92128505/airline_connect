import 'package:freezed_annotation/freezed_annotation.dart';

part 'flight_search_dto.freezed.dart';
part 'flight_search_dto.g.dart';

/// Simplified DTO for flight search - focused on boarding pass needs
@freezed
abstract class FlightSearchDTO with _$FlightSearchDTO {
  const factory FlightSearchDTO({
    String? departureAirport, // Airport code for departure search
    String? departureDate, // Date in YYYY-MM-DD format
    int? maxResults, // Limit results for performance
  }) = _FlightSearchDTO;

  factory FlightSearchDTO.fromJson(Map<String, Object?> json) =>
      _$FlightSearchDTOFromJson(json);
}
