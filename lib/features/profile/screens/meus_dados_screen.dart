import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/azure_button.dart';
import '../../../core/widgets/azure_card.dart';
import '../../../core/widgets/azure_confirm_dialog.dart';
import '../../../core/widgets/azure_navbar.dart';
import '../../../core/widgets/azure_text_field.dart';
import '../../../core/widgets/top_toast.dart';
import '../../children/models/child_model.dart';
import '../../children/widgets/child_form_dialog.dart';
import '../../children/widgets/authorized_guardians_dialog.dart';
import '../../classrooms/models/kid_notification_model.dart';
import '../../classrooms/screens/classrooms_screen.dart';
import '../../classrooms/widgets/notifications_sheet.dart';
import '../../events/models/church_event_model.dart';
import '../../events/screens/events_screen.dart';
import '../models/user_profile_model.dart';

class MeusDadosScreen extends StatefulWidget {
  const MeusDadosScreen({super.key});

  @override
  State<MeusDadosScreen> createState() => _MeusDadosScreenState();
}

class _MeusDadosScreenState extends State<MeusDadosScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  DateTime? _selectedBirthDate;
  String? _gender = 'responsavel';
  bool _isTeacher = false;
  bool _isAdmin = false;

  String? _avatarUrl;
  Uint8List? _localAvatarBytes;

  List<ChildModel> _children = [];
  ChurchEventModel? _currentActiveEvent;
  List<KidNotificationModel> _unreadNotifications = [];

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;

  final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final profile = await SupabaseService.instance.getProfile();
      final children = await SupabaseService.instance.getChildren();
      final activeEvents = await SupabaseService.instance.getActiveEvents();

      List<KidNotificationModel> unread = [];
      try {
        final allNotifs = await SupabaseService.instance.getKidNotificationsForCurrentGuardian();
        unread = allNotifs.where((n) => !n.isRead).toList();
      } catch (_) {}

      if (mounted) {
        setState(() {
          _nameController.text = profile.fullName;
          _emailController.text = profile.email;
          _phoneController.text = profile.phone;
          _selectedBirthDate = profile.birthDate;
          _gender = profile.gender ?? 'responsavel';
          _isTeacher = profile.isTeacher;
          _isAdmin = profile.isAdmin;
          _avatarUrl = profile.avatarUrl;
          _children = children;
          _currentActiveEvent = activeEvents.isNotEmpty ? activeEvents.first : null;
          _unreadNotifications = unread;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dados: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onPhoneChanged(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    String formatted = digits;

    if (digits.length > 11) {
      formatted = digits.substring(0, 11);
    }

    if (formatted.length >= 11) {
      formatted = '(${formatted.substring(0, 2)}) ${formatted.substring(2, 7)}-${formatted.substring(7)}';
    } else if (formatted.length >= 7) {
      formatted = '(${formatted.substring(0, 2)}) ${formatted.substring(2, 6)}-${formatted.substring(6)}';
    } else if (formatted.length >= 3) {
      formatted = '(${formatted.substring(0, 2)}) ${formatted.substring(2)}';
    }

    if (formatted != value) {
      _phoneController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final initial = _selectedBirthDate ?? DateTime(now.year - 25, now.month, now.day);
    final first = DateTime(1920);
    final last = now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      helpText: 'SUA DATA DE NASCIMENTO',
      cancelText: 'CANCELAR',
      confirmText: 'CONFIRMAR',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryAzure,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedBirthDate = picked);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.of(context).pop();
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final ext = picked.name.split('.').last;

        setState(() {
          _localAvatarBytes = bytes;
          _isUploadingPhoto = true;
        });

        try {
          final uploadedUrl = await SupabaseService.instance.uploadAvatar(
            bytes: bytes,
            fileExtension: ext,
          );
          if (mounted) {
            setState(() {
              _avatarUrl = uploadedUrl;
              _isUploadingPhoto = false;
            });
          }
        } catch (_) {
          if (mounted) {
            setState(() => _isUploadingPhoto = false);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao selecionar foto: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showImagePickerModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
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
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text('Foto do Perfil', style: AppTypography.titleMedium, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.azureLight, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.camera_alt_outlined, color: AppColors.primaryAzure),
                ),
                title: Text('Tirar foto com a câmera', style: AppTypography.labelMedium),
                onTap: () => _pickImage(ImageSource.camera),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.azureLight, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.photo_library_outlined, color: AppColors.primaryAzure),
                ),
                title: Text('Escolher da galeria', style: AppTypography.labelMedium),
                onTap: () => _pickImage(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isSaving = true);

      try {
        await SupabaseService.instance.updateProfile(
          fullName: _nameController.text,
          phone: _phoneController.text,
          birthDate: _selectedBirthDate,
          gender: _gender,
          avatarUrl: _avatarUrl,
          isTeacher: _isTeacher,
          isAdmin: _isAdmin,
        );

        if (mounted) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Dados salvos com sucesso!'),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  Future<void> _openChildDialog([ChildModel? child]) async {
    final result = await ChildFormDialog.show(context, child: child);
    if (result != null) {
      final updatedList = await SupabaseService.instance.getChildren();
      setState(() {
        _children = updatedList;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              child == null ? 'Criança cadastrada com sucesso!' : 'Dados da criança atualizados!',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _handleDeleteChild(ChildModel child) async {
    final confirm = await AzureConfirmDialog.show(
      context,
      title: 'Excluir Criança',
      message: 'Deseja realmente remover o cadastro de ${child.fullName}? O histórico e as autorizações também serão removidos.',
      confirmText: 'Sim, Excluir',
      cancelText: 'Cancelar',
      isDestructive: true,
      icon: Icons.delete_forever_rounded,
    );

    if (confirm) {
      await SupabaseService.instance.deleteChild(child.id);
      final updatedList = await SupabaseService.instance.getChildren();
      setState(() {
        _children = updatedList;
      });
      if (mounted) {
        TopToast.showSuccess(context, 'Cadastro de ${child.fullName} removido.');
      }
    }
  }

  List<String> _calculateActiveRoles() {
    final profile = UserProfileModel(
      id: '',
      fullName: _nameController.text,
      email: _emailController.text,
      gender: _gender,
      isTeacher: _isTeacher,
      isAdmin: _isAdmin,
    );
    return profile.getRoles(childrenCount: _children.length);
  }

  @override
  Widget build(BuildContext context) {
    final activeRoles = _calculateActiveRoles();

    return Scaffold(
      appBar: const AzureNavbar(
        title: 'Meus Dados',
        currentRoute: '/meus-dados',
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryAzure))
            : Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Avatar e Níveis de Acesso
                        _buildAvatarSection(),
                        const SizedBox(height: 14),

                        // Badges dos Níveis de Acesso do Usuário
                        _buildRolesBadges(activeRoles),
                        const SizedBox(height: 18),

                        // Banner de Avisos Não Lidos do Kids (Chamadas Urgentes)
                        if (_unreadNotifications.isNotEmpty) ...[
                          _buildUnreadNotificationsBanner(),
                          const SizedBox(height: 14),
                        ],

                        // Card Informativo do Evento Ativo no Momento
                        _buildActiveEventStatusCard(),
                        const SizedBox(height: 14),

                        // Banner de Check-in Rápido
                        _buildCheckInBanner(),
                        const SizedBox(height: 14),

                        // Atalhos de Acesso Rápido aos Módulos (Turmas & Eventos) - APENAS Professores e Administradores
                        if (_isTeacher || _isAdmin) ...[
                          _buildModulesNavigationCard(),
                          const SizedBox(height: 14),
                        ],
                        const SizedBox(height: 10),

                        // Formulário de Dados Pessoais
                        _buildPersonalDataCard(),
                        const SizedBox(height: 24),

                        // Seção de Gestão de Crianças (Filhos)
                        _buildChildrenSection(),
                        const SizedBox(height: 24),

                        // Seção de Permissões / Níveis Adicionais (Apenas Administrador pode ver e gerenciar)
                        if (_isAdmin) ...[
                          _buildPermissionsCard(),
                          const SizedBox(height: 28),
                        ],

                        // Botão Salvar Geral
                        AzureButton(
                          text: 'Salvar Alterações',
                          icon: Icons.save_outlined,
                          isLoading: _isSaving,
                          onPressed: _handleSave,
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    final nameInitials = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : 'US';

    return Center(
      child: Stack(
        children: [
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryAzure.withValues(alpha: 0.25), width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryAzure.withValues(alpha: 0.15),
                  offset: const Offset(0, 8),
                  blurRadius: 18,
                ),
              ],
            ),
            child: ClipOval(
              child: _localAvatarBytes != null
                  ? Image.memory(_localAvatarBytes!, fit: BoxFit.cover)
                  : (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                      ? Image.network(
                          _avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildInitialsAvatar(nameInitials),
                        )
                      : _buildInitialsAvatar(nameInitials),
            ),
          ),
          if (_isUploadingPhoto)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), shape: BoxShape.circle),
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _showImagePickerModal,
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialsAvatar(String initials) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: Center(
        child: Text(
          initials,
          style: AppTypography.displayLarge.copyWith(color: Colors.white, fontSize: 30),
        ),
      ),
    );
  }

  Widget _buildRolesBadges(List<String> roles) {
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: roles.map((role) {
            final isParent = role == 'Pai' || role == 'Mãe';
            final isTeacher = role.contains('Professor');
            final isAdmin = role.contains('Administrador');

            Color bgColor = AppColors.azureLight;
            Color textColor = AppColors.primaryAzure;
            IconData icon = Icons.person_rounded;

            if (isParent) {
              bgColor = const Color(0xFFF3E8FF); // Roxo suave modern tech
              textColor = const Color(0xFF9333EA);
              icon = Icons.family_restroom_rounded;
            } else if (isTeacher) {
              bgColor = const Color(0xFFECFDF5); // Verde suave
              textColor = const Color(0xFF059669);
              icon = Icons.school_rounded;
            } else if (isAdmin) {
              bgColor = const Color(0xFFFEF3C7); // Âmbar suave
              textColor = const Color(0xFFD97706);
              icon = Icons.shield_rounded;
            }

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: textColor.withValues(alpha: 0.25), width: 1.2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: textColor, size: 15),
                  const SizedBox(width: 6),
                  Text(
                    role,
                    style: AppTypography.labelMedium.copyWith(
                      color: textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActiveEventStatusCard() {
    final hasActive = _currentActiveEvent != null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: hasActive ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasActive ? const Color(0xFF86EFAC) : AppColors.border,
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: hasActive
                  ? const Color(0xFF16A34A).withValues(alpha: 0.15)
                  : AppColors.border.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasActive ? Icons.event_available_rounded : Icons.event_busy_rounded,
              color: hasActive ? const Color(0xFF16A34A) : AppColors.textMuted,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      hasActive ? 'Recepção Kids Aberta' : 'Recepção Kids Fechada',
                      style: AppTypography.labelMedium.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: hasActive ? const Color(0xFF15803D) : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: hasActive ? const Color(0xFF16A34A) : AppColors.textMuted,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        hasActive ? 'ATIVO' : 'AGUARDANDO',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  hasActive
                      ? '${_currentActiveEvent!.name} • ${_currentActiveEvent!.startTime} às ${_currentActiveEvent!.endTime}'
                      : 'Nenhum evento ativo no momento para entrega de crianças.',
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 11.5,
                    color: hasActive ? const Color(0xFF166534) : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnreadNotificationsBanner() {
    if (_unreadNotifications.isEmpty) return const SizedBox.shrink();

    final latest = _unreadNotifications.first;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF), // Azul suave amigável
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryAzure.withValues(alpha: 0.35), width: 1.3),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryAzure.withValues(alpha: 0.08),
            offset: const Offset(0, 4),
            blurRadius: 14,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryAzure.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.notifications_active_rounded, color: AppColors.primaryAzure, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'AVISO DO DUNA KIDS',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.primaryAzure,
                            fontWeight: FontWeight.bold,
                            fontSize: 11.5,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryAzure,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_unreadNotifications.length} aviso(s)',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      latest.title,
                      style: AppTypography.titleMedium.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            latest.message,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (latest.childName != null || latest.classroomName != null) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                if (latest.childName != null)
                  Text(
                    'Criança: ${latest.childName}',
                    style: const TextStyle(fontSize: 11.5, color: AppColors.primaryAzure, fontWeight: FontWeight.w600),
                  ),
                if (latest.classroomName != null)
                  Text(
                    '• Sala: ${latest.classroomName}',
                    style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryAzure,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.mark_email_read_rounded, size: 16),
            label: const Text('Ver Aviso e Confirmar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            onPressed: () async {
              await NotificationsSheet.show(context);
              _loadAllData();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCheckInBanner() {
    return InkWell(
      onTap: () => Navigator.of(context).pushNamed('/checkin'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF007FFF), Color(0xFF0052CC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryAzure.withValues(alpha: 0.25),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Check-in Kids',
                        style: AppTypography.titleMedium.copyWith(color: Colors.white, fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Recepção',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Entregar crianças e imprimir etiquetas Brother DK-1201',
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildModulesNavigationCard() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const ClassroomsScreen()),
            ),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.azureLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.meeting_room_rounded, color: AppColors.primaryAzure, size: 20),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('Gestão de Turmas', style: AppTypography.labelMedium.copyWith(fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(
                    'Salas & Alunos',
                    style: AppTypography.bodyMedium.copyWith(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const EventsScreen()),
            ),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.calendar_month_rounded, color: Color(0xFF0284C7), size: 20),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('Gestão de Eventos', style: AppTypography.labelMedium.copyWith(fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(
                    'Abertura de Salas',
                    style: AppTypography.bodyMedium.copyWith(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalDataCard() {
    return AzureCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.azureLight, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.badge_rounded, color: AppColors.primaryAzure, size: 20),
                ),
                const SizedBox(width: 12),
                Text('Dados Pessoais', style: AppTypography.titleMedium.copyWith(fontSize: 16)),
              ],
            ),
            const Divider(height: 24, color: AppColors.border),

            AzureTextField(
              label: 'Nome Completo',
              hintText: 'Seu nome completo',
              controller: _nameController,
              prefixIcon: Icons.person_outline_rounded,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe seu nome' : null,
            ),
            const SizedBox(height: 16),

            AzureTextField(
              label: 'E-mail',
              hintText: 'seu@email.com',
              controller: _emailController,
              enabled: false,
              prefixIcon: Icons.mail_outline_rounded,
            ),
            const SizedBox(height: 16),

            // Papel Familiar Genérico (Responsável)
            _buildResponsibleSelector(),
            const SizedBox(height: 16),

            AzureTextField(
              label: 'Número de Contato / WhatsApp',
              hintText: '(11) 99999-9999',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_outlined,
              onChanged: _onPhoneChanged,
            ),
            const SizedBox(height: 16),

            _buildBirthDateField(),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsibleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Text('Papel Familiar / Responsável', style: AppTypography.labelMedium),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E8FF),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF9333EA).withValues(alpha: 0.3)),
              ),
              child: Text(
                'Responsável',
                style: AppTypography.codeBadge.copyWith(
                  fontSize: 11,
                  color: const Color(0xFF9333EA),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 1.2),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.family_restroom_rounded, color: Color(0xFF9333EA), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Responsável Legal / Cuidador',
                      style: AppTypography.labelMedium.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Acesso genérico válido para pai, mãe, avô, avó, tios ou tutores legais no Duna Kids.',
                      style: AppTypography.bodyMedium.copyWith(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBirthDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Data de Nascimento', style: AppTypography.labelMedium),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickBirthDate,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedBirthDate != null ? AppColors.primaryAzure : AppColors.border,
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_month_outlined, size: 20, color: AppColors.primaryAzure),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedBirthDate != null
                        ? _dateFormatter.format(_selectedBirthDate!)
                        : 'Selecione sua data de nascimento',
                    style: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary),
                  ),
                ),
                const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChildrenSection() {
    return AzureCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E8FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.family_restroom_rounded, color: Color(0xFF9333EA), size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Crianças Cadastradas',
                            style: AppTypography.titleMedium.copyWith(fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${_children.length} ${_children.length == 1 ? "criança" : "crianças"}',
                            style: AppTypography.bodyMedium.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAzure,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Adicionar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                onPressed: () => _openChildDialog(),
              ),
            ],
          ),
          const Divider(height: 24, color: AppColors.border),

          if (_children.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  const Icon(Icons.escalator_warning_outlined, color: AppColors.textMuted, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    'Nenhuma criança cadastrada ainda',
                    style: AppTypography.labelMedium.copyWith(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ao cadastrar uma criança, seu perfil será automaticamente atualizado para o nível de acesso Responsável (válido para pais, mães, avós e tutores).',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Banner de Pessoas Autorizadas da Família
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E8FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFC084FC).withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9333EA),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.how_to_reg_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pessoas Autorizadas a Retirar',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6B21A8),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Escolha outros usuários do app ou familiares para retirar todos os seus filhos.',
                          style: TextStyle(fontSize: 11, color: Color(0xFF7E22CE)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9333EA),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      AuthorizedGuardiansDialog.show(
                        context,
                        child: _children.first,
                        onUpdated: _loadAllData,
                      );
                    },
                    child: const Text('Gerenciar', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _children.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final child = _children[index];
                return _buildChildCard(child);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChildCard(ChildModel child) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: child.inclusionLaw13146 ? AppColors.primaryAzure.withValues(alpha: 0.5) : AppColors.border,
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.azureLight,
                ),
                child: ClipOval(
                  child: (child.photoUrl != null && child.photoUrl!.isNotEmpty)
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      child.fullName,
                      style: AppTypography.labelMedium.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '${child.ageFormatted} • Nasc: ${_dateFormatter.format(child.birthDate)}',
                          style: AppTypography.bodyMedium.copyWith(fontSize: 12),
                        ),
                        if (child.isInClassroom)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF86EFAC)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('🟢 ', style: TextStyle(fontSize: 8)),
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
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.textSecondary),
                tooltip: 'Editar',
                onPressed: () => _openChildDialog(child),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.error),
                tooltip: 'Remover',
                onPressed: () => _handleDeleteChild(child),
              ),
            ],
          ),

          // Badge de Inclusão da Lei 13.146/2015
          if (child.inclusionLaw13146) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF), // Blue tint
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primaryAzure.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.accessibility_new_rounded, size: 16, color: AppColors.primaryAzure),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Lei nº 13.146/2015 • Inclusão${child.inclusionDetails != null && child.inclusionDetails!.isNotEmpty ? ": ${child.inclusionDetails}" : ""}',
                      style: AppTypography.bodyMedium.copyWith(
                        fontSize: 11,
                        color: AppColors.primaryAzure,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (child.notes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Obs: ${child.notes}',
              style: AppTypography.bodyMedium.copyWith(fontSize: 11, color: AppColors.textMuted),
            ),
          ],

          const SizedBox(height: 12),
          InkWell(
            onTap: () {
              AuthorizedGuardiansDialog.show(
                context,
                child: child,
                onUpdated: _loadAllData,
              );
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.azureLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primaryAzure.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryAzure.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.how_to_reg_rounded,
                      size: 18,
                      color: AppColors.primaryAzure,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pessoas Autorizadas a Retirar',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryAzure,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          child.authorizedUserIds.isNotEmpty
                              ? '${child.authorizedUserIds.length} autorizada(s) • Válido para todos os filhos'
                              : 'Autorizar outro usuário ou familiar (todos os filhos)',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppColors.primaryAzure,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsCard() {
    return AzureCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.verified_user_rounded, color: Color(0xFF059669), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Permissões & Funções do Usuário', style: AppTypography.titleMedium.copyWith(fontSize: 16)),
                    Text(
                      'A pessoa pode ser simultaneamente Responsável, Professor(a) e Administrador(a)',
                      style: AppTypography.bodyMedium.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: AppColors.border),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Função de Professor(a)', style: AppTypography.labelMedium),
                    const SizedBox(height: 2),
                    Text(
                      'Permite gerenciar salas de aula e atividades',
                      style: AppTypography.bodyMedium.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: _isTeacher,
                activeTrackColor: AppColors.primaryAzure,
                onChanged: (val) {
                  setState(() {
                    _isTeacher = val;
                  });
                },
              ),
            ],
          ),
          const Divider(height: 20, color: AppColors.border),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Função de Administrador(a)', style: AppTypography.labelMedium),
                    const SizedBox(height: 2),
                    Text(
                      'Acesso irrestrito a configurações e todos os módulos',
                      style: AppTypography.bodyMedium.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: _isAdmin,
                activeTrackColor: const Color(0xFFD97706),
                onChanged: (val) {
                  setState(() {
                    _isAdmin = val;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
