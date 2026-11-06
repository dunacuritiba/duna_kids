import 'package:flutter/material.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/azure_button.dart';
import '../../../core/widgets/azure_card.dart';
import '../../../core/widgets/azure_text_field.dart';
import '../../../core/widgets/social_auth_button.dart';
import '../../profile/screens/meus_dados_screen.dart';
import '../widgets/auth_header.dart';
import 'forgot_password_dialog.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      try {
        await SupabaseService.instance.signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );

        if (mounted) {
          setState(() => _isLoading = false);
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              settings: const RouteSettings(name: '/meus-dados'),
              builder: (context) => const MeusDadosScreen(),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text(e.toString())),
                ],
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AuthHeader(
                  title: 'Bem-vindo de volta',
                  subtitle: 'Acesse o aplicativo Duna Kids',
                  badgeText: 'Duna Kids',
                ),
                const SizedBox(height: 28),

                AzureCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AzureTextField(
                          label: 'E-mail ou Usuário',
                          hintText: 'admin@azure.com',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.alternate_email_rounded,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Informe seu e-mail';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                              return 'E-mail inválido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),

                        AzureTextField(
                          label: 'Senha',
                          hintText: '••••••••••••',
                          controller: _passwordController,
                          isPassword: true,
                          prefixIcon: Icons.lock_outline_rounded,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Informe a sua senha';
                            }
                            if (value.length < 6) {
                              return 'Senha deve ter no mínimo 6 dígitos';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Lembrar de mim & Esqueceu a senha
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          runSpacing: 8,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: Checkbox(
                                    value: _rememberMe,
                                    activeColor: AppColors.primaryAzure,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    onChanged: (val) {
                                      setState(() {
                                        _rememberMe = val ?? false;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Lembrar de mim',
                                  style: AppTypography.bodyMedium.copyWith(fontSize: 13),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () => ForgotPasswordDialog.show(context),
                              child: Text(
                                'Esqueceu a senha?',
                                style: AppTypography.labelMedium.copyWith(
                                  fontSize: 13,
                                  color: AppColors.primaryAzure,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        AzureButton(
                          text: 'Acessar Plataforma',
                          icon: Icons.login_rounded,
                          isLoading: _isLoading,
                          onPressed: _handleLogin,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Separador OR
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppColors.border, thickness: 1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        'OU ENTRE COM',
                        style: AppTypography.labelMedium.copyWith(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider(color: AppColors.border, thickness: 1)),
                  ],
                ),

                const SizedBox(height: 20),

                // Social Auth Buttons
                Row(
                  children: [
                    Expanded(
                      child: SocialAuthButton(
                        label: 'Google',
                        icon: const Icon(
                          Icons.g_mobiledata_rounded,
                          size: 26,
                          color: Color(0xFFEA4335),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Login com Google em desenvolvimento')),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SocialAuthButton(
                        label: 'Apple',
                        icon: const Icon(
                          Icons.apple_rounded,
                          size: 22,
                          color: Colors.black,
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Login com Apple em desenvolvimento')),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Link para Cadastro
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4,
                  children: [
                    Text(
                      'Não possui acesso? ',
                      style: AppTypography.bodyMedium,
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Criar conta agora',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.primaryAzure,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  }
}
