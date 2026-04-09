// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/app_config.dart';
import 'config/app_theme.dart';
import 'config/app_router.dart';
import 'providers/providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );
  runApp(const ProviderScope(child: NirmanApp()));
}

class NirmanApp extends ConsumerWidget {
  const NirmanApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // FIX: Activate persistence listener here so it runs for the app's lifetime.
    // This replaces the old approach where selectedProjectProvider was writing
    // to SharedPreferences inside a FutureProvider build — which caused a race
    // condition between read (projectInitProvider) and write (selectedProjectProvider)
    // both touching SharedPreferences simultaneously during startup, resulting in
    // the 1680 skipped frames.
    ref.watch(projectPersistProvider);

    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

// FIX: Moved GoRouterRefreshStream here so it's only defined once
// (was duplicated between main.dart and app_router.dart in the original).
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    // FIX: _sub is now typed as StreamSubscription instead of dynamic
    _sub = stream.listen((_) => notifyListeners());
  }
  late final dynamic _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
