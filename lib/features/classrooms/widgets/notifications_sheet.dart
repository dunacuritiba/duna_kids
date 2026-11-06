import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/kid_notification_model.dart';

class NotificationsSheet extends StatefulWidget {
  const NotificationsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const NotificationsSheet(),
    );
  }

  @override
  State<NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<NotificationsSheet> {
  final DateFormat _timeFormat = DateFormat('HH:mm');
  final DateFormat _dateFormat = DateFormat('dd/MM');
  List<KidNotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    final list = await SupabaseService.instance.getKidNotificationsForCurrentGuardian();
    if (mounted) {
      setState(() {
        _notifications = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(KidNotificationModel notif) async {
    if (notif.isRead) return;
    await SupabaseService.instance.markKidNotificationAsRead(notif.id);
    _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Barra de arraste
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 38,
              height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),

          // Cabeçalho
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: AppColors.azureLight, shape: BoxShape.circle),
                      child: const Icon(Icons.notifications_active_rounded, color: AppColors.primaryAzure, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text('Avisos do Duna Kids', style: AppTypography.titleMedium.copyWith(fontSize: 16)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Lista de Notificações
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryAzure))
                : _notifications.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.notifications_none_rounded, size: 48, color: AppColors.textMuted),
                              const SizedBox(height: 12),
                              Text('Nenhum aviso no momento', style: AppTypography.labelMedium),
                              const SizedBox(height: 4),
                              Text(
                                'Quando os professores precisarem do seu comparecimento, o aviso aparecerá aqui.',
                                textAlign: TextAlign.center,
                                style: AppTypography.bodyMedium.copyWith(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadNotifications,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          itemCount: _notifications.length,
                          separatorBuilder: (c, i) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final notif = _notifications[index];
                            final isUnread = !notif.isRead;

                            return InkWell(
                              onTap: () => _markAsRead(notif),
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isUnread ? const Color(0xFFFEF2F2) : AppColors.surface,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isUnread ? const Color(0xFFFCA5A5) : AppColors.border,
                                    width: isUnread ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: isUnread ? const Color(0xFFEF4444).withValues(alpha: 0.15) : AppColors.azureLight,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isUnread ? Icons.priority_high_rounded : Icons.check_circle_outline_rounded,
                                        color: isUnread ? const Color(0xFFDC2626) : AppColors.primaryAzure,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  notif.title,
                                                  style: AppTypography.titleMedium.copyWith(
                                                    fontSize: 14,
                                                    fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                                    color: isUnread ? const Color(0xFF991B1B) : AppColors.textPrimary,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                '${_dateFormat.format(notif.createdAt.toLocal())} às ${_timeFormat.format(notif.createdAt.toLocal())}',
                                                style: AppTypography.codeBadge.copyWith(fontSize: 10),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            notif.message,
                                            style: AppTypography.bodyMedium.copyWith(fontSize: 12.5),
                                          ),
                                          if (notif.classroomName != null || notif.childName != null) ...[
                                            const SizedBox(height: 6),
                                            Wrap(
                                              spacing: 6,
                                              children: [
                                                if (notif.childName != null)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.surfaceSubtle,
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      'Criança: ${notif.childName}',
                                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                                    ),
                                                  ),
                                                if (notif.classroomName != null)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.surfaceSubtle,
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      'Sala: ${notif.classroomName}',
                                                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
