import 'package:app/core/failures/failure.dart';
import 'package:app/features/member/domain/entities/member.dart';
import 'package:app/features/member/domain/value_objects/member_number.dart';
import 'package:dartz/dartz.dart';

/// Secure storage repository interface for sensitive data persistence
/// Provides encrypted storage for authentication state and preferences
abstract class SecureStorageRepository {
  /// Save authenticated member with session to secure storage
  Future<Either<Failure, void>> saveMember(Member member);

  /// Restore authenticated member from secure storage
  Future<Either<Failure, Member?>> getMember();

  /// Check if valid authenticated member exists in storage
  Future<Either<Failure, bool>> hasValidMember();

  /// Get last member number for login convenience
  Future<Either<Failure, MemberNumber?>> getLastMemberNumber();

  /// Update member session activity timestamp
  Future<Either<Failure, void>> updateMemberActivity();

  /// Set auto-login preference for member
  Future<Either<Failure, void>> setAutoLoginEnabled(
    MemberNumber memberNumber,
    bool enabled,
  );

  /// Clear member data from storage (logout)
  Future<Either<Failure, void>> clearMember();

  /// Clear all storage data including preferences
  Future<Either<Failure, void>> clearAll();

  /// Save application preferences (theme, language, etc.)
  Future<Either<Failure, void>> saveAppPreferences(
    Map<String, dynamic> preferences,
  );

  /// Get application preferences
  Future<Either<Failure, Map<String, dynamic>>> getAppPreferences();

  /// Validate storage integrity and cleanup if needed
  Future<Either<Failure, bool>> validateIntegrity();

  /// Cleanup expired sessions for maintenance
  Future<Either<Failure, void>> cleanupExpiredSessions();

  /// Get storage statistics for monitoring
  Future<Either<Failure, StorageStatistics>> getStatistics();
}

/// Storage statistics for health monitoring
class StorageStatistics {
  final bool hasCurrentMember;
  final bool hasLastMemberNumber;
  final bool hasAppPreferences;
  final int currentMemberSize;
  final DateTime lastChecked;
  final String? error;

  const StorageStatistics({
    required this.hasCurrentMember,
    required this.hasLastMemberNumber,
    required this.hasAppPreferences,
    required this.currentMemberSize,
    required this.lastChecked,
    this.error,
  });

  bool get isHealthy =>
      error == null && (hasCurrentMember ? currentMemberSize > 0 : true);

  Map<String, dynamic> toJson() {
    return {
      'hasCurrentMember': hasCurrentMember,
      'hasLastMemberNumber': hasLastMemberNumber,
      'hasAppPreferences': hasAppPreferences,
      'currentMemberSize': currentMemberSize,
      'lastChecked': lastChecked.toIso8601String(),
      'error': error,
      'isHealthy': isHealthy,
    };
  }

  @override
  String toString() {
    return 'StorageStatistics(healthy: $isHealthy, '
        'hasMember: $hasCurrentMember, size: ${currentMemberSize}B)';
  }
}
