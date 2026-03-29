/// Constantes de la aplicación
library;

class AppConstants {
  AppConstants._();

  // Supabase
  static const String supabaseUrl = 'https://ideulcafzllttoueamjw.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlkZXVsY2FmemxsdHRvdWVhbWp3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ4MTAzMzksImV4cCI6MjA5MDM4NjMzOX0.o7J-Gs10I0vKhhIC0qKvYn8CFvdl1IAXalTn8yEmp_g';

  // Roles de usuario
  static const String roleAdmin = 'admin';
  static const String roleCobrador = 'cobrador';

  // Estados de préstamos
  static const String loanStateActivo = 'activo';
  static const String loanStatePagado = 'pagado';
  static const String loanStateMora = 'mora';
  static const String loanStateAEntregar = 'a_entregar';

  // Estados de cuotas
  static const String installmentStatePagada = 'pagada';
  static const String installmentStatePendiente = 'pendiente';
  static const String installmentStateVencida = 'vencida';

  // Estados de caja
  static const String boxStateAbierta = 'abierta';
  static const String boxStateCerrada = 'cerrada';

  // Estados de clientes
  static const String clientStateActivo = 'activo';
  static const String clientStateInactivo = 'inactivo';

  // Resultados de intento de cobro
  static const String paymentResultPagado = 'pagado';
  static const String paymentResultNoPagado = 'no_pagado';
  static const String paymentResultDiferir = 'diferir';

  // Resultados de intento de entrega
  static const String deliveryResultEntregado = 'entregado';
  static const String deliveryResultNoEntregado = 'no_entregado';
  static const String deliveryResultDiferir = 'diferir';

  // Mora por defecto
  static const double defaultMoraPerDay = 50.0;
}
