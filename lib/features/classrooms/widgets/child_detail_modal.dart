import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/azure_button.dart';
import '../../../core/widgets/top_toast.dart';
import '../../children/models/authorized_guardian_model.dart';
import '../models/attendance_model.dart';
import '../models/classroom_model.dart';

class ChildDetailModal extends StatefulWidget {
  final AttendanceModel attendance;
  final ClassroomModel classroom;
  final VoidCallback onCheckOutRequested;

  const ChildDetailModal({
    super.key,
    required this.attendance,
    required this.classroom,
    required this.onCheckOutRequested,
  });

  static Future<void> show(
    BuildContext context, {
    required AttendanceModel attendance,
    required ClassroomModel classroom,
    required VoidCallback onCheckOutRequested,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ChildDetailModal(
        attendance: attendance,
        classroom: classroom,
        onCheckOutRequested: onCheckOutRequested,
      ),
    );
  }

  @override
  State<ChildDetailModal> createState() => _ChildDetailModalState();
}

class _ChildDetailModalState extends State<ChildDetailModal> {
  final DateFormat _timeFormat = DateFormat('HH:mm');
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final TextEditingController _customMessageController = TextEditingController();

  GuardianContactInfo? _guardianInfo;
  List<AuthorizedGuardianModel> _authorizedGuardians = [];
  bool _isLoadingGuardian = true;
  bool _isSendingNotification = false;
  String _selectedQuickNotice = 'Favor comparecer ao Kids';

