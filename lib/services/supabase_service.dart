// lib/services/supabase_service.dart
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/models.dart';
import '../config/app_config.dart';

class SupabaseService {
  static final _client = Supabase.instance.client;

  // ─── AUTH ───────────────────────────────────────────────

  static Future<bool> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn(
        clientId: Platform.isIOS
            ? AppConfig.googleClientIdIOS
            : AppConfig.googleClientIdAndroid,
        serverClientId: AppConfig.googleClientIdWeb,
        scopes: ['email', 'profile', 'openid'],
      );

      // Sign out first to force account picker every time
      await googleSignIn.signOut();

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return false;

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('idToken is null - check Android OAuth client ID and SHA-1');
      }

      await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      return true;
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _client.auth.signOut();
  }

  static User? get currentUser => _client.auth.currentUser;

  static Stream<AuthState> get authStateStream => _client.auth.onAuthStateChange;
