class KidNotificationModel {
  final String id;
  final DateTime createdAt;
  final String? guardianUserId;
  final String? childId;
  final String? childName;
  final String? classroomId;
  final String? classroomName;
  final String? eventId;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final String? sentByName;

  const KidNotificationModel({
    required this.id,
    required this.createdAt,
    this.guardianUserId,
    this.childId,
    this.childName,
    this.classroomId,
    this.classroomName,
    this.eventId,
    required this.title,
    required this.message,
    this.type = 'call_parent',
    this.isRead = false,
    this.sentByName,
  });

  factory KidNotificationModel.fromMap(Map<String, dynamic> map) {
    return KidNotificationModel(
      id: map['id']?.toString() ?? '',
      createdAt: map['created_at'] != null
          ? (DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
      guardianUserId: map['guardian_user_id']?.toString(),
      childId: map['child_id']?.toString(),
      childName: map['child_name']?.toString(),
      classroomId: map['classroom_id']?.toString(),
      classroomName: map['classroom_name']?.toString(),
      eventId: map['event_id']?.toString(),
      title: map['title']?.toString() ?? 'Aviso Duna Kids',
      message: map['message']?.toString() ?? '',
      type: map['type']?.toString() ?? 'call_parent',
      isRead: map['is_read'] == true,
      sentByName: map['sent_by_name']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'guardian_user_id': guardianUserId,
      'child_id': childId,
      'child_name': childName,
      'classroom_id': classroomId,
      'classroom_name': classroomName,
      'event_id': eventId,
      'title': title,
      'message': message,
      'type': type,
      'is_read': isRead,
      'sent_by_name': sentByName,
    };
  }
}
