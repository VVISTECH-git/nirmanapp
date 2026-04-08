// lib/screens/notifications/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../widgets/shared_widgets.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () async {
              await SupabaseService.markAllNotificationsRead();
              ref.invalidate(notificationsProvider);
              ref.invalidate(unreadCountProvider);
            },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: notifAsync.when(
        loading: () => const LoadingScreen(),
        error: (e, _) => Center(child: Text('$e')),
        data: (notifs) {
          if (notifs.isEmpty) {
            return const EmptyState(
              title: 'No notifications',
              subtitle: 'You\'re all caught up!',
              icon: Icons.notifications_none_outlined,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifs.length,
            itemBuilder: (_, i) => _NotifCard(notif: notifs[i]),
          );
        },
      ),
    );
  }
}

class _NotifCard extends StatelessWidget {
  final AppNotification notif;
  const _NotifCard({required this.notif});

  IconData get _icon {
    switch (notif.type) {
      case 'access_approved': return Icons.check_circle_outline;
      case 'task_overdue': return Icons.schedule;
      case 'payment_due': return Icons.payments_outlined;
      case 'issue_opened': return Icons.bug_report_outlined;
      default: return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: notif.isRead ? Colors.white : const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: notif.isRead ? const Color(0xFFEEEEEE) : const Color(0xFFB5D4F4),
          width: 0.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFE6F1FB),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(_icon, size: 18, color: const Color(0xFF185FA5)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notif.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                if (notif.body != null) ...[
                  const SizedBox(height: 2),
                  Text(notif.body!, style: const TextStyle(fontSize: 13, color: Color(0xFF666666))),
                ],
                const SizedBox(height: 4),
                Text(
                  _timeAgo(notif.createdAt),
                  style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E)),
                ),
              ],
            ),
          ),
          if (!notif.isRead)
            Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF378ADD), shape: BoxShape.circle)),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
