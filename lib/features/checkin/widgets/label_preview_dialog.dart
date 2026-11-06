import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/azure_button.dart';
import '../services/label_printer_service.dart';

class LabelPreviewDialog extends StatefulWidget {
  final String guardianName;
  final String securityCode;
  final DateTime checkInTime;
  final List<CheckInChildData> childrenData;

  const LabelPreviewDialog({
    super.key,
    required this.guardianName,
    required this.securityCode,
    required this.checkInTime,
    required this.childrenData,
  });

  static Future<void> show(
    BuildContext context, {
    required String guardianName,
    required String securityCode,
    required DateTime checkInTime,
    required List<CheckInChildData> childrenData,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LabelPreviewDialog(
        guardianName: guardianName,
        securityCode: securityCode,
        checkInTime: checkInTime,
        childrenData: childrenData,
      ),
    );
  }

  @override
  State<LabelPreviewDialog> createState() => _LabelPreviewDialogState();
}

class _LabelPreviewDialogState extends State<LabelPreviewDialog> {
  bool _isPrinting = false;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final DateFormat _timeFormat = DateFormat('HH:mm');

  Future<void> _handlePrint() async {
    setState(() => _isPrinting = true);
    try {
      await LabelPrinterService.printLabels(
        guardianName: widget.guardianName,
        securityCode: widget.securityCode,
        checkInTime: widget.checkInTime,
        childrenData: widget.childrenData,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao imprimir: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPrinting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = _dateFormat.format(widget.checkInTime);
    final timeStr = _timeFormat.format(widget.checkInTime);
    final totalLabels = 1 + widget.childrenData.length;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 540),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabeçalho Modal
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: AppColors.azureLight.withValues(alpha: 0.5),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: const Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryAzure,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.print_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Etiquetas de Check-in Geradas',
                          style: AppTypography.titleMedium.copyWith(fontSize: 17),
                        ),
                        Text(
                          'Brother DK-1201 QL-800 • 29mm x 90mm ($totalLabels etiquetas)',
                          style: AppTypography.bodyMedium.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                    tooltip: 'Fechar',
                  ),
                ],
              ),
            ),

            // Lista de Pré-visualização das Etiquetas
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dica informativa
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF86EFAC)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Check-in concluído! Código da família: ${widget.securityCode}',
                              style: AppTypography.labelMedium.copyWith(
                                color: const Color(0xFF15803D),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 1ª ETIQUETA: RESPONSÁVEL
                    _buildSectionTitle('1. ETIQUETA DO RESPONSÁVEL (COM QR CODE)'),
                    const SizedBox(height: 8),
                    _buildGuardianLabelCard(dateStr, timeStr),
                    const SizedBox(height: 22),

                    // DEMAIS ETIQUETAS: CRIANÇAS
                    _buildSectionTitle('2. ETIQUETAS DAS CRIANÇAS (COLAR NA ROUPA/IDENTIFICADOR)'),
                    const SizedBox(height: 8),
                    ...widget.childrenData.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final childData = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _buildChildLabelCard(childData, idx + 1, dateStr, timeStr),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Rodapé com Ações
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                children: [
                  AzureButton(
                    text: 'Imprimir Etiquetas (Brother QL-800)',
                    icon: Icons.print_outlined,
                    isLoading: _isPrinting,
                    onPressed: _handlePrint,
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.done_all_rounded, size: 18),
                    label: const Text('Concluir e Voltar'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: AppTypography.labelMedium.copyWith(
        fontSize: 11,
        color: AppColors.textMuted,
        letterSpacing: 0.8,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  /// Card Visual idêntico à Etiqueta Brother DK-1201 QL-800 do Responsável
  Widget _buildGuardianLabelCard(String dateStr, String timeStr) {
    final qrPayload =
        'DUNA-CHECKOUT|COD:${widget.securityCode}|RESP:${widget.guardianName}|QTD:${widget.childrenData.length}|DT:$dateStr $timeStr';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // QR Code de Saída
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: QrImageView(
              data: qrPayload,
              version: QrVersions.auto,
              size: 78,
              gapless: true,
            ),
          ),
          const SizedBox(width: 14),

          // Informações da Etiqueta
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'DUNA KIDS • RESPONSÁVEL',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: Colors.black,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.securityCode,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.guardianName.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Crianças: ${widget.childrenData.length} (${widget.childrenData.map((c) => c.child.fullName.split(' ').first).join(', ')})',
                  style: const TextStyle(fontSize: 11, color: Colors.black87),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Entrada: $dateStr às $timeStr',
                  style: const TextStyle(fontSize: 10, color: Colors.black54),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Apresente este QR Code para retirar a(s) criança(s).',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontStyle: FontStyle.italic,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Card Visual idêntico à Etiqueta Brother DK-1201 QL-800 da Criança
  Widget _buildChildLabelCard(CheckInChildData childData, int index, String dateStr, String timeStr) {
    final child = childData.child;
    final room = childData.classroom;

    String restrictions = '';
    final allergies = child.allergies ?? '';
    final notes = child.notes;
    if (allergies.isNotEmpty || notes.isNotEmpty) {
      restrictions = [allergies, notes].where((s) => s.isNotEmpty).join('; ');
    }
    final bool hasInclusion = child.inclusionLaw13146;
    final inclusionDetails = child.inclusionDetails ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Topo: DUNA KIDS | TURMA | CÓDIGO
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'DUNA KIDS',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: Colors.black,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'SALA: ${room.name.toUpperCase()}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: Colors.black,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.securityCode,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Nome da Criança e Flag de Inclusão
          Row(
            children: [
              Expanded(
                child: Text(
                  child.fullName.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (hasInclusion)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    border: Border.all(color: Colors.black, width: 1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'LEI 13.146 (INCLUSÃO)',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),

          // Responsável e Horário
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Resp: ${widget.guardianName.toUpperCase()}',
                style: const TextStyle(fontSize: 10.5, color: Colors.black87),
              ),
              Text(
                '$dateStr às $timeStr',
                style: const TextStyle(fontSize: 10, color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Pertences trazidos
          Row(
            children: [
              const Text(
                'Pertences: ',
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              Expanded(
                child: Text(
                  childData.belongingsSummary,
                  style: const TextStyle(fontSize: 10.5, color: Colors.black87),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Restrições / Alergias
          if (restrictions.isNotEmpty || (hasInclusion && inclusionDetails.isNotEmpty))
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFFEF4444), width: 0.8),
              ),
              child: Text(
                '⚠️ RESTRIÇÃO: ${hasInclusion && inclusionDetails.isNotEmpty ? "[Inclusão: $inclusionDetails] " : ""}$restrictions',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF991B1B),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            )
          else
            const Text(
              'Sem restrições médicas/alimentares informadas.',
              style: TextStyle(fontSize: 9.5, color: Colors.black45),
            ),
        ],
      ),
    );
  }
}
