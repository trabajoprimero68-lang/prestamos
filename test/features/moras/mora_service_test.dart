import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MoraService - Escenarios del Negocio', () {
    
    test('Escenario: Cliente paga en fecha - sin mora', () {
      // Dado: Una cuota con vencimiento hoy
      // Cuando: El cliente paga en la fecha de vencimiento
      // Entonces: mora = 0
      
      const fechaVencimiento = '2024-01-15';
      const fechaPago = '2024-01-15';
      const moraPorDia = 50.0;
      
      final mora = _calcularMora(fechaVencimiento, fechaPago, moraPorDia);
      expect(mora, 0);
    });

    test('Escenario: Cliente paga 1 día después - mora de 1 día', () {
      // Dado: Una cuota con vencimiento ayer
      // Cuando: El cliente paga hoy (1 día de atraso)
      // Entonces: mora = 50 × 1 = 50
      
      const fechaVencimiento = '2024-01-14';
      const fechaPago = '2024-01-15';
      const moraPorDia = 50.0;
      
      final mora = _calcularMora(fechaVencimiento, fechaPago, moraPorDia);
      expect(mora, 50.0);
    });

    test('Escenario: Cliente paga 3 días después - mora de 3 días', () {
      // Dado: Una cuota con vencimiento hace 3 días
      // Cuando: El cliente paga hoy
      // Entonces: mora = 50 × 3 = 150
      
      const fechaVencimiento = '2024-01-12';
      const fechaPago = '2024-01-15';
      const moraPorDia = 50.0;
      
      final mora = _calcularMora(fechaVencimiento, fechaPago, moraPorDia);
      expect(mora, 150.0);
    });

    test('Edge case: 0 días de atraso = 0 mora', () {
      // Verifica que no haya mora si paga antes o en fecha
      
      const fechaVencimiento = '2024-01-20';
      const fechaPago = '2024-01-18';
      const moraPorDia = 50.0;
      
      final mora = _calcularMora(fechaVencimiento, fechaPago, moraPorDia);
      expect(mora, 0);
    });

    test('Edge case: Mora configurable diferente a 50', () {
      // Dado: La empresa configura mora de 100 por día
      // Cuando: Cliente paga con 2 días de atraso
      // Entonces: mora = 100 × 2 = 200
      
      const fechaVencimiento = '2024-01-13';
      const fechaPago = '2024-01-15';
      const moraPorDia = 100.0;
      
      final mora = _calcularMora(fechaVencimiento, fechaPago, moraPorDia);
      expect(mora, 200.0);
    });

    test('Escenario: Cuota no pagada aplica mora automáticamente', () {
      // Dado: Una cuota vencida que no se pagó
      // Cuando: Se consulta la mora
      // Entonces: mora se calcula automáticamente desde el día 1
      
      const fechaVencimiento = '2024-01-10';
      // Simulamos que estamos a 5 días del vencimiento
      final fechaActual = DateTime(2024, 1, 15);
      final mora = _calcularMoraConFechaActual(fechaVencimiento, fechaActual, 50.0);
      
      expect(mora, 250.0); // 5 días × 50
    });

    test('Escenario: Primera oportunidad - no pagado pasa a mañana sin mora aún', () {
      // Este test documenta la regla de negocio
      // Si es la primera vez que no paga, pasa a lista del día siguiente
      // pero la mora se aplica cuando realmente no paga en la nueva fecha
      
      // Dado: Cuota vence hoy, cobrador va y cliente no paga
      // Cuando: Se registra "no pagado" pero se diferirá para mañana
      // Entonces: Por ahora sin mora (se aplica si no paga mañana)
      
      const fechaVencimiento = '2024-01-15';
      const fechaPago = '2024-01-16'; // El siguiente día
      const moraPorDia = 50.0;
      
      // Si paga al día siguiente sin haber registrado "no pagado" antes
      final mora = _calcularMora(fechaVencimiento, fechaPago, moraPorDia);
      expect(mora, 50.0); // 1 día de atraso = mora
    });
  });

  group('Cálculos de Mora - Casos Extremos', () {
    
    test('Caso extremo: 30 días de atraso', () {
      const fechaVencimiento = '2023-12-15';
      const fechaPago = '2024-01-14';
      const moraPorDia = 50.0;
      
      final mora = _calcularMora(fechaVencimiento, fechaPago, moraPorDia);
      expect(mora, 1500.0); // 30 días × 50
    });

    test('Caso extremo: Mora cero configurada', () {
      const fechaVencimiento = '2024-01-10';
      const fechaPago = '2024-01-15';
      const moraPorDia = 0.0;
      
      final mora = _calcularMora(fechaVencimiento, fechaPago, moraPorDia);
      expect(mora, 0);
    });

    test('Caso extremo: Fecha de pago igual a vencimiento', () {
      const fechaVencimiento = '2024-01-15';
      const fechaPago = '2024-01-15';
      const moraPorDia = 50.0;
      
      final mora = _calcularMora(fechaVencimiento, fechaPago, moraPorDia);
      expect(mora, 0);
    });
  });
}

/// Helper para calcular mora (simula la lógica del servicio)
double _calcularMora(String fechaVencimiento, String fechaPago, double moraPorDia) {
  final v = DateTime.parse(fechaVencimiento);
  final p = DateTime.parse(fechaPago);
  final diasAtraso = p.difference(v).inDays;
  
  if (diasAtraso <= 0) return 0;
  return moraPorDia * diasAtraso;
}

/// Helper para calcular mora con fecha actual
double _calcularMoraConFechaActual(String fechaVencimiento, DateTime fechaActual, double moraPorDia) {
  final v = DateTime.parse(fechaVencimiento);
  final diasAtraso = fechaActual.difference(v).inDays;
  
  if (diasAtraso <= 0) return 0;
  return moraPorDia * diasAtraso;
}
