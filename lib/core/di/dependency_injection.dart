import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/shared/infrastructure/database/objectbox.dart';
import 'package:app/features/member/presentation/notifiers/member_auth_notifier.dart';
import 'package:app/features/member/infrastructure/repositories/secure_storage_repository_impl.dart';
import 'package:app/features/member/infrastructure/repositories/member_repository_impl.dart';
import 'package:app/features/member/domain/services/member_auth_service.dart';
import 'package:app/features/member/domain/repositories/secure_storage_repository.dart';
import 'package:app/features/member/domain/repositories/member_repository.dart';
import 'package:app/features/member/application/use_cases/validate_member_eligibility_use_case.dart';
import 'package:app/features/member/application/use_cases/upgrade_member_tier_use_case.dart';
import 'package:app/features/member/application/use_cases/update_member_contact_use_case.dart';
import 'package:app/features/member/application/use_cases/register_member_use_case.dart';
import 'package:app/features/member/application/use_cases/logout_member_use_case.dart';
import 'package:app/features/member/application/use_cases/get_member_profile_use_case.dart';
import 'package:app/features/member/application/use_cases/authenticate_member_use_case.dart';
import 'package:app/features/member/application/services/member_application_service.dart';
import 'package:app/features/flight/infrastructure/repositories/flight_repository_impl.dart';
import 'package:app/features/flight/domain/services/flight_status_service.dart';
import 'package:app/features/flight/domain/repositories/flight_repository.dart';
import 'package:app/features/boarding_pass/infrastructure/repositories/boarding_pass_repository_impl.dart';
import 'package:app/features/boarding_pass/domain/services/qr_code_service.dart';
import 'package:app/features/boarding_pass/domain/services/boarding_pass_service.dart';
import 'package:app/features/boarding_pass/domain/repositories/boarding_pass_repository.dart';
import 'package:app/features/boarding_pass/application/use_cases/validate_qr_code_use_case.dart';
import 'package:app/features/boarding_pass/application/use_cases/validate_boarding_eligibility_use_case.dart';
import 'package:app/features/boarding_pass/application/use_cases/use_boarding_pass_use_case.dart';
import 'package:app/features/boarding_pass/application/use_cases/update_seat_assignment_use_case.dart';
import 'package:app/features/boarding_pass/application/use_cases/get_boarding_passes_for_member_use_case.dart';
import 'package:app/features/boarding_pass/application/use_cases/get_boarding_pass_details_use_case.dart';
import 'package:app/features/boarding_pass/application/use_cases/create_boarding_pass_use_case.dart';
import 'package:app/features/boarding_pass/application/use_cases/auto_expire_boarding_passes_use_case.dart';
import 'package:app/features/boarding_pass/application/use_cases/activate_boarding_pass_use_case.dart';
import 'package:app/features/boarding_pass/application/services/boarding_pass_application_service.dart';

/// Global ObjectBox instance provider
/// Should be initialized in main() before app starts
final objectBoxProvider = Provider<ObjectBox>((ref) {
  throw UnimplementedError('ObjectBox must be initialized in main()');
});

