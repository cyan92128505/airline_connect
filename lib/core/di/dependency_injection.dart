import 'package:app/features/flight/infrastructure/repositories/flight_repository_impl.dart';
import 'package:app/features/flight/repositories/flight_repository.dart';
import 'package:app/features/flight/services/flight_status_service.dart';
import 'package:app/features/member/infrastructure/repositories/member_repository_impl.dart';
import 'package:app/features/member/repositories/member_repository.dart';
import 'package:app/features/member/services/member_auth_service.dart';
import 'package:app/features/shared/infrastructure/database/objectbox.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global ObjectBox instance provider
/// Should be initialized in main() before app starts
final objectBoxProvider = Provider<ObjectBox>((ref) {
  throw UnimplementedError('ObjectBox must be initialized in main()');
});

/// Repository providers using ObjectBox
final memberRepositoryProvider = Provider<MemberRepository>((ref) {
  final objectBox = ref.watch(objectBoxProvider);
  return MemberRepositoryImpl(objectBox);
});

final flightRepositoryProvider = Provider<FlightRepository>((ref) {
  final objectBox = ref.watch(objectBoxProvider);
  return FlightRepositoryImpl(objectBox);
});

/// Service providers
final memberAuthServiceProvider = Provider<MemberAuthService>((ref) {
  final memberRepository = ref.watch(memberRepositoryProvider);
  return MemberAuthService(memberRepository);
});

final flightStatusServiceProvider = Provider<FlightStatusService>((ref) {
  final flightRepository = ref.watch(flightRepositoryProvider);
  return FlightStatusService(flightRepository);
});
