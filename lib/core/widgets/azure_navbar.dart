import 'package:flutter/material.dart';
import '../../features/classrooms/screens/classrooms_screen.dart';
import '../../features/classrooms/widgets/notifications_sheet.dart';
import '../../features/events/screens/events_screen.dart';
import '../../features/profile/models/user_profile_model.dart';
import '../../features/profile/screens/meus_dados_screen.dart';
import '../services/supabase_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class AzureNavbar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final String currentRoute;
  final bool showBackButton;

  const AzureNavbar({
    super.key,
    required this.title,
    required this.currentRoute,
    this.showBackButton = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64.0);

  @override
  State<AzureNavbar> createState() => _AzureNavbarState();
}

class _AzureNavbarState extends State<AzureNavbar> {
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _checkUnreadNotifications();
  }

  Future<void> _checkUnreadNotifications() async {
    try {
      final count = await SupabaseService.instance.getUnreadNotificationsCount();
      if (mounted) {
        setState(() => _unreadNotifications = count);
      }
    } catch (_) {}
  }

  void _navigateTo(BuildContext context, String route) {
    if (widget.currentRoute == route) return;

    if (route == '/meus-dados') {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const MeusDadosScreen(),
          transitionsBuilder: (context, anim, _, child) => FadeTransition(opacity: anim, child: child),
        ),
      );
    } else if (route == '/turmas') {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const ClassroomsScreen(),
          transitionsBuilder: (context, anim, _, child) => FadeTransition(opacity: anim, child: child),
        ),
      );
    } else if (route == '/eventos') {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const EventsScreen(),
          transitionsBuilder: (context, anim, _, child) => FadeTransition(opacity: anim, child: child),
        ),
      );
    }
  }

  void _showNavigationMenu(BuildContext context) async {
    UserProfileModel? profile;
    try {
      profile = await SupabaseService.instance.getProfile();
    } catch (_) {}

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 28),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Barra de arraste
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Identificação do Usuário Logado
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.azureLight,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primaryAzure.withValues(alpha: 0.2)),
                    ),
                    child: ClipOval(
                      child: (profile?.avatarUrl != null && profile!.avatarUrl!.isNotEmpty)
                          ? Image.network(profile.avatarUrl!, fit: BoxFit.cover)
                          : Center(
                              child: Text(
                                profile?.fullName.isNotEmpty == true ? profile!.fullName[0].toUpperCase() : 'U',
                                style: AppTypography.titleMedium.copyWith(color: AppColors.primaryAzure),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile?.fullName.isNotEmpty == true ? profile!.fullName : 'Usuário Conectado',
                          style: AppTypography.labelMedium.copyWith(fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          profile?.email.isNotEmpty == true ? profile!.email : 'Sessão ativa',
                          style: AppTypography.bodyMedium.copyWith(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, color: AppColors.border),

              Text(
                'MÓDULOS DO SISTEMA',
                style: AppTypography.labelMedium.copyWith(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 10),

              // Item 1: Meus Dados
              _buildMenuItem(
                context: ctx,
                title: 'Meus Dados',
                subtitle: 'Perfil, dados de contato e crianças cadastradas',
                icon: Icons.person_pin_rounded,
                route: '/meus-dados',
                badgeText: 'Perfil',
              ),
              const SizedBox(height: 6),

              // Item 2: Check-in Kids
              _buildMenuItem(
                context: ctx,
                title: 'Check-in Kids',
                subtitle: 'Entrada de crianças e impressão Brother DK-1201',
                icon: Icons.qr_code_scanner_rounded,
                route: '/checkin',
                badgeText: 'Entrada',
              ),
              const SizedBox(height: 6),

              // Item 3: Avisos do Kids
              _buildMenuItem(
                context: ctx,
                title: 'Avisos & Chamadas',
                subtitle: 'Notificações enviadas pelos professores das salas',
                icon: Icons.notifications_active_outlined,
                route: '/avisos',
                badgeText: 'Avisos',
                customTap: () {
                  Navigator.of(ctx).pop();
                  NotificationsSheet.show(context);
                },
              ),

              // Item 3: Gestão de Turmas (Apenas Professores e Administradores)
              if (profile?.isTeacher == true || profile?.isAdmin == true) ...[
                const SizedBox(height: 6),
                _buildMenuItem(
                  context: ctx,
                  title: 'Gestão de Turmas',
                  subtitle: 'Salas infantis, capacidade e presença ao vivo',
                  icon: Icons.meeting_room_rounded,
                  route: '/turmas',
                  badgeText: 'Salas',
                ),
              ],

              // Item 4: Gestão de Eventos (Apenas Administradores)
              if (profile?.isAdmin == true) ...[
                const SizedBox(height: 6),
                _buildMenuItem(
                  context: ctx,
                  title: 'Gestão de Eventos',
                  subtitle: 'Cultos, horários e abertura de salas',
                  icon: Icons.calendar_month_rounded,
                  route: '/eventos',
                  badgeText: 'Abertura',
                ),
              ],

              const Divider(height: 24, color: AppColors.border),

              // Botão Sair da Conta
              InkWell(
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await SupabaseService.instance.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.errorSubtle,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Encerrar Sessão',
                        style: AppTypography.labelMedium.copyWith(color: AppColors.error),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required String route,
    required String badgeText,
    VoidCallback? customTap,
  }) {
    final isSelected = widget.currentRoute == route;

    return InkWell(
      onTap: () {
        if (customTap != null) {
          customTap();
        } else {
          Navigator.of(context).pop();
          _navigateTo(context, route);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.azureSubtle : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryAzure.withValues(alpha: 0.3) : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryAzure : AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: AppTypography.labelMedium.copyWith(
                          fontSize: 14,
                          color: isSelected ? AppColors.primaryAzure : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryAzure,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.bodyMedium.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: isSelected ? AppColors.primaryAzure : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
          bottom: BorderSide(color: AppColors.border, width: 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              // Botão Voltar (se ativado) ou Logo Oficial
              if (widget.showBackButton)
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textPrimary),
                  tooltip: 'Voltar',
                  onPressed: () => Navigator.of(context).pop(),
                )
              else
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryAzure.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Image.asset(
                      'assets/images/logo.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.rocket_launch_rounded,
                        color: AppColors.primaryAzure,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 12),

              // Título da View atual com estilo refinado
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: AppTypography.titleMedium.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryAzure,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Duna Kids',
                          style: AppTypography.bodyMedium.copyWith(
                            fontSize: 11,
                            color: AppColors.primaryAzure,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Botão de Notificações / Avisos com Badge de Alerta
              InkWell(
                onTap: () async {
                  await NotificationsSheet.show(context);
                  _checkUnreadNotifications();
                },
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: _unreadNotifications > 0 ? const Color(0xFFFEF2F2) : AppColors.azureLight,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _unreadNotifications > 0 ? const Color(0xFFEF4444) : AppColors.primaryAzure.withValues(alpha: 0.25),
                          width: 1.2,
                        ),
                      ),
                      child: Icon(
                        _unreadNotifications > 0 ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                        color: _unreadNotifications > 0 ? const Color(0xFFDC2626) : AppColors.primaryAzure,
                        size: 19,
                      ),
                    ),
                    if (_unreadNotifications > 0)
                      Positioned(
                        top: -3,
                        right: 2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
                          child: Center(
                            child: Text(
                              '$_unreadNotifications',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Botão Dropdown Moderno no estilo pílula com ícone
              InkWell(
                onTap: () => _showNavigationMenu(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.azureLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primaryAzure.withValues(alpha: 0.25),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.grid_view_rounded,
                        color: AppColors.primaryAzure,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Menu',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.primaryAzure,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.primaryAzure,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
