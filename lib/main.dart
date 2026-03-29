/// Punto de entrada de la aplicación
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/constants/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // TODO: Inicializar Supabase con credenciales reales
  // await SupabaseClientManager.initializeWithDefaults();
  
  runApp(
    const ProviderScope(
      child: AleGestionApp(),
    ),
  );
}

class AleGestionApp extends ConsumerWidget {
  const AleGestionApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      title: 'ALE Gestión',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}
