import 'package:flutter_test/flutter_test.dart';
import 'package:duna_kids/features/children/models/child_model.dart';

void main() {
  group('ChildModel Tests', () {
    test('ChildModel correctly parses is_in_classroom from map', () {
      final mapWithInClassroom = {
        'id': 'child_123',
        'full_name': 'Alice Teste',
        'birth_date': '2020-01-01',
        'is_in_classroom': true,
      };

      final child = ChildModel.fromMap(mapWithInClassroom, fallbackUserId: 'user_123');
      expect(child.isInClassroom, isTrue);

      final toMapResult = child.toMap();
      expect(toMapResult['is_in_classroom'], isTrue);
    });

    test('ChildModel defaults is_in_classroom to false if null or absent', () {
      final mapWithoutField = {
        'id': 'child_456',
        'full_name': 'Bob Teste',
        'birth_date': '2022-05-10',
      };

      final child = ChildModel.fromMap(mapWithoutField, fallbackUserId: 'user_123');
      expect(child.isInClassroom, isFalse);

      final updatedChild = child.copyWith(isInClassroom: true);
      expect(updatedChild.isInClassroom, isTrue);
    });
  });
}
