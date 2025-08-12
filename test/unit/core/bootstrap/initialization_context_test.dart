import 'package:app/core/bootstrap/contracts/initialization_context.dart';
import 'package:app/features/boarding_pass/infrastructure/services/qr_code_service_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:app/features/shared/infrastructure/database/objectbox.dart';

import 'initialization_context_test.mocks.dart';

@GenerateMocks([ObjectBox, QRCodeServiceImpl])
void main() {
  group('InitializationContext', () {
    late InitializationContext context;

    setUp(() {
      context = InitializationContext();
    });

    group('ObjectBox management', () {
      test('should start with null ObjectBox instance', () {
        // Assert
        expect(context.objectBox, isNull);
      });

      test('should allow setting ObjectBox instance', () {
        // Arrange
        final mockObjectBox = MockObjectBox();

        // Act
        context.objectBox = mockObjectBox;

        // Assert
        expect(context.objectBox, equals(mockObjectBox));
      });

      test('should allow updating ObjectBox instance', () {
        // Arrange
        final mockObjectBox1 = MockObjectBox();
        final mockObjectBox2 = MockObjectBox();

        // Act
        context.objectBox = mockObjectBox1;
        context.objectBox = mockObjectBox2;

        // Assert
        expect(context.objectBox, equals(mockObjectBox2));
        expect(context.objectBox, isNot(equals(mockObjectBox1)));
      });
    });

    group('data storage and retrieval', () {
      test('should store and retrieve string data', () {
        // Arrange
        const key = 'test_string';
        const value = 'Hello World';

        // Act
        context.setData(key, value);
        final retrievedValue = context.getData<String>(key);

        // Assert
        expect(retrievedValue, equals(value));
      });

      test('should store and retrieve complex objects', () {
        // Arrange
        const key = 'test_map';
        final value = {'name': 'John', 'age': 30, 'active': true};

        // Act
        context.setData(key, value);
        final retrievedValue = context.getData<Map<String, dynamic>>(key);

        // Assert
        expect(retrievedValue, equals(value));
        expect(retrievedValue!['name'], equals('John'));
        expect(retrievedValue['age'], equals(30));
        expect(retrievedValue['active'], isTrue);
      });

      test('should return null for non-existent keys', () {
        // Act
        final result = context.getData<String>('non_existent_key');

        // Assert
        expect(result, isNull);
      });

      test('should allow overwriting existing data', () {
        // Arrange
        const key = 'overwrite_test';
        const originalValue = 'original';
        const newValue = 'updated';

        // Act
        context.setData(key, originalValue);
        context.setData(key, newValue);
        final result = context.getData<String>(key);

        // Assert
        expect(result, equals(newValue));
      });
    });

    group('data existence checks', () {
      test('should return true for existing keys', () {
        // Arrange
        context.setData('existing_key', 'some_value');

        // Act & Assert
        expect(context.hasData('existing_key'), isTrue);
      });

      test('should return false for non-existing keys', () {
        // Act & Assert
        expect(context.hasData('non_existing_key'), isFalse);
      });

      test('should return true even for null values', () {
        // Arrange
        context.setData('null_key', null);

        // Act & Assert
        expect(context.hasData('null_key'), isTrue);
      });
    });

    group('type safety', () {
      test('should handle different data types correctly', () {
        // Arrange & Act
        context.setData('string', 'text');
        context.setData('int', 42);
        context.setData('bool', true);
        context.setData('double', 3.14);
        context.setData('list', [1, 2, 3]);

        // Assert
        expect(context.getData<String>('string'), equals('text'));
        expect(context.getData<int>('int'), equals(42));
        expect(context.getData<bool>('bool'), isTrue);
        expect(context.getData<double>('double'), equals(3.14));
        expect(context.getData<List<int>>('list'), equals([1, 2, 3]));
      });

      test('should handle generic types', () {
        // Arrange
        final testMap = <String, int>{'a': 1, 'b': 2};
        final testList = <String>['hello', 'world'];

        // Act
        context.setData('map', testMap);
        context.setData('list', testList);

        // Assert
        expect(context.getData<Map<String, int>>('map'), equals(testMap));
        expect(context.getData<List<String>>('list'), equals(testList));
      });
    });

    group('edge cases', () {
      test('should handle empty string keys', () {
        // Arrange
        const value = 'empty key test';

        // Act
        context.setData('', value);

        // Assert
        expect(context.getData<String>(''), equals(value));
        expect(context.hasData(''), isTrue);
      });

      test('should handle special character keys', () {
        // Arrange
        const specialKey = 'key@#\$%^&*()_+-=[]{}|;:,.<>?';

        const value = 'special characters';

        // Act
        context.setData(specialKey, value);

        // Assert
        expect(context.getData<String>(specialKey), equals(value));
        expect(context.hasData(specialKey), isTrue);
      });

      test('should handle unicode keys', () {
        // Arrange
        const unicodeKey = '測試鍵值';
        const value = 'unicode test';

        // Act
        context.setData(unicodeKey, value);

        // Assert
        expect(context.getData<String>(unicodeKey), equals(value));
        expect(context.hasData(unicodeKey), isTrue);
      });
    });
  });
}
