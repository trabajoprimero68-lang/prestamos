/// Entidades de Cliente
library;

import 'package:equatable/equatable.dart';

enum ClientStatus { activo, inactivo }

class ClientEntity extends Equatable {
  final String id;
  final String nombre;
  final String? telefono;
  final String? direccion;
  final String? documento;
  final ClientStatus estado;
  final DateTime createdAt;

  const ClientEntity({
    required this.id,
    required this.nombre,
    this.telefono,
    this.direccion,
    this.documento,
    required this.estado,
    required this.createdAt,
  });

  bool get isActive => estado == ClientStatus.activo;

  factory ClientEntity.fromJson(Map<String, dynamic> json) {
    return ClientEntity(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      telefono: json['telefono'] as String?,
      direccion: json['direccion'] as String?,
      documento: json['documento'] as String?,
      estado: json['estado'] == 'activo' ? ClientStatus.activo : ClientStatus.inactivo,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'telefono': telefono,
      'direccion': direccion,
      'documento': documento,
      'estado': estado == ClientStatus.activo ? 'activo' : 'inactivo',
    };
  }

  @override
  List<Object?> get props => [id, nombre, telefono, direccion, documento, estado, createdAt];
}
