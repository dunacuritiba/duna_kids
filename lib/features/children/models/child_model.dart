class ChildModel {
  final String id;
  final String fullName;
  final DateTime birthDate;
  final String notes;
  final String? allergies;
  final String? specialCare;
  final String? photoUrl;
  final bool inclusionLaw13146; // Lei nº 13.146/2015 (Estatuto da Pessoa com Deficiência / Inclusão)
  final String? inclusionDetails;
  final bool isInClassroom; // Status 'em sala': true se o check-in estiver ativo e sem checkout
  final List<String> authorizedUserIds; // IDs de outros usuarios autorizados a retirar/fazer checkin
  final String userId;
  final String? guardianId;
  final DateTime? createdAt;

  const ChildModel({
    required this.id,
    required this.fullName,
    required this.birthDate,
    this.notes = '',
    this.allergies,
    this.specialCare,
    this.photoUrl,
    this.inclusionLaw13146 = false,
    this.inclusionDetails,
    this.isInClassroom = false,
    this.authorizedUserIds = const [],
    required this.userId,
    this.guardianId,
    this.createdAt,
  });

  /// Calcula a idade da criança em anos
  int get ageYears {
    final now = DateTime.now();
    int years = now.year - birthDate.year;
    if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) {
      years--;
    }
    return years < 0 ? 0 : years;
  }

  /// Calcula a idade da criança formatada (anos e meses)
  String get ageFormatted {
    final now = DateTime.now();
    int years = now.year - birthDate.year;
    int months = now.month - birthDate.month;

    if (now.day < birthDate.day) {
      months--;
    }
    if (months < 0) {
      years--;
      months += 12;
    }

    if (years <= 0) {
      return '$months ${months == 1 ? "mês" : "meses"}';
    } else if (years < 2) {
      return '$years ano e $months ${months == 1 ? "mês" : "meses"}';
    } else {
      return '$years anos';
    }
  }

  factory ChildModel.fromMap(Map<String, dynamic> map, {required String fallbackUserId}) {
    DateTime parsedBirthDate;
    if (map['birth_date'] != null) {
      parsedBirthDate = DateTime.tryParse(map['birth_date'].toString()) ?? DateTime.now();
    } else {
      parsedBirthDate = DateTime.now();
    }

    DateTime? parsedCreatedAt;
    if (map['created_at'] != null) {
      parsedCreatedAt = DateTime.tryParse(map['created_at'].toString());
    }

    List<String> parsedAuthorizedUserIds = [];
    if (map['authorized_user_ids'] != null && map['authorized_user_ids'] is List) {
      parsedAuthorizedUserIds = (map['authorized_user_ids'] as List)
          .map((e) => e.toString())
          .toList();
    }

    return ChildModel(
      id: map['id']?.toString() ?? '',
      fullName: map['full_name']?.toString() ?? '',
      birthDate: parsedBirthDate,
      notes: map['notes']?.toString() ?? '',
      allergies: map['allergies']?.toString(),
      specialCare: map['special_care']?.toString(),
      photoUrl: map['photo_url']?.toString() ?? map['photo_base64']?.toString(),
      inclusionLaw13146: map['inclusion_law_13146'] == true,
      inclusionDetails: map['inclusion_details']?.toString(),
      isInClassroom: map['is_in_classroom'] == true,
      authorizedUserIds: parsedAuthorizedUserIds,
      userId: map['user_id']?.toString() ?? fallbackUserId,
      guardianId: map['guardian_id']?.toString(),
      createdAt: parsedCreatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'birth_date': birthDate.toIso8601String(),
      'notes': notes,
      if (allergies != null) 'allergies': allergies,
      if (specialCare != null) 'special_care': specialCare,
      'photo_url': photoUrl,
      'inclusion_law_13146': inclusionLaw13146,
      'inclusion_details': inclusionDetails,
      'is_in_classroom': isInClassroom,
      'authorized_user_ids': authorizedUserIds,
      'user_id': userId,
      if (guardianId != null && guardianId != userId) 'guardian_id': guardianId,
      'created_at': createdAt?.toIso8601String() ?? DateTime.now().toUtc().toIso8601String(),
    };
  }

  ChildModel copyWith({
    String? id,
    String? fullName,
    DateTime? birthDate,
    String? notes,
    String? allergies,
    String? specialCare,
    String? photoUrl,
    bool? inclusionLaw13146,
    String? inclusionDetails,
    bool? isInClassroom,
    List<String>? authorizedUserIds,
    String? userId,
    String? guardianId,
    DateTime? createdAt,
  }) {
    return ChildModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      birthDate: birthDate ?? this.birthDate,
      notes: notes ?? this.notes,
      allergies: allergies ?? this.allergies,
      specialCare: specialCare ?? this.specialCare,
      photoUrl: photoUrl ?? this.photoUrl,
      inclusionLaw13146: inclusionLaw13146 ?? this.inclusionLaw13146,
      inclusionDetails: inclusionDetails ?? this.inclusionDetails,
      isInClassroom: isInClassroom ?? this.isInClassroom,
      authorizedUserIds: authorizedUserIds ?? this.authorizedUserIds,
      userId: userId ?? this.userId,
      guardianId: guardianId ?? this.guardianId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
