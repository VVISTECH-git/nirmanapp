// lib/screens/auth/pending_approval_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/supabase_service.dart';
import '../../providers/providers.dart';

class PendingApprovalScreen extends ConsumerWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final email = SupabaseService.currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFFAEEDA),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Icon(Icons.hourglass_top_rounded, size: 40, color: Color(0xFFBA7517)),
              ),
              const SizedBox(height: 24),
              const Text('Awaiting approval',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
              const SizedBox(height: 10),
              Text(
                'You\'ve signed in as\n$email\n\nThe project admin will review and approve your access. You\'ll receive an email notification once approved.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Color(0xFF666666), height: 1.7),
              ),
              const Spacer(flex: 2),
              // Refresh button - check if approved
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => ref.invalidate(currentProfileProvider),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Check approval status'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () async {
                  await SupabaseService.signOut();
                },
                child: const Text('Sign out', style: TextStyle(color: Color(0xFF9E9E9E))),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
