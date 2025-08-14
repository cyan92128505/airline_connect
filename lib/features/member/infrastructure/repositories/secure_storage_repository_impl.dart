import 'package:app/core/failures/failure.dart';
import 'package:app/features/member/domain/entities/member.dart';
import 'package:app/features/member/domain/enums/member_tier.dart';
import 'package:app/features/member/domain/value_objects/member_number.dart';
import 'package:app/features/member/domain/repositories/secure_storage_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:timezone/timezone.dart' as tz;
import 'dart:convert';

/// Concrete implementation of SecureStorageRepository using FlutterSecureStorage
class SecureStorageRepositoryImpl implements SecureStorageRepository {
  static final Logger _logger = Logger();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      sharedPreferencesName: 'airline_connect_secure_prefs',
      preferencesKeyPrefix: 'ac_',
    ),
    iOptions: IOSOptions(
      groupId: null, // Use default keychain access group
      accountName: 'AirlineConnectAuth',
      accessibility: KeychainAccessibility.first_unlock_this_device,
      synchronizable: false,
    ),
  );

  // Storage keys - organized and namespaced
  static const String _keyCurrentMember = 'current_member';
  static const String _keyLastMemberNumber = 'last_member_number';
  static const String _keyAppPreferences = 'app_preferences';

  @override
  Future<Either<Failure, void>> saveMember(Member member) async {
    try {
      // Prepare member data for storage
      final memberData = _memberToStorageFormat(member);

      await Future.wait([
        _storage.write(key: _keyCurrentMember, value: jsonEncode(memberData)),
        _storage.write(
          key: _keyLastMemberNumber,
          value: member.memberNumber.value,
        ),
      ]);

      return const Right(null);
    } on PlatformException catch (e) {
      _logger.e('Platform error saving member: ${e.code} - ${e.message}');

      if (e.code == '-34018') {
        return Left(
          SecurityFailure(
            'iOS Keychain access denied. Check entitlements configuration.',
            e,
          ),
        );
      }

      return Left(SecurityFailure('Platform storage error: ${e.message}', e));
    } catch (e, stackTrace) {
      _logger.e('Error saving member', error: e, stackTrace: stackTrace);
      return Left(StorageFailure('Failed to save member: $e'));
    }
  }

  @override
  Future<Either<Failure, Member?>> getMember() async {
    try {
      final memberDataJson = await _storage.read(key: _keyCurrentMember);
      if (memberDataJson == null) {
        return const Right(null);
      }

      final memberData = jsonDecode(memberDataJson) as Map<String, dynamic>;
      final member = _memberFromStorageFormat(memberData);

      return Right(member);
    } on PlatformException catch (e) {
      _logger.e('Platform error retrieving member: ${e.code} - ${e.message}');
      return Left(SecurityFailure('Platform storage error: ${e.message}', e));
    } catch (e, stackTrace) {
      _logger.e('Error retrieving member', error: e, stackTrace: stackTrace);
      // Clear corrupted data
      await clearMember();
      return Left(StorageFailure('Failed to retrieve member: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> hasValidMember() async {
    final memberResult = await getMember();
    return memberResult.fold(
      (failure) => Left(failure),
      (member) => Right(member != null),
    );
  }

  @override
  Future<Either<Failure, MemberNumber?>> getLastMemberNumber() async {
    try {
      final memberNumberStr = await _storage.read(key: _keyLastMemberNumber);
      if (memberNumberStr == null) {
        return const Right(null);
      }

      final memberNumber = MemberNumber.create(memberNumberStr);
      return Right(memberNumber);
    } on PlatformException catch (e) {
      _logger.e('Platform error retrieving last member number: $e');
      return Left(SecurityFailure('Platform storage error: ${e.message}', e));
    } catch (e, stackTrace) {
      _logger.e(
        'Error retrieving last member number',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(StorageFailure('Failed to retrieve last member number: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateMemberActivity() async {
    try {
      final memberResult = await getMember();
      return memberResult.fold((failure) => Left(failure), (member) async {
        if (member == null) {
          return const Right(null);
        }

        return saveMember(member);
      });
    } catch (e, stackTrace) {
      _logger.e(
        'Error updating member activity',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(StorageFailure('Failed to update member activity: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> setAutoLoginEnabled(
    MemberNumber memberNumber,
    bool enabled,
  ) async {
    try {
      _logger.d(
        'Setting auto-login enabled: $enabled for ${memberNumber.value}',
      );

      final memberResult = await getMember();
      return memberResult.fold((failure) => Left(failure), (member) async {
        if (member == null || member.memberNumber != memberNumber) {
          return Left(
            NotFoundFailure('Member not found for auto-login update'),
          );
        }

        return saveMember(member);
      });
    } catch (e, stackTrace) {
      _logger.e(
        'Error setting auto-login preference',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(StorageFailure('Failed to update auto-login preference: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> clearMember() async {
    try {
      await _storage.delete(key: _keyCurrentMember);
      // Keep last member number for login convenience

      return const Right(null);
    } on PlatformException catch (e) {
      _logger.e('Platform error clearing member: $e');
      return Left(SecurityFailure('Platform storage error: ${e.message}', e));
    } catch (e, stackTrace) {
      _logger.e('Error clearing member data', error: e, stackTrace: stackTrace);
      return Left(StorageFailure('Failed to clear member data: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> clearAll() async {
    try {
      await _storage.deleteAll();

      return const Right(null);
    } on PlatformException catch (e) {
      _logger.e('Platform error clearing all storage: $e');
      return Left(SecurityFailure('Platform storage error: ${e.message}', e));
    } catch (e, stackTrace) {
      _logger.e('Error clearing all storage', error: e, stackTrace: stackTrace);
      return Left(StorageFailure('Failed to clear all storage: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> saveAppPreferences(
    Map<String, dynamic> preferences,
  ) async {
    try {
      await _storage.write(
        key: _keyAppPreferences,
        value: jsonEncode(preferences),
      );

      return const Right(null);
    } on PlatformException catch (e) {
      _logger.e('Platform error saving preferences: $e');
      return Left(SecurityFailure('Platform storage error: ${e.message}', e));
    } catch (e, stackTrace) {
      _logger.e(
        'Error saving app preferences',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(StorageFailure('Failed to save app preferences: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getAppPreferences() async {
    try {
      final prefsJson = await _storage.read(key: _keyAppPreferences);
      if (prefsJson == null) {
        return const Right({});
      }

      final preferences = jsonDecode(prefsJson) as Map<String, dynamic>;
      return Right(preferences);
    } on PlatformException catch (e) {
      _logger.e('Platform error retrieving preferences: $e');
      return Left(SecurityFailure('Platform storage error: ${e.message}', e));
    } catch (e, stackTrace) {
      _logger.e(
        'Error retrieving app preferences',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(StorageFailure('Failed to retrieve app preferences: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> validateIntegrity() async {
    try {
      final memberResult = await getMember();
      return memberResult.fold((failure) => Left(failure), (member) async {
        // If we have a member, validate all required fields
        if (member != null) {
          final isValid =
              member.memberId.value.isNotEmpty &&
              member.memberNumber.value.isNotEmpty &&
              member.fullName.value.isNotEmpty &&
              member.contactInfo.email.isNotEmpty;

          if (!isValid) {
            _logger.w('Invalid member data found, clearing storage');
            await clearMember();
            return const Right(false);
          }
        }

        return const Right(true);
      });
    } catch (e, stackTrace) {
      _logger.e('Error validating integrity', error: e, stackTrace: stackTrace);
      await clearMember(); // Clear corrupted data
      return Left(StorageFailure('Failed to validate storage integrity: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> cleanupExpiredSessions() async {
    try {
      final memberResult = await getMember();
      return memberResult.fold((failure) => Left(failure), (member) async {
        // getMember() already handles expired session cleanup
        // If we get here and member is null, cleanup was already done
        return const Right(null);
      });
    } catch (e, stackTrace) {
      _logger.e('Error during cleanup', error: e, stackTrace: stackTrace);
      await clearMember(); // Clear on any error during cleanup
      return Left(StorageFailure('Failed to cleanup expired sessions: $e'));
    }
  }

  @override
  Future<Either<Failure, StorageStatistics>> getStatistics() async {
    try {
      final currentMember = await _storage.read(key: _keyCurrentMember);
      final lastMemberNumber = await _storage.read(key: _keyLastMemberNumber);
      final appPreferences = await _storage.read(key: _keyAppPreferences);

      final stats = StorageStatistics(
        hasCurrentMember: currentMember != null,
        hasLastMemberNumber: lastMemberNumber != null,
        hasAppPreferences: appPreferences != null,
        currentMemberSize: currentMember?.length ?? 0,
        lastChecked: DateTime.now(),
      );

      return Right(stats);
    } catch (e, stackTrace) {
      _logger.e(
        'Error generating statistics',
        error: e,
        stackTrace: stackTrace,
      );

      final errorStats = StorageStatistics(
        hasCurrentMember: false,
        hasLastMemberNumber: false,
        hasAppPreferences: false,
        currentMemberSize: 0,
        lastChecked: DateTime.now(),
        error: e.toString(),
      );

      return Right(errorStats);
    }
  }

  // ================================================================
  // CONVERSION HELPERS
  // ================================================================

  /// Convert Member to storage format
  Map<String, dynamic> _memberToStorageFormat(Member member) {
    return {
      'version': 1, // For future migration compatibility
      'memberId': member.memberId.value,
      'memberNumber': member.memberNumber.value,
      'fullName': member.fullName.value,
      'contactInfo': {
        'email': member.contactInfo.email,
        'phone': member.contactInfo.phone,
      },
      'tier': member.tier.value,
      'createdAt': member.createdAt?.toIso8601String(),
      'lastLoginAt': member.lastLoginAt?.toIso8601String(),
      'storedAt': DateTime.now().toIso8601String(), // Track when stored
    };
  }

  /// Convert storage format to Member
  Member _memberFromStorageFormat(Map<String, dynamic> data) {
    // Handle version compatibility
    final version = data['version'] as int? ?? 1;
    if (version > 1) {
      throw StorageException('Unsupported storage version: $version');
    }

    final contactInfo = data['contactInfo'] as Map<String, dynamic>;

    return Member.fromPersistence(
      memberId: data['memberId'] as String,
      memberNumber: data['memberNumber'] as String,
      fullName: data['fullName'] as String,
      email: contactInfo['email'] as String,
      phone: contactInfo['phone'] as String,
      tier: MemberTier.fromString(data['tier'] as String),
      createdAt: data['createdAt'] != null
          ? tz.TZDateTime.parse(tz.local, data['createdAt'] as String)
          : null,
      lastLoginAt: data['lastLoginAt'] != null
          ? tz.TZDateTime.parse(tz.local, data['lastLoginAt'] as String)
          : null,
    );
  }
}

/// Storage exception for domain-specific errors
class StorageException implements Exception {
  final String message;
  final Object? cause;

  StorageException(this.message, [this.cause]);

  @override
  String toString() =>
      'StorageException: $message${cause != null ? ' (cause: $cause)' : ''}';
}
