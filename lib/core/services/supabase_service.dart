import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/children/models/authorized_guardian_model.dart';
import '../../features/children/models/child_model.dart';
import '../../features/classrooms/models/attendance_model.dart';
import '../../features/classrooms/models/classroom_model.dart';
import '../../features/classrooms/models/kid_notification_model.dart';
import '../../features/events/models/church_event_model.dart';
import '../../features/profile/models/user_profile_model.dart';
import '../config/supabase_config.dart';

class SupabaseService {
  SupabaseService._();

  static final SupabaseService instance = SupabaseService._();

  SupabaseClient get client => Supabase.instance.client;

  bool get isInitialized {
    try {
      Supabase.instance;
      return true;
    } catch (_) {
      return false;
    }
  }

  User? get currentUser {
    try {
      if (!isInitialized) return null;
      return Supabase.instance.client.auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  bool get isAuthenticated => currentUser != null;

  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        publishableKey: SupabaseConfig.publishableKey,
      );
      debugPrint('Supabase inicializado com sucesso.');
    } catch (e) {
      debugPrint('Aviso ao inicializar Supabase: $e');
    }
  }

  /// Autentica o usuário com e-mail e senha
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      return response;
    } on AuthException catch (e) {
      throw _translateAuthException(e);
    } catch (e) {
      throw 'Não foi possível conectar ao servidor. Verifique sua conexão.';
    }
  }

  /// Cadastra um novo usuário
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'full_name': fullName.trim(),
        },
      );

      final user = response.user;
      if (user != null) {
        try {
          await client.from('profiles').upsert({
            'id': user.id,
            'email': email.trim(),
            'full_name': fullName.trim(),
            'is_teacher': false,
            'is_admin': false,
            'gender': 'responsavel',
          });
        } catch (_) {}
      }

      return response;
    } on AuthException catch (e) {
      throw _translateAuthException(e);
    } catch (e) {
      throw 'Erro ao cadastrar usuário. Tente novamente.';
    }
  }

  /// Carrega o perfil do usuário atual
  Future<UserProfileModel> getProfile() async {
    final user = currentUser;
    if (user == null) {
      throw 'Usuário não autenticado.';
    }

    try {
      final data = await client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data != null) {
        return UserProfileModel.fromMap(data, fallbackEmail: user.email ?? '');
      }
    } catch (e) {
      debugPrint('Erro ao buscar dados da tabela profiles: $e');
    }

    // Fallback utilizando os metadados do Auth
    final metadata = user.userMetadata ?? {};
    DateTime? birthDate;
    if (metadata['birth_date'] != null) {
      birthDate = DateTime.tryParse(metadata['birth_date'].toString());
    }

    return UserProfileModel(
      id: user.id,
      fullName: metadata['full_name']?.toString() ?? '',
      email: user.email ?? '',
      phone: metadata['phone']?.toString() ?? '',
      birthDate: birthDate,
      gender: metadata['gender']?.toString(),
      avatarUrl: metadata['avatar_url']?.toString(),
      isTeacher: metadata['is_teacher'] == true,
      isAdmin: metadata['is_admin'] == true,
    );
  }

  /// Atualiza o perfil do usuário
  Future<UserProfileModel> updateProfile({
    required String fullName,
    required String phone,
    DateTime? birthDate,
    String? gender,
    String? avatarUrl,
    bool isTeacher = false,
    bool isAdmin = false,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw 'Usuário não autenticado.';
    }

    final updatedData = {
      'id': user.id,
      'email': user.email,
      'full_name': fullName.trim(),
      'phone': phone.trim(),
      'birth_date': birthDate?.toIso8601String().split('T').first,
      'gender': gender,
      'avatar_url': avatarUrl,
      'is_teacher': isTeacher,
      'is_admin': isAdmin,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    // 1. Persiste na tabela profiles
    try {
      await client.from('profiles').upsert(updatedData);
    } catch (e) {
      debugPrint('Aviso ao persistir na tabela profiles: $e');
    }

    // 2. Atualiza os metadados no auth.users
    try {
      await client.auth.updateUser(
        UserAttributes(
          data: {
            'full_name': fullName.trim(),
            'phone': phone.trim(),
            'birth_date': birthDate?.toIso8601String().split('T').first,
            'gender': gender,
            'avatar_url': avatarUrl,
            'is_teacher': isTeacher,
            'is_admin': isAdmin,
          },
        ),
      );
    } catch (e) {
      debugPrint('Aviso ao atualizar metadados de Auth: $e');
    }

    return UserProfileModel(
      id: user.id,
      fullName: fullName.trim(),
      email: user.email ?? '',
      phone: phone.trim(),
      birthDate: birthDate,
      gender: gender,
      avatarUrl: avatarUrl,
      isTeacher: isTeacher,
      isAdmin: isAdmin,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  /// Faz upload de foto de perfil para o Supabase Storage
  Future<String> uploadAvatar({
    required Uint8List bytes,
    required String fileExtension,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw 'Usuário não autenticado.';
    }

    final sanitizedExt = fileExtension.replaceAll('.', '').toLowerCase();
    final filePath = '${user.id}/avatar_${DateTime.now().millisecondsSinceEpoch}.$sanitizedExt';

    await client.storage.from('avatars').uploadBinary(
      filePath,
      bytes,
      fileOptions: FileOptions(
        contentType: 'image/$sanitizedExt',
        upsert: true,
      ),
    );

    return client.storage.from('avatars').getPublicUrl(filePath);
  }

  // ==========================================
  // GESTÃO DE CRIANÇAS / DEPENDENTES
  // ==========================================

  /// Busca as crianças cadastradas pelo usuário ou que ele está autorizado a gerenciar/fazer check-in
  Future<List<ChildModel>> getChildren() async {
    final user = currentUser;
    if (user == null) return [];

    try {
      // 1. Busca IDs de crianças onde o usuário é autorizado
      List<String> authorizedChildIds = [];
      try {
        final authRes = await client
            .from('child_authorized_guardians')
            .select('child_id')
            .eq('user_id', user.id);
        authorizedChildIds = (authRes as List<dynamic>)
            .map((e) => e['child_id']?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toList();
      } catch (_) {}

      // 2. Monta filtro: dono da crianca (user_id/guardian_id) OU autorizado
      String filter = 'user_id.eq.${user.id},guardian_id.eq.${user.id},authorized_user_ids.cs.{${user.id}}';
      if (authorizedChildIds.isNotEmpty) {
        final formattedIds = authorizedChildIds.map((id) => '"$id"').join(',');
        filter = '$filter,id.in.($formattedIds)';
      }

      final response = await client
          .from('children')
          .select()
          .or(filter)
          .order('birth_date', ascending: false);

      final list = response as List<dynamic>;
      return list.map((item) => ChildModel.fromMap(item as Map<String, dynamic>, fallbackUserId: user.id)).toList();
    } catch (e) {
      debugPrint('Erro ao buscar crianças: $e');
      return [];
    }
  }

  /// Salva ou atualiza uma criança
  Future<ChildModel> saveChild(ChildModel child) async {
    final user = currentUser;
    if (user == null) {
      throw 'Usuário não autenticado.';
    }

    String? validGuardianId = child.guardianId;
    if (validGuardianId != null && validGuardianId != user.id && validGuardianId.startsWith('g')) {
      // ID existente de guardian
    } else {
      try {
        final existingGuardian = await client
            .from('guardians')
            .select('id')
            .eq('auth_user_id', user.id)
            .maybeSingle();
        if (existingGuardian != null) {
          validGuardianId = existingGuardian['id']?.toString();
        } else {
          validGuardianId = null;
        }
      } catch (_) {
        validGuardianId = null;
      }
    }

    final data = <String, dynamic>{
      'id': child.id,
      'full_name': child.fullName,
      'birth_date': child.birthDate.toIso8601String(),
      'notes': child.notes,
      'photo_url': child.photoUrl,
      'inclusion_law_13146': child.inclusionLaw13146,
      'inclusion_details': child.inclusionDetails,
      'user_id': user.id,
      'guardian_id': validGuardianId,
      'created_at': child.createdAt?.toIso8601String() ?? DateTime.now().toUtc().toIso8601String(),
    };

    try {
      await client.from('children').upsert(data);
      return child.copyWith(guardianId: validGuardianId, userId: user.id);
    } catch (e) {
      debugPrint('Erro ao salvar criança: $e');
      throw 'Não foi possível salvar os dados da criança: $e';
    }
  }

  /// Remove uma criança cadastrada
  Future<void> deleteChild(String childId) async {
    final user = currentUser;
    if (user == null) return;

    try {
      await client.from('children').delete().eq('id', childId);
    } catch (e) {
      debugPrint('Erro ao excluir criança: $e');
      throw 'Erro ao excluir criança: $e';
    }
  }

  /// Upload da foto da criança
  Future<String> uploadChildPhoto({
    required Uint8List bytes,
    required String fileExtension,
    required String childId,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw 'Usuário não autenticado.';
    }

    final sanitizedExt = fileExtension.replaceAll('.', '').toLowerCase();
    final filePath = '${user.id}/child_${childId}_${DateTime.now().millisecondsSinceEpoch}.$sanitizedExt';

    await client.storage.from('avatars').uploadBinary(
      filePath,
      bytes,
      fileOptions: FileOptions(
        contentType: 'image/$sanitizedExt',
        upsert: true,
      ),
    );

    return client.storage.from('avatars').getPublicUrl(filePath);
  }

  // ==========================================
  // RESPONSÁVEIS AUTORIZADOS (RETIRADA E CHECK-IN)
  // ==========================================

  /// Busca os perfis de outros usuários para poder selecioná-los como responsáveis autorizados (exceto o usuário atual)
  Future<List<UserProfileModel>> getAvailableProfilesForAuthorization() async {
    try {
      final user = currentUser;
      final currentUserId = user?.id;
      final currentUserEmail = user?.email?.toLowerCase().trim();

      final res = await client
          .from('profiles')
          .select()
          .order('full_name', ascending: true);

      final list = (res as List<dynamic>)
          .map((m) => UserProfileModel.fromMap(m as Map<String, dynamic>))
          .where((p) {
            final matchesId = currentUserId != null && p.id == currentUserId;
            final matchesEmail = currentUserEmail != null &&
                currentUserEmail.isNotEmpty &&
                p.email.toLowerCase().trim() == currentUserEmail;
            final isSelf = matchesId || matchesEmail;
            return !isSelf && p.fullName.trim().isNotEmpty;
          })
          .toList();
      return list;
    } catch (e) {
      debugPrint('Erro ao buscar perfis para autorização: $e');
      return [];
    }
  }

  /// Adiciona múltiplos usuários selecionados do sistema como responsáveis autorizados
  Future<void> addMultipleAuthorizedGuardians({
    required List<UserProfileModel> profiles,
    required String relationship,
    bool canCheckIn = true,
    bool canCheckOut = true,
    bool applyToAllChildren = true,
    required String childId,
  }) async {
    for (final profile in profiles) {
      await addAuthorizedGuardian(
        childId: childId,
        name: profile.fullName,
        email: profile.email.isNotEmpty ? profile.email : null,
        phone: profile.phone.isNotEmpty ? profile.phone : null,
        relationship: relationship,
        userId: profile.id,
        canCheckIn: canCheckIn,
        canCheckOut: canCheckOut,
        applyToAllChildren: applyToAllChildren,
      );
    }
  }

  /// Busca todas as pessoas / responsáveis autorizados a retirar ou fazer check-in da criança
  Future<List<AuthorizedGuardianModel>> getAuthorizedGuardiansForChild(String childId) async {
    try {
      final res = await client
          .from('child_authorized_guardians')
          .select()
          .eq('child_id', childId)
          .order('created_at', ascending: true);

      final list = res as List<dynamic>;
      return list.map((m) => AuthorizedGuardianModel.fromMap(m as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Erro ao buscar responsáveis autorizados: $e');
      return [];
    }
  }

  /// Adiciona uma nova pessoa / usuário autorizado para a criança (ou para todos os filhos)
  Future<AuthorizedGuardianModel> addAuthorizedGuardian({
    required String childId,
    required String name,
    String? email,
    String? phone,
    required String relationship,
    String? documentCpf,
    String? userId,
    bool canCheckIn = true,
    bool canCheckOut = true,
    bool applyToAllChildren = true,
  }) async {
    final user = currentUser;
    if (user == null) throw 'Usuário não autenticado.';

    try {
      List<String> targetChildIds = [childId];

      if (applyToAllChildren) {
        try {
          final childrenRes = await client
              .from('children')
              .select('id')
              .or('user_id.eq.${user.id},guardian_id.eq.${user.id}');
          final list = childrenRes as List<dynamic>;
          final ids = list.map((c) => c['id']?.toString() ?? '').where((id) => id.isNotEmpty).toList();
          if (ids.isNotEmpty) {
            targetChildIds = ids;
          }
        } catch (e) {
          debugPrint('Erro ao buscar todos os filhos para aplicar autorização: $e');
        }
      }

      AuthorizedGuardianModel? firstSavedModel;

      for (final cid in targetChildIds) {
        // Verifica se já existe autorização para essa criança e esse usuário/pessoa
        String? existingRecordId;
        try {
          var query = client.from('child_authorized_guardians').select('id').eq('child_id', cid);
          if (userId != null && userId.isNotEmpty) {
            query = query.eq('user_id', userId);
          } else {
            query = query.eq('name', name.trim());
          }
          final existing = await query.maybeSingle();
          if (existing != null) {
            existingRecordId = existing['id']?.toString();
          }
        } catch (_) {}

        final data = {
          'child_id': cid,
          'user_id': userId,
          'name': name.trim(),
          'email': email?.trim(),
          'phone': phone?.trim(),
          'relationship': relationship,
          'document_cpf': documentCpf?.trim(),
          'can_checkin': canCheckIn,
          'can_checkout': canCheckOut,
          'added_by_user_id': user.id,
        };

        Map<String, dynamic> savedRow;
        if (existingRecordId != null) {
          savedRow = await client
              .from('child_authorized_guardians')
              .update(data)
              .eq('id', existingRecordId)
              .select()
              .single();
        } else {
          savedRow = await client
              .from('child_authorized_guardians')
              .insert(data)
              .select()
              .single();
        }

        firstSavedModel ??= AuthorizedGuardianModel.fromMap(savedRow);

        // Se tiver userId cadastrado, adiciona ao array authorized_user_ids na tabela children
        if (userId != null && userId.isNotEmpty) {
          try {
            final childRow = await client
                .from('children')
                .select('authorized_user_ids')
                .eq('id', cid)
                .maybeSingle();

            List<dynamic> currentIds = (childRow?['authorized_user_ids'] as List<dynamic>?) ?? [];
            if (!currentIds.contains(userId)) {
              currentIds.add(userId);
              await client
                  .from('children')
                  .update({'authorized_user_ids': currentIds})
                  .eq('id', cid);
            }
          } catch (arrErr) {
            debugPrint('Aviso ao sincronizar array authorized_user_ids para $cid: $arrErr');
          }
        }
      }

      return firstSavedModel ??
          AuthorizedGuardianModel(
            id: 'saved',
            childId: childId,
            userId: userId,
            name: name,
            email: email,
            phone: phone,
            relationship: relationship,
            documentCpf: documentCpf,
            canCheckIn: canCheckIn,
            canCheckOut: canCheckOut,
            createdAt: DateTime.now(),
          );
    } catch (e) {
      debugPrint('Erro ao adicionar responsável autorizado: $e');
      throw 'Erro ao adicionar responsável autorizado: $e';
    }
  }

  /// Remove uma pessoa autorizada (por padrão, de todas as crianças da família)
  Future<void> removeAuthorizedGuardian(
    String guardianRecordId, {
    required String childId,
    String? userId,
    String? guardianName,
    bool removeFromAllChildren = true,
  }) async {
    final user = currentUser;
    try {
      if (removeFromAllChildren && user != null) {
        // Deleta os registros correspondentes para todas as crianças do usuário
        if (userId != null && userId.isNotEmpty) {
          await client
              .from('child_authorized_guardians')
              .delete()
              .eq('user_id', userId)
              .eq('added_by_user_id', user.id);

          // Remove do array authorized_user_ids de todas as crianças do usuário
          final childrenRes = await client
              .from('children')
              .select('id, authorized_user_ids')
              .or('user_id.eq.${user.id},guardian_id.eq.${user.id}');
          for (final row in (childrenRes as List<dynamic>)) {
            final cid = row['id']?.toString() ?? '';
            List<dynamic> currentIds = (row['authorized_user_ids'] as List<dynamic>?) ?? [];
            if (currentIds.contains(userId)) {
              currentIds.remove(userId);
              await client
                  .from('children')
                  .update({'authorized_user_ids': currentIds})
                  .eq('id', cid);
            }
          }
        } else {
          // Remove por nome e added_by_user_id
          final nameToRemove = guardianName?.trim();
          if (nameToRemove != null && nameToRemove.isNotEmpty) {
            await client
                .from('child_authorized_guardians')
                .delete()
                .eq('name', nameToRemove)
                .eq('added_by_user_id', user.id);
          } else {
            await client.from('child_authorized_guardians').delete().eq('id', guardianRecordId);
          }
        }
      } else {
        await client.from('child_authorized_guardians').delete().eq('id', guardianRecordId);

        // Se tiver userId vinculado, remove do array na tabela children daquela criança
        if (userId != null && userId.isNotEmpty) {
          try {
            final childRow = await client
                .from('children')
                .select('authorized_user_ids')
                .eq('id', childId)
                .maybeSingle();

            List<dynamic> currentIds = (childRow?['authorized_user_ids'] as List<dynamic>?) ?? [];
            currentIds.remove(userId);
            await client
                .from('children')
                .update({'authorized_user_ids': currentIds})
                .eq('id', childId);
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('Erro ao remover responsável autorizado: $e');
      throw 'Erro ao remover responsável autorizado: $e';
    }
  }

  /// Retorna as pessoas autorizadas consolidadas para a família do usuário
  Future<List<AuthorizedGuardianModel>> getFamilyAuthorizedGuardians() async {
    final user = currentUser;
    if (user == null) return [];

    try {
      final res = await client
          .from('child_authorized_guardians')
          .select()
          .eq('added_by_user_id', user.id)
          .order('created_at', ascending: true);

      final list = res as List<dynamic>;
      final models = list.map((m) => AuthorizedGuardianModel.fromMap(m as Map<String, dynamic>)).toList();

      // Deduplica por userId ou nome
      final Map<String, AuthorizedGuardianModel> deduplicated = {};
      for (final g in models) {
        final key = (g.userId != null && g.userId!.isNotEmpty) ? 'u_${g.userId}' : 'n_${g.name.toLowerCase()}';
        if (!deduplicated.containsKey(key)) {
          deduplicated[key] = g;
        }
      }

      return deduplicated.values.toList();
    } catch (e) {
      debugPrint('Erro ao buscar responsáveis da família: $e');
      return [];
    }
  }

  // ==========================================
  // GESTÃO DE TURMAS / SALAS (CLASSROOMS)
  // ==========================================

  /// Busca todas as turmas cadastradas
  Future<List<ClassroomModel>> getClassrooms() async {
    try {
      final response = await client
          .from('classrooms')
          .select()
          .order('min_age_years', ascending: true);

      final list = response as List<dynamic>;
      return list.map((item) => ClassroomModel.fromMap(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Erro ao buscar turmas: $e');
      return [];
    }
  }

  /// Salva ou atualiza uma turma (Apenas Admin)
  Future<ClassroomModel> saveClassroom(ClassroomModel classroom) async {
    final data = classroom.toMap();
    try {
      await client.from('classrooms').upsert(data);
      return classroom;
    } catch (e) {
      debugPrint('Erro ao salvar turma: $e');
      throw 'Erro ao salvar turma: $e';
    }
  }

  /// Exclui uma turma (Apenas Admin)
  Future<void> deleteClassroom(String classroomId) async {
    try {
      await client.from('classrooms').delete().eq('id', classroomId);
    } catch (e) {
      debugPrint('Erro ao excluir turma: $e');
      throw 'Erro ao excluir turma: $e';
    }
  }

  // ==========================================
  // GESTÃO DE EVENTOS (CHURCH_EVENTS)
  // ==========================================

  /// Busca todos os eventos cadastrados
  Future<List<ChurchEventModel>> getEvents() async {
    try {
      final response = await client
          .from('church_events')
          .select()
          .order('date', ascending: false);

      final list = response as List<dynamic>;
      return list.map((item) => ChurchEventModel.fromMap(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Erro ao buscar eventos: $e');
      return [];
    }
  }

  /// Busca eventos atualmente ativos
  Future<List<ChurchEventModel>> getActiveEvents() async {
    try {
      final response = await client
          .from('church_events')
          .select()
          .eq('is_active', true)
          .order('date', ascending: false);

      final list = response as List<dynamic>;
      return list.map((item) => ChurchEventModel.fromMap(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Erro ao buscar eventos ativos: $e');
      return [];
    }
  }

  /// Salva ou atualiza um evento (Apenas Admin)
  Future<ChurchEventModel> saveEvent(ChurchEventModel event) async {
    final data = event.toMap();
    try {
      await client.from('church_events').upsert(data);
      return event;
    } catch (e) {
      debugPrint('Erro ao salvar evento: $e');
      throw 'Erro ao salvar evento: $e';
    }
  }

  /// Exclui um evento (Apenas Admin)
  Future<void> deleteEvent(String eventId) async {
    try {
      await client.from('church_events').delete().eq('id', eventId);
    } catch (e) {
      debugPrint('Erro ao excluir evento: $e');
      throw 'Erro ao excluir evento: $e';
    }
  }

  // ==========================================
  // CONTROLE DE PRESENÇAS / CRIANÇAS NA SALA
  // ==========================================

  /// Busca as crianças presentes em uma sala durante um evento
  Future<List<AttendanceModel>> getAttendancesForClassroom(String classroomId, {String? eventId}) async {
    try {
      var query = client
          .from('attendances')
          .select()
          .eq('classroom_id', classroomId)
          .isFilter('check_out_time', null);

      if (eventId != null && eventId.isNotEmpty) {
        query = query.eq('event_id', eventId);
      }

      final response = await query.order('check_in_time', ascending: false);
      final list = response as List<dynamic>;

      // Para cada attendance, busca os dados da criança
      final List<AttendanceModel> attendances = [];
      for (final item in list) {
        final childId = item['child_id']?.toString() ?? '';
        ChildModel? child;
        if (childId.isNotEmpty) {
          try {
            final childData = await client
                .from('children')
                .select()
                .eq('id', childId)
                .maybeSingle();
            if (childData != null) {
              child = ChildModel.fromMap(childData, fallbackUserId: '');
            }
          } catch (_) {}
        }
        attendances.add(AttendanceModel.fromMap(item as Map<String, dynamic>, child: child));
      }

      return attendances;
    } catch (e) {
      debugPrint('Erro ao buscar presenças da sala: $e');
      return [];
    }
  }

  /// Check-out de uma criança da sala
  Future<void> checkOutChild(String attendanceId) async {
    try {
      final attendance = await client
          .from('attendances')
          .select('child_id')
          .eq('id', attendanceId)
          .maybeSingle();

      await client.from('attendances').update({
        'check_out_time': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', attendanceId);

      // Atualiza o status 'em sala' para false na tabela children
      if (attendance != null && attendance['child_id'] != null) {
        final childId = attendance['child_id'].toString();
        await client
            .from('children')
            .update({'is_in_classroom': false})
            .eq('id', childId);
      }
    } catch (e) {
      debugPrint('Erro ao realizar check-out: $e');
      throw 'Erro ao realizar check-out: $e';
    }
  }

  /// Registra um grupo de check-in de crianças no evento ativo gerando um código de segurança único compartilhado
  Future<List<AttendanceModel>> registerCheckInGroup({
    required String eventId,
    required String guardianName,
    required List<Map<String, dynamic>> checkIns,
  }) async {
    final childIds = checkIns.map((c) => c['child_id'].toString()).toList();

    // 1. Validação estrita: não permite dar entrada duas vezes na mesma criança
    try {
      final activeAttendances = await client
          .from('attendances')
          .select('child_id')
          .inFilter('child_id', childIds)
          .isFilter('check_out_time', null);

      final activeList = activeAttendances as List<dynamic>;
      if (activeList.isNotEmpty) {
        throw 'Uma ou mais crianças selecionadas já estão com check-in realizado e não podem receber nova entrada.';
      }
    } catch (e) {
      if (e is String) rethrow;
      debugPrint('Aviso ao checar presenças ativas: $e');
    }

    final rand = Random();
    final securityCode = 'DK-${rand.nextInt(9000) + 1000}';
    final now = DateTime.now().toUtc();

    final List<Map<String, dynamic>> rowsToInsert = [];
    for (final item in checkIns) {
      final id = 'att_${DateTime.now().millisecondsSinceEpoch}_${rand.nextInt(10000)}';
      rowsToInsert.add({
        'id': id,
        'event_id': eventId,
        'child_id': item['child_id'],
        'classroom_id': item['classroom_id'],
        'check_in_time': now.toIso8601String(),
        'check_out_time': null,
        'security_code': securityCode,
        'checked_in_by_guardian_name': guardianName,
        'has_bag': item['has_bag'] == true,
        'has_bottle': item['has_bottle'] == true,
        'has_pacifier': item['has_pacifier'] == true,
        'belongings_notes': item['belongings_notes'] ?? '',
        'created_at': now.toIso8601String(),
      });
    }

    try {
      await client.from('attendances').insert(rowsToInsert);

      // 2. Atualiza o status 'em sala' para true na tabela children
      try {
        await client
            .from('children')
            .update({'is_in_classroom': true})
            .inFilter('id', childIds);
      } catch (err) {
        debugPrint('Aviso ao atualizar is_in_classroom: $err');
      }

      return rowsToInsert.map((r) => AttendanceModel.fromMap(r)).toList();
    } catch (e) {
      debugPrint('Erro ao registrar check-in: $e');
      throw 'Erro ao registrar check-in: $e';
    }
  }

  /// Envia e-mail de recuperação de senha
  Future<void> resetPassword({required String email}) async {
    try {
      await client.auth.resetPasswordForEmail(email.trim());
    } on AuthException catch (e) {
      throw _translateAuthException(e);
    } catch (e) {
      throw 'Erro ao solicitar redefinição. Tente novamente.';
    }
  }

  /// Encerra a sessão
  Future<void> signOut() async {
    await client.auth.signOut();
  }

  /// Tradução amigável dos erros do Supabase Auth
  String _translateAuthException(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login credentials') || msg.contains('invalid credentials')) {
      return 'E-mail ou senha incorretos.';
    }
    if (msg.contains('user already registered') || msg.contains('already exists')) {
      return 'Já existe uma conta cadastrada com este e-mail.';
    }
    if (msg.contains('password should be at least')) {
      return 'A senha deve conter no mínimo 6 caracteres.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Por favor, confirme o e-mail cadastrado antes de entrar.';
    }
    if (msg.contains('rate limit')) {
      return 'Muitas tentativas em pouco tempo. Aguarde alguns minutos.';
    }
    return e.message;
  }

  // ==========================================
  // COMUNICAÇÃO E NOTIFICAÇÕES KIDS
  // ==========================================

  /// Busca os dados de contato do responsável da criança (telefone, WhatsApp, nome, e-mail)
  Future<GuardianContactInfo> getGuardianContactForChild(
    String childId, {
    String? fallbackName,
  }) async {
    try {
      // 1. Busca a criança para obter o user_id ou guardian_id
      final childRes = await client
          .from('children')
          .select('user_id, guardian_id')
          .eq('id', childId)
          .maybeSingle();

      String? userId = childRes?['user_id']?.toString();
      String? guardianId = childRes?['guardian_id']?.toString();

      if (userId != null && userId.isNotEmpty) {
        final profileRes = await client
            .from('profiles')
            .select('full_name, phone, email, gender')
            .eq('id', userId)
            .maybeSingle();

        if (profileRes != null) {
          final name = profileRes['full_name']?.toString() ?? fallbackName ?? 'Responsável';
          final phone = profileRes['phone']?.toString() ?? '';
          final email = profileRes['email']?.toString() ?? '';
          final rawGender = profileRes['gender']?.toString().toLowerCase() ?? 'responsavel';
          final role = (rawGender == 'pai' || rawGender == 'mae') ? rawGender.toUpperCase() : 'Responsável';

          return GuardianContactInfo(
            name: name,
            phone: phone,
            email: email,
            role: role,
            userId: userId,
          );
        }
      }

      // 2. Se não encontrou em profiles, tenta em guardians
      if (guardianId != null && guardianId.isNotEmpty) {
        final gRes = await client
            .from('guardians')
            .select('full_name, encrypted_phone, encrypted_email, role')
            .eq('id', guardianId)
            .maybeSingle();

        if (gRes != null) {
          return GuardianContactInfo(
            name: gRes['full_name']?.toString() ?? fallbackName ?? 'Responsável',
            phone: gRes['encrypted_phone']?.toString() ?? '',
            email: gRes['encrypted_email']?.toString() ?? '',
            role: gRes['role']?.toString() ?? 'Responsável',
            userId: null,
          );
        }
      }

      return GuardianContactInfo(
        name: fallbackName ?? 'Responsável',
        phone: '',
        email: '',
        role: 'Responsável',
        userId: userId,
      );
    } catch (e) {
      debugPrint('Erro ao buscar contato do responsável: $e');
      return GuardianContactInfo(
        name: fallbackName ?? 'Responsável',
        phone: '',
        email: '',
        role: 'Responsável',
      );
    }
  }

  /// Envia uma notificação para o responsável da criança
  Future<void> sendKidNotification({
    required String? guardianUserId,
    required String childId,
    required String childName,
    required String classroomId,
    required String classroomName,
    required String? eventId,
    required String title,
    required String message,
    String type = 'call_parent',
  }) async {
    try {
      final currentProfile = await getProfile();
      final senderName = currentProfile.fullName.isNotEmpty
          ? currentProfile.fullName
          : 'Equipe Duna Kids';

      // Garante que o guardianUserId seja preenchido buscando na tabela children se vier nulo
      String? targetGuardianId = guardianUserId;
      if (targetGuardianId == null || targetGuardianId.isEmpty) {
        final childRow = await client
            .from('children')
            .select('user_id')
            .eq('id', childId)
            .maybeSingle();
        targetGuardianId = childRow?['user_id']?.toString();
      }

      await client.from('kids_notifications').insert({
        'guardian_user_id': targetGuardianId,
        'child_id': childId,
        'child_name': childName,
        'classroom_id': classroomId,
        'classroom_name': classroomName,
        'event_id': eventId,
        'title': title,
        'message': message,
        'type': type,
        'is_read': false,
        'sent_by_name': senderName,
      });
    } catch (e) {
      debugPrint('Erro ao enviar notificação: $e');
      throw 'Erro ao enviar notificação: $e';
    }
  }

  /// Busca notificações destinadas ao responsável atual (por usuário ou por suas crianças cadastradas)
  Future<List<KidNotificationModel>> getKidNotificationsForCurrentGuardian() async {
    try {
      final currentUserId = client.auth.currentUser?.id;
      if (currentUserId == null) return [];

      // 1. Busca os IDs das crianças vinculadas a este responsável
      final myChildren = await getChildren();
      final myChildIds = myChildren.map((c) => c.id).toList();

      // 2. Monta a busca: por guardian_user_id OU por child_id das crianças dele
      String filter = 'guardian_user_id.eq.$currentUserId';
      if (myChildIds.isNotEmpty) {
        final formattedIds = myChildIds.map((id) => '"$id"').join(',');
        filter = '$filter,child_id.in.($formattedIds)';
      }

      final res = await client
          .from('kids_notifications')
          .select()
          .or(filter)
          .order('created_at', ascending: false)
          .limit(30);

      final list = res as List<dynamic>;
      return list.map((m) => KidNotificationModel.fromMap(m as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Erro ao buscar notificações: $e');
      return [];
    }
  }

  /// Retorna a quantidade de notificações não lidas para o responsável
  Future<int> getUnreadNotificationsCount() async {
    try {
      final list = await getKidNotificationsForCurrentGuardian();
      return list.where((n) => !n.isRead).length;
    } catch (_) {
      return 0;
    }
  }

  /// Marca notificação como lida
  Future<void> markKidNotificationAsRead(String notificationId) async {
    try {
      await client
          .from('kids_notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      debugPrint('Erro ao marcar notificação como lida: $e');
    }
  }
}

class GuardianContactInfo {
  final String name;
  final String phone;
  final String email;
  final String role;
  final String? userId;

  const GuardianContactInfo({
    required this.name,
    this.phone = '',
    this.email = '',
    this.role = 'Responsável',
    this.userId,
  });

  String get cleanPhoneNumber => phone.replaceAll(RegExp(r'\D'), '');

  String get formattedWhatsAppNumber {
    final clean = cleanPhoneNumber;
    if (clean.isEmpty) return '';
    if (clean.length == 10 || clean.length == 11) {
      return '55$clean';
    }
    return clean;
  }
}
