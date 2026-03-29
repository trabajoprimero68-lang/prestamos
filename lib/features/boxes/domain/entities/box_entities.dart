/// Entidades de Cajas
library;

import 'package:equatable/equatable.dart';

enum BoxState { abierta, cerrada }

enum MovementType { apertura, cobro, rendicion, ajuste }

class CashBoxEntity extends Equatable {
  final String id;
  final String cobradorId;
  final double initialAmount;
  final double currentAmount;
  final BoxState estado;
  final DateTime openedAt;
  final DateTime? closedAt;

  const CashBoxEntity({
    required this.id,
    required this.cobradorId,
    required this.initialAmount,
    required this.currentAmount,
    required this.estado,
    required this.openedAt,
    this.closedAt,
  });

  bool get isOpen => estado == BoxState.abierta;
  double get totalCobrado => currentAmount - initialAmount;

  factory CashBoxEntity.fromJson(Map<String, dynamic> json) {
    return CashBoxEntity(
      id: json['id'] as String,
      cobradorId: json['cobrador_id'] as String,
      initialAmount: (json['initial_amount'] as num).toDouble(),
      currentAmount: (json['current_amount'] as num).toDouble(),
      estado: json['estado'] == 'abierta' ? BoxState.abierta : BoxState.cerrada,
      openedAt: DateTime.parse(json['opened_at'] as String),
      closedAt: json['closed_at'] != null 
          ? DateTime.parse(json['closed_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cobrador_id': cobradorId,
      'initial_amount': initialAmount,
      'current_amount': currentAmount,
      'estado': estado == BoxState.abierta ? 'abierta' : 'cerrada',
      'opened_at': openedAt.toIso8601String(),
      'closed_at': closedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, cobradorId, initialAmount, currentAmount, estado, openedAt, closedAt];
}

class CashBoxMovement extends Equatable {
  final String id;
  final String boxId;
  final MovementType type;
  final double amount;
  final String? description;
  final DateTime createdAt;

  const CashBoxMovement({
    required this.id,
    required this.boxId,
    required this.type,
    required this.amount,
    this.description,
    required this.createdAt,
  });

  factory CashBoxMovement.fromJson(Map<String, dynamic> json) {
    return CashBoxMovement(
      id: json['id'] as String,
      boxId: json['box_id'] as String,
      type: _parseMovementType(json['type'] as String),
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  static MovementType _parseMovementType(String type) {
    switch (type) {
      case 'apertura':
        return MovementType.apertura;
      case 'cobro':
        return MovementType.cobro;
      case 'rendicion':
        return MovementType.rendicion;
      case 'ajuste':
        return MovementType.ajuste;
      default:
        return MovementType.ajuste;
    }
  }

  @override
  List<Object?> get props => [id, boxId, type, amount, description, createdAt];
}
