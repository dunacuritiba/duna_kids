import 'package:flutter/material.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/azure_button.dart';
import '../../../core/widgets/azure_card.dart';
import '../../../core/widgets/azure_confirm_dialog.dart';
import '../../../core/widgets/azure_navbar.dart';
import '../../../core/widgets/top_toast.dart';
import '../../events/models/church_event_model.dart';
import '../../profile/models/user_profile_model.dart';
import '../models/classroom_model.dart';
import '../widgets/classroom_form_dialog.dart';
import 'classroom_detail_screen.dart';

class ClassroomsScreen extends StatefulWidget {
  const ClassroomsScreen({super.key});

  @override
  State<ClassroomsScreen> createState() => _ClassroomsScreenState();
}

class _ClassroomsScreenState extends State<ClassroomsScreen> {
  List<ClassroomModel> _classrooms = [];
  List<ChurchEventModel> _activeEvents = [];
  UserProfileModel? _userProfile;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final classroomsFuture = SupabaseService.instance.getClassrooms();
      final eventsFuture = SupabaseService.instance.getActiveEvents();
      final profileFuture = SupabaseService.instance.getProfile();

      final results = await Future.wait([classroomsFuture, eventsFuture, profileFuture]);

      if (mounted) {
        setState(() {
          _classrooms = results[0] as List<ClassroomModel>;
          _activeEvents = results[1] as List<ChurchEventModel>;
          _userProfile = results[2] as UserProfileModel;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar turmas: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  /// Verifica se a sala está ativa em algum evento corrente
  ChurchEventModel? _getEventForClassroom(String classroomId) {
    for (final event in _activeEvents) {
      if (event.isClassroomActive(classroomId)) {
        return event;
      }
    }
    return null;
  }

  Future<void> _openClassroomDialog([ClassroomModel? classroom]) async {
    final result = await ClassroomFormDialog.show(context, classroom: classroom);
    if (result != null) {
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(classroom == null ? 'Turma criada com sucesso!' : 'Turma atualizada com sucesso!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _handleDeleteClassroom(ClassroomModel classroom) async {
    final confirm = await AzureConfirmDialog.show(
      context,
      title: 'Excluir Turma',
      message: 'Deseja realmente excluir a turma "${classroom.name}"? As crianças associadas perderão o vínculo com esta sala.',
      confirmText: 'Sim, Excluir',
      cancelText: 'Cancelar',
      isDestructive: true,
      icon: Icons.delete_sweep_rounded,
    );

    if (confirm) {
      try {
        await SupabaseService.instance.deleteClassroom(classroom.id);
        _loadData();
        if (mounted) {
          TopToast.showSuccess(context, 'Turma "${classroom.name}" excluída com sucesso.');
        }
      } catch (e) {
        if (mounted) {
          TopToast.showError(context, 'Erro ao excluir turma: $e');
        }
      }
    }
  }

  void _onClassroomTap(ClassroomModel classroom, ChurchEventModel? activeEvent) {
    final canView = (_userProfile?.isTeacher == true) || (_userProfile?.isAdmin == true);

    if (!canView) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Apenas Professores e Administradores têm permissão para ver as crianças dentro das salas.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ClassroomDetailScreen(
          classroom: classroom,
          eventId: activeEvent?.id,
          eventName: activeEvent?.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _userProfile?.isAdmin == true;
    final isTeacher = _userProfile?.isTeacher == true;
    final canAccess = isTeacher || isAdmin;

    if (!_isLoading && _userProfile != null && !canAccess) {
      return Scaffold(
        appBar: const AzureNavbar(
          title: 'Gestão de Turmas',
          currentRoute: '/turmas',
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: AzureCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: AppColors.errorSubtle,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_person_rounded, size: 40, color: AppColors.error),
                  ),
                  const SizedBox(height: 16),
                  Text('Acesso Restrito', style: AppTypography.titleMedium.copyWith(fontSize: 18)),
                  const SizedBox(height: 8),
                  Text(
                    'A Gestão de Turmas é restrita a Professores e Administradores do Duna Kids.\n\nComo Responsável, você pode verificar eventos ativos e realizar o Check-in dos seus dependentes.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  AzureButton(
                    text: 'Ir para Check-in Kids',
                    icon: Icons.qr_code_scanner_rounded,
                    onPressed: () => Navigator.of(context).pushReplacementNamed('/checkin'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    int activeCount = 0;
    for (final c in _classrooms) {
      if (_getEventForClassroom(c.id) != null) activeCount++;
    }

    return Scaffold(
      appBar: const AzureNavbar(
        title: 'Gestão de Turmas',
        currentRoute: '/turmas',
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _openClassroomDialog(),
              backgroundColor: AppColors.primaryAzure,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nova Turma', style: TextStyle(fontWeight: FontWeight.w700)),
            )
          : null,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryAzure))
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      children: [
                        // Card Resumo no topo
                        _buildSummaryHeader(activeCount),
                        const SizedBox(height: 20),

                        // Título e Aviso de Permissões
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Turmas Cadastradas (${_classrooms.length})',
                              style: AppTypography.titleMedium.copyWith(fontSize: 16),
                            ),
                            if (isAdmin)
                              Text('Modo Administrador', style: AppTypography.codeBadge.copyWith(fontSize: 11))
                            else if (isTeacher)
                              Text('Modo Professor', style: AppTypography.codeBadge.copyWith(fontSize: 11, color: const Color(0xFF059669))),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (_classrooms.isEmpty) ...[
                          AzureCard(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                const Icon(Icons.meeting_room_outlined, size: 48, color: AppColors.textMuted),
                                const SizedBox(height: 12),
                                Text('Nenhuma turma cadastrada', style: AppTypography.labelMedium),
                                const SizedBox(height: 4),
                                Text(
                                  isAdmin
                                      ? 'Clique no botão "Nova Turma" abaixo para criar a primeira turma.'
                                      : 'Aguarde um administrador cadastrar as turmas.',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.bodyMedium.copyWith(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _classrooms.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final classroom = _classrooms[index];
                              final activeEvent = _getEventForClassroom(classroom.id);
                              return _buildClassroomCard(classroom, activeEvent, isAdmin);
                            },
                          ),
                        ],
                        const SizedBox(height: 60),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryHeader(int activeCount) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryAzure.withValues(alpha: 0.25),
            offset: const Offset(0, 10),
            blurRadius: 24,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Visão Geral das Salas',
                style: AppTypography.titleMedium.copyWith(color: Colors.white, fontSize: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: activeCount > 0 ? const Color(0xFF34D399) : Colors.white70,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$activeCount ${activeCount == 1 ? "Ativa" : "Ativas"}',
                      style: AppTypography.buttonText.copyWith(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'A turma só fica ativa/aberta quando vinculada a um evento ativo no sistema.',
            style: AppTypography.bodyMedium.copyWith(color: Colors.white.withValues(alpha: 0.85), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildClassroomCard(ClassroomModel classroom, ChurchEventModel? activeEvent, bool isAdmin) {
    final isActive = activeEvent != null;

    return InkWell(
      onTap: () => _onClassroomTap(classroom, activeEvent),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? classroom.color.withValues(alpha: 0.6) : AppColors.border,
            width: isActive ? 1.6 : 1.1,
          ),
          boxShadow: [
            if (isActive)
              BoxShadow(
                color: classroom.color.withValues(alpha: 0.10),
                offset: const Offset(0, 4),
                blurRadius: 14,
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(color: classroom.color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    classroom.name,
                    style: AppTypography.titleMedium.copyWith(fontSize: 16),
                  ),
                ),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFFECFDF5) : AppColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isActive ? const Color(0xFF059669).withValues(alpha: 0.3) : AppColors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isActive ? const Color(0xFF059669) : AppColors.textMuted,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isActive ? 'Aberta' : 'Fechada',
                        style: AppTypography.codeBadge.copyWith(
                          fontSize: 11,
                          color: isActive ? const Color(0xFF059669) : AppColors.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isAdmin) ...[
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, size: 20, color: AppColors.textSecondary),
                    onSelected: (val) {
                      if (val == 'edit') _openClassroomDialog(classroom);
                      if (val == 'delete') _handleDeleteClassroom(classroom);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Editar')])),
                      const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, color: AppColors.error, size: 18), SizedBox(width: 8), Text('Excluir', style: TextStyle(color: AppColors.error))])),
                    ],
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.cake_outlined, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text('Idade: ${classroom.ageRangeFormatted}', style: AppTypography.bodyMedium.copyWith(fontSize: 12)),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.group_outlined, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text('Capacidade: ${classroom.maxCapacity}', style: AppTypography.bodyMedium.copyWith(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),

            if (isActive) ...[
              const Divider(height: 18, color: AppColors.border),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.event_available_rounded, size: 15, color: Color(0xFF059669)),
                      const SizedBox(width: 6),
                      Text(
                        'Evento: ${activeEvent.name}',
                        style: AppTypography.bodyMedium.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        'Ver sala',
                        style: AppTypography.labelMedium.copyWith(
                          fontSize: 12,
                          color: AppColors.primaryAzure,
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.primaryAzure),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