  final List<Map<String, String>> _quickNotices = [
    {
      'label': 'Favor comparecer ao Kids',
      'title': 'Aviso do Kids',
      'msg': 'Favor comparecer ao Kids.',
    },
    {
      'label': 'Hora da mamadeira / Fome',
      'title': 'Aviso do Kids',
      'msg': 'Hora da mamadeira / alimentação.',
    },
    {
      'label': 'Troca de fralda necessária',
      'title': 'Aviso do Kids',
      'msg': 'Troca de fralda necessária.',
    },
    {
      'label': 'Chorando / Acolhimento',
      'title': 'Aviso do Kids',
      'msg': 'A criança solicita o carinho e acolhimento do responsável.',
    },
    {
      'label': 'Outro motivo',
      'title': 'Aviso do Kids',
      'msg': '',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadGuardianDetails();
  }

  @override
  void dispose() {
    _customMessageController.dispose();
    super.dispose();
  }

  Future<void> _loadGuardianDetails() async {
    final childId = widget.attendance.childId;
    final fallbackName = widget.attendance.checkedInByGuardianName;

    try {
      final results = await Future.wait([
        SupabaseService.instance.getGuardianContactForChild(
          childId,
          fallbackName: fallbackName,
        ),
        SupabaseService.instance.getAuthorizedGuardiansForChild(childId),
      ]);

      if (mounted) {
        setState(() {
          _guardianInfo = results[0] as GuardianContactInfo?;
          _authorizedGuardians = results[1] as List<AuthorizedGuardianModel>;
          _isLoadingGuardian = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingGuardian = false);
      }
    }
  }

  Future<void> _handleOpenWhatsAppFor(String phone, String guardianName, {String? customMessage}) async {
    final clean = phone.replaceAll(RegExp(r'\D'), '');
    if (clean.isEmpty) {
      TopToast.showError(context, 'Número de WhatsApp não informado para este responsável.');
      return;
    }

    String formatted = clean;
    if (formatted.length == 10 || formatted.length == 11) {
      formatted = '55$formatted';
    }

    final childName = widget.attendance.child?.fullName ?? 'sua criança';
    final roomName = widget.classroom.name;
    final noticeText = customMessage ?? _getSelectedMessageText();

    final fullMessage = 'Olá $guardianName! Aqui é da equipe do *Duna Kids* (Sala: $roomName).\n\n'
        'Entramos em contato sobre *$childName*:\n'
        '👉 *$noticeText*';

    final encodedMsg = Uri.encodeComponent(fullMessage);
    final waUri = Uri.parse('https://wa.me/$formatted?text=$encodedMsg');

    try {
      if (await canLaunchUrl(waUri)) {
        await launchUrl(waUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(waUri);
      }
    } catch (e) {
      if (mounted) {
        TopToast.showError(context, 'Erro ao abrir o WhatsApp: $e');
      }
    }
  }

  Future<void> _handleCallPhone(String phoneNumber) async {
    final clean = phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (clean.isEmpty) {
      TopToast.showError(context, 'Número de telefone não informado para este responsável.');
      return;
    }

    final uri = Uri.parse('tel:$clean');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        TopToast.showError(context, 'Não foi possível iniciar a ligação: $e');
      }
    }
  }

  Future<void> _handleOpenWhatsApp({String? customMessage}) async {
    final rawPhone = _guardianInfo?.formattedWhatsAppNumber ?? '';
    if (rawPhone.isEmpty) {
      TopToast.showError(context, 'Número de WhatsApp não disponível para este responsável.');
      return;
    }

    final childName = widget.attendance.child?.fullName ?? 'sua criança';
    final roomName = widget.classroom.name;
    final noticeText = customMessage ?? _getSelectedMessageText();

    final fullMessage = 'Olá ${_guardianInfo?.name ?? "Responsável"}! Aqui é da equipe do *Duna Kids* (Sala: $roomName).\n\n'
        'Entramos em contato sobre *$childName*:\n'
        '👉 *$noticeText*';

    final encodedMsg = Uri.encodeComponent(fullMessage);
    final waUri = Uri.parse('https://wa.me/$rawPhone?text=$encodedMsg');

    try {
      if (await canLaunchUrl(waUri)) {
        await launchUrl(waUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(waUri);
      }
    } catch (e) {
      if (mounted) {
        TopToast.showError(context, 'Erro ao abrir o WhatsApp: $e');
      }
    }
  }

  String _getSelectedMessageText() {
    if (_selectedQuickNotice == 'Outro motivo') {
      return _customMessageController.text.trim().isNotEmpty
          ? _customMessageController.text.trim()
          : 'Favor comparecer ao Kids.';
    }
    final match = _quickNotices.firstWhere(
      (n) => n['label'] == _selectedQuickNotice,
      orElse: () => _quickNotices.first,
    );
    final extra = _customMessageController.text.trim();
    if (extra.isNotEmpty) {
      return '${match["msg"]} (Obs: $extra)';
    }
    return match['msg']!;
  }

  String _getSelectedTitle() {
    final match = _quickNotices.firstWhere(
      (n) => n['label'] == _selectedQuickNotice,
      orElse: () => _quickNotices.first,
    );
    return match['title'] ?? 'Aviso Duna Kids';
  }

  Future<void> _handleSendAppNotification() async {
    final child = widget.attendance.child;
    final childName = child?.fullName ?? 'Criança';
    final message = _getSelectedMessageText();
    final title = _getSelectedTitle();

    setState(() => _isSendingNotification = true);

    try {
      await SupabaseService.instance.sendKidNotification(
        guardianUserId: _guardianInfo?.userId,
        childId: widget.attendance.childId,
        childName: childName,
        classroomId: widget.classroom.id,
        classroomName: widget.classroom.name,
        eventId: widget.attendance.eventId,
        title: title,
        message: message,
      );

      if (mounted) {
        setState(() => _isSendingNotification = false);

        // Exibe confirmação com destaque no TOPO DA TELA (visível acima da caixa / modal)
        TopToast.showSuccess(
          context,
          'Notificação enviada ao responsável de $childName!',
        );

        // Opção conveniente de também enviar via WhatsApp se desejar
        if (_guardianInfo?.formattedWhatsAppNumber.isNotEmpty == true) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              _showWhatsAppPromptModal(message);
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSendingNotification = false);
        TopToast.showError(context, 'Erro ao enviar notificação: $e');
      }
    }
  }

  void _showWhatsAppPromptModal(String messageText) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.mark_chat_unread_rounded, color: Color(0xFF25D366)),
            SizedBox(width: 8),
            Text('Disparar no WhatsApp?'),
          ],
        ),
        content: const Text(
          'A notificação foi salva no app Duna Kids. Deseja também enviar a mensagem agora diretamente pelo WhatsApp do responsável?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Apenas no App', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.send_rounded, size: 16),
            label: const Text('Abrir WhatsApp'),
            onPressed: () {
              Navigator.of(ctx).pop();
              _handleOpenWhatsApp(customMessage: messageText);
            },
          ),
        ],
      ),
    );
  }

  void _showEnlargedPhoto(String? photoUrl, String childName) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420, maxHeight: 520),
                color: Colors.black,
                child: (photoUrl != null && photoUrl.isNotEmpty)
                    ? Image.network(
                        photoUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (c, e, s) => _buildPlaceholderPhoto(childName, size: 200),
                      )
                    : _buildPlaceholderPhoto(childName, size: 200),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: InkWell(
                onTap: () => Navigator.of(ctx).pop(),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderPhoto(String name, {double size = 120}) {
    final initials = name.trim().isNotEmpty
        ? name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : 'DK';
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: size * 0.35),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.attendance.child;
    final childName = child?.fullName ?? 'Criança';
    final ageText = child?.ageFormatted ?? 'Idade não informada';
    final photoUrl = child?.photoUrl;
    final hasInclusion = child?.inclusionLaw13146 == true;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Barra de Arraste superior
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),

          // Header com Título e Fechar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(color: widget.classroom.color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Ficha da Criança • ${widget.classroom.name}',
                      style: AppTypography.titleMedium.copyWith(fontSize: 15),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Conteúdo com Scroll
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ============================================
                  // SEÇÃO 1: FOTO AUMENTADA E DADOS DA CRIANÇA
                  // ============================================
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () => _showEnlargedPhoto(photoUrl, childName),
                          child: Stack(
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.azureLight,
                                  border: Border.all(
                                    color: AppColors.primaryAzure.withValues(alpha: 0.4),
                                    width: 3.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryAzure.withValues(alpha: 0.18),
                                      blurRadius: 18,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: (photoUrl != null && photoUrl.isNotEmpty)
                                      ? Image.network(
                                          photoUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (c, e, s) => _buildPlaceholderPhoto(childName),
                                        )
                                      : _buildPlaceholderPhoto(childName),
                                ),
                              ),
                              Positioned(
                                bottom: 2,
                                right: 2,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primaryAzure,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 18),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          childName,
                          textAlign: TextAlign.center,
                          style: AppTypography.titleLarge.copyWith(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(ageText, style: AppTypography.bodyMedium),
                            if (child?.birthDate != null)
                              Text(
                                '• Nasc: ${_dateFormat.format(child!.birthDate)}',
                                style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
                              ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFF86EFAC)),
                              ),
                              child: const Text(
                                '🟢 Check-in Realizado',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF166534),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Check-in às ${_timeFormat.format(widget.attendance.checkInTime.toLocal())} • Código: ${widget.attendance.securityCode}',
                          style: AppTypography.codeBadge.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Inclusão - Lei 13.146/15 se houver
                  if (hasInclusion) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E8FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF9333EA).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.accessibility_new_rounded, size: 22, color: Color(0xFF9333EA)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Criança sob a Lei nº 13.146/2015 (Inclusão)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF9333EA),
                                  ),
                                ),
                                if (child != null && child.inclusionDetails != null && child.inclusionDetails!.isNotEmpty)
                                  Text(
                                    child.inclusionDetails!,
                                    style: AppTypography.bodyMedium.copyWith(fontSize: 12),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Alergias e Cuidados Médicos
                  if ((child?.allergies != null && child!.allergies!.isNotEmpty) ||
                      (child?.notes != null && child!.notes.isNotEmpty)) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, size: 22, color: Color(0xFFDC2626)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Restrições Médicas / Alergias',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  [child.allergies ?? '', child.notes]
                                      .where((s) => s.isNotEmpty)
                                      .join(' • '),
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF7F1D1D)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Pertences trazidos no Check-in
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pertences Identificados no Check-in', style: AppTypography.labelMedium.copyWith(fontSize: 12)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            if (widget.attendance.hasBag)
                              _buildPertenceBadge('👜 Bolsa Entregue', const Color(0xFFEFF6FF), AppColors.primaryAzure),
                            if (widget.attendance.hasBottle)
                              _buildPertenceBadge('🍼 Mamadeira', const Color(0xFFFDF4FF), const Color(0xFFC026D3)),
                            if (widget.attendance.hasPacifier)
                              _buildPertenceBadge('👶 Chupeta', const Color(0xFFFFFBEB), const Color(0xFFD97706)),
                            if (!widget.attendance.hasBag && !widget.attendance.hasBottle && !widget.attendance.hasPacifier)
                              const Text('Nenhum pertence específico registrado.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          ],
                        ),
                        if (widget.attendance.belongingsNotes.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Obs: ${widget.attendance.belongingsNotes}',
                            style: AppTypography.bodyMedium.copyWith(fontSize: 11, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ============================================
                  // SEÇÃO 2: DADOS DO RESPONSÁVEL & CONTATO
                  // ============================================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'RESPONSÁVEL PELA CRIANÇA',
                        style: AppTypography.labelMedium.copyWith(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          letterSpacing: 0.8,
                        ),
                      ),
                      if (_guardianInfo?.role.isNotEmpty == true)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.azureLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _guardianInfo!.role,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryAzure),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  _isLoadingGuardian
                      ? const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(strokeWidth: 2)))
                      : Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border, width: 1.2),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 3)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppColors.azureLight,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppColors.primaryAzure.withValues(alpha: 0.3)),
                                    ),
                                    child: const Icon(Icons.person_rounded, color: AppColors.primaryAzure, size: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _guardianInfo?.name ?? widget.attendance.checkedInByGuardianName,
                                          style: AppTypography.titleMedium.copyWith(fontSize: 15),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _guardianInfo?.phone.isNotEmpty == true
                                              ? _guardianInfo!.phone
                                              : 'Telefone não cadastrado',
                                          style: AppTypography.bodyMedium.copyWith(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: _guardianInfo?.phone.isNotEmpty == true
                                                ? AppColors.textPrimary
                                                : AppColors.textMuted,
                                          ),
                                        ),
                                        if (_guardianInfo?.email.isNotEmpty == true)
                                          Text(
                                            _guardianInfo!.email,
                                            style: AppTypography.bodyMedium.copyWith(fontSize: 11, color: AppColors.textMuted),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              // Botões de Ação Direta: WhatsApp e Ligar
                              Row(
                                children: [
                                  // Botão WhatsApp
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF25D366),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(vertical: 11),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                                      label: const Text(
                                        'WhatsApp',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      onPressed: (_guardianInfo?.cleanPhoneNumber.isNotEmpty == true)
                                          ? () => _handleOpenWhatsApp()
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // Botão Ligar
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primaryAzure,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(vertical: 11),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      icon: const Icon(Icons.phone_in_talk_rounded, size: 18),
                                      label: const Text(
                                        'Ligar',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      onPressed: (_guardianInfo?.cleanPhoneNumber.isNotEmpty == true)
                                          ? () => _handleCallPhone(_guardianInfo!.phone)
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                  // ============================================
                  // SEÇÃO: PESSOAS AUTORIZADAS PARA RETIRADA
                  // ============================================
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.verified_user_rounded, color: Color(0xFF059669), size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'PESSOAS AUTORIZADAS A RETIRAR',
                            style: AppTypography.labelMedium.copyWith(
                              fontSize: 12,
                              color: AppColors.textMuted,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF86EFAC)),
                        ),
                        child: Text(
                          '${_authorizedGuardians.length} cadastrada(s)',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF059669),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (_authorizedGuardians.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline_rounded, size: 18, color: AppColors.textMuted),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Apenas o responsável titular está cadastrado para check-in e retirada desta criança.',
                              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._authorizedGuardians.map((g) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildAuthorizedGuardianCard(g),
                        )),

                  const SizedBox(height: 24),

                  // ============================================
                  // SEÇÃO 3: ENVIAR NOTIFICAÇÃO AO RESPONSÁVEL
                  // ============================================
                  Row(
                    children: [
                      const Icon(Icons.notifications_active_outlined, color: AppColors.primaryAzure, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'ENVIAR NOTIFICAÇÃO AO PAI / RESPONSÁVEL',
                        style: AppTypography.labelMedium.copyWith(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Escolha o aviso rápido:', style: AppTypography.labelMedium.copyWith(fontSize: 12)),
                        const SizedBox(height: 8),

                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _quickNotices.map((notice) {
                            final label = notice['label']!;
                            final isSelected = _selectedQuickNotice == label;
                            return ChoiceChip(
                              label: Text(label),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => _selectedQuickNotice = label);
                                }
                              },
                              selectedColor: AppColors.azureLight,
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
                          }).toList(),
                        ),
                        const SizedBox(height: 12),

                        // Campo de Mensagem personalizada / observação
                        TextField(
                          controller: _customMessageController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: _selectedQuickNotice == 'Outro motivo'
                                ? 'Digite a mensagem para o responsável...'
                                : 'Observação adicional (opcional)...',
                            hintStyle: AppTypography.bodyMedium.copyWith(fontSize: 12),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            filled: true,
                            fillColor: AppColors.surface,
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
                        const SizedBox(height: 14),

                        // Botão Enviar Notificação
                        AzureButton(
                          text: 'Enviar Notificação no App',
                          icon: Icons.send_rounded,
                          isLoading: _isSendingNotification,
                          onPressed: _handleSendAppNotification,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ============================================
                  // SEÇÃO 4: BOTÃO DE CHECK-OUT / SAÍDA DA SALA
                  // ============================================
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Registrar Saída (Check-out)', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onCheckOutRequested();
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPertenceBadge(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: text.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: text),
      ),
    );
  }

  Widget _buildAuthorizedGuardianCard(AuthorizedGuardianModel guardian) {
    final initials = guardian.name.trim().isNotEmpty
        ? guardian.name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : 'AP';
    final hasPhone = guardian.phone != null && guardian.phone!.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: guardian.canCheckout ? const Color(0xFF86EFAC) : AppColors.border,
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.azureLight,
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryAzure,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            guardian.name,
                            style: AppTypography.titleMedium.copyWith(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSubtle,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            guardian.relationshipFormatted,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (guardian.canCheckout)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              '✓ Autorizado a Retirar',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              '✕ Não pode retirar',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
                            ),
                          ),
                        if (guardian.canCheckin)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.azureLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Pode Check-in',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primaryAzure),
                            ),
                          ),
                        if (guardian.isRegisteredAppUser)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3E8FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'App Vinculado',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF9333EA)),
                            ),
                          ),
                      ],
                    ),
                    if (hasPhone) ...[
                      const SizedBox(height: 4),
                      Text(
                        guardian.phone!,
                        style: AppTypography.bodyMedium.copyWith(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          if (hasPhone) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 15),
                    label: const Text('WhatsApp', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () => _handleOpenWhatsAppFor(guardian.phone!, guardian.name),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryAzure,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.phone_in_talk_rounded, size: 15),
                    label: const Text('Ligar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () => _handleCallPhone(guardian.phone!),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
