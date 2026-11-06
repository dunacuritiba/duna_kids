import 'package:flutter/material.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/azure_button.dart';
import '../../../core/widgets/azure_card.dart';
import '../../../core/widgets/azure_navbar.dart';
import '../../children/models/child_model.dart';
import '../../classrooms/models/classroom_model.dart';
import '../../events/models/church_event_model.dart';
import '../../profile/models/user_profile_model.dart';
import '../services/label_printer_service.dart';
import '../widgets/label_preview_dialog.dart';

class _ChildSelectionState {
  final ChildModel child;
  bool isSelected;
  ClassroomModel? selectedClassroom;
  bool hasBag;
  bool hasBottle;
  bool hasPacifier;
  final TextEditingController notesController;

  _ChildSelectionState({
    required this.child,
    this.isSelected = true,
    this.selectedClassroom,
    this.hasBag = false,
    this.hasBottle = false,
    this.hasPacifier = false,
  }) : notesController = TextEditingController();
}

class CheckinScreen extends StatefulWidget {
  const CheckinScreen({super.key});

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  bool _isLoading = true;
  bool _isSubmitting = false;

  UserProfileModel? _profile;
  ChurchEventModel? _activeEvent;
  List<ClassroomModel> _availableClassrooms = [];
  final List<_ChildSelectionState> _childrenSelections = [];

  String _selectedPrinterLabel = 'Impressora: Automática';

  @override
  void initState() {
    super.initState();
    _loadCheckInData();
    _loadPrinterStatus();
  }

  Future<void> _loadPrinterStatus() async {
    try {
      final saved = await LabelPrinterService.getSavedPrinterUrl();
      final brotherList = await LabelPrinterService.getBrotherPrinters();

      if (mounted) {
        setState(() {
          if (saved != null && saved != 'auto') {
            final matched = brotherList.where((p) => p.url == saved || p.name == saved);
            _selectedPrinterLabel = matched.isNotEmpty
                ? 'Guichê: ${matched.first.name}'
                : 'Guichê: $saved';
          } else {
            _selectedPrinterLabel = brotherList.length > 1
                ? 'Balanceamento (${brotherList.length} impressoras)'
                : 'Impressão Direta Brother';
          }
        });
      }
    } catch (_) {}
  }

