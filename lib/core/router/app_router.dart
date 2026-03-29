/// Configuración de rutas con GoRouter
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';

/// Provider para el router
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: true,
    routes: [
      // Ruta de login
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      
      // Ruta del dashboard (home)
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      
      // Ruta de clientes
      GoRoute(
        path: '/clients',
        name: 'clients',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Pantalla de Clientes - Por implementar')),
        ),
      ),
      
      // Ruta de préstamos
      GoRoute(
        path: '/loans',
        name: 'loans',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Pantalla de Préstamos - Por implementar')),
        ),
      ),
      
      // Ruta de cobros
      GoRoute(
        path: '/payments',
        name: 'payments',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Pantalla de Cobros - Por implementar')),
        ),
      ),
      
      // Ruta de cajas
      GoRoute(
        path: '/boxes',
        name: 'boxes',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Pantalla de Cajas - Por implementar')),
        ),
      ),
      
      // Ruta de configuración de moras
      GoRoute(
        path: '/mora-config',
        name: 'mora-config',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Configuración de Moras - Por implementar')),
        ),
      ),
    ],
    
    // Redirecciones
    redirect: (context, state) {
      // TODO: Agregar lógica de autenticación
      // Por ahora, todas las rutas van directo
      
      // Ejemplo de redirección:
      // final isLoggedIn = ref.read(authProvider).isLoggedIn;
      // final isLoginRoute = state.matchedLocation == '/login';
      // 
      // if (!isLoggedIn && !isLoginRoute) {
      //   return '/login';
      // }
      // if (isLoggedIn && isLoginRoute) {
      //   return '/dashboard';
      // }
      
      return null;
    },
    
    // Página de error
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Página no encontrada',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(state.matchedLocation),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/dashboard'),
              child: const Text('Ir al Dashboard'),
            ),
          ],
        ),
      ),
    ),
  );
});
