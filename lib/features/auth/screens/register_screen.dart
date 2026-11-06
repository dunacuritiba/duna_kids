import 'package:flutter/material.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/azure_button.dart';
import '../../../core/widgets/azure_card.dart';
import '../../../core/widgets/azure_text_field.dart';
import '../widgets/auth_header.dart';
import '../widgets/password_strength_indicator.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _acceptTerms = false;
  bool _isLoading = false;
  String _currentPassword = '';

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() {
      setState(() {
        _currentPassword = _passwordController.text;
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, aceite os termos de uso para continuar.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      try {
        await SupabaseService.instance.signUp(
          email: _emailController.text,
          password: _passwordController.text,
          fullName: _nameController.text,
        );

        if (mounted) {
          setState(() => _isLoading = false);
          _showSuccessDialog();
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

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.surface,
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppColors.azureLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mark_email_read_rounded,
                color: AppColors.primaryAzure,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Acesso Criado!',
              style: AppTypography.titleLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Text(
          'Enviamos uma mensagem de ativação para ${_emailController.text}. Basta confirmar para começar a usar.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium,
        ),
        actions: [
          AzureButton(
            text: 'Ir para o Login',
            onPressed: () {
              Navigator.of(context).pop(); // Fecha o diálogo
              Navigator.of(context).pop(); // Volta para a tela de login
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              const AuthHeader(
                title: 'Criar Novo Acesso',
                subtitle: 'Cadastre sua conta com padrão moderno e seguro',
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
                        label: 'Nome Completo',
                        hintText: 'Ex: Carlos Silva',
                        controller: _nameController,
                        prefixIcon: Icons.person_outline_rounded,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Informe seu nome';
                          }
                          if (value.trim().split(' ').length < 2) {
                            return 'Informe nome e sobrenome';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      AzureTextField(
                        label: 'E-mail',
                        hintText: 'nome@empresa.com',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.mail_outline_rounded,
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
                      const SizedBox(height: 16),

                      AzureTextField(
                        label: 'Senha',
                        hintText: '••••••••••••',
                        controller: _passwordController,
                        isPassword: true,
                        prefixIcon: Icons.lock_outline_rounded,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Informe uma senha';
                          }
                          if (value.length < 8) {
                            return 'A senha deve ter no mínimo 8 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      PasswordStrengthIndicator(password: _currentPassword),
                      const SizedBox(height: 16),

                      AzureTextField(
                        label: 'Confirmar Senha',
                        hintText: '••••••••••••',
                        controller: _confirmPasswordController,
                        isPassword: true,
                        prefixIcon: Icons.lock_reset_rounded,
                        validator: (value) {
                          if (value != _passwordController.text) {
                            return 'As senhas não coincidem';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: Checkbox(
                              value: _acceptTerms,
                              activeColor: AppColors.primaryAzure,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              onChanged: (val) {
                                setState(() {
                                  _acceptTerms = val ?? false;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Concordo com os Termos de Serviço e Política de Privacidade.',
                              style: AppTypography.bodyMedium.copyWith(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      AzureButton(
                        text: 'Finalizar Cadastro',
                        isLoading: _isLoading,
                        onPressed: _handleRegister,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 4,
                children: [
                  Text(
                    'Já tem uma conta? ',
                    style: AppTypography.bodyMedium,
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Text(
                      'Fazer Login',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.primaryAzure,
                      ),
                    ),
                  ),
                ],
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
}
