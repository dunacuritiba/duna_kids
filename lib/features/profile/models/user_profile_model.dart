class UserProfileModel {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final DateTime? birthDate;
  final String? gender; // 'masculino', 'feminino' ou outro
  final String? avatarUrl;
  final bool isTeacher;
  final bool isAdmin;
  final DateTime? updatedAt;

  const UserProfileModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone = '',
    this.birthDate,
    this.gender,
    this.avatarUrl,
    this.isTeacher = false,
    this.isAdmin = false,
    this.updatedAt,
  });

  /// Determina a lista de níveis de acesso / papéis do usuário
  List<String> getRoles({required int childrenCount}) {
    final List<String> roles = [];

    // Papel de Responsável quando há crianças cadastradas (independente se é pai, mãe, avô, avó, tutor, etc.)
    if (childrenCount > 0) {
      roles.add('Responsável');
    } else {
      roles.add('Usuário');
    }

    // Papel de Professor
    if (isTeacher) {
      roles.add('Professor(a)');
    }

    // Papel de Administrador
    if (isAdmin) {
      roles.add('Administrador(a)');
    }

    return roles;
  }

  factory UserProfileModel.fromMap(Map<String, dynamic> map, {String fallbackEmail = ''}) {
    DateTime? parsedBirthDate;
    if (map['birth_date'] != null) {
      if (map['birth_date'] is String) {
        parsedBirthDate = DateTime.tryParse(map['birth_date']);
      }
    }

    DateTime? parsedUpdatedAt;
    if (map['updated_at'] != null) {
      if (map['updated_at'] is String) {
        parsedUpdatedAt = DateTime.tryParse(map['updated_at']);
      }
    }

    return UserProfileModel(
      id: map['id']?.toString() ?? '',
      fullName: map['full_name']?.toString() ?? '',
      email: map['email']?.toString() ?? fallbackEmail,
      phone: map['phone']?.toString() ?? '',
      birthDate: parsedBirthDate,
      gender: map['gender']?.toString(),
      avatarUrl: map['avatar_url']?.toString(),
      isTeacher: map['is_teacher'] == true,
      isAdmin: map['is_admin'] == true,
      updatedAt: parsedUpdatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'birth_date': birthDate?.toIso8601String().split('T').first,
      'gender': gender,
      'avatar_url': avatarUrl,
      'is_teacher': isTeacher,
      'is_admin': isAdmin,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  UserProfileModel copyWith({
    String? fullName,
    String? email,
    String? phone,
    DateTime? birthDate,
    String? gender,
    String? avatarUrl,
    bool? isTeacher,
    bool? isAdmin,
    DateTime? updatedAt,
  }) {
    return UserProfileModel(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isTeacher: isTeacher ?? this.isTeacher,
      isAdmin: isAdmin ?? this.isAdmin,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
