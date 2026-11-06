import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../children/models/child_model.dart';
import '../../classrooms/models/classroom_model.dart';

class CheckInChildData {
  final ChildModel child;
  final ClassroomModel classroom;
  final bool hasBag;
  final bool hasBottle;
  final bool hasPacifier;
  final String belongingsNotes;

  const CheckInChildData({
    required this.child,
    required this.classroom,
    this.hasBag = false,
    this.hasBottle = false,
    this.hasPacifier = false,
    this.belongingsNotes = '',
  });

  String get belongingsSummary {
    final List<String> items = [];
    if (hasBag) items.add('Bolsa');
    if (hasBottle) items.add('Mamadeira');
    if (hasPacifier) items.add('Chupeta');
    if (belongingsNotes.trim().isNotEmpty) items.add(belongingsNotes.trim());
    return items.isEmpty ? 'Nenhum pertence' : items.join(' • ');
  }
}

class LabelPrinterService {
  LabelPrinterService._();

  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _timeFormat = DateFormat('HH:mm');

  /// Dimensões oficiais da etiqueta Brother DK-1201 QL-800: 29mm x 90mm
  /// No modo paisagem (landscape): largura 90mm x altura 29mm
  static final PdfPageFormat dk1201PageFormat = PdfPageFormat(
    90 * PdfPageFormat.mm,
    29 * PdfPageFormat.mm,
    marginLeft: 2 * PdfPageFormat.mm,
    marginRight: 2 * PdfPageFormat.mm,
    marginTop: 1.5 * PdfPageFormat.mm,
    marginBottom: 1.5 * PdfPageFormat.mm,
  );

