import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class AzureConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final bool isDestructive;
  final IconData icon;

  const AzureConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Sim, Excluir',
    this.cancelText = 'Cancelar',
    this.isDestructive = true,
    this.icon = Icons.delete_forever_rounded,
  });

  /// Exibe o modal de confirmação padronizado na tela
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Sim, Excluir',
    String cancelText = 'Cancelar',
    bool isDestructive = true,
    IconData icon = Icons.delete_forever_rounded,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AzureConfirmDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        isDestructive: isDestructive,
        icon: icon,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final alertColor = isDestructive ? AppColors.error : AppColors.primaryAzure;
    final alertBg = isDestructive ? const Color(0xFFFEF2F2) : AppColors.azureLight;
    final alertBorder = isDestructive ? const Color(0xFFFCA5A5) : AppColors.primaryAzure.withValues(alpha: 0.3);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: AppColors.surface,
      elevation: 12,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ícone de Alerta em Destaque
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: alertBg,
                shape: BoxShape.circle,
                border: Border.all(color: alertBorder, width: 2),
              ),
              child: Center(
                child: Icon(icon, color: alertColor, size: 28),
              ),
            ),
            const SizedBox(height: 18),

            // Título
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.titleLarge.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),

            // Mensagem explicativa
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                fontSize: 13.5,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            // Botões de Ação
            Row(
              children: [
                // Botão Cancelar
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppColors.border, width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      foregroundColor: AppColors.textPrimary,
                    ),
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      cancelText,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Botão Confirmar Ação
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: alertColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(
                      confirmText,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
