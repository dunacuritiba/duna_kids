import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({
    super.key,
    required this.password,
  });

  int _calculateStrength() {
    if (password.isEmpty) return 0;
    int score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;
    return score;
  }

  String _getStrengthLabel(int score) {
    switch (score) {
      case 1:
        return 'Fraca';
      case 2:
        return 'Razoável';
      case 3:
        return 'Boa';
      case 4:
        return 'Excelente';
      default:
        return 'Segurança da senha';
    }
  }

  Color _getStrengthColor(int score) {
    switch (score) {
      case 1:
        return AppColors.error;
      case 2:
        return AppColors.warning;
      case 3:
        return AppColors.primaryAzure;
      case 4:
        return AppColors.success;
      default:
        return AppColors.border;
    }
  }

  @override
  Widget build(BuildContext context) {
    final score = _calculateStrength();
    final activeColor = _getStrengthColor(score);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Força da Senha',
              style: AppTypography.labelMedium.copyWith(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              _getStrengthLabel(score),
              style: AppTypography.labelMedium.copyWith(
                fontSize: 12,
                color: score == 0 ? AppColors.textMuted : activeColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: List.generate(4, (index) {
            final isFilled = index < score;
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(
                  right: index < 3 ? 6.0 : 0.0,
                ),
                height: 4.5,
                decoration: BoxDecoration(
                  color: isFilled ? activeColor : AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        _buildRequirementItem(
          isValid: password.length >= 8,
          text: 'Mínimo de 8 caracteres',
        ),
        _buildRequirementItem(
          isValid: RegExp(r'[A-Z]').hasMatch(password),
          text: 'Pelo menos uma letra maiúscula',
        ),
        _buildRequirementItem(
          isValid: RegExp(r'[0-9]').hasMatch(password),
          text: 'Pelo menos um número',
        ),
      ],
    );
  }

  Widget _buildRequirementItem({required bool isValid, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 14,
            color: isValid ? AppColors.success : AppColors.textMuted,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 12,
              color: isValid ? AppColors.textPrimary : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
