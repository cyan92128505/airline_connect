import 'package:app/core/di/dependency_injection.dart';
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

/// Base class for widget tests with DI mocking
abstract class BaseWidgetTest {
  late MockMemberApplicationService mockMemberService;
  late MockBoardingPassApplicationService mockBoardingPassService;

  @mustCallSuper
  void setUp() {
    mockMemberService = MockMemberApplicationService();
    mockBoardingPassService = MockBoardingPassApplicationService();
  }

  /// Helper to pump widget with mocked dependencies
  Future<void> pumpWidgetWithMocks(WidgetTester tester, Widget widget) async {
    await tester.pumpWidget(
      TestProviderScope.create(
        memberService: mockMemberService,
        boardingPassService: mockBoardingPassService,
        child: MaterialApp(home: widget),
      ),
    );
  }
}
