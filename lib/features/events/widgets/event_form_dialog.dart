import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/azure_button.dart';
import '../../../core/widgets/azure_text_field.dart';
import '../../classrooms/models/classroom_model.dart';
import '../models/church_event_model.dart';

class EventFormDialog extends StatefulWidget {
  final ChurchEventModel? initialEvent;
  final List<ClassroomModel> classrooms;

  const EventFormDialog({
    super.key,
    this.initialEvent,
    required this.classrooms,
  });

  static Future<ChurchEventModel?> show(
    BuildContext context, {
    ChurchEventModel? event,
    required List<ClassroomModel> classrooms,
  }) {
    return showModalBottomSheet<ChurchEventModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EventFormDialog(
        initialEvent: event,
        classrooms: classrooms,
      ),
    );
  }

  @override
  State<EventFormDialog> createState() => _EventFormDialogState();
}

class _EventFormDialogState extends State<EventFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 11, minute: 30);

  bool _isActive = true;
  List<String> _activeClassroomIds = [];

  bool _isSaving = false;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    if (widget.initialEvent != null) {
      final e = widget.initialEvent!;
      _titleController.text = e.name;
      _startDate = e.date;
      _endDate = e.endDate ?? e.date;
      _isActive = e.isActive;
      _activeClassroomIds = List<String>.from(e.activeClassroomIds);

      final startParts = e.startTime.split(':');
      if (startParts.length == 2) {
        _startTime = TimeOfDay(
          hour: int.tryParse(startParts[0]) ?? 9,
          minute: int.tryParse(startParts[1]) ?? 0,
        );
      }

      final endParts = e.endTime.split(':');
      if (endParts.length == 2) {
        _endTime = TimeOfDay(
          hour: int.tryParse(endParts[0]) ?? 11,
          minute: int.tryParse(endParts[1]) ?? 30,
        );
      }
    } else {
      // Por padrão, seleciona todas as salas existentes
      _activeClassroomIds = widget.classrooms.map((c) => c.id).toList();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      helpText: 'DATA DE INÍCIO DO EVENTO',
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate.isBefore(picked)) {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate.isBefore(_startDate) ? _startDate : _endDate,
      firstDate: _startDate,
      lastDate: DateTime(2035),
      helpText: 'DATA DE TÉRMINO DO EVENTO',
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
      helpText: 'HORÁRIO DE INÍCIO',
    );
    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
      helpText: 'HORÁRIO DE TÉRMINO',
    );
    if (picked != null) {
      setState(() => _endTime = picked);
    }
  }

  void _handleSave() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isSaving = true);

      final eventId = widget.initialEvent?.id ?? 'event_${DateTime.now().millisecondsSinceEpoch}';

      final event = ChurchEventModel(
        id: eventId,
        name: _titleController.text.trim(),
        date: _startDate,
        endDate: _endDate,
        startTime: _formatTimeOfDay(_startTime),
        endTime: _formatTimeOfDay(_endTime),
        isActive: _isActive,
        activeClassroomIds: _activeClassroomIds,
        createdAt: widget.initialEvent?.createdAt,
      );

      try {
        final saved = await SupabaseService.instance.saveEvent(event);
        if (mounted) {
          setState(() => _isSaving = false);
          Navigator.of(context).pop(saved);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao salvar evento: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isEditing = widget.initialEvent != null;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 20,
        right: 20,
        bottom: bottomInset + 20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                isEditing ? 'Editar Evento' : 'Criar Novo Evento',
                style: AppTypography.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Defina os horários e selecione as salas que estarão ativas/abertas.',
                style: AppTypography.bodyMedium.copyWith(fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Título do Evento
              AzureTextField(
                label: 'Título do Evento',
                hintText: 'Ex: Culto de Domingo - Manhã',
                controller: _titleController,
                prefixIcon: Icons.event_note_rounded,
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Informe o título do evento' : null,
              ),
              const SizedBox(height: 16),

              // Datas de Início e Fim
              Row(
                children: [
                  Expanded(
                    child: _buildPickerCard(
                      label: 'Data de Início',
                      value: _dateFormat.format(_startDate),
                      icon: Icons.calendar_today_rounded,
                      onTap: _pickStartDate,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPickerCard(
                      label: 'Data de Término',
                      value: _dateFormat.format(_endDate),
                      icon: Icons.event_available_rounded,
                      onTap: _pickEndDate,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Horários de Início e Fim
              Row(
                children: [
                  Expanded(
                    child: _buildPickerCard(
                      label: 'Horário de Início',
                      value: _formatTimeOfDay(_startTime),
                      icon: Icons.access_time_rounded,
                      onTap: _pickStartTime,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPickerCard(
                      label: 'Horário de Término',
                      value: _formatTimeOfDay(_endTime),
                      icon: Icons.timelapse_rounded,
                      onTap: _pickEndTime,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Switch Evento Ativo
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _isActive ? const Color(0xFFEFF6FF) : AppColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _isActive ? AppColors.primaryAzure : AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isActive ? Icons.play_circle_fill_rounded : Icons.pause_circle_filled_rounded,
                      color: _isActive ? AppColors.primaryAzure : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isActive ? 'Evento Ativo' : 'Evento Inativo / Pausado',
                            style: AppTypography.labelMedium.copyWith(
                              color: _isActive ? AppColors.primaryAzure : AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            _isActive ? 'As salas selecionadas ficarão abertas' : 'Nenhuma sala ficará ativa por este evento',
                            style: AppTypography.bodyMedium.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: _isActive,
                      activeTrackColor: AppColors.primaryAzure,
                      onChanged: (val) => setState(() => _isActive = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Seção de Salas Abertas
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Salas / Turmas Abertas neste Evento',
                    style: AppTypography.titleMedium.copyWith(fontSize: 15),
                  ),
                  Text(
                    '${_activeClassroomIds.length} de ${widget.classrooms.length}',
                    style: AppTypography.codeBadge.copyWith(fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (widget.classrooms.isEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Nenhuma turma cadastrada. Crie turmas primeiro na tela de Gestão de Turmas.',
                    style: AppTypography.bodyMedium.copyWith(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ] else ...[
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.classrooms.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final classroom = widget.classrooms[index];
                    final isRoomActive = _activeClassroomIds.contains(classroom.id);

                    return InkWell(
                      onTap: () {
                        setState(() {
                          if (isRoomActive) {
                            _activeClassroomIds.remove(classroom.id);
                          } else {
                            _activeClassroomIds.add(classroom.id);
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isRoomActive ? AppColors.azureSubtle : AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isRoomActive ? AppColors.primaryAzure : AppColors.border,
                            width: isRoomActive ? 1.5 : 1.1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: classroom.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    classroom.name,
                                    style: AppTypography.labelMedium.copyWith(
                                      color: isRoomActive ? AppColors.primaryAzure : AppColors.textPrimary,
                                      fontWeight: isRoomActive ? FontWeight.w700 : FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Faixa: ${classroom.ageRangeFormatted} • Vagas: ${classroom.maxCapacity}',
                                    style: AppTypography.bodyMedium.copyWith(fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            Checkbox(
                              value: isRoomActive,
                              activeColor: AppColors.primaryAzure,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _activeClassroomIds.add(classroom.id);
                                  } else {
                                    _activeClassroomIds.remove(classroom.id);
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 24),

              AzureButton(
                text: isEditing ? 'Salvar Alterações do Evento' : 'Criar Evento',
                icon: Icons.check_circle_outline_rounded,
                isLoading: _isSaving,
                onPressed: _handleSave,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPickerCard({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelMedium.copyWith(fontSize: 12)),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 1.2),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: AppColors.primaryAzure),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
