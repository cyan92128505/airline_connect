import 'package:app/core/bootstrap/contracts/auth_initializer.dart';
import 'package:app/core/bootstrap/contracts/initialization_context.dart';
import 'package:app/core/failures/failure.dart';
import 'package:app/features/member/application/dtos/member_dto.dart';
import 'package:app/features/member/infrastructure/repositories/secure_storage_repository_impl.dart';
import 'package:app/features/member/presentation/notifiers/member_auth_notifier.dart';
import 'package:dartz/dartz.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';

/// Concrete implementation of AuthInitializer for Member feature
/// Handles authentication state restoration and provider initialization
class MemberAuthInitializer implements AuthInitializer {
  static final Logger _logger = Logger();

  @override
  String get name => 'Member Authentication Initializer';

  @override
  bool get isRequired => false; // Non-critical - app can start without auth

  @override
  Future<Either<Failure, void>> initialize(
    InitializationContext context,
  ) async {
    try {
      final authStateResult = await _restoreAuthenticationState();

      final initialAuthState = authStateResult.fold(
        (failure) {
          _logger.w('Auth state restoration failed: ${failure.message}');
          return _createUnauthenticatedState(
            errorMessage: 'Session restoration failed: ${failure.message}',
          );
        },
        (state) {
          return state;
        },
      );

      context.setData('memberAuthState', initialAuthState);

      if (context.container != null) {
        await _initializeAuthNotifier(context.container!, initialAuthState);
      }

      return const Right(null);
    } catch (e, stackTrace) {
      _logger.e(
        'Member auth initialization failed',
        error: e,
        stackTrace: stackTrace,
      );

      final fallbackState = _createUnauthenticatedState(
        errorMessage: 'Authentication initialization failed',
      );
      context.setData('memberAuthState', fallbackState);

      return const Right(null);
    }
  }

  @override
  Future<Either<Failure, bool>> validate(InitializationContext context) async {
    try {
      final authState = context.getData<MemberAuthState>('memberAuthState');
      if (authState == null) {
        return Left(ValidationFailure('Auth state not found in context'));
      }

      if (!authState.isInitialized) {
        return Left(ValidationFailure('Auth state not properly initialized'));
      }

      if (context.container != null) {
        try {
          final currentState = context.container!.read(
            memberAuthNotifierProvider,
          );

          if (!currentState.isInitialized) {
            return Left(ValidationFailure('Notifier state not initialized'));
          }

          return const Right(true);
        } catch (e) {
          _logger.w('Notifier validation failed: $e');
          return Left(ValidationFailure('Notifier validation failed: $e'));
        }
      }

      return const Right(true);
    } catch (e) {
      _logger.e('Member auth validation error: $e');
      return Left(ValidationFailure('Validation error: $e'));
    }
  }

  @override
  Future<void> cleanup() async {
    try {
      // Currently no specific cleanup required
      // Future: cleanup any resources, close connections, etc.
    } catch (e) {
      _logger.w('Error during member auth cleanup: $e');
      // Don't rethrow - cleanup should not fail
    }
  }

  /// Restore authentication state from secure storage
  Future<Either<Failure, MemberAuthState>> _restoreAuthenticationState() async {
    try {
      final secureStorage = SecureStorageRepositoryImpl();
      final memberResult = await secureStorage.getMember();

      return memberResult.fold(
        (failure) {
          return Right(_createUnauthenticatedState());
        },
        (member) {
          if (member != null) {
            return Right(
              MemberAuthState(
                member: MemberDTOExtensions.fromDomain(member),
                isAuthenticated: true,
                isInitialized: true,
              ),
            );
          } else {
            return Right(_createUnauthenticatedState());
          }
        },
      );
    } catch (e) {
      return Left(StorageFailure('Failed to restore auth state: $e'));
    }
  }

  /// Initialize the auth notifier with restored state
  Future<void> _initializeAuthNotifier(
    ProviderContainer container,
    MemberAuthState initialState,
  ) async {
    try {
      final authNotifier = container.read(memberAuthNotifierProvider.notifier);
      authNotifier.initializeWithRestoredState(initialState);
    } catch (e) {
      _logger.e('Failed to initialize auth notifier: $e');
      rethrow;
    }
  }

  MemberAuthState _createUnauthenticatedState({String? errorMessage}) {
    return MemberAuthState(
      member: MemberDTOExtensions.unauthenticated(),
      isAuthenticated: false,
      isInitialized: true,
      errorMessage: errorMessage,
    );
  }
}
