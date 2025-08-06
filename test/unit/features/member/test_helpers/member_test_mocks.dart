import 'package:mockito/annotations.dart';
import 'package:app/features/member/domain/repositories/member_repository.dart';
import 'package:app/features/member/domain/services/member_auth_service.dart';
import 'package:app/features/member/application/use_cases/authenticate_member_use_case.dart';

/// Centralized mock definitions for member module testing
/// Ensures consistent mocking across all test files
@GenerateMocks([
  // Domain Services
  MemberAuthService,

  // Repositories
  MemberRepository,

  // Use Cases
  AuthenticateMemberUseCase,
])
void main() {}
