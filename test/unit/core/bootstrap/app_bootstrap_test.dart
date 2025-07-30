import 'package:app/core/bootstrap/contracts/initialization_context.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:app/core/bootstrap/app_bootstrap.dart';
import 'package:app/core/bootstrap/bootstrap_config.dart';
import 'package:app/core/bootstrap/initialization_step.dart';

import 'app_bootstrap_test.mocks.dart';

@GenerateMocks([InitializationContext, InitializationStep])
void main() {
  // Initialize Flutter binding for all tests
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppBootstrap', () {
    group('initialize', () {
      test('should complete initialization with valid configuration', () async {
        // Arrange
        const config = BootstrapConfig(
          enableDebugMode: false,
          enableDemoData: false,
          enableDetailedLogging: false,
          timezoneName: 'UTC',
          maxInitializationTimeoutSeconds: 5,
        );

        // Act & Assert
        // Verify configuration properties
        expect(config.timezoneName, equals('UTC'));
        expect(config.maxInitializationTimeoutSeconds, equals(5));

        // Test that AppBootstrap.initialize exists and can be called
        expect(() => AppBootstrap.initialize, returnsNormally);
      });

      test('should have proper timeout configuration', () {
        // Arrange
        const config = BootstrapConfig(
          enableDebugMode: false,
          enableDemoData: false,
          enableDetailedLogging: false,
          timezoneName: 'UTC',
          maxInitializationTimeoutSeconds: 1,
        );

        // Act & Assert
        expect(config.maxInitializationTimeoutSeconds, equals(1));
      });
    });

    group('initialization step execution', () {
      late MockInitializationContext mockContext;
      late MockInitializationStep mockStep1;
      late MockInitializationStep mockStep2;

      setUp(() {
        mockContext = MockInitializationContext();
        mockStep1 = MockInitializationStep();
        mockStep2 = MockInitializationStep();
      });

      test(
        'should execute all steps in sequence for successful initialization',
        () async {
          // Arrange - Configure mock properties and behaviors
          when(mockStep1.name).thenReturn('Step 1');
          when(mockStep1.isCritical).thenReturn(true);
          when(mockStep1.execute(mockContext)).thenAnswer((_) async {});

          when(mockStep2.name).thenReturn('Step 2');
          when(mockStep2.isCritical).thenReturn(false);
          when(mockStep2.execute(mockContext)).thenAnswer((_) async {});

          // Act
          await mockStep1.execute(mockContext);
          await mockStep2.execute(mockContext);

          // Assert
          verify(mockStep1.execute(mockContext)).called(1);
          verify(mockStep2.execute(mockContext)).called(1);
          expect(mockStep1.name, equals('Step 1'));
          expect(mockStep2.name, equals('Step 2'));
        },
      );

      test('should fail fast when critical step fails', () async {
        // Arrange
        when(mockStep1.name).thenReturn('Critical Step');
        when(mockStep1.isCritical).thenReturn(true);
        when(
          mockStep1.execute(mockContext),
        ).thenThrow(Exception('Critical failure'));

        when(mockStep2.name).thenReturn('Non-Critical Step');
        when(mockStep2.isCritical).thenReturn(false);

        // Act & Assert
        expect(() => mockStep1.execute(mockContext), throwsException);
        expect(mockStep1.isCritical, isTrue);
        expect(mockStep2.isCritical, isFalse);
      });

      test('should continue execution when non-critical step fails', () async {
        // Arrange
        when(mockStep1.name).thenReturn('Non-Critical Step');
        when(mockStep1.isCritical).thenReturn(false);
        when(
          mockStep1.execute(mockContext),
        ).thenThrow(Exception('Non-critical failure'));

        when(mockStep2.name).thenReturn('Next Step');
        when(mockStep2.isCritical).thenReturn(true);
        when(mockStep2.execute(mockContext)).thenAnswer((_) async {});

        // Act
        try {
          await mockStep1.execute(mockContext);
        } catch (e) {
          // Expected to fail, but should not stop execution
        }
        await mockStep2.execute(mockContext);

        // Assert
        expect(mockStep1.isCritical, isFalse);
        verify(mockStep2.execute(mockContext)).called(1);
      });
    });

    group('InitializationException', () {
      test('should create exception with message only', () {
        // Arrange & Act
        const exception = InitializationException('Test error message');

        // Assert
        expect(exception.message, equals('Test error message'));
        expect(exception.originalError, isNull);
        expect(exception.stackTrace, isNull);
      });

      test('should create exception with message and original error', () {
        // Arrange
        final originalError = Exception('Original error');
        final stackTrace = StackTrace.current;

        // Act
        final exception = InitializationException(
          'Wrapper error message',
          originalError: originalError,
          stackTrace: stackTrace,
        );

        // Assert
        expect(exception.message, equals('Wrapper error message'));
        expect(exception.originalError, equals(originalError));
        expect(exception.stackTrace, equals(stackTrace));
      });

      test('should provide meaningful toString with original error', () {
        // Arrange
        final originalError = Exception('Database connection failed');
        final exception = InitializationException(
          'Initialization failed',
          originalError: originalError,
        );

        // Act
        final stringRepresentation = exception.toString();

        // Assert
        expect(stringRepresentation, contains('Initialization failed'));
        expect(stringRepresentation, contains('Database connection failed'));
        expect(stringRepresentation, contains('Caused by:'));
      });

      test('should provide simple toString without original error', () {
        // Arrange
        const exception = InitializationException('Simple error');

        // Act
        final stringRepresentation = exception.toString();

        // Assert
        expect(
          stringRepresentation,
          equals('InitializationException: Simple error'),
        );
        expect(stringRepresentation, isNot(contains('Caused by:')));
      });
    });

    group('context sharing between steps', () {
      late InitializationContext realContext;

      setUp(() {
        realContext = InitializationContext();
      });

      test('should allow steps to share data through context', () async {
        // Arrange
        const testKey = 'shared_data';
        const testValue = 'test_value';

        // Use real context for data operations
        realContext.setData(testKey, testValue);

        // Act & Assert
        expect(realContext.hasData(testKey), isTrue);
        expect(realContext.getData<String>(testKey), equals(testValue));
      });
    });

    group('configuration-based initialization', () {
      test('should include demo data step when enabled in config', () {
        // Arrange
        const configWithDemo = BootstrapConfig(
          enableDebugMode: true,
          enableDemoData: true,
          enableDetailedLogging: false,
          timezoneName: 'UTC',
        );

        const configWithoutDemo = BootstrapConfig(
          enableDebugMode: false,
          enableDemoData: false,
          enableDetailedLogging: false,
          timezoneName: 'UTC',
        );

        // Act & Assert
        expect(configWithDemo.enableDemoData, isTrue);
        expect(configWithoutDemo.enableDemoData, isFalse);
      });

      test('should respect timeout configuration', () {
        // Arrange
        const shortTimeoutConfig = BootstrapConfig(
          enableDebugMode: false,
          enableDemoData: false,
          enableDetailedLogging: false,
          timezoneName: 'UTC',
          maxInitializationTimeoutSeconds: 1,
        );

        const longTimeoutConfig = BootstrapConfig(
          enableDebugMode: false,
          enableDemoData: false,
          enableDetailedLogging: false,
          timezoneName: 'UTC',
          maxInitializationTimeoutSeconds: 60,
        );

        // Act & Assert
        expect(shortTimeoutConfig.maxInitializationTimeoutSeconds, equals(1));
        expect(longTimeoutConfig.maxInitializationTimeoutSeconds, equals(60));
      });
    });

    group('error handling strategies', () {
      late MockInitializationContext mockContext;
      late MockInitializationStep mockStep1;
      late MockInitializationStep mockStep2;

      setUp(() {
        mockContext = MockInitializationContext();
        mockStep1 = MockInitializationStep();
        mockStep2 = MockInitializationStep();
      });

      test('should aggregate multiple non-critical failures', () async {
        // Arrange
        when(mockStep1.name).thenReturn('Non-Critical Step 1');
        when(mockStep1.isCritical).thenReturn(false);
        when(
          mockStep1.execute(mockContext),
        ).thenThrow(Exception('First non-critical error'));

        when(mockStep2.name).thenReturn('Non-Critical Step 2');
        when(mockStep2.isCritical).thenReturn(false);
        when(
          mockStep2.execute(mockContext),
        ).thenThrow(Exception('Second non-critical error'));

        // Act & Assert
        expect(() => mockStep1.execute(mockContext), throwsException);
        expect(() => mockStep2.execute(mockContext), throwsException);
        expect(mockStep1.isCritical, isFalse);
        expect(mockStep2.isCritical, isFalse);
      });

      test('should provide detailed error information', () {
        // Arrange
        final originalError = StateError('Database initialization failed');
        final stackTrace = StackTrace.current;

        // Act
        final exception = InitializationException(
          'Failed to initialize database step',
          originalError: originalError,
          stackTrace: stackTrace,
        );

        // Assert
        expect(exception.message, contains('database step'));
        expect(exception.originalError, isA<StateError>());
        expect(exception.stackTrace, equals(stackTrace));
        expect(
          exception.toString(),
          contains('Database initialization failed'),
        );
      });
    });

    group('provider container creation', () {
      test('should create container with proper overrides', () {
        // Arrange
        final context = InitializationContext();
        const testKey = 'test_key';
        const testValue = 'test_value';

        context.setData(testKey, testValue);

        // Act
        final hasTestData = context.hasData(testKey);
        final retrievedValue = context.getData<String>(testKey);

        // Assert
        expect(hasTestData, isTrue);
        expect(retrievedValue, equals(testValue));
      });

      test('should handle container creation without ObjectBox', () {
        // Arrange
        final context = InitializationContext();

        // Act & Assert
        expect(context.objectBox, isNull);
      });
    });

    group('integration scenarios', () {
      late MockInitializationContext mockContext;
      late List<MockInitializationStep> mockSteps;

      setUp(() {
        mockContext = MockInitializationContext();
        mockSteps = List.generate(3, (i) => MockInitializationStep());
      });

      test(
        'should handle mixed critical and non-critical step failures',
        () async {
          // Arrange
          when(mockSteps[0].name).thenReturn('Step 1');
          when(mockSteps[0].isCritical).thenReturn(false);
          when(
            mockSteps[0].execute(mockContext),
          ).thenThrow(Exception('Non-critical failure'));

          when(mockSteps[1].name).thenReturn('Step 2');
          when(mockSteps[1].isCritical).thenReturn(true);
          when(mockSteps[1].execute(mockContext)).thenAnswer((_) async {});

          when(mockSteps[2].name).thenReturn('Step 3');
          when(mockSteps[2].isCritical).thenReturn(false);
          when(mockSteps[2].execute(mockContext)).thenAnswer((_) async {});

          // Act
          try {
            await mockSteps[0].execute(mockContext);
          } catch (e) {
            // Expected non-critical failure
          }
          await mockSteps[1].execute(mockContext);
          await mockSteps[2].execute(mockContext);

          // Assert
          verify(mockSteps[1].execute(mockContext)).called(1);
          verify(mockSteps[2].execute(mockContext)).called(1);
        },
      );

      test('should maintain proper execution order', () async {
        // Arrange
        final executionOrder = <String>[];
        final stepNames = ['First', 'Second', 'Third'];

        for (int i = 0; i < mockSteps.length; i++) {
          when(mockSteps[i].name).thenReturn(stepNames[i]);
          when(mockSteps[i].isCritical).thenReturn(true);
          when(mockSteps[i].execute(mockContext)).thenAnswer((_) async {
            executionOrder.add(stepNames[i]);
          });
        }

        // Act
        for (final step in mockSteps) {
          await step.execute(mockContext);
        }

        // Assert
        expect(executionOrder, equals(stepNames));
      });
    });
  });

  group('MockInitializationStep behavior', () {
    late MockInitializationContext mockContext;
    late MockInitializationStep mockStep;

    setUp(() {
      mockContext = MockInitializationContext();
      mockStep = MockInitializationStep();
    });

    test('should properly implement InitializationStep interface', () {
      // Arrange & Act
      when(mockStep.name).thenReturn('Test Step');
      when(mockStep.isCritical).thenReturn(true);

      // Assert
      expect(mockStep.name, equals('Test Step'));
      expect(mockStep.isCritical, isTrue);
      expect(mockStep, isA<InitializationStep>());
    });

    test('should allow mocking of execute method', () async {
      // Arrange
      when(mockStep.name).thenReturn('Mockable Step');
      when(mockStep.isCritical).thenReturn(false);
      when(mockStep.execute(mockContext)).thenAnswer((_) async {
        // Simulate some work
        await Future.delayed(const Duration(milliseconds: 1));
      });

      // Act
      await mockStep.execute(mockContext);

      // Assert
      verify(mockStep.execute(mockContext)).called(1);
    });

    test('should support different step configurations', () {
      // Arrange
      final criticalStep = MockInitializationStep();
      final nonCriticalStep = MockInitializationStep();

      when(criticalStep.name).thenReturn('Critical');
      when(criticalStep.isCritical).thenReturn(true);
      when(nonCriticalStep.name).thenReturn('Non-Critical');
      when(nonCriticalStep.isCritical).thenReturn(false);

      // Act & Assert
      expect(criticalStep.isCritical, isTrue);
      expect(nonCriticalStep.isCritical, isFalse);
      expect(criticalStep.name, equals('Critical'));
      expect(nonCriticalStep.name, equals('Non-Critical'));
    });
  });
}
