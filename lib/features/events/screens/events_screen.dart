import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/azure_button.dart';
import '../../../core/widgets/azure_card.dart';
import '../../../core/widgets/azure_confirm_dialog.dart';
import '../../../core/widgets/azure_navbar.dart';
import '../../../core/widgets/top_toast.dart';
import '../../classrooms/models/classroom_model.dart';
import '../../profile/models/user_profile_model.dart';
import '../models/church_event_model.dart';
import '../widgets/event_form_dialog.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  List<ChurchEventModel> _events = [];
  List<ClassroomModel> _classrooms = [];
  UserProfileModel? _userProfile;

  bool _isLoading = true;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final eventsFuture = SupabaseService.instance.getEvents();
      final classroomsFuture = SupabaseService.instance.getClassrooms();
      final profileFuture = SupabaseService.instance.getProfile();

      final results = await Future.wait([eventsFuture, classroomsFuture, profileFuture]);

      if (mounted) {
        setState(() {
          _events = results[0] as List<ChurchEventModel>;
          _classrooms = results[1] as List<ClassroomModel>;
          _userProfile = results[2] as UserProfileModel;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar eventos: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _openEventDialog([ChurchEventModel? event]) async {
    final result = await EventFormDialog.show(
      context,
      event: event,
      classrooms: _classrooms,
    );
    if (result != null) {
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(event == null ? 'Evento criado com sucesso!' : 'Evento atualizado!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _toggleEventActive(ChurchEventModel event, bool val) async {
    try {
      final updated = event.copyWith(isActive: val);
      await SupabaseService.instance.saveEvent(updated);
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _handleDeleteEvent(ChurchEventModel event) async {
    final confirm = await AzureConfirmDialog.show(
      context,
      title: 'Excluir Evento / Culto',
      message: 'Deseja realmente excluir o evento "${event.name}"? Os check-ins associados a este evento serão arquivados.',
      confirmText: 'Sim, Excluir',
      cancelText: 'Cancelar',
      isDestructive: true,
      icon: Icons.event_busy_rounded,
    );

    if (confirm) {
      try {
        await SupabaseService.instance.deleteEvent(event.id);
        _loadData();
        if (mounted) {
          TopToast.showSuccess(context, 'Evento "${event.name}" excluído com sucesso.');
        }
      } catch (e) {
        if (mounted) {
          TopToast.showError(context, 'Erro ao excluir evento: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _userProfile?.isAdmin == true;

    if (!_isLoading && _userProfile != null && !isAdmin) {
      return Scaffold(
        appBar: const AzureNavbar(
          title: 'Gestão de Eventos',
          currentRoute: '/eventos',
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
                    'A Gestão e Abertura de Eventos é restrita a Administradores do Duna Kids.\n\nComo Responsável, você pode verificar eventos ativos e realizar o Check-in dos seus dependentes.',
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

    final activeCount = _events.where((e) => e.isActive).length;

    return Scaffold(
      appBar: const AzureNavbar(
        title: 'Gestão de Eventos',
        currentRoute: '/eventos',
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _openEventDialog(),
              backgroundColor: AppColors.primaryAzure,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Novo Evento', style: TextStyle(fontWeight: FontWeight.w700)),
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
                        _buildHeaderCard(activeCount),
                        const SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Eventos (${_events.length})',
                              style: AppTypography.titleMedium.copyWith(fontSize: 16),
                            ),
                            if (isAdmin)
                              Text('Administrador', style: AppTypography.codeBadge.copyWith(fontSize: 11)),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (_events.isEmpty) ...[
                          AzureCard(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                const Icon(Icons.event_busy_outlined, size: 48, color: AppColors.textMuted),
                                const SizedBox(height: 12),
                                Text('Nenhum evento cadastrado', style: AppTypography.labelMedium),
                                const SizedBox(height: 4),
                                Text(
                                  isAdmin
                                      ? 'Crie o primeiro evento para ativar as salas de aula.'
                                      : 'Nenhum evento disponível no momento.',
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
                            itemCount: _events.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final event = _events[index];
                              return _buildEventCard(event, isAdmin);
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

  Widget _buildHeaderCard(int activeCount) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            offset: const Offset(0, 4),
            blurRadius: 14,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.azureLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.calendar_month_rounded, color: AppColors.primaryAzure, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Eventos e Abertura de Salas', style: AppTypography.titleMedium.copyWith(fontSize: 16)),
                const SizedBox(height: 2),
                Text(
                  'Eventos ativos abrem as turmas selecionadas para atendimento.',
                  style: AppTypography.bodyMedium.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: activeCount > 0 ? const Color(0xFFECFDF5) : AppColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$activeCount Ativo',
              style: AppTypography.codeBadge.copyWith(
                color: activeCount > 0 ? const Color(0xFF059669) : AppColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(ChurchEventModel event, bool isAdmin) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: event.isActive ? AppColors.primaryAzure.withValues(alpha: 0.5) : AppColors.border,
          width: event.isActive ? 1.5 : 1.1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  event.name,
                  style: AppTypography.titleMedium.copyWith(fontSize: 16),
                ),
              ),
              if (isAdmin) ...[
                Switch.adaptive(
                  value: event.isActive,
                  activeTrackColor: AppColors.primaryAzure,
                  onChanged: (val) => _toggleEventActive(event, val),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, size: 20, color: AppColors.textSecondary),
                  onSelected: (val) {
                    if (val == 'edit') _openEventDialog(event);
                    if (val == 'delete') _handleDeleteEvent(event);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Editar')])),
                    const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, color: AppColors.error, size: 18), SizedBox(width: 8), Text('Excluir', style: TextStyle(color: AppColors.error))])),
                  ],
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: event.isActive ? const Color(0xFFECFDF5) : AppColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    event.isActive ? 'Ativo' : 'Encerrado',
                    style: AppTypography.codeBadge.copyWith(
                      color: event.isActive ? const Color(0xFF059669) : AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),

          // Informações de Data e Horário
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 15, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                '${_dateFormat.format(event.date)}${event.endDate != null && event.endDate != event.date ? " até ${_dateFormat.format(event.endDate!)}" : ""}',
                style: AppTypography.bodyMedium.copyWith(fontSize: 12),
              ),
              const SizedBox(width: 14),
              const Icon(Icons.access_time_rounded, size: 15, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                '${event.startTime} às ${event.endTime}',
                style: AppTypography.bodyMedium.copyWith(fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Salas Abertas vinculadas
          Row(
            children: [
              const Icon(Icons.meeting_room_outlined, size: 15, color: AppColors.primaryAzure),
              const SizedBox(width: 6),
              Text(
                'Salas Abertas: ',
                style: AppTypography.labelMedium.copyWith(fontSize: 12, color: AppColors.primaryAzure),
              ),
              Expanded(
                child: Text(
                  event.activeClassroomIds.isEmpty
                      ? 'Nenhuma sala selecionada'
                      : _getClassroomsNames(event.activeClassroomIds),
                  style: AppTypography.bodyMedium.copyWith(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getClassroomsNames(List<String> ids) {
    final names = _classrooms.where((c) => ids.contains(c.id)).map((c) => c.name).toList();
    if (names.isEmpty) return '${ids.length} salas';
    return names.join(', ');
  }
}
