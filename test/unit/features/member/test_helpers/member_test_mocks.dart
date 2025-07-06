import 'package:mockito/annotations.dart';
import 'package:app/features/member/repositories/member_repository.dart';
import 'package:app/features/member/services/member_auth_service.dart';
import 'package:app/features/member/application/use_cases/authenticate_member_use_case.dart';
import 'package:app/features/member/application/use_cases/get_member_profile_use_case.dart';
import 'package:app/features/member/application/use_cases/register_member_use_case.dart';
import 'package:app/features/member/application/use_cases/update_member_contact_use_case.dart';
import 'package:app/features/member/application/use_cases/upgrade_member_tier_use_case.dart';
import 'package:app/features/member/application/use_cases/validate_member_eligibility_use_case.dart';

/// Centralized mock definitions for member module testing
/// Ensures consistent mocking across all test files
@GenerateMocks([
  // Domain Services
  MemberAuthService,

  // Repositories
  MemberRepository,

  // Use Cases
  AuthenticateMemberUseCase,
  GetMemberProfileUseCase,
  RegisterMemberUseCase,
  UpdateMemberContactUseCase,
  UpgradeMemberTierUseCase,
  ValidateMemberEligibilityUseCase,
])
void main() {}
