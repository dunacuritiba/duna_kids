import 'package:flutter_test/flutter_test.dart';
import 'package:duna_kids/features/children/models/authorized_guardian_model.dart';
import 'package:duna_kids/features/children/models/child_model.dart';

void main() {
  group('AuthorizedGuardianModel Tests', () {
    test('Serializa e deserializa AuthorizedGuardianModel corretamente', () {
      final map = {
        'id': 'auth-123',
        'child_id': 'child-456',
        'user_id': 'user-789',
        'name': 'Maria da Silva',
        'email': 'maria@teste.com',
        'phone': '(41) 98888-7777',
        'relationship': 'Mãe',
        'document_cpf': '123.456.789-00',
        'can_checkin': true,
        'can_checkout': true,
        'added_by_user_id': 'owner-001',
        'created_at': '2026-11-04T12:00:00Z',
      };

      final model = AuthorizedGuardianModel.fromMap(map);

      expect(model.id, 'auth-123');
      expect(model.childId, 'child-456');
      expect(model.userId, 'user-789');
      expect(model.name, 'Maria da Silva');
      expect(model.phone, '(41) 98888-7777');
      expect(model.relationship, 'Mãe');
      expect(model.relationshipFormatted, 'Mãe');
      expect(model.canCheckin, isTrue);
      expect(model.canCheckout, isTrue);
      expect(model.isRegisteredAppUser, isTrue);

      final toMap = model.toMap();
      expect(toMap['child_id'], 'child-456');
      expect(toMap['user_id'], 'user-789');
      expect(toMap['can_checkin'], isTrue);
      expect(toMap['can_checkout'], isTrue);
    });

    test('Identifica usuário externo sem login no app', () {
      final model = AuthorizedGuardianModel(
        id: '1',
        childId: 'c1',
        name: 'Vovô João',
        relationship: 'Avô',
        phone: '41999998888',
        canCheckIn: true,
        canCheckOut: true,
        createdAt: DateTime.now(),
      );

      expect(model.isRegisteredAppUser, isFalse);
      expect(model.canCheckout, isTrue);
      expect(model.relationshipFormatted, 'Avô');
    });
  });

  group('ChildModel Authorized Users Tests', () {
    test('Mapeia authorized_user_ids de List<dynamic>', () {
      final map = {
        'id': 'c-1',
        'guardian_id': 'g-1',
        'full_name': 'Stella Alves',
        'birth_date': '2020-05-10',
        'authorized_user_ids': ['user-aaa', 'user-bbb'],
      };

      final child = ChildModel.fromMap(map, fallbackUserId: 'g-1');
      expect(child.authorizedUserIds.length, 2);
      expect(child.authorizedUserIds, contains('user-aaa'));
      expect(child.authorizedUserIds, contains('user-bbb'));

      final toMap = child.toMap();
      expect(toMap['authorized_user_ids'], ['user-aaa', 'user-bbb']);
    });
  });
}
