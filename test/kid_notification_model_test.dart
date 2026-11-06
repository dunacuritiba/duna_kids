import 'package:flutter_test/flutter_test.dart';
import 'package:duna_kids/features/classrooms/models/kid_notification_model.dart';

void main() {
  group('KidNotificationModel Tests', () {
    test('Converte de Map para KidNotificationModel e vice-versa corretamente', () {
      final map = {
        'id': 'notif_123',
        'created_at': '2026-11-04T12:00:00.000Z',
        'guardian_user_id': 'user_abc',
        'child_id': 'child_xyz',
        'child_name': 'Alice Teste',
        'classroom_id': 'room_1',
        'classroom_name': 'Maternal',
        'title': 'Chamada ao Kids',
        'message': 'Favor comparecer ao Kids para acompanhar a criança.',
        'type': 'call_parent',
        'is_read': false,
        'sent_by_name': 'Professora Ana',
      };

      final notif = KidNotificationModel.fromMap(map);
      expect(notif.id, 'notif_123');
      expect(notif.childName, 'Alice Teste');
      expect(notif.classroomName, 'Maternal');
      expect(notif.isRead, isFalse);
      expect(notif.title, 'Chamada ao Kids');

      final toMap = notif.toMap();
      expect(toMap['child_name'], 'Alice Teste');
      expect(toMap['message'], contains('Favor comparecer ao Kids'));
      expect(toMap['is_read'], isFalse);
    });
  });
}
