class AuthorizedGuardianModel {
  final String id;
  final String childId;
  final String? userId;
  final String name;
  final String? email;
  final String? phone;
  final String relationship;
  final String? documentCpf;
  final bool canCheckIn;
  final bool canCheckOut;
  final String? addedByUserId;
  final DateTime createdAt;

  bool get canCheckin => canCheckIn;
  bool get canCheckout => canCheckOut;
  bool get isRegisteredAppUser => userId != null && userId!.trim().isNotEmpty;
  String get relationshipFormatted => relationship.trim().isNotEmpty ? relationship : 'Responsável';

  const AuthorizedGuardianModel({
    required this.id,
    required this.childId,
    this.userId,
    required this.name,
    this.email,
    this.phone,
    required this.relationship,
    this.documentCpf,
    this.canCheckIn = true,
    this.canCheckOut = true,
    this.addedByUserId,
    required this.createdAt,
  });

  factory AuthorizedGuardianModel.fromMap(Map<String, dynamic> map) {
    return AuthorizedGuardianModel(
      id: map['id']?.toString() ?? '',
      childId: map['child_id']?.toString() ?? '',
      userId: map['user_id']?.toString(),
      name: map['name']?.toString() ?? '',
      email: map['email']?.toString(),
      phone: map['phone']?.toString(),
      relationship: map['relationship']?.toString() ?? 'Responsável',
      documentCpf: map['document_cpf']?.toString(),
      canCheckIn: map['can_checkin'] != false,
      canCheckOut: map['can_checkout'] != false,
      addedByUserId: map['added_by_user_id']?.toString(),
      createdAt: map['created_at'] != null
          ? (DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'child_id': childId,
      'user_id': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'relationship': relationship,
      'document_cpf': documentCpf,
      'can_checkin': canCheckIn,
      'can_checkout': canCheckOut,
      'added_by_user_id': addedByUserId,
    };
  }

  AuthorizedGuardianModel copyWith({
    String? id,
    String? childId,
    String? userId,
    String? name,
    String? email,
    String? phone,
    String? relationship,
    String? documentCpf,
    bool? canCheckIn,
    bool? canCheckOut,
    String? addedByUserId,
    DateTime? createdAt,
  }) {
    return AuthorizedGuardianModel(
      id: id ?? this.id,
      childId: childId ?? this.childId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      relationship: relationship ?? this.relationship,
      documentCpf: documentCpf ?? this.documentCpf,
      canCheckIn: canCheckIn ?? this.canCheckIn,
      canCheckOut: canCheckOut ?? this.canCheckOut,
      addedByUserId: addedByUserId ?? this.addedByUserId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
