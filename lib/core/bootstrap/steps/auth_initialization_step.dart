import 'package:app/core/bootstrap/initialization_step.dart';
import 'package:app/features/member/infrastructure/repositories/secure_storage_repository_impl.dart';
import 'package:app/features/member/application/dtos/member_dto.dart';
import 'package:app/features/member/presentation/notifiers/member_auth_notifier.dart';
import 'package:logger/logger.dart';

final Logger _logger = Logger();

/// Initialize authentication state after all other components are ready
class AuthInitializationStep extends InitializationStep {
  const AuthInitializationStep()
    : super(name: 'Authentication Initialization', isCritical: false);

  @override
  Future<void> execute(InitializationContext context) async {
    try {
      // Initialize secure storage repository
      final secureStorage = SecureStorageRepositoryImpl();

      // Attempt to restore member session
      final memberResult = await secureStorage.getMember();

      final initialAuthState = memberResult.fold(
        (failure) {
          _logger.i('No existing session found: ${failure.message}');
          return _createUnauthenticatedState();
        },
        (member) {
          if (member != null) {
            _logger.i(
              'Session restored for member: ${member.memberNumber.value}',
            );
            return MemberAuthState(
              member: MemberDTOExtensions.fromDomain(member),
              isAuthenticated: true,
              isInitialized: true,
            );
          } else {
            _logger.i('No member found in secure storage');
            return _createUnauthenticatedState();
          }
        },
      );

      // Store authentication state in context for provider initialization
      context.setData('initialAuthState', initialAuthState);

      _logger.i('Authentication state prepared successfully');
    } catch (e, stackTrace) {
      _logger.e('Failed to restore authentication state: $e \n $stackTrace');

      // Provide fallback state even on failure
      final fallbackState = _createUnauthenticatedState(
        errorMessage: 'Session restoration failed: ${e.toString()}',
      );

      context.setData('initialAuthState', fallbackState);
    }
  }

  /// Create an unauthenticated state with proper initialization
  MemberAuthState _createUnauthenticatedState({String? errorMessage}) {
    return MemberAuthState(
      member: MemberDTOExtensions.unauthenticated(),
      isAuthenticated: false,
      isInitialized: true,
      errorMessage: errorMessage,
    );
  }
}
