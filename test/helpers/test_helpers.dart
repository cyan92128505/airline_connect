import 'package:app/core/failures/failure.dart';
import 'package:app/di/dependency_injection.dart';
import 'package:app/features/member/domain/entities/member.dart';
import 'package:app/features/member/domain/repositories/secure_storage_repository.dart';
import 'package:app/features/member/domain/value_objects/member_number.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:app/features/member/application/services/member_application_service.dart';
import 'package:app/features/boarding_pass/application/services/boarding_pass_application_service.dart';

/// Mock classes for testing
class MockMemberApplicationService extends Mock
    implements MemberApplicationService {}

class MockBoardingPassApplicationService extends Mock
    implements BoardingPassApplicationService {}

/// Test helper for creating ProviderScope with overrides
class TestProviderScope {
  /// Create ProviderScope with mocked application services
  static ProviderScope create({
    required Widget child,
    MemberApplicationService? memberService,
    BoardingPassApplicationService? boardingPassService,
  }) {
    return ProviderScope(
      overrides: [
        // Override application service providers with mocks
        if (memberService != null)
          memberApplicationServiceProvider.overrideWithValue(memberService),
        if (boardingPassService != null)
          boardingPassApplicationServiceProvider.overrideWithValue(
            boardingPassService,
          ),
      ],
      child: child,
    );
  }
}

/// Mock Secure Storage Repository for testing
class MockSecureStorageRepository implements SecureStorageRepository {
  Member? _mockMember;
  Map<String, dynamic> _mockPreferences = {};

  void setMockMember(Member? member) {
    _mockMember = member;
  }

  @override
  Future<Either<Failure, void>> saveMember(Member member) async {
    _mockMember = member;
    return const Right(null);
  }

  @override
  Future<Either<Failure, Member?>> getMember() async {
    return Right(_mockMember);
  }

  @override
  Future<Either<Failure, bool>> hasValidMember() async {
    return Right(_mockMember != null);
  }

  @override
  Future<Either<Failure, void>> clearMember() async {
    _mockMember = null;
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> clearAll() async {
    _mockMember = null;
    _mockPreferences.clear();
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> saveAppPreferences(
    Map<String, dynamic> preferences,
  ) async {
    _mockPreferences = Map.from(preferences);
    return const Right(null);
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getAppPreferences() async {
    return Right(Map.from(_mockPreferences));
  }

  // Implement other required methods with mock behavior
  @override
  Future<Either<Failure, void>> cleanupExpiredSessions() async =>
      const Right(null);

  @override
  Future<Either<Failure, MemberNumber?>> getLastMemberNumber() async =>
      const Right(null);

  @override
  Future<Either<Failure, StorageStatistics>> getStatistics() async {
    return Right(
      StorageStatistics(
        hasCurrentMember: _mockMember != null,
        hasLastMemberNumber: false,
        hasAppPreferences: _mockPreferences.isNotEmpty,
        currentMemberSize: _mockMember != null ? 100 : 0,
        lastChecked: DateTime.now(),
      ),
    );
  }

  @override
  Future<Either<Failure, void>> setAutoLoginEnabled(
    memberNumber,
    bool enabled,
  ) async => const Right(null);

  @override
  Future<Either<Failure, void>> updateMemberActivity() async =>
      const Right(null);

  @override
  Future<Either<Failure, bool>> validateIntegrity() async => const Right(true);
}
