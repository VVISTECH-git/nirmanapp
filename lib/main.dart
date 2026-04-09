import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/app_config.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );
  runApp(const NirmanApp());
}

class NirmanApp extends StatelessWidget {
  const NirmanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NirmanApp',
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          final session = snapshot.data?.session;
          if (session != null) {
            return const HomeScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
