/// Entidades de Préstamos
library;

import 'package:equatable/equatable.dart';

enum LoanStatus { aEntregar, activo, pagado, mora }

class LoanEntity extends Equatable {
  final String id;
  final String clientId;
  final String clientNombre;
  final double monto;
  final double interes;
  final int cantidadCuotas;
  final double montoCuota;
  final DateTime fechaInicio;
  final LoanStatus estado;
  final DateTime? fechaEntrega;
  final DateTime createdAt;

  const LoanEntity({
    required this.id,
    required this.clientId,
    required this.clientNombre,
    required this.monto,
    required this.interes,
    required this.cantidadCuotas,
    required this.montoCuota,
    required this.fechaInicio,
    required this.estado,
    this.fechaEntrega,
    required this.createdAt,
  });

  double get montoTotal => monto + (monto * interes / 100);

  factory LoanEntity.fromJson(Map<String, dynamic> json) {
    return LoanEntity(
      id: json['id'] as String,
      clientId: json['client_id'] as String,
      clientNombre: json['clients']?['nombre'] as String? ?? 'Sin nombre',
      monto: (json['monto'] as num).toDouble(),
      interes: (json['interes'] as num).toDouble(),
      cantidadCuotas: json['cantidad_cuotas'] as int,
      montoCuota: (json['monto_cuota'] as num).toDouble(),
      fechaInicio: DateTime.parse(json['fecha_inicio'] as String),
      estado: _parseStatus(json['estado'] as String),
      fechaEntrega: json['fecha_entrega'] != null 
          ? DateTime.parse(json['fecha_entrega'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  static LoanStatus _parseStatus(String status) {
    switch (status) {
      case 'a_entregar':
        return LoanStatus.aEntregar;
      case 'activo':
        return LoanStatus.activo;
      case 'pagado':
        return LoanStatus.pagado;
      case 'mora':
        return LoanStatus.mora;
      default:
        return LoanStatus.activo;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'client_id': clientId,
      'monto': monto,
      'interes': interes,
      'cantidad_cuotas': cantidadCuotas,
      'monto_cuota': montoCuota,
      'fecha_inicio': fechaInicio.toIso8601String().split('T')[0],
      'estado': estado.name,
      'fecha_entrega': fechaEntrega?.toIso8601String().split('T')[0],
    };
  }

  @override
  List<Object?> get props => [id, clientId, clientNombre, monto, interes, cantidadCuotas, montoCuota, fechaInicio, estado, fechaEntrega, createdAt];
}

class InstallmentEntity extends Equatable {
  final String id;
  final String loanId;
  final int numeroCuota;
  final double monto;
  final double montoPagado;
  final double moraAplicada;
  final DateTime fechaVencimiento;
  final DateTime? fechaPago;
  final String estado;

  const InstallmentEntity({
    required this.id,
    required this.loanId,
    required this.numeroCuota,
    required this.monto,
    required this.montoPagado,
    required this.moraAplicada,
    required this.fechaVencimiento,
    this.fechaPago,
    required this.estado,
  });

  double get totalAPagar => monto + moraAplicada;
  double get pendiente => totalAPagar - montoPagado;
  bool get isPaid => estado == 'pagada';
  bool get isOverdue => estado == 'vencida' || (estado == 'pendiente' && fechaVencimiento.isBefore(DateTime.now()));

  factory InstallmentEntity.fromJson(Map<String, dynamic> json) {
    return InstallmentEntity(
      id: json['id'] as String,
      loanId: json['loan_id'] as String,
      numeroCuota: json['numero_cuota'] as int,
      monto: (json['monto'] as num).toDouble(),
      montoPagado: (json['monto_pagado'] as num?)?.toDouble() ?? 0.0,
      moraAplicada: (json['mora_aplicada'] as num?)?.toDouble() ?? 0.0,
      fechaVencimiento: DateTime.parse(json['fecha_vencimiento'] as String),
      fechaPago: json['fecha_pago'] != null 
          ? DateTime.parse(json['fecha_pago'] as String)
          : null,
      estado: json['estado'] as String,
    );
  }

  @override
  List<Object?> get props => [id, loanId, numeroCuota, monto, montoPagado, moraAplicada, fechaVencimiento, fechaPago, estado];
}
