// lib/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/supabase_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _signInWithGoogle() async {
    setState(() { _loading = true; _error = null; });
    try {
      final success = await SupabaseService.signInWithGoogle();
      if (!success && mounted) {
        setState(() => _error = 'Sign in cancelled. Please try again.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Error: $e');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A0A04),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Center(
                  child: Text('N', style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFFF6B2B),
                    fontFamily: 'Arial Black',
                  )),
                ),
              ),
              const SizedBox(height: 20),
              const Text('NirmanApp',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
              const SizedBox(height: 6),
              const Text('Track your house construction',
                  style: TextStyle(fontSize: 15, color: Color(0xFF9E9E9E))),
              const Spacer(flex: 2),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: _loading ? null : _signInWithGoogle,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE0E0E0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: Colors.white,
                  ),
                  child: _loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.network(
                              'https://www.google.com/favicon.ico',
                              width: 20, height: 20,
                              errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, size: 24, color: Color(0xFFE24B4A)),
                            ),
                            const SizedBox(width: 12),
                            const Text('Continue with Google',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF1A1A1A))),
                          ],
                        ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCEBEB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_error!,
                      style: const TextStyle(color: Color(0xFFE24B4A), fontSize: 13)),
                ),
              ],
              const SizedBox(height: 20),
              const Text(
                'Access is restricted to invited members.\nNew users require admin approval.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Color(0xFFAAAAAA), height: 1.6),
              ),
              const Spacer(flex: 1),
              const Text('NirmanApp v1.0 • Made with ❤️ in Hyderabad',
                  style: TextStyle(fontSize: 11, color: Color(0xFFCCCCCC))),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
