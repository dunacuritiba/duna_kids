import '../../children/models/child_model.dart';

class AttendanceModel {
  final String id;
  final String eventId;
  final String childId;
  final String classroomId;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final String securityCode;
  final String checkedInByGuardianName;
  final bool hasBag;
  final bool hasBottle;
  final bool hasPacifier;
  final String belongingsNotes;
  final ChildModel? child;

  const AttendanceModel({
    required this.id,
    required this.eventId,
    required this.childId,
    required this.classroomId,
    required this.checkInTime,
    this.checkOutTime,
    this.securityCode = '',
    this.checkedInByGuardianName = '',
    this.hasBag = false,
    this.hasBottle = false,
    this.hasPacifier = false,
    this.belongingsNotes = '',
    this.child,
  });

  bool get isPresent => checkOutTime == null;

  factory AttendanceModel.fromMap(Map<String, dynamic> map, {ChildModel? child}) {
    return AttendanceModel(
      id: map['id']?.toString() ?? '',
      eventId: map['event_id']?.toString() ?? '',
      childId: map['child_id']?.toString() ?? '',
      classroomId: map['classroom_id']?.toString() ?? '',
      checkInTime: map['check_in_time'] != null
          ? (DateTime.tryParse(map['check_in_time'].toString()) ?? DateTime.now())
          : DateTime.now(),
      checkOutTime: map['check_out_time'] != null
          ? DateTime.tryParse(map['check_out_time'].toString())
          : null,
      securityCode: map['security_code']?.toString() ?? '',
      checkedInByGuardianName: map['checked_in_by_guardian_name']?.toString() ?? '',
      hasBag: map['has_bag'] == true,
      hasBottle: map['has_bottle'] == true,
      hasPacifier: map['has_pacifier'] == true,
      belongingsNotes: map['belongings_notes']?.toString() ?? '',
      child: child,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'event_id': eventId,
      'child_id': childId,
      'classroom_id': classroomId,
      'check_in_time': checkInTime.toIso8601String(),
      'check_out_time': checkOutTime?.toIso8601String(),
      'security_code': securityCode,
      'checked_in_by_guardian_name': checkedInByGuardianName,
      'has_bag': hasBag,
      'has_bottle': hasBottle,
      'has_pacifier': hasPacifier,
      'belongings_notes': belongingsNotes,
    };
  }
}
