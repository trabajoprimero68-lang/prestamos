import 'package:flutter_test/flutter_test.dart';
import 'package:ale_gestion/core/utils/date_utils.dart';

void main() {
  group('calculateMora', () {
    test('debe retornar 0 si no hay atraso', () {
      final mora = calculateMora(
        moraPerDay: 50.0,
        dueDate: DateTime.now(),
        paymentDate: DateTime.now(),
      );
      expect(mora, 0);
    });

    test('debe retornar 50 si hay 1 día de atraso', () {
      final mora = calculateMora(
        moraPerDay: 50.0,
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
        paymentDate: DateTime.now(),
      );
      expect(mora, 50.0);
    });

    test('debe retornar 250 si hay 5 días de atraso', () {
      final mora = calculateMora(
        moraPerDay: 50.0,
        dueDate: DateTime.now().subtract(const Duration(days: 5)),
        paymentDate: DateTime.now(),
      );
      expect(mora, 250.0);
    });

    test('debe retornar 150 si hay 3 días de atraso', () {
      final mora = calculateMora(
        moraPerDay: 50.0,
        dueDate: DateTime.now().subtract(const Duration(days: 3)),
        paymentDate: DateTime.now(),
      );
      expect(mora, 150.0);
    });

    test('debe usar fecha actual si no se especifica paymentDate', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final mora = calculateMora(
        moraPerDay: 50.0,
        dueDate: yesterday,
      );
      expect(mora, 50.0);
    });

    test('debe calcular correctamente con mora de 100 por día', () {
      final mora = calculateMora(
        moraPerDay: 100.0,
        dueDate: DateTime.now().subtract(const Duration(days: 2)),
        paymentDate: DateTime.now(),
      );
      expect(mora, 200.0);
    });
  });

  group('calculateDaysOverdue', () {
    test('debe retornar 0 si no hay atraso', () {
      final days = calculateDaysOverdue(DateTime.now().add(const Duration(days: 1)));
      expect(days, 0);
    });

    test('debe retornar 1 si hay 1 día de atraso', () {
      final days = calculateDaysOverdue(DateTime.now().subtract(const Duration(days: 1)));
      expect(days, 1);
    });

    test('debe retornar 10 si hay 10 días de atraso', () {
      final days = calculateDaysOverdue(DateTime.now().subtract(const Duration(days: 10)));
      expect(days, 10);
    });

    test('debe retornar 0 si la fecha es hoy', () {
      final days = calculateDaysOverdue(DateTime.now());
      expect(days, 0);
    });
  });

  group('isOverdue', () {
    test('debe retornar true si la fecha está vencida', () {
      final result = isOverdue(DateTime.now().subtract(const Duration(days: 1)));
      expect(result, true);
    });

    test('debe retornar false si la fecha no está vencida', () {
      final result = isOverdue(DateTime.now().add(const Duration(days: 1)));
      expect(result, false);
    });

    test('debe retornar false si la fecha es hoy', () {
      final result = isOverdue(DateTime.now());
      expect(result, false);
    });
  });

  group('calculateInstallmentDueDate', () {
    test('debe calcular fecha de primera cuota correctamente', () {
      final startDate = DateTime(2024, 1, 1);
      final dueDate = calculateInstallmentDueDate(
        startDate: startDate,
        installmentNumber: 1,
        intervalDays: 30,
      );
      expect(dueDate, DateTime(2024, 1, 1));
    });

    test('debe calcular fecha de segunda cuota correctamente', () {
      final startDate = DateTime(2024, 1, 1);
      final dueDate = calculateInstallmentDueDate(
        startDate: startDate,
        installmentNumber: 2,
        intervalDays: 30,
      );
      expect(dueDate, DateTime(2024, 1, 31));
    });

    test('debe calcular fecha de cuota con intervalo de 15 días', () {
      final startDate = DateTime(2024, 1, 1);
      final dueDate = calculateInstallmentDueDate(
        startDate: startDate,
        installmentNumber: 3,
        intervalDays: 15,
      );
      expect(dueDate, DateTime(2024, 1, 16));
    });
  });

  group('isToday', () {
    test('debe retornar true para fecha de hoy', () {
      expect(isToday(DateTime.now()), true);
    });

    test('debe retornar false para fecha de mañana', () {
      expect(isToday(DateTime.now().add(const Duration(days: 1))), false);
    });

    test('debe retornar false para fecha de ayer', () {
      expect(isToday(DateTime.now().subtract(const Duration(days: 1))), false);
    });
  });

  group('startOfDay', () {
    test('debe retornar medianoche del mismo día', () {
      final result = startOfDay(DateTime(2024, 5, 15, 14, 30, 45));
      expect(result, DateTime(2024, 5, 15, 0, 0, 0));
    });
  });

  group('endOfDay', () {
    test('debe retornar el final del día', () {
      final result = endOfDay(DateTime(2024, 5, 15, 10, 0, 0));
      expect(result, DateTime(2024, 5, 15, 23, 59, 59));
    });
  });
}
