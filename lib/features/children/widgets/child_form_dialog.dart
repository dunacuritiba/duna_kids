import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/azure_button.dart';
import '../../../core/widgets/azure_text_field.dart';
import '../models/child_model.dart';

class ChildFormDialog extends StatefulWidget {
  final ChildModel? initialChild;

  const ChildFormDialog({super.key, this.initialChild});

  static Future<ChildModel?> show(BuildContext context, {ChildModel? child}) {
    return showModalBottomSheet<ChildModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ChildFormDialog(initialChild: child),
    );
  }

  @override
  State<ChildFormDialog> createState() => _ChildFormDialogState();
}

class _ChildFormDialogState extends State<ChildFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  final _inclusionDetailsController = TextEditingController();

  DateTime? _selectedBirthDate;
  bool _inclusionLaw13146 = false;
  String? _photoUrl;
  Uint8List? _localPhotoBytes;

  bool _isSaving = false;
  bool _isUploadingPhoto = false;

  final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    if (widget.initialChild != null) {
      final c = widget.initialChild!;
      _nameController.text = c.fullName;
      _notesController.text = c.notes;
      _inclusionDetailsController.text = c.inclusionDetails ?? '';
      _selectedBirthDate = c.birthDate;
      _inclusionLaw13146 = c.inclusionLaw13146;
      _photoUrl = c.photoUrl;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    _inclusionDetailsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
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
        final tempId = widget.initialChild?.id ?? DateTime.now().millisecondsSinceEpoch.toString();

        setState(() {
          _localPhotoBytes = bytes;
          _isUploadingPhoto = true;
        });

        try {
          final url = await SupabaseService.instance.uploadChildPhoto(
            bytes: bytes,
            fileExtension: ext,
            childId: tempId,
          );
          if (mounted) {
            setState(() {
              _photoUrl = url;
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

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final initial = _selectedBirthDate ?? DateTime(now.year - 4, now.month, now.day);
    final first = DateTime(now.year - 18);
    final last = now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      helpText: 'DATA DE NASCIMENTO DA CRIANÇA',
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
      setState(() {
        _selectedBirthDate = picked;
      });
    }
  }

  void _handleSave() async {
    if (_selectedBirthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, informe a data de nascimento da criança.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isSaving = true);

      final user = SupabaseService.instance.currentUser;
      final childId = widget.initialChild?.id ?? 'child_${DateTime.now().millisecondsSinceEpoch}';

      final child = ChildModel(
        id: childId,
        fullName: _nameController.text.trim(),
        birthDate: _selectedBirthDate!,
        notes: _notesController.text.trim(),
        photoUrl: _photoUrl,
        inclusionLaw13146: _inclusionLaw13146,
        inclusionDetails: _inclusionLaw13146 ? _inclusionDetailsController.text.trim() : null,
        userId: user?.id ?? '',
        guardianId: widget.initialChild?.guardianId,
        createdAt: widget.initialChild?.createdAt,
      );

      try {
        final saved = await SupabaseService.instance.saveChild(child);
        if (mounted) {
          setState(() => _isSaving = false);
          Navigator.of(context).pop(saved);
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

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isEditing = widget.initialChild != null;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      padding: EdgeInsets.only(
        top: 20,
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
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                isEditing ? 'Editar Dados da Criança' : 'Cadastrar Nova Criança',
                style: AppTypography.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Ao cadastrar uma criança, seu acesso passa a ter o papel de Responsável',
                style: AppTypography.bodyMedium.copyWith(fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Avatar da Criança
              _buildChildPhotoPicker(),
              const SizedBox(height: 20),

              // Nome Completo
              AzureTextField(
                label: 'Nome Completo da Criança',
                hintText: 'Ex: Alice Silva',
                controller: _nameController,
                prefixIcon: Icons.child_care_rounded,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Informe o nome da criança';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Data de Nascimento
              _buildBirthDateField(),
              const SizedBox(height: 18),

              // Card de Inclusão - Lei nº 13.146/2015
              _buildInclusionCard(),
              const SizedBox(height: 18),

              // Observações gerais
              AzureTextField(
                label: 'Observações (Alergias, Cuidados ou Medicamentos)',
                hintText: 'Ex: Alergia a amendoim, usa óculos...',
                controller: _notesController,
                prefixIcon: Icons.notes_rounded,
              ),
              const SizedBox(height: 24),

              // Botão Salvar
              AzureButton(
                text: isEditing ? 'Salvar Alterações' : 'Concluir Cadastro da Criança',
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

  Widget _buildChildPhotoPicker() {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryAzure.withValues(alpha: 0.3), width: 2.5),
            ),
            child: ClipOval(
              child: _localPhotoBytes != null
                  ? Image.memory(_localPhotoBytes!, fit: BoxFit.cover)
                  : (_photoUrl != null && _photoUrl!.isNotEmpty)
                      ? Image.network(
                          _photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                        )
                      : _buildPlaceholder(),
            ),
          ),
          if (_isUploadingPhoto)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => _pickImage(ImageSource.gallery),
              child: Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add_a_photo_rounded, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.azureLight,
      child: const Icon(Icons.child_care_rounded, color: AppColors.primaryAzure, size: 44),
    );
  }

  Widget _buildBirthDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Data de Nascimento',
          style: AppTypography.labelMedium.copyWith(color: AppColors.textPrimary),
        ),
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
                Icon(
                  Icons.calendar_month_outlined,
                  size: 20,
                  color: _selectedBirthDate != null ? AppColors.primaryAzure : AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedBirthDate != null
                        ? _dateFormatter.format(_selectedBirthDate!)
                        : 'Selecione a data de nascimento',
                    style: _selectedBirthDate != null
                        ? AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary)
                        : AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
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

  Widget _buildInclusionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _inclusionLaw13146 ? AppColors.azureSubtle : AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _inclusionLaw13146 ? AppColors.primaryAzure : AppColors.border,
          width: 1.3,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _inclusionLaw13146 ? AppColors.primaryAzure : AppColors.border,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.accessibility_new_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lei nº 13.146/2015 - Inclusão',
                      style: AppTypography.labelMedium.copyWith(
                        color: _inclusionLaw13146 ? AppColors.primaryAzure : AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Estatuto da Pessoa com Deficiência',
                      style: AppTypography.bodyMedium.copyWith(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: _inclusionLaw13146,
                activeTrackColor: AppColors.primaryAzure,
                onChanged: (val) {
                  setState(() {
                    _inclusionLaw13146 = val;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Ative esta opção se a criança necessitar de apoio ou adaptações específicas para acolhimento inclusivo.',
            style: AppTypography.bodyMedium.copyWith(fontSize: 12),
          ),
          if (_inclusionLaw13146) ...[
            const SizedBox(height: 14),
            AzureTextField(
              label: 'Descreva a necessidade de inclusão ou apoio',
              hintText: 'Ex: TEA (Autismo), deficiência auditiva, cadeira de rodas...',
              controller: _inclusionDetailsController,
              prefixIcon: Icons.medical_services_outlined,
            ),
          ],
        ],
      ),
    );
  }
}
