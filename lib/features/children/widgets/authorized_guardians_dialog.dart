import 'package:flutter/material.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/azure_button.dart';
import '../../../core/widgets/azure_confirm_dialog.dart';
import '../../../core/widgets/azure_text_field.dart';
import '../../../core/widgets/top_toast.dart';
import '../../profile/models/user_profile_model.dart';
import '../models/authorized_guardian_model.dart';
import '../models/child_model.dart';

class AuthorizedGuardiansDialog extends StatefulWidget {
  final ChildModel? child;
  final VoidCallback onUpdated;

  const AuthorizedGuardiansDialog({
    super.key,
    this.child,
    required this.onUpdated,
  });

  static Future<void> show(
    BuildContext context, {
    ChildModel? child,
    required VoidCallback onUpdated,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AuthorizedGuardiansDialog(child: child, onUpdated: onUpdated),
    );
  }

  @override
  State<AuthorizedGuardiansDialog> createState() => _AuthorizedGuardiansDialogState();
}

class _AuthorizedGuardiansDialogState extends State<AuthorizedGuardiansDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cpfController = TextEditingController();
  final _searchController = TextEditingController();

  // Modo de Adição: 0 = Usuários do App (Seleção Múltipla), 1 = Familiar / Externo
  int _selectedModeTab = 0;

  String _selectedRelationship = 'Responsável';
  bool _canCheckIn = true;
  bool _canCheckOut = true;
  bool _applyToAllChildren = true;

  // Conjunto de IDs dos perfis selecionados na lista de usuários do sistema
  final Set<String> _selectedProfileIds = {};

  List<UserProfileModel> _availableProfiles = [];
  List<AuthorizedGuardianModel> _guardians = [];
  List<ChildModel> _allMyChildren = [];

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isFormVisible = false;

  final List<String> _relationships = [
    'Responsável',
    'Mãe',
    'Pai',
    'Avó',
    'Avô',
    'Tio(a)',
    'Padrinho / Madrinha',
    'Irmão / Irmã (Maior)',
    'Tutor Legal',
    'Outro',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cpfController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final children = await SupabaseService.instance.getChildren();
      final profiles = await SupabaseService.instance.getAvailableProfilesForAuthorization();

      List<AuthorizedGuardianModel> list;
      if (widget.child != null) {
        list = await SupabaseService.instance.getAuthorizedGuardiansForChild(widget.child!.id);
      } else {
        list = await SupabaseService.instance.getFamilyAuthorizedGuardians();
      }

      if (list.isEmpty) {
        list = await SupabaseService.instance.getFamilyAuthorizedGuardians();
      }

      if (mounted) {
        setState(() {
          _allMyChildren = children;
          _guardians = list;
          _availableProfiles = profiles;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        TopToast.showError(context, 'Erro ao carregar pessoas autorizadas: $e');
      }
    }
  }

  List<UserProfileModel> get _filteredProfiles {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _availableProfiles;
    return _availableProfiles.where((p) {
      final matchName = p.fullName.toLowerCase().contains(query);
      final matchEmail = p.email.toLowerCase().contains(query);
      final matchPhone = p.phone.replaceAll(RegExp(r'\D'), '').contains(query);
      return matchName || matchEmail || matchPhone;
    }).toList();
  }

  void _toggleProfile(String profileId) {
    setState(() {
      if (_selectedProfileIds.contains(profileId)) {
        _selectedProfileIds.remove(profileId);
      } else {
        _selectedProfileIds.add(profileId);
      }
    });
  }

  void _selectAllFiltered() {
    setState(() {
      final filteredIds = _filteredProfiles.map((p) => p.id);
      _selectedProfileIds.addAll(filteredIds);
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedProfileIds.clear();
    });
  }

  Future<void> _handleSave() async {
    final targetChildId = widget.child?.id ?? (_allMyChildren.isNotEmpty ? _allMyChildren.first.id : '');
    if (targetChildId.isEmpty) {
      TopToast.showError(context, 'Nenhuma criança cadastrada para autorizar.');
      return;
    }

    // Modo 0: Seleção de um ou mais Usuários do Sistema
    if (_selectedModeTab == 0) {
      if (_selectedProfileIds.isEmpty) {
        TopToast.showError(context, 'Selecione ao menos um usuário na lista abaixo.');
        return;
      }

      setState(() => _isSaving = true);
      try {
        final selectedProfiles = _availableProfiles
            .where((p) => _selectedProfileIds.contains(p.id))
            .toList();

        await SupabaseService.instance.addMultipleAuthorizedGuardians(
          profiles: selectedProfiles,
          relationship: _selectedRelationship,
          canCheckIn: _canCheckIn,
          canCheckOut: _canCheckOut,
          applyToAllChildren: _applyToAllChildren,
          childId: targetChildId,
        );

        if (mounted) {
          final count = selectedProfiles.length;
          final names = count <= 2
              ? selectedProfiles.map((p) => p.fullName).join(' e ')
              : '${selectedProfiles.first.fullName} e mais ${count - 1} pessoa(s)';

          final successMsg = _applyToAllChildren
              ? '$names agora pode(m) retirar todos os seus filhos!'
              : '$names agora está(ão) autorizado(a/s)!';

          TopToast.showSuccess(context, successMsg);
          _resetForm();
          await _loadData();
          widget.onUpdated();
        }
      } catch (e) {
        if (mounted) TopToast.showError(context, 'Erro ao salvar: $e');
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
      return;
    }

    // Modo 1: Cadastro Manual de Familiar Externo
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await SupabaseService.instance.addAuthorizedGuardian(
        childId: targetChildId,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        relationship: _selectedRelationship,
        documentCpf: _cpfController.text.trim().isNotEmpty ? _cpfController.text.trim() : null,
        userId: null,
        canCheckIn: _canCheckIn,
        canCheckOut: _canCheckOut,
        applyToAllChildren: _applyToAllChildren,
      );

      if (mounted) {
        final feedbackMsg = _applyToAllChildren
            ? '${_nameController.text.trim()} agora pode retirar todos os seus filhos!'
            : '${_nameController.text.trim()} agora está autorizado(a)!';
        TopToast.showSuccess(context, feedbackMsg);
        _resetForm();
        await _loadData();
        widget.onUpdated();
      }
    } catch (e) {
      if (mounted) TopToast.showError(context, 'Erro ao salvar: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _resetForm() {
    _nameController.clear();
    _phoneController.clear();
    _cpfController.clear();
    _searchController.clear();
    _selectedProfileIds.clear();
    _selectedRelationship = 'Responsável';
    _canCheckIn = true;
    _canCheckOut = true;
    _applyToAllChildren = true;
    _isFormVisible = false;
  }

  Future<void> _handleDelete(AuthorizedGuardianModel guardian) async {
    final childrenCount = _allMyChildren.length;
    final message = childrenCount > 1
        ? 'Deseja realmente revogar a autorização de retirada e check-in de ${guardian.name} para todos os seus filhos (${_allMyChildren.map((c) => c.fullName).join(", ")})?'
        : 'Deseja realmente revogar a autorização de retirada e check-in de ${guardian.name}?';

    final confirm = await AzureConfirmDialog.show(
      context,
      title: 'Remover Autorização',
      message: message,
      confirmText: childrenCount > 1 ? 'Sim, Remover de Todos' : 'Sim, Remover',
      cancelText: 'Cancelar',
      isDestructive: true,
      icon: Icons.person_remove_rounded,
    );

    if (confirm) {
      try {
        final targetChildId = widget.child?.id ?? (_allMyChildren.isNotEmpty ? _allMyChildren.first.id : '');
        await SupabaseService.instance.removeAuthorizedGuardian(
          guardian.id,
          childId: targetChildId,
          userId: guardian.userId,
          guardianName: guardian.name,
          removeFromAllChildren: true,
        );
        if (mounted) {
          TopToast.showSuccess(context, 'Autorização de ${guardian.name} revogada.');
          await _loadData();
          widget.onUpdated();
        }
      } catch (e) {
        if (mounted) TopToast.showError(context, 'Erro ao remover: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleSubtitle = _allMyChildren.isNotEmpty
        ? 'Válido para: ${_allMyChildren.map((c) => c.fullName).join(" e ")}'
        : 'Para todos os seus dependentes';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.94,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Barra de arraste
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: AppColors.azureLight, shape: BoxShape.circle),
                        child: const Icon(Icons.verified_user_rounded, color: AppColors.primaryAzure, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pessoas Autorizadas a Retirar',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              titleSubtitle,
                              style: AppTypography.bodyMedium.copyWith(fontSize: 11.5, color: AppColors.primaryAzure),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Conteúdo
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryAzure))
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Card explicativo sobre a regra de valer para todas as crianças
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primaryAzure.withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.family_restroom_rounded, color: AppColors.primaryAzure, size: 22),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Ao autorizar responsáveis, eles poderão fazer check-in e retirar todos os seus filhos no Duna Kids.',
                                  style: AppTypography.bodyMedium.copyWith(fontSize: 12, color: AppColors.textPrimary),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Lista dos já autorizados
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'RESPONSÁVEIS AUTORIZADOS (${_guardians.length})',
                              style: AppTypography.labelMedium.copyWith(fontSize: 11.5, color: AppColors.textMuted),
                            ),
                            if (!_isFormVisible)
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryAzure,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                                label: const Text('Incluir Responsável', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                onPressed: () => setState(() => _isFormVisible = true),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        if (_guardians.isEmpty && !_isFormVisible)
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSubtle,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.people_outline_rounded, size: 40, color: AppColors.textMuted),
                                const SizedBox(height: 8),
                                const Text('Nenhum outro responsável adicionado', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                const SizedBox(height: 4),
                                const Text(
                                  'Apenas você está registrado para retirada e check-in. Clique abaixo para escolher usuários cadastrados ou familiares.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                                ),
                                const SizedBox(height: 14),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryAzure,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  icon: const Icon(Icons.add_rounded, size: 18),
                                  label: const Text('Incluir Novo Responsável'),
                                  onPressed: () => setState(() => _isFormVisible = true),
                                ),
                              ],
                            ),
                          )
                        else ...[
                          ..._guardians.map((g) => _buildGuardianItem(g)),
                        ],

                        // Formulário para Adicionar Responsáveis
                        if (_isFormVisible) ...[
                          const SizedBox(height: 16),
                          _buildFormSection(),
                        ],

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuardianItem(AuthorizedGuardianModel guardian) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.azureLight,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryAzure.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.person_rounded, color: AppColors.primaryAzure, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        guardian.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        guardian.relationshipFormatted,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
                if (guardian.phone != null && guardian.phone!.isNotEmpty)
                  Text(guardian.phone!, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (guardian.canCheckout)
                      _buildMiniBadge('✓ Retirada Autorizada', const Color(0xFFF0FDF4), const Color(0xFF16A34A)),
                    if (guardian.canCheckin)
                      _buildMiniBadge('✓ Check-in', const Color(0xFFEFF6FF), AppColors.primaryAzure),
                    if (guardian.isRegisteredAppUser)
                      _buildMiniBadge('📱 Usuário do App', const Color(0xFFFDF4FF), const Color(0xFFC026D3)),
                    _buildMiniBadge('👨‍👩‍👧‍👦 Todos os Filhos', const Color(0xFFF3E8FF), const Color(0xFF7E22CE)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 22),
            tooltip: 'Remover Autorização de Todos',
            onPressed: () => _handleDelete(guardian),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBadge(String text, Color bg, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _buildFormSection() {
    final filtered = _filteredProfiles;
    final allFilteredSelected = filtered.isNotEmpty && filtered.every((p) => _selectedProfileIds.contains(p.id));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryAzure.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.person_add_rounded, color: AppColors.primaryAzure, size: 20),
                    SizedBox(width: 8),
                    Text('Incluir Responsável', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => setState(() => _isFormVisible = false),
                ),
              ],
            ),
            const Divider(height: 16, color: AppColors.border),

            // SELETOR DE MODO: Usuários do Sistema vs Familiar Externo
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedModeTab = 0),
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(11)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedModeTab == 0 ? AppColors.primaryAzure : Colors.transparent,
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(11)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_alt_rounded,
                              size: 16,
                              color: _selectedModeTab == 0 ? Colors.white : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Usuários do Sistema',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: _selectedModeTab == 0 ? Colors.white : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedModeTab = 1),
                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(11)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedModeTab == 1 ? AppColors.primaryAzure : Colors.transparent,
                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(11)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_outline_rounded,
                              size: 16,
                              color: _selectedModeTab == 1 ? Colors.white : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Familiar Externo',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: _selectedModeTab == 1 ? Colors.white : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ========================================================
            // SEÇÃO DO MODO 0: LISTA DE USUÁRIOS DO SISTEMA (EXCETO EU)
            // ========================================================
            if (_selectedModeTab == 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Selecione uma ou mais pessoas:',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Mostrando todos os usuários cadastrados exceto você',
                          style: AppTypography.bodyMedium.copyWith(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  if (filtered.isNotEmpty)
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: allFilteredSelected ? _clearSelection : _selectAllFiltered,
                      child: Text(
                        allFilteredSelected ? 'Desmarcar Todos' : 'Selecionar Todos',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryAzure),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Campo de Busca
              if (_availableProfiles.length > 3) ...[
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Pesquisar por nome ou e-mail...',
                    hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textSecondary),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 16),
                            onPressed: () => setState(() => _searchController.clear()),
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 8),
              ],

              // Indicador de seleção
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _selectedProfileIds.isNotEmpty ? const Color(0xFFEFF6FF) : AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _selectedProfileIds.isNotEmpty ? AppColors.primaryAzure.withValues(alpha: 0.3) : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _selectedProfileIds.isNotEmpty ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                      size: 16,
                      color: _selectedProfileIds.isNotEmpty ? AppColors.primaryAzure : AppColors.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedProfileIds.isNotEmpty
                            ? '${_selectedProfileIds.length} ${_selectedProfileIds.length == 1 ? "pessoa selecionada" : "pessoas selecionadas"}'
                            : 'Nenhuma pessoa selecionada ainda (toque no card para marcar)',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: _selectedProfileIds.isNotEmpty ? FontWeight.bold : FontWeight.normal,
                          color: _selectedProfileIds.isNotEmpty ? AppColors.primaryAzure : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Lista de Cards de Usuários
              if (filtered.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Center(
                    child: Text(
                      'Nenhum outro usuário cadastrado no sistema foi encontrado.',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ),
                )
              else
                ...filtered.map((p) {
                  final isSelected = _selectedProfileIds.contains(p.id);
                  final initials = p.fullName.trim().isNotEmpty
                      ? p.fullName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
                      : 'U';

                  return InkWell(
                    onTap: () => _toggleProfile(p.id),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.azureLight.withValues(alpha: 0.5) : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.primaryAzure : AppColors.border,
                          width: isSelected ? 1.8 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Checkbox intuitivo
                          Transform.scale(
                            scale: 1.1,
                            child: Checkbox(
                              value: isSelected,
                              activeColor: AppColors.primaryAzure,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              onChanged: (_) => _toggleProfile(p.id),
                            ),
                          ),
                          const SizedBox(width: 4),

                          // Avatar
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: isSelected ? AppColors.primaryAzure : AppColors.azureLight,
                            child: Text(
                              initials,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : AppColors.primaryAzure,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Dados do Usuário
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.fullName,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                    color: isSelected ? AppColors.primaryAzure : AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  p.email,
                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                ),
                                if (p.phone.isNotEmpty)
                                  Text(
                                    p.phone,
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

              const SizedBox(height: 6),
            ],

            // ========================================================
            // SEÇÃO DO MODO 1: CADASTRO MANUAL (Familiar externo)
            // ========================================================
            if (_selectedModeTab == 1) ...[
              AzureTextField(
                label: 'Nome Completo do Familiar',
                hintText: 'Ex: Mariana Silva',
                controller: _nameController,
                prefixIcon: Icons.badge_outlined,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o nome completo' : null,
              ),
              const SizedBox(height: 12),
              AzureTextField(
                label: 'Telefone / WhatsApp (para contato da sala)',
                hintText: '(11) 99999-9999',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
              ),
              const SizedBox(height: 12),
              AzureTextField(
                label: 'CPF ou Documento (opcional para conferência)',
                hintText: '000.000.000-00',
                controller: _cpfController,
                prefixIcon: Icons.security_rounded,
              ),
              const SizedBox(height: 12),
            ],

            // ========================================================
            // CONFIGURAÇÕES COMUNS: Parentesco, Permissões e Regra
            // ========================================================
            Text('Grau de Parentesco / Vínculo:', style: AppTypography.labelMedium.copyWith(fontSize: 12)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedRelationship,
                  isExpanded: true,
                  items: _relationships.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedRelationship = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Permissões
            Text('Permissões Concedidas:', style: AppTypography.labelMedium.copyWith(fontSize: 12)),
            const SizedBox(height: 4),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Autorizado a Retirar a Criança (Check-out)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              subtitle: const Text('Permite buscar as crianças na saída do Kids', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
              value: _canCheckOut,
              activeColor: AppColors.primaryAzure,
              onChanged: (val) => setState(() => _canCheckOut = val ?? true),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Autorizado a fazer Check-in (Entregar no Kids)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              subtitle: const Text('Pode levar e dar entrada das crianças na sala', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
              value: _canCheckIn,
              activeColor: AppColors.primaryAzure,
              onChanged: (val) => setState(() => _canCheckIn = val ?? true),
            ),
            const SizedBox(height: 8),

            // Regra: Valer para todos os filhos
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E8FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFC084FC)),
              ),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: const Text(
                  'Valer para todos os meus filhos',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF6B21A8)),
                ),
                subtitle: Text(
                  _allMyChildren.isNotEmpty
                      ? 'Aplica autorização para: ${_allMyChildren.map((c) => c.fullName).join(", ")}'
                      : 'Aplica para todas as suas crianças cadastradas',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF7E22CE)),
                ),
                value: _applyToAllChildren,
                activeThumbColor: const Color(0xFF9333EA),
                onChanged: (val) => setState(() => _applyToAllChildren = val),
              ),
            ),
            const SizedBox(height: 16),

            // Botão Salvar com texto dinâmico
            AzureButton(
              text: _selectedModeTab == 0
                  ? (_selectedProfileIds.isEmpty
                      ? 'Selecione as pessoas acima'
                      : 'Autorizar ${_selectedProfileIds.length} ${_selectedProfileIds.length == 1 ? "Pessoa" : "Pessoas"} para Meus Filhos')
                  : 'Salvar Autorização',
              icon: Icons.check_circle_outline_rounded,
              isLoading: _isSaving,
              onPressed: (_selectedModeTab == 0 && _selectedProfileIds.isEmpty) ? null : _handleSave,
            ),
          ],
        ),
      ),
    );
  }
}
