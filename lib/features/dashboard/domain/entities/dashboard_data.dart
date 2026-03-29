/// Entidades del Dashboard
library;

import 'package:equatable/equatable.dart';

/// Cliente
class Client extends Equatable {
  final String id;
  final String nombre;
  final String? telefono;
  final String estado;

  const Client({
    required this.id,
    required this.nombre,
    this.telefono,
    required this.estado,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      telefono: json['telefono'] as String?,
      estado: json['estado'] as String,
    );
  }

  @override
  List<Object?> get props => [id, nombre, telefono, estado];
}

/// Préstamo
class Loan extends Equatable {
  final String id;
  final String clientId;
  final String clientNombre;
  final double monto;
  final String estado;
  final DateTime? fechaEntrega;
  final DateTime fechaInicio;

  const Loan({
    required this.id,
    required this.clientId,
    required this.clientNombre,
    required this.monto,
    required this.estado,
    this.fechaEntrega,
    required this.fechaInicio,
  });

  factory Loan.fromJson(Map<String, dynamic> json) {
    return Loan(
      id: json['id'] as String,
      clientId: json['client_id'] as String,
      clientNombre: json['clients']?['nombre'] as String? ?? 'Sin nombre',
      monto: (json['monto'] as num).toDouble(),
      estado: json['estado'] as String,
      fechaEntrega: json['fecha_entrega'] != null 
          ? DateTime.parse(json['fecha_entrega'] as String)
          : null,
      fechaInicio: DateTime.parse(json['fecha_inicio'] as String),
    );
  }

  @override
  List<Object?> get props => [id, clientId, clientNombre, monto, estado, fechaEntrega, fechaInicio];
}

/// Cuota
class Installment extends Equatable {
  final String id;
  final String loanId;
  final String clientNombre;
  final double monto;
  final double montoPagado;
  final double moraAplicada;
  final DateTime fechaVencimiento;
  final DateTime? fechaPago;
  final String estado;

  const Installment({
    required this.id,
    required this.loanId,
    required this.clientNombre,
    required this.monto,
    required this.montoPagado,
    required this.moraAplicada,
    required this.fechaVencimiento,
    this.fechaPago,
    required this.estado,
  });

  double get totalAPagar => monto + moraAplicada;
  double get pendiente => totalAPagar - montoPagado;

  factory Installment.fromJson(Map<String, dynamic> json) {
    return Installment(
      id: json['id'] as String,
      loanId: json['loan_id'] as String,
      clientNombre: json['loans']?['clients']?['nombre'] as String? ?? 'Sin nombre',
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
  List<Object?> get props => [id, loanId, clientNombre, monto, montoPagado, moraAplicada, fechaVencimiento, fechaPago, estado];
}

/// Caja
class CashBox extends Equatable {
  final String id;
  final String cobradorId;
  final double initialAmount;
  final double currentAmount;
  final String estado;
  final DateTime openedAt;

  const CashBox({
    required this.id,
    required this.cobradorId,
    required this.initialAmount,
    required this.currentAmount,
    required this.estado,
    required this.openedAt,
  });

  factory CashBox.fromJson(Map<String, dynamic> json) {
    return CashBox(
      id: json['id'] as String,
      cobradorId: json['cobrador_id'] as String,
      initialAmount: (json['initial_amount'] as num).toDouble(),
      currentAmount: (json['current_amount'] as num).toDouble(),
      estado: json['estado'] as String,
      openedAt: DateTime.parse(json['opened_at'] as String),
    );
  }

  @override
  List<Object?> get props => [id, cobradorId, initialAmount, currentAmount, estado, openedAt];
}

/// Datos del Dashboard
class DashboardData extends Equatable {
  final List<Loan> aEntregar;
  final List<Installment> aCobrar;
  final List<Installment> pendientes;
  final CashBox? caja;

  const DashboardData({
    required this.aEntregar,
    required this.aCobrar,
    required this.pendientes,
    this.caja,
  });

  @override
  List<Object?> get props => [aEntregar, aCobrar, pendientes, caja];
}
