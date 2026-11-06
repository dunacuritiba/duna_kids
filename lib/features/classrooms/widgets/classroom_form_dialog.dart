import 'package:flutter/material.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/azure_button.dart';
import '../../../core/widgets/azure_text_field.dart';
import '../models/classroom_model.dart';

class ClassroomFormDialog extends StatefulWidget {
  final ClassroomModel? initialClassroom;

  const ClassroomFormDialog({super.key, this.initialClassroom});

  static Future<ClassroomModel?> show(BuildContext context, {ClassroomModel? classroom}) {
    return showModalBottomSheet<ClassroomModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ClassroomFormDialog(initialClassroom: classroom),
    );
  }

  @override
  State<ClassroomFormDialog> createState() => _ClassroomFormDialogState();
}

class _ClassroomFormDialogState extends State<ClassroomFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _capacityController = TextEditingController();
  final _minAgeController = TextEditingController();
  final _maxAgeController = TextEditingController();

  int _selectedColorValue = 0xFF007FFF; // Azure Blue padrão
  bool _isSaving = false;

  final List<int> _availableColors = [
    0xFF007FFF, // Azure Blue
    0xFF059669, // Emerald
    0xFF9333EA, // Purple
    0xFFD97706, // Amber
    0xFFE11D48, // Rose
    0xFF0284C7, // Sky
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialClassroom != null) {
      final c = widget.initialClassroom!;
      _nameController.text = c.name;
      _capacityController.text = c.maxCapacity.toString();
      _minAgeController.text = c.minAgeYears.toString();
      _maxAgeController.text = c.maxAgeYears.toString();
      _selectedColorValue = c.colorValue;
    } else {
      _capacityController.text = '15';
      _minAgeController.text = '3';
      _maxAgeController.text = '5';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _capacityController.dispose();
    _minAgeController.dispose();
    _maxAgeController.dispose();
    super.dispose();
  }

  void _handleSave() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isSaving = true);

      final classroomId = widget.initialClassroom?.id ?? 'room_${DateTime.now().millisecondsSinceEpoch}';
      final minAge = int.tryParse(_minAgeController.text.trim()) ?? 0;
      final maxAge = int.tryParse(_maxAgeController.text.trim()) ?? 12;
      final capacity = int.tryParse(_capacityController.text.trim()) ?? 15;

      final classroom = ClassroomModel(
        id: classroomId,
        name: _nameController.text.trim(),
        minAgeYears: minAge,
        maxAgeYears: maxAge,
        maxCapacity: capacity,
        colorValue: _selectedColorValue,
        createdAt: widget.initialClassroom?.createdAt,
      );

      try {
        final saved = await SupabaseService.instance.saveClassroom(classroom);
        if (mounted) {
          setState(() => _isSaving = false);
          Navigator.of(context).pop(saved);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isEditing = widget.initialClassroom != null;

    return Container(
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
                isEditing ? 'Editar Turma' : 'Cadastrar Nova Turma',
                style: AppTypography.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'A turma só fica ativa quando vinculada a um evento aberto.',
                style: AppTypography.bodyMedium.copyWith(fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Nome da Turma
              AzureTextField(
                label: 'Nome da Turma',
                hintText: 'Ex: Maternal, Juniores, Berçário',
                controller: _nameController,
                prefixIcon: Icons.meeting_room_rounded,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Informe o nome da turma';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Capacidade Máxima
              AzureTextField(
                label: 'Capacidade Máxima de Alunos',
                hintText: 'Ex: 15',
                controller: _capacityController,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.group_rounded,
                validator: (val) {
                  final n = int.tryParse(val ?? '');
                  if (n == null || n <= 0) return 'Informe uma capacidade válida';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Faixa Etária (Idade Mínima e Máxima)
              Row(
                children: [
                  Expanded(
                    child: AzureTextField(
                      label: 'Idade Mínima (anos)',
                      hintText: '0',
                      controller: _minAgeController,
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.cake_outlined,
                      validator: (val) {
                        if (int.tryParse(val ?? '') == null) return 'Inválido';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AzureTextField(
                      label: 'Idade Máxima (anos)',
                      hintText: '5',
                      controller: _maxAgeController,
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.cake_outlined,
                      validator: (val) {
                        final max = int.tryParse(val ?? '');
                        final min = int.tryParse(_minAgeController.text.trim()) ?? 0;
                        if (max == null) return 'Inválido';
                        if (max < min) return 'Deve ser ≥ mín';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Seletor de Cor da Turma
              Text('Cor de Identificação', style: AppTypography.labelMedium),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _availableColors.map((colorVal) {
                  final isSelected = _selectedColorValue == colorVal;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColorValue = colorVal),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Color(colorVal),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: Color(colorVal).withValues(alpha: 0.5),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                        ],
                      ),
                      child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              AzureButton(
                text: isEditing ? 'Salvar Alterações' : 'Criar Turma',
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
}