  /// Gera o arquivo PDF com todas as etiquetas no tamanho 29mm x 90mm
  static Future<Uint8List> generateLabelsPdf({
    required String guardianName,
    required String securityCode,
    required DateTime checkInTime,
    required List<CheckInChildData> childrenData,
  }) async {
    final pdf = pw.Document();

    final dateStr = _dateFormat.format(checkInTime);
    final timeStr = _timeFormat.format(checkInTime);

    // 1. Etiqueta do Responsável (Guardião)
    final qrPayload = 'DUNA-CHECKOUT|COD:$securityCode|RESP:$guardianName|QTD:${childrenData.length}|DT:$dateStr $timeStr';

    pdf.addPage(
      pw.Page(
        pageFormat: dk1201PageFormat,
        build: (pw.Context context) {
          return pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // QR Code para conferência no checkout
              pw.Container(
                width: 25 * PdfPageFormat.mm,
                height: 25 * PdfPageFormat.mm,
                padding: const pw.EdgeInsets.all(1),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 0.8),
                ),
                child: pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: qrPayload,
                  drawText: false,
                ),
              ),
              pw.SizedBox(width: 2.5 * PdfPageFormat.mm),

              // Informações do Responsável
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'DUNA KIDS • RESPONSÁVEL',
                          style: pw.TextStyle(
                            fontSize: 7.5,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.black,
                            borderRadius: pw.BorderRadius.circular(2),
                          ),
                          child: pw.Text(
                            securityCode,
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 7.5,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 1.5),
                    pw.Text(
                      guardianName.toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 8.5,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: pw.TextOverflow.clip,
                    ),
                    pw.SizedBox(height: 1.5),
                    pw.Text(
                      'Crianças deixadas: ${childrenData.length} (${childrenData.map((c) => c.child.fullName.split(' ').first).join(', ')})',
                      style: const pw.TextStyle(fontSize: 6.5),
                      maxLines: 1,
                    ),
                    pw.Text(
                      'Check-in: $dateStr às $timeStr',
                      style: const pw.TextStyle(fontSize: 6.5),
                    ),
                    pw.SizedBox(height: 1),
                    pw.Text(
                      'Obrigatória a apresentação desta etiqueta para o checkout.',
                      style: pw.TextStyle(
                        fontSize: 5.5,
                        fontStyle: pw.FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    // 2. Etiquetas individuais para cada Criança
    for (final item in childrenData) {
      final child = item.child;
      final room = item.classroom;

      // Restrições / Alergias
      String restrictions = '';
      final allergies = child.allergies ?? '';
      final notes = child.notes;
      if (allergies.isNotEmpty || notes.isNotEmpty) {
        restrictions = [allergies, notes].where((s) => s.isNotEmpty).join('; ');
      }
      final bool hasInclusion = child.inclusionLaw13146;
      final inclusionDetails = child.inclusionDetails ?? '';

      pdf.addPage(
        pw.Page(
          pageFormat: dk1201PageFormat,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                // Topo: Cabeçalho com Nome da Sala e Código de Segurança
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'DUNA KIDS',
                      style: pw.TextStyle(
                        fontSize: 7.5,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.black, width: 0.8),
                        borderRadius: pw.BorderRadius.circular(2),
                      ),
                      child: pw.Text(
                        'SALA: ${room.name.toUpperCase()}',
                        style: pw.TextStyle(
                          fontSize: 7.5,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.black,
                        borderRadius: pw.BorderRadius.circular(2),
                      ),
                      child: pw.Text(
                        securityCode,
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 7.5,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                // Nome da Criança em Destaque
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        child.fullName.toUpperCase(),
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        maxLines: 1,
                      ),
                    ),
                    if (hasInclusion)
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.black, width: 0.8),
                        ),
                        child: pw.Text(
                          'INCLUSÃO (LEI 13.146)',
                          style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                  ],
                ),

                // Responsável e Horário
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Resp: ${guardianName.toUpperCase()}',
                      style: const pw.TextStyle(fontSize: 6.5),
                      maxLines: 1,
                    ),
                    pw.Text(
                      '$dateStr $timeStr',
                      style: const pw.TextStyle(fontSize: 6.5),
                    ),
                  ],
                ),

                // Pertences
                pw.Text(
                  'Pertences: ${item.belongingsSummary}',
                  style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold),
                  maxLines: 1,
                ),

                // Restrições / Alergias
                if (restrictions.isNotEmpty || (hasInclusion && inclusionDetails.isNotEmpty))
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    child: pw.Text(
                      'ATENÇÃO: ${hasInclusion && inclusionDetails.isNotEmpty ? "[Inclusão: $inclusionDetails] " : ""}$restrictions',
                      style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold),
                      maxLines: 1,
                    ),
                  )
                else
                  pw.Text(
                    'Sem restrições médicas/alimentares informadas.',
                    style: const pw.TextStyle(fontSize: 5.5, color: PdfColors.grey700),
                  ),
              ],
            );
          },
        ),
      );
    }

    return pdf.save();
  }

  static int _roundRobinIndex = 0;
  static const String _prefSelectedPrinterUrlKey = 'duna_kids_selected_printer_url';

  /// Retorna todas as impressoras Brother detectadas (ou todas do sistema caso nenhuma seja Brother explicitamente)
  static Future<List<Printer>> getBrotherPrinters() async {
    try {
      final allPrinters = await Printing.listPrinters();
      final brotherPrinters = allPrinters.where((p) {
        final name = p.name.toLowerCase();
        return name.contains('brother') || name.contains('ql-') || name.contains('ql800') || name.contains('ql700');
      }).toList();

      return brotherPrinters.isNotEmpty ? brotherPrinters : allPrinters;
    } catch (_) {
      return [];
    }
  }

  /// Recupera o identificador da impressora salva nas preferências locais (se houver)
  static Future<String?> getSavedPrinterUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_prefSelectedPrinterUrlKey);
    } catch (_) {
      return null;
    }
  }

  /// Salva uma impressora fixa para este dispositivo/guichê ('auto' para balanceamento automático)
  static Future<void> saveSelectedPrinterUrl(String? url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (url == null || url == 'auto') {
        await prefs.remove(_prefSelectedPrinterUrlKey);
      } else {
        await prefs.setString(_prefSelectedPrinterUrlKey, url);
      }
    } catch (_) {}
  }

  /// Seleciona a impressora de destino suportando:
  /// 1. Impressora fixa selecionada pelo atendente neste guichê
  /// 2. Balanceamento de carga automático (Round-Robin) entre as várias impressoras Brother conectadas
  /// 3. Impressora padrão do SO
  static Future<Printer?> getTargetPrinter() async {
    try {
      final printers = await getBrotherPrinters();
      if (printers.isEmpty) return null;

      // 1. Verifica se este guichê tem uma impressora fixa salva
      final savedUrl = await getSavedPrinterUrl();
      if (savedUrl != null && savedUrl.isNotEmpty) {
        final matched = printers.where((p) => p.url == savedUrl || p.name == savedUrl);
        if (matched.isNotEmpty) {
          return matched.first;
        }
      }

      // 2. Se houver mais de uma Brother conectada, faz o balanceamento Round-Robin
      if (printers.length > 1) {
        final selected = printers[_roundRobinIndex % printers.length];
        _roundRobinIndex++;
        debugPrint('[Duna Kids] Round-Robin balanceado para: ${selected.name}');
        return selected;
      }

      // 3. Única impressora ou padrão
      return printers.first;
    } catch (_) {
      return null;
    }
  }

  /// Dispara a impressão das etiquetas diretamente para a impressora configurada ou balanceada
  /// ignorando a tela de diálogo do sistema operacional (Silent / Direct Print).
  /// Se a primeira falhar, tenta automaticamente a próxima impressora Brother do pool.
  static Future<bool> printLabels({
    required String guardianName,
    required String securityCode,
    required DateTime checkInTime,
    required List<CheckInChildData> childrenData,
    bool forceDirectPrint = true,
  }) async {
    final pdfBytes = await generateLabelsPdf(
      guardianName: guardianName,
      securityCode: securityCode,
      checkInTime: checkInTime,
      childrenData: childrenData,
    );

    if (forceDirectPrint) {
      final printers = await getBrotherPrinters();
      final targetPrinter = await getTargetPrinter();

      if (targetPrinter != null) {
        try {
          final success = await Printing.directPrintPdf(
            printer: targetPrinter,
            onLayout: (PdfPageFormat format) async => pdfBytes,
            name: 'Etiquetas_DunaKids_$securityCode.pdf',
            format: dk1201PageFormat,
          );
          if (success) {
            return true;
          }
        } catch (e) {
          debugPrint('Falha ao imprimir na impressora (${targetPrinter.name}): $e');
        }

        // Se falhou e existem outras impressoras conectadas, tenta o Fallback automático na próxima
        for (final fallbackPrinter in printers) {
          if (fallbackPrinter.url != targetPrinter.url && fallbackPrinter.name != targetPrinter.name) {
            try {
              debugPrint('Tentando fallback na impressora: ${fallbackPrinter.name}');
              final fallbackSuccess = await Printing.directPrintPdf(
                printer: fallbackPrinter,
                onLayout: (PdfPageFormat format) async => pdfBytes,
                name: 'Etiquetas_DunaKids_$securityCode.pdf',
                format: dk1201PageFormat,
              );
              if (fallbackSuccess) return true;
            } catch (_) {}
          }
        }
      }
    }

    // Fallback final: abre o diálogo nativo do sistema operacional
    return await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Etiquetas_DunaKids_$securityCode.pdf',
      format: dk1201PageFormat,
    );
  }
}
