/// Utilidades para cálculos de fecha y mora
library;

/// Calcula la mora basada en días de atraso
/// 
/// Fórmula: mora = moraConfig.monto × días_de_atraso
/// Ejemplo: $50 × 3 días = $150 de mora
double calculateMora({
  required double moraPerDay,
  required DateTime dueDate,
  DateTime? paymentDate,
}) {
  final effectivePaymentDate = paymentDate ?? DateTime.now();
  final daysOverdue = effectivePaymentDate.difference(dueDate).inDays;
  
  if (daysOverdue <= 0) {
    return 0;
  }
  
  return moraPerDay * daysOverdue;
}

/// Calcula los días de atraso desde la fecha de vencimiento
int calculateDaysOverdue(DateTime dueDate, {DateTime? fromDate}) {
  final effectiveFromDate = fromDate ?? DateTime.now();
  final days = effectiveFromDate.difference(dueDate).inDays;
  return days > 0 ? days : 0;
}

/// Verifica si una fecha está vencida
bool isOverdue(DateTime dueDate, {DateTime? fromDate}) {
  final effectiveFromDate = fromDate ?? DateTime.now();
  return effectiveFromDate.isAfter(dueDate);
}

/// Obtiene la fecha de vencimiento de una cuota basada en el número de cuota
DateTime calculateInstallmentDueDate({
  required DateTime startDate,
  required int installmentNumber,
  required int intervalDays,
}) {
  return startDate.add(Duration(days: intervalDays * (installmentNumber - 1)));
}

/// Verifica si es el día de hoy
bool isToday(DateTime date) {
  final now = DateTime.now();
  return date.year == now.year && 
         date.month == now.month && 
         date.day == now.day;
}

/// Verifica si es el día de mañana
bool isTomorrow(DateTime date) {
  final tomorrow = DateTime.now().add(const Duration(days: 1));
  return date.year == tomorrow.year && 
         date.month == tomorrow.month && 
         date.day == tomorrow.day;
}

/// Obtiene el inicio del día
DateTime startOfDay(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

/// Obtiene el final del día
DateTime endOfDay(DateTime date) {
  return DateTime(date.year, date.month, date.day, 23, 59, 59);
}

/// Calcula la fecha límite para el siguiente día laborable
DateTime nextBusinessDay(DateTime date) {
  var next = date.add(const Duration(days: 1));
  while (next.weekday == DateTime.saturday || next.weekday == DateTime.sunday) {
    next = next.add(const Duration(days: 1));
  }
  return next;
}
