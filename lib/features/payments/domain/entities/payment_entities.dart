/// Entidades de Pagos
library;

import 'package:equatable/equatable.dart';

enum PaymentResult { pagado, noPagado, diferir }

class PaymentAttemptEntity extends Equatable {
  final String id;
  final String installmentId;
  final String cobradorId;
  final DateTime fecha;
  final PaymentResult resultado;
  final double? montoCobrado;
  final double moraDelDia;
  final String? observaciones;
  final DateTime createdAt;

  const PaymentAttemptEntity({
    required this.id,
    required this.installmentId,
    required this.cobradorId,
    required this.fecha,
    required this.resultado,
    this.montoCobrado,
    required this.moraDelDia,
    this.observaciones,
    required this.createdAt,
  });

  factory PaymentAttemptEntity.fromJson(Map<String, dynamic> json) {
    return PaymentAttemptEntity(
      id: json['id'] as String,
      installmentId: json['installment_id'] as String,
      cobradorId: json['cobrador_id'] as String,
      fecha: DateTime.parse(json['fecha'] as String),
      resultado: _parseResult(json['resultado'] as String),
      montoCobrado: (json['monto_cobrado'] as num?)?.toDouble(),
      moraDelDia: (json['mora_del_dia'] as num?)?.toDouble() ?? 0.0,
      observaciones: json['observaciones'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  static PaymentResult _parseResult(String result) {
    switch (result) {
      case 'pagado':
        return PaymentResult.pagado;
      case 'no_pagado':
        return PaymentResult.noPagado;
      case 'diferir':
        return PaymentResult.diferir;
      default:
        return PaymentResult.noPagado;
    }
  }

  @override
  List<Object?> get props => [id, installmentId, cobradorId, fecha, resultado, montoCobrado, moraDelDia, observaciones, createdAt];
}
