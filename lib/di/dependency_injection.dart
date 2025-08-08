import 'package:app/core/bootstrap/contracts/auth_initializer.dart';
import 'package:app/features/boarding_pass/application/services/boarding_pass_application_service.dart';
import 'package:app/features/boarding_pass/application/use_cases/activate_boarding_pass_use_case.dart';
import 'package:app/features/boarding_pass/application/use_cases/get_boarding_passes_for_member_use_case.dart';
import 'package:app/features/boarding_pass/application/use_cases/validate_qr_code_use_case.dart';
import 'package:app/features/boarding_pass/domain/repositories/boarding_pass_repository.dart';
import 'package:app/features/boarding_pass/domain/services/boarding_pass_service.dart';
import 'package:app/features/boarding_pass/domain/services/qr_code_service.dart';
import 'package:app/features/boarding_pass/infrastructure/repositories/boarding_pass_repository_impl.dart';
import 'package:app/features/flight/domain/repositories/flight_repository.dart';
import 'package:app/features/flight/domain/services/flight_status_service.dart';
import 'package:app/features/flight/infrastructure/repositories/flight_repository_impl.dart';
import 'package:app/features/member/application/services/member_application_service.dart';
import 'package:app/features/member/application/use_cases/authenticate_member_use_case.dart';
import 'package:app/features/member/application/use_cases/logout_member_use_case.dart';
import 'package:app/features/member/domain/repositories/member_repository.dart';
import 'package:app/features/member/domain/repositories/secure_storage_repository.dart';
import 'package:app/features/member/domain/services/member_auth_service.dart';
import 'package:app/features/member/infrastructure/repositories/member_repository_impl.dart';
import 'package:app/features/member/infrastructure/repositories/secure_storage_repository_impl.dart';
import 'package:app/features/shared/application/services/permission_application_service.dart';
import 'package:app/features/shared/domain/services/scanner_service.dart';
import 'package:app/features/shared/infrastructure/database/objectbox.dart';
import 'package:app/features/shared/infrastructure/services/mobile_scanner_service_impl.dart';
import 'package:app/features/shared/domain/services/permission_service.dart';
import 'package:app/features/shared/infrastructure/services/permission_service_impl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:http/http.dart' as http;

/// Global ObjectBox instance provider
/// Should be initialized in main() before app starts
final objectBoxProvider = Provider<ObjectBox>((ref) {
  throw UnimplementedError('ObjectBox must be initialized in main()');
});

/// Auth initializer provider - will be overridden in bootstrap
final authInitializerProvider = Provider<AuthInitializer>((ref) {
  throw UnimplementedError(
    'AuthInitializer must be provided via override in bootstrap',
  );
});

// ================================================================
// SHARED MODULE PROVIDERS
// ================================================================

/// Connectivity instance provider - can be overridden for testing
final connectivityProvider = Provider<Connectivity>((ref) {
  return Connectivity();
});

/// HttpClient instance provider - can be overridden for testing
final httpClientProvider = Provider<http.Client>((ref) {
  return http.Client();
});

/// Permission Service providers
final permissionServiceProvider = Provider<PermissionService>((ref) {
  return PermissionServiceImpl();
});

final permissionApplicationServiceProvider =
    Provider<PermissionApplicationService>((ref) {
      final permissionService = ref.watch(permissionServiceProvider);
      return PermissionApplicationService(permissionService);
    });

final scannerServiceProvider = Provider<ScannerService>((ref) {
  return MobileScannerServiceImpl();
});

// ================================================================
// MEMBER MODULE PROVIDERS
// ================================================================

/// Repository providers
final memberRepositoryProvider = Provider<MemberRepository>((ref) {
  final objectBox = ref.watch(objectBoxProvider);
  return MemberRepositoryImpl(objectBox);
});

final secureStorageRepositoryProvider = Provider<SecureStorageRepository>((
  ref,
) {
  return SecureStorageRepositoryImpl();
});

/// Service providers
final memberAuthServiceProvider = Provider<MemberAuthService>((ref) {
  final memberRepository = ref.watch(memberRepositoryProvider);
  final secureStorageRepository = ref.watch(secureStorageRepositoryProvider);
  return MemberAuthService(memberRepository, secureStorageRepository);
});

/// Use Case providers
final authenticateMemberUseCaseProvider = Provider<AuthenticateMemberUseCase>((
  ref,
) {
  final memberAuthService = ref.watch(memberAuthServiceProvider);
  return AuthenticateMemberUseCase(memberAuthService);
});

final logoutMemberUseCaseProvider = Provider<LogoutMemberUseCase>((ref) {
  final memberAuthService = ref.watch(memberAuthServiceProvider);
  return LogoutMemberUseCase(memberAuthService);
});

/// Application Service provider
final memberApplicationServiceProvider = Provider<MemberApplicationService>((
  ref,
) {
  return MemberApplicationService(
    ref.watch(authenticateMemberUseCaseProvider),
    ref.watch(logoutMemberUseCaseProvider),
  );
});

// ================================================================
// BOARDING PASS MODULE PROVIDERS
// ================================================================

/// Repository providers
final boardingPassRepositoryProvider = Provider<BoardingPassRepository>((ref) {
  final objectBox = ref.watch(objectBoxProvider);
  return BoardingPassRepositoryImpl(objectBox);
});

/// Service providers
final boardingPassServiceProvider = Provider<BoardingPassService>((ref) {
  final boardingPassRepository = ref.watch(boardingPassRepositoryProvider);
  return BoardingPassService(boardingPassRepository);
});

final qrCodeServiceProvider = Provider<QRCodeService>((ref) {
  final boardingPassRepository = ref.watch(boardingPassRepositoryProvider);
  return QRCodeService(boardingPassRepository);
});

/// Use Case providers

final activateBoardingPassUseCaseProvider =
    Provider<ActivateBoardingPassUseCase>((ref) {
      final boardingPassService = ref.watch(boardingPassServiceProvider);
      return ActivateBoardingPassUseCase(boardingPassService);
    });

final validateQRCodeUseCaseProvider = Provider<ValidateQRCodeUseCase>((ref) {
  final qrCodeService = ref.watch(qrCodeServiceProvider);
  return ValidateQRCodeUseCase(qrCodeService);
});

final getBoardingPassesForMemberUseCaseProvider =
    Provider<GetBoardingPassesForMemberUseCase>((ref) {
      final boardingPassService = ref.watch(boardingPassServiceProvider);
      return GetBoardingPassesForMemberUseCase(boardingPassService);
    });

/// Application Service provider
final boardingPassApplicationServiceProvider =
    Provider<BoardingPassApplicationService>((ref) {
      return BoardingPassApplicationService(
        ref.watch(activateBoardingPassUseCaseProvider),
        ref.watch(validateQRCodeUseCaseProvider),
        ref.watch(getBoardingPassesForMemberUseCaseProvider),
      );
    });

// ================================================================
// FLIGHT MODULE PROVIDERS
// ================================================================

/// Repository providers
final flightRepositoryProvider = Provider<FlightRepository>((ref) {
  final objectBox = ref.watch(objectBoxProvider);
  return FlightRepositoryImpl(objectBox);
});

/// Service providers
final flightStatusServiceProvider = Provider<FlightStatusService>((ref) {
  final flightRepository = ref.watch(flightRepositoryProvider);
  return FlightStatusService(flightRepository);
});
