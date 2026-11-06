import 'package:flutter/material.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/azure_button.dart';
import '../../../core/widgets/azure_card.dart';
import '../../auth/screens/login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = SupabaseService.instance.currentUser;
    final fullName = user?.userMetadata?['full_name'] as String? ?? 'Usuário';
    final email = user?.email ?? 'Não informado';

    return Scaffold(
      appBar: AppBar(
        title: Text('Painel de Acesso', style: AppTypography.titleMedium),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            tooltip: 'Sair da conta',
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.border, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryAzure.withValues(alpha: 0.20),
                            offset: const Offset(0, 10),
                            blurRadius: 24,
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Image.asset(
                          'assets/images/logo.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.rocket_launch_rounded,
                            color: AppColors.primaryAzure,
                            size: 44,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'Olá, $fullName! 👋',
                    style: AppTypography.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    email,
                    style: AppTypography.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),

                  AzureCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.successSubtle,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.cloud_done_rounded, color: AppColors.success, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Supabase Conectado', style: AppTypography.labelMedium),
                                  Text('Autenticação em tempo real ativa', style: AppTypography.bodyMedium.copyWith(fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 28, color: AppColors.border),
                        _buildInfoRow('User ID', user?.id ?? 'Local Session'),
                        const SizedBox(height: 10),
                        _buildInfoRow('Último Acesso', user?.lastSignInAt ?? 'Agora'),
                        const SizedBox(height: 10),
                        _buildInfoRow('Provedor', 'Supabase Auth (Postgres)'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  AzureButton(
                    text: 'Encerrar Sessão',
                    icon: Icons.logout_rounded,
                    variant: AzureButtonVariant.outline,
                    onPressed: () => _handleLogout(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelMedium.copyWith(fontSize: 11, color: AppColors.textMuted),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(fontSize: 13, color: AppColors.textPrimary),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  void _handleLogout(BuildContext context) async {
    await SupabaseService.instance.signOut();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }
}