  void _showPrinterSelectorModal() async {
    final brotherList = await LabelPrinterService.getBrotherPrinters();
    final currentSaved = await LabelPrinterService.getSavedPrinterUrl();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Icon(Icons.print_rounded, color: AppColors.primaryAzure, size: 22),
                  const SizedBox(width: 10),
                  Text('Roteamento de Impressoras', style: AppTypography.titleMedium.copyWith(fontSize: 16)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Configure como as etiquetas serão distribuídas neste atendimento.',
                style: AppTypography.bodyMedium.copyWith(fontSize: 12),
              ),
              const Divider(height: 24, color: AppColors.border),

              // Opção 1: Automático / Balanceamento de Carga
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.sync_rounded, color: AppColors.primaryAzure, size: 20),
                ),
                title: Text('Automático / Balancear Carga', style: AppTypography.labelMedium),
                subtitle: Text(
                  'Alterna os check-ins entre as várias impressoras Brother conectadas',
                  style: AppTypography.bodyMedium.copyWith(fontSize: 11),
                ),
                trailing: (currentSaved == null || currentSaved == 'auto')
                    ? const Icon(Icons.check_circle_rounded, color: AppColors.primaryAzure)
                    : null,
                onTap: () {
                  Navigator.of(ctx).pop();
                  LabelPrinterService.saveSelectedPrinterUrl('auto').then((_) {
                    if (mounted) _loadPrinterStatus();
                  });
                },
              ),
              const SizedBox(height: 8),

              // Lista das Impressoras Conectadas
              if (brotherList.isNotEmpty) ...[
                Text('IMPRESSORAS CONECTADAS DETECTADAS', style: AppTypography.codeBadge.copyWith(fontSize: 10)),
                const SizedBox(height: 6),
                ...brotherList.map((printer) {
                  final isSelected = currentSaved == printer.url || currentSaved == printer.name;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.local_printshop_outlined, size: 20, color: AppColors.textPrimary),
                    ),
                    title: Text(printer.name, style: AppTypography.labelMedium),
                    subtitle: Text('Fixar impressões deste guichê nesta impressora', style: AppTypography.bodyMedium.copyWith(fontSize: 11)),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded, color: AppColors.primaryAzure)
                        : null,
                    onTap: () {
                      final urlToSave = printer.url.isNotEmpty ? printer.url : printer.name;
                      Navigator.of(ctx).pop();
                      LabelPrinterService.saveSelectedPrinterUrl(urlToSave).then((_) {
                        if (mounted) _loadPrinterStatus();
                      });
                    },
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    for (final s in _childrenSelections) {
      s.notesController.dispose();
    }
    super.dispose();
  }

  Future<void> _loadCheckInData() async {
    setState(() => _isLoading = true);
    try {
      final profile = await SupabaseService.instance.getProfile();
      final activeEvents = await SupabaseService.instance.getActiveEvents();
      final allClassrooms = await SupabaseService.instance.getClassrooms();
      final children = await SupabaseService.instance.getChildren();

      ChurchEventModel? currentEvent;
      List<ClassroomModel> openRooms = [];

      if (activeEvents.isNotEmpty) {
        currentEvent = activeEvents.first;
        final openIds = currentEvent.activeClassroomIds;
        openRooms = allClassrooms.where((c) => openIds.contains(c.id)).toList();
        if (openRooms.isEmpty && allClassrooms.isNotEmpty) {
          // Fallback caso nenhuma sala específica tenha sido filtrada
          openRooms = allClassrooms;
        }
      }

      _childrenSelections.clear();
      for (final child in children) {
        // Encontra a melhor sala com base na idade da criança:
        // Dá preferência para a sala correspondente à idade (ex: sala de 4 anos)
        // em vez da sala de inclusão (0-15 anos), que só será usada se o usuário selecionar.
        ClassroomModel? bestRoom;
        final age = child.ageYears;
        if (openRooms.isNotEmpty) {
          // 1. Prioriza salas regulares correspondentes à idade (excluindo 'Inclusão')
          final regularRooms = openRooms.where((r) {
            final lower = r.name.toLowerCase();
            return !lower.contains('inclus');
          }).toList();

          final ageMatchInRegular = regularRooms.where(
            (r) => age >= r.minAgeYears && age <= r.maxAgeYears,
          );

          if (ageMatchInRegular.isNotEmpty) {
            bestRoom = ageMatchInRegular.first;
          } else if (regularRooms.isNotEmpty) {
            bestRoom = regularRooms.first;
          } else {
            bestRoom = openRooms.first;
          }
        }

        _childrenSelections.add(
          _ChildSelectionState(
            child: child,
            isSelected: !child.isInClassroom, // Crianças já em sala começam desmarcadas
            selectedClassroom: bestRoom,
            hasBag: false, // Pertences deselecionados por padrão
            hasBottle: false, // O responsável seleciona manualmente se trouxe
            hasPacifier: false,
          ),
        );
      }

      if (mounted) {
        setState(() {
          _profile = profile;
          _activeEvent = currentEvent;
          _availableClassrooms = openRooms;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dados para check-in: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _handleConfirmCheckIn() async {
    final selectedItems = _childrenSelections.where((s) => s.isSelected).toList();

    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione ao menos 1 criança para realizar o check-in.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_activeEvent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhum evento ativo no momento para receber crianças.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    for (final item in selectedItems) {
      if (item.selectedClassroom == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Por favor, selecione a sala para ${item.child.fullName}.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      final guardianName = _profile?.fullName.trim().isNotEmpty == true
          ? _profile!.fullName.trim()
          : 'Responsável Duna Kids';

      final List<Map<String, dynamic>> checkInsPayload = selectedItems.map((item) {
        return {
          'child_id': item.child.id,
          'classroom_id': item.selectedClassroom!.id,
          'has_bag': item.hasBag,
          'has_bottle': item.hasBottle,
          'has_pacifier': item.hasPacifier,
          'belongings_notes': item.notesController.text.trim(),
        };
      }).toList();

      final results = await SupabaseService.instance.registerCheckInGroup(
        eventId: _activeEvent!.id,
        guardianName: guardianName,
        checkIns: checkInsPayload,
      );

      final securityCode = results.isNotEmpty ? results.first.securityCode : 'DK-${DateTime.now().millisecond}';
      final checkInTime = DateTime.now();

      final List<CheckInChildData> labelChildren = selectedItems.map((s) {
        return CheckInChildData(
          child: s.child,
          classroom: s.selectedClassroom!,
          hasBag: s.hasBag,
          hasBottle: s.hasBottle,
          hasPacifier: s.hasPacifier,
          belongingsNotes: s.notesController.text.trim(),
        );
      }).toList();

      if (mounted) {
        setState(() => _isSubmitting = false);

        // 1. Envia imediatamente o PDF com as etiquetas Brother DK-1201 para impressão
        try {
          await LabelPrinterService.printLabels(
            guardianName: guardianName,
            securityCode: securityCode,
            checkInTime: checkInTime,
            childrenData: labelChildren,
          );
        } catch (printError) {
          debugPrint('Aviso de impressão: $printError');
        }

        if (mounted) {
          // 2. Exibe o modal com a pré-visualização das etiquetas e comprovante do responsável com QR Code
          await LabelPreviewDialog.show(
            context,
            guardianName: guardianName,
            securityCode: securityCode,
            checkInTime: checkInTime,
            childrenData: labelChildren,
          );

          if (mounted) {
            // Atualiza dados após conclusão
            _loadCheckInData();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao registrar check-in: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Navbar Moderno com Menu Dropdown
            const AzureNavbar(
              title: 'Check-in Kids',
              currentRoute: '/checkin',
            ),

            // Conteúdo Principal
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(AppColors.primaryAzure),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadCheckInData,
                      color: AppColors.primaryAzure,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 640),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Banner do Evento Ativo
                                _buildEventStatusBanner(),
                                const SizedBox(height: 20),

                                // Lista de Crianças para Check-in
                                if (_childrenSelections.isEmpty)
                                  _buildEmptyChildrenCard()
                                else ...[
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'CRIANÇAS SOB SUA RESPONSABILIDADE',
                                        style: AppTypography.labelMedium.copyWith(
                                          fontSize: 12,
                                          color: AppColors.textMuted,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                      Text(
                                        '${_childrenSelections.where((s) => !s.child.isInClassroom && s.isSelected).length} de ${_childrenSelections.where((s) => !s.child.isInClassroom).length} disponível(is)',
                                        style: AppTypography.codeBadge.copyWith(fontSize: 11),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  ..._childrenSelections.map((selection) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 16),
                                      child: _buildChildCheckInCard(selection),
                                    );
                                  }),

                                  const SizedBox(height: 12),

                                  // Mensagem se todas já estiverem com check-in realizado
                                  if (_childrenSelections.isNotEmpty &&
                                      _childrenSelections.every((s) => s.child.isInClassroom)) ...[
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF0FDF4),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: const Color(0xFF86EFAC)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.check_circle_outline_rounded,
                                              color: Color(0xFF16A34A), size: 24),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              'Todas as crianças sob sua responsabilidade já estão com o check-in realizado.',
                                              style: AppTypography.bodyMedium.copyWith(
                                                color: const Color(0xFF166534),
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],

                                  // Botão de Confirmação e Impressão com Roteador de Impressoras
                                  if (_activeEvent != null &&
                                      _childrenSelections.any((s) => !s.child.isInClassroom)) ...[
                                    Center(child: _buildPrinterSelectorChip()),
                                    const SizedBox(height: 12),
                                    AzureButton(
                                      text: 'Realizar Check-in e Imprimir Etiquetas',
                                      icon: Icons.qr_code_scanner_rounded,
                                      isLoading: _isSubmitting,
                                      onPressed: _handleConfirmCheckIn,
                                    ),
                                  ],
                                  const SizedBox(height: 24),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrinterSelectorChip() {
    return InkWell(
      onTap: _showPrinterSelectorModal,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.azureLight.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primaryAzure.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.print_outlined, size: 16, color: AppColors.primaryAzure),
            const SizedBox(width: 8),
            Text(
              _selectedPrinterLabel,
              style: AppTypography.labelMedium.copyWith(
                fontSize: 12,
                color: AppColors.primaryAzure,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down_rounded, size: 18, color: AppColors.primaryAzure),
          ],
        ),
      ),
    );
  }

  /// Banner com status do evento atual
  Widget _buildEventStatusBanner() {
    if (_activeEvent == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.event_busy_rounded, color: Color(0xFFDC2626), size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nenhum Evento Ativo no Momento',
                    style: AppTypography.labelMedium.copyWith(
                      color: const Color(0xFF991B1B),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Para realizar check-in, um administrador precisa abrir o evento e liberar as salas.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: const Color(0xFFB91C1C),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF16A34A).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.event_available_rounded, color: Color(0xFF16A34A), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Recepção Aberta: ${_activeEvent!.name}',
                      style: AppTypography.labelMedium.copyWith(
                        color: const Color(0xFF15803D),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Horário: ${_activeEvent!.startTime} às ${_activeEvent!.endTime} • ${_availableClassrooms.length} sala(s) disponível(is)',
                  style: AppTypography.bodyMedium.copyWith(
                    color: const Color(0xFF166534),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Card para quando o tutor não possui crianças cadastradas ainda
  Widget _buildEmptyChildrenCard() {
    return AzureCard(
      child: Column(
        children: [
          const Icon(Icons.escalator_warning_outlined, color: AppColors.textMuted, size: 48),
          const SizedBox(height: 12),
          Text(
            'Nenhuma criança cadastrada',
            style: AppTypography.titleMedium.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            'Para fazer o check-in no Kids, primeiro cadastre os dados do seu filho(a) ou dependente em Meus Dados.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 18),
          AzureButton(
            text: 'Ir para Meus Dados',
            icon: Icons.person_add_alt_1_rounded,
            onPressed: () => Navigator.of(context).pushNamed('/meus-dados'),
          ),
        ],
      ),
    );
  }

  /// Card de seleção e configuração de pertences da criança
  Widget _buildChildCheckInCard(_ChildSelectionState state) {
    final child = state.child;
    final isInClassroom = child.isInClassroom;
    final isSelected = !isInClassroom && state.isSelected;

    return AzureCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header com Checkbox, Foto e Nome da Criança
          Row(
            children: [
              Checkbox(
                value: isInClassroom ? false : isSelected,
                activeColor: AppColors.primaryAzure,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                onChanged: isInClassroom
                    ? null
                    : (val) {
                        setState(() {
                          state.isSelected = val ?? false;
                        });
                      },
              ),
              const SizedBox(width: 4),

              // Avatar
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.azureLight,
                  border: Border.all(
                    color: isInClassroom
                        ? const Color(0xFF16A34A).withValues(alpha: 0.4)
                        : AppColors.primaryAzure.withValues(alpha: 0.3),
                  ),
                ),
                child: ClipOval(
                  child: (child.photoUrl != null && child.photoUrl!.isNotEmpty)
                      ? Image.network(
                          child.photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _initials(child.fullName),
                        )
                      : _initials(child.fullName),
                ),
              ),
              const SizedBox(width: 12),

              // Nome, Idade e Status de Sala
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      child.fullName,
                      style: AppTypography.titleMedium.copyWith(fontSize: 15),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '${child.ageYears} anos',
                          style: AppTypography.bodyMedium.copyWith(fontSize: 12),
                        ),
                        if (isInClassroom)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF86EFAC)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('🟢 ', style: TextStyle(fontSize: 9)),
                                Text(
                                  'Check-in Realizado',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF166534),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSubtle,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Text(
                              'Check-in não realizado',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        if (child.inclusionLaw13146)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.5)),
                            ),
                            child: const Text(
                              'Lei 13.146/15',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFB45309),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (isInClassroom) ...[
            const Divider(height: 20, color: AppColors.border),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Check-in já realizado',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF15803D),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Esta criança já está com check-in realizado. Não é possível registrar uma nova entrada até que seja feito o check-out.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.green.shade900.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else if (isSelected) ...[
            const Divider(height: 24, color: AppColors.border),

            // Seleção de Sala/Turma Disponível
            Text(
              'Sala / Turma no Kids',
              style: AppTypography.labelMedium.copyWith(fontSize: 12),
            ),
            const SizedBox(height: 8),

            if (_availableClassrooms.isEmpty)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Nenhuma sala disponível no momento.',
                  style: AppTypography.bodyMedium.copyWith(fontSize: 12),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<ClassroomModel>(
                    value: state.selectedClassroom,
                    isExpanded: true,
                    hint: const Text('Selecione a sala'),
                    items: _availableClassrooms.map((room) {
                      final isInclusion = room.name.toLowerCase().contains('inclus');
                      final isAgeMatch = !isInclusion &&
                          child.ageYears >= room.minAgeYears &&
                          child.ageYears <= room.maxAgeYears;

                      String tag = room.ageRangeFormatted;
                      if (isAgeMatch) {
                        tag = '${room.ageRangeFormatted} • Recomendada por idade';
                      } else if (isInclusion) {
                        tag = 'Sala de Inclusão (Opcional)';
                      }

                      return DropdownMenuItem<ClassroomModel>(
                        value: room,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(room.name, style: AppTypography.labelMedium),
                            Text(
                              tag,
                              style: TextStyle(
                                fontSize: 11,
                                color: isAgeMatch
                                    ? const Color(0xFF16A34A)
                                    : (isInclusion ? const Color(0xFF9333EA) : AppColors.textMuted),
                                fontWeight: isAgeMatch ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (room) {
                      setState(() {
                        state.selectedClassroom = room;
                      });
                    },
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Pertences que a criança trouxe (Bolsa, Mamadeira, Chupeta)
            Text(
              'Pertences com a Criança (serão impressos na etiqueta)',
              style: AppTypography.labelMedium.copyWith(fontSize: 12),
            ),
            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildBelongingChip(
                  label: '👜 Bolsa',
                  isSelected: state.hasBag,
                  onSelected: (val) => setState(() => state.hasBag = val),
                ),
                _buildBelongingChip(
                  label: '🍼 Mamadeira',
                  isSelected: state.hasBottle,
                  onSelected: (val) => setState(() => state.hasBottle = val),
                ),
                _buildBelongingChip(
                  label: '👶 Chupeta',
                  isSelected: state.hasPacifier,
                  onSelected: (val) => setState(() => state.hasPacifier = val),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Outro pertence / observação rápida
            TextField(
              controller: state.notesController,
              decoration: InputDecoration(
                hintText: 'Outro pertence ou observação (ex: casaco azul)...',
                hintStyle: AppTypography.bodyMedium.copyWith(fontSize: 12),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                filled: true,
                fillColor: AppColors.surfaceSubtle,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
              style: AppTypography.bodyMedium.copyWith(fontSize: 13),
            ),

            // Alerta de Restrições Médicas/Alimentares se houver
            if ((child.allergies != null && child.allergies!.isNotEmpty) || child.notes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Restrições: ${[child.allergies ?? '', child.notes].where((s) => s.isNotEmpty).join(" • ")}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF991B1B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildBelongingChip({
    required String label,
    required bool isSelected,
    required ValueChanged<bool> onSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: AppColors.azureLight,
      checkmarkColor: AppColors.primaryAzure,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? AppColors.primaryAzure : AppColors.textPrimary,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? AppColors.primaryAzure : AppColors.border,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      backgroundColor: AppColors.surface,
    );
  }

  Widget _initials(String name) {
    final initials = name.trim().isNotEmpty
        ? name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : 'DK';
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}
