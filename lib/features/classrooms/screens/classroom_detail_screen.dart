import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/azure_card.dart';
import '../../../core/widgets/azure_confirm_dialog.dart';
import '../../../core/widgets/azure_navbar.dart';
import '../../../core/widgets/top_toast.dart';
import '../models/attendance_model.dart';
import '../models/classroom_model.dart';
import '../widgets/child_detail_modal.dart';

class ClassroomDetailScreen extends StatefulWidget {
  final ClassroomModel classroom;
  final String? eventId;
  final String? eventName;

  const ClassroomDetailScreen({
    super.key,
    required this.classroom,
    this.eventId,
    this.eventName,
  });

  @override
  State<ClassroomDetailScreen> createState() => _ClassroomDetailScreenState();
}

class _ClassroomDetailScreenState extends State<ClassroomDetailScreen> {
  List<AttendanceModel> _attendances = [];
  bool _isLoading = true;
  final DateFormat _timeFormat = DateFormat('HH:mm');

  @override
  void initState() {
    super.initState();
    _loadAttendances();
  }

  Future<void> _loadAttendances() async {
    setState(() => _isLoading = true);
    try {
      final list = await SupabaseService.instance.getAttendancesForClassroom(
        widget.classroom.id,
        eventId: widget.eventId,
      );
      if (mounted) {
        setState(() {
          _attendances = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar crianças: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _handleCheckOut(AttendanceModel attendance) async {
    final childName = attendance.child?.fullName ?? 'esta criança';
    final confirm = await AzureConfirmDialog.show(
      context,
      title: 'Confirmar Saída da Sala',
      message: 'Confirmar a saída / retirada de "$childName" da sala ${widget.classroom.name}?',
      confirmText: 'Confirmar Saída',
      cancelText: 'Cancelar',
      isDestructive: false,
      icon: Icons.logout_rounded,
    );

    if (confirm) {
      try {
        await SupabaseService.instance.checkOutChild(attendance.id);
        _loadAttendances();
        if (mounted) {
          TopToast.showSuccess(context, 'Saída de $childName registrada com sucesso!');
        }
      } catch (e) {
        if (mounted) {
          TopToast.showError(context, 'Erro ao registrar saída: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final presentCount = _attendances.length;
    final maxCapacity = widget.classroom.maxCapacity;
    final isFull = presentCount >= maxCapacity;

    return Scaffold(
      appBar: AzureNavbar(
        title: widget.classroom.name,
        currentRoute: '/turmas',
        showBackButton: true,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryAzure))
                : RefreshIndicator(
                    onRefresh: _loadAttendances,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      children: [
                        // Card Informativo da Turma
                        _buildClassroomHeaderCard(presentCount, maxCapacity, isFull),
                        const SizedBox(height: 20),

                        // Título da Lista
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Crianças na Sala ($presentCount)',
                              style: AppTypography.titleMedium.copyWith(fontSize: 16),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(color: Color(0xFF059669), shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Sala Aberta',
                                    style: AppTypography.codeBadge.copyWith(color: const Color(0xFF059669), fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Lista de Crianças Presentes
                        if (_attendances.isEmpty) ...[
                          AzureCard(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                const Icon(Icons.child_care_outlined, size: 48, color: AppColors.textMuted),
                                const SizedBox(height: 12),
                                Text(
                                  'Nenhuma criança na sala no momento',
                                  style: AppTypography.labelMedium,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'As crianças aparecerão aqui assim que o check-in for realizado na recepção.',
                                  style: AppTypography.bodyMedium.copyWith(fontSize: 12),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _attendances.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final attendance = _attendances[index];
                              return _buildAttendanceCard(attendance);
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildClassroomHeaderCard(int presentCount, int maxCapacity, bool isFull) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.classroom.color.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: widget.classroom.color.withValues(alpha: 0.08),
            offset: const Offset(0, 6),
            blurRadius: 18,
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
                decoration: BoxDecoration(color: widget.classroom.color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.classroom.name,
                  style: AppTypography.titleMedium.copyWith(fontSize: 18),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isFull ? const Color(0xFFFEF2F2) : AppColors.azureLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$presentCount / $maxCapacity alunos',
                  style: AppTypography.codeBadge.copyWith(
                    color: isFull ? AppColors.error : AppColors.primaryAzure,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.cake_outlined, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text('Faixa Etária: ${widget.classroom.ageRangeFormatted}', style: AppTypography.bodyMedium),
            ],
          ),
          if (widget.eventName != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.event_outlined, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Evento: ${widget.eventName}',
                    style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(AttendanceModel attendance) {
    final child = attendance.child;
    final childName = child?.fullName ?? 'Criança';
    final ageText = child?.ageFormatted ?? 'Idade n/d';
    final hasInclusion = child?.inclusionLaw13146 == true;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          ChildDetailModal.show(
            context,
            attendance: attendance,
            classroom: widget.classroom,
            onCheckOutRequested: () => _handleCheckOut(attendance),
          );
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasInclusion ? const Color(0xFF9333EA).withValues(alpha: 0.4) : AppColors.border,
              width: hasInclusion ? 1.5 : 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar clicável com indicação de foto
                  Hero(
                    tag: 'child_avatar_${attendance.id}',
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.azureLight,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primaryAzure.withValues(alpha: 0.3)),
                      ),
                      child: ClipOval(
                        child: (child?.photoUrl != null && child!.photoUrl!.isNotEmpty)
                            ? Image.network(
                                child.photoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Icon(
                                  Icons.child_care_rounded,
                                  color: AppColors.primaryAzure,
                                  size: 26,
                                ),
                              )
                            : const Icon(
                                Icons.child_care_rounded,
                                color: AppColors.primaryAzure,
                                size: 26,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(childName, style: AppTypography.labelMedium.copyWith(fontSize: 15)),
                        const SizedBox(height: 2),
                        Text(
                          '$ageText • Entrada: ${_timeFormat.format(attendance.checkInTime.toLocal())}',
                          style: AppTypography.bodyMedium.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Botão de Informações / Notificar
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.azureLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.contact_phone_outlined, size: 20, color: AppColors.primaryAzure),
                      tooltip: 'Ver Foto e Contatar Responsável',
                      onPressed: () {
                        ChildDetailModal.show(
                          context,
                          attendance: attendance,
                          classroom: widget.classroom,
                          onCheckOutRequested: () => _handleCheckOut(attendance),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Botão de Saída Direta
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surfaceSubtle,
                      foregroundColor: AppColors.textPrimary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: AppColors.border),
                      ),
                    ),
                    onPressed: () => _handleCheckOut(attendance),
                    child: const Text('Saída', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),

              // Destaque de Inclusão - Lei nº 13.146/2015
              if (hasInclusion) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF9333EA).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.accessibility_new_rounded, size: 16, color: Color(0xFF9333EA)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Lei nº 13.146/2015 - Inclusão${child?.inclusionDetails != null && child!.inclusionDetails!.isNotEmpty ? ": ${child.inclusionDetails}" : ""}',
                          style: AppTypography.bodyMedium.copyWith(
                            fontSize: 11,
                            color: const Color(0xFF9333EA),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (child?.notes != null && child!.notes.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Alergias/Obs: ${child.notes}',
                  style: AppTypography.bodyMedium.copyWith(fontSize: 11, color: AppColors.error),
                ),
              ],

              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Toque para foto ampliada e contatos',
                    style: AppTypography.bodyMedium.copyWith(fontSize: 11, color: AppColors.primaryAzure),
                  ),
                  const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.primaryAzure),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