/// Will be overridden in main.dart with pre-initialized state
final initialAuthStateProvider = Provider<MemberAuthState>((ref) {
  throw UnimplementedError(
    'Initial auth state must be provided via override in main.dart',
  );
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

final getMemberProfileUseCaseProvider = Provider<GetMemberProfileUseCase>((
  ref,
) {
  final memberRepository = ref.watch(memberRepositoryProvider);
  return GetMemberProfileUseCase(memberRepository);
});

final registerMemberUseCaseProvider = Provider<RegisterMemberUseCase>((ref) {
  final memberRepository = ref.watch(memberRepositoryProvider);
  return RegisterMemberUseCase(memberRepository);
});

final updateMemberContactUseCaseProvider = Provider<UpdateMemberContactUseCase>(
  (ref) {
    final memberRepository = ref.watch(memberRepositoryProvider);
    return UpdateMemberContactUseCase(memberRepository);
  },
);

final upgradeMemberTierUseCaseProvider = Provider<UpgradeMemberTierUseCase>((
  ref,
) {
  final memberRepository = ref.watch(memberRepositoryProvider);
  return UpgradeMemberTierUseCase(memberRepository);
});

final validateMemberEligibilityUseCaseProvider =
    Provider<ValidateMemberEligibilityUseCase>((ref) {
      final memberAuthService = ref.watch(memberAuthServiceProvider);
      return ValidateMemberEligibilityUseCase(memberAuthService);
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
    ref.watch(getMemberProfileUseCaseProvider),
    ref.watch(registerMemberUseCaseProvider),
    ref.watch(updateMemberContactUseCaseProvider),
    ref.watch(upgradeMemberTierUseCaseProvider),
    ref.watch(validateMemberEligibilityUseCaseProvider),
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
final createBoardingPassUseCaseProvider = Provider<CreateBoardingPassUseCase>((
  ref,
) {
  final boardingPassService = ref.watch(boardingPassServiceProvider);
  final memberRepository = ref.watch(memberRepositoryProvider);
  final flightRepository = ref.watch(flightRepositoryProvider);
  return CreateBoardingPassUseCase(
    boardingPassService,
    memberRepository,
    flightRepository,
  );
});

final activateBoardingPassUseCaseProvider =
    Provider<ActivateBoardingPassUseCase>((ref) {
      final boardingPassService = ref.watch(boardingPassServiceProvider);
      return ActivateBoardingPassUseCase(boardingPassService);
    });

final useBoardingPassUseCaseProvider = Provider<UseBoardingPassUseCase>((ref) {
  final boardingPassService = ref.watch(boardingPassServiceProvider);
  return UseBoardingPassUseCase(boardingPassService);
});

final updateSeatAssignmentUseCaseProvider =
    Provider<UpdateSeatAssignmentUseCase>((ref) {
      final boardingPassService = ref.watch(boardingPassServiceProvider);
      return UpdateSeatAssignmentUseCase(boardingPassService);
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

final getBoardingPassDetailsUseCaseProvider =
    Provider<GetBoardingPassDetailsUseCase>((ref) {
      final boardingPassRepository = ref.watch(boardingPassRepositoryProvider);
      return GetBoardingPassDetailsUseCase(boardingPassRepository);
    });

final validateBoardingEligibilityUseCaseProvider =
    Provider<ValidateBoardingEligibilityUseCase>((ref) {
      final boardingPassService = ref.watch(boardingPassServiceProvider);
      final boardingPassRepository = ref.watch(boardingPassRepositoryProvider);
      return ValidateBoardingEligibilityUseCase(
        boardingPassService,
        boardingPassRepository,
      );
    });

final autoExpireBoardingPassesUseCaseProvider =
    Provider<AutoExpireBoardingPassesUseCase>((ref) {
      final boardingPassService = ref.watch(boardingPassServiceProvider);
      return AutoExpireBoardingPassesUseCase(boardingPassService);
    });

/// Application Service provider
final boardingPassApplicationServiceProvider =
    Provider<BoardingPassApplicationService>((ref) {
      return BoardingPassApplicationService(
        ref.watch(createBoardingPassUseCaseProvider),
        ref.watch(activateBoardingPassUseCaseProvider),
        ref.watch(useBoardingPassUseCaseProvider),
        ref.watch(updateSeatAssignmentUseCaseProvider),
        ref.watch(validateQRCodeUseCaseProvider),
        ref.watch(getBoardingPassesForMemberUseCaseProvider),
        ref.watch(getBoardingPassDetailsUseCaseProvider),
        ref.watch(validateBoardingEligibilityUseCaseProvider),
        ref.watch(autoExpireBoardingPassesUseCaseProvider),
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
