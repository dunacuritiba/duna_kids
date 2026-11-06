class ChurchEventModel {
  final String id;
  final String name;
  final DateTime date;
  final DateTime? endDate;
  final String startTime;
  final String endTime;
  final bool isActive;
  final List<String> activeClassroomIds;
  final DateTime? createdAt;

  const ChurchEventModel({
    required this.id,
    required this.name,
    required this.date,
    this.endDate,
    required this.startTime,
    required this.endTime,
    this.isActive = true,
    this.activeClassroomIds = const [],
    this.createdAt,
  });

  bool isClassroomActive(String classroomId) {
    return isActive && activeClassroomIds.contains(classroomId);
  }

  factory ChurchEventModel.fromMap(Map<String, dynamic> map) {
    DateTime parsedDate;
    if (map['date'] != null) {
      parsedDate = DateTime.tryParse(map['date'].toString()) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    DateTime? parsedEndDate;
    if (map['end_date'] != null) {
      parsedEndDate = DateTime.tryParse(map['end_date'].toString());
    }

    DateTime? parsedCreatedAt;
    if (map['created_at'] != null) {
      parsedCreatedAt = DateTime.tryParse(map['created_at'].toString());
    }

    List<String> classroomIds = [];
    if (map['active_classroom_ids'] != null) {
      if (map['active_classroom_ids'] is List) {
        classroomIds = (map['active_classroom_ids'] as List)
            .map((e) => e.toString())
            .toList();
      }
    }

    return ChurchEventModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      date: parsedDate,
      endDate: parsedEndDate ?? parsedDate,
      startTime: map['start_time']?.toString() ?? '09:00',
      endTime: map['end_time']?.toString() ?? '11:30',
      isActive: map['is_active'] == true,
      activeClassroomIds: classroomIds,
      createdAt: parsedCreatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'date': date.toIso8601String(),
      'end_date': (endDate ?? date).toIso8601String(),
      'start_time': startTime,
      'end_time': endTime,
      'is_active': isActive,
      'active_classroom_ids': activeClassroomIds,
      'created_at': createdAt?.toIso8601String() ?? DateTime.now().toUtc().toIso8601String(),
    };
  }

  ChurchEventModel copyWith({
    String? id,
    String? name,
    DateTime? date,
    DateTime? endDate,
    String? startTime,
    String? endTime,
    bool? isActive,
    List<String>? activeClassroomIds,
    DateTime? createdAt,
  }) {
    return ChurchEventModel(
      id: id ?? this.id,
      name: name ?? this.name,
      date: date ?? this.date,
      endDate: endDate ?? this.endDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isActive: isActive ?? this.isActive,
      activeClassroomIds: activeClassroomIds ?? this.activeClassroomIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
