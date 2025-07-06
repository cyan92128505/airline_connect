import 'package:app/features/member/application/services/member_application_service.dart';
import 'package:app/features/member/application/use_cases/authenticate_member_use_case.dart';
import 'package:app/features/member/application/use_cases/get_member_profile_use_case.dart';
import 'package:app/features/member/application/use_cases/register_member_use_case.dart';
import 'package:app/features/member/application/use_cases/update_member_contact_use_case.dart';
import 'package:app/features/member/application/use_cases/upgrade_member_tier_use_case.dart';
import 'package:app/features/member/application/use_cases/validate_member_eligibility_use_case.dart';
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

/// Repository providers
final memberRepositoryProvider = Provider<MemberRepository>((ref) {
  final objectBox = ref.watch(objectBoxProvider);
  return MemberRepositoryImpl(objectBox);
});

/// Service providers
final memberAuthServiceProvider = Provider<MemberAuthService>((ref) {
  final memberRepository = ref.watch(memberRepositoryProvider);
  return MemberAuthService(memberRepository);
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
  );
});
