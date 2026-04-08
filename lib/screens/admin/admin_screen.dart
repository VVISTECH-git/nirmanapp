// lib/screens/admin/admin_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../widgets/shared_widgets.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingUsersProvider);
    final approvedAsync = ref.watch(approvedUsersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(title: const Text('Admin panel')),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: SectionHeader('Access requests'),
            ),
          ),
          pendingAsync.when(
            loading: () => const SliverToBoxAdapter(child: LoadingScreen()),
            error: (e, _) => SliverToBoxAdapter(child: Center(child: Text('$e'))),
            data: (users) {
              if (users.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: _EmptyPending(),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: _PendingUserCard(user: users[i], ref: ref),
                  ),
                  childCount: users.length,
                ),
              );
            },
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: SectionHeader('Approved users'),
            ),
          ),
          approvedAsync.when(
            loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
            error: (e, _) => SliverToBoxAdapter(child: Center(child: Text('$e'))),
            data: (users) => SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: _ApprovedUserCard(user: users[i]),
                ),
                childCount: users.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

class _PendingUserCard extends StatefulWidget {
  final UserProfile user;
  final WidgetRef ref;
  const _PendingUserCard({required this.user, required this.ref});

  @override
  State<_PendingUserCard> createState() => _PendingUserCardState();
}

class _PendingUserCardState extends State<_PendingUserCard> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFAC775), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(initials: widget.user.initials, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.user.displayName,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    Text(widget.user.email,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
                    if (widget.user.requestedAt != null)
                      Text(
                        'Requested ${_timeAgo(widget.user.requestedAt!)} · via Google',
                        style: const TextStyle(fontSize: 11, color: Color(0xFFBA7517)),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAEEDA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Pending', style: TextStyle(fontSize: 11, color: Color(0xFFBA7517), fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _approve,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1D9E75)),
                    child: _loading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Approve'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: OutlinedButton(
                    onPressed: _loading ? null : _reject,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE24B4A)),
                      foregroundColor: const Color(0xFFE24B4A),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _approve() async {
    setState(() => _loading = true);
    try {
      await SupabaseService.approveUser(widget.user.id);
      widget.ref.invalidate(pendingUsersProvider);
      widget.ref.invalidate(approvedUsersProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.user.displayName} approved!')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _reject() async {
    setState(() => _loading = true);
    try {
      await SupabaseService.rejectUser(widget.user.id);
      widget.ref.invalidate(pendingUsersProvider);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _ApprovedUserCard extends StatelessWidget {
  final UserProfile user;
  const _ApprovedUserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 0.5),
      ),
      child: Row(
        children: [
          UserAvatar(initials: user.initials, imageUrl: user.avatarUrl, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.displayName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                Text(user.email, style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
              ],
            ),
          ),
          if (user.isSuperAdmin)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: const Color(0xFFEEEDFE), borderRadius: BorderRadius.circular(8)),
              child: const Text('Admin', style: TextStyle(fontSize: 11, color: Color(0xFF3C3489), fontWeight: FontWeight.w500)),
            )
          else
            const Icon(Icons.check_circle, color: Color(0xFF1D9E75), size: 18),
        ],
      ),
    );
  }
}

class _EmptyPending extends StatelessWidget {
  const _EmptyPending();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: const Column(
        children: [
          Icon(Icons.check_circle_outline, color: Color(0xFF1D9E75), size: 32),
          SizedBox(height: 8),
          Text('No pending requests', style: TextStyle(fontWeight: FontWeight.w500)),
          Text('All access requests have been reviewed.', style: TextStyle(fontSize: 12, color: Color(0xFF9E9E9E))),
        ],
      ),
    );
  }
}
