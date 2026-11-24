/// Unidade física da academia (na UI, "Bloco" ou "Unidade").
///
/// Não é apagada: a exclusão é lógica, com [active] = false, porque
/// alunos e turnos da escala apontam para ela.
class UnitModel {
  final String id;
  final String name;
  final String? address;
  final bool active;

  /// Gravado uma única vez, na criação do documento.
  final DateTime? createdAt;

  const UnitModel({
    required this.id,
    required this.name,
    this.address,
    this.active = true,
    this.createdAt,
  });

  /// Documento completo, usado somente na criação.
  Map<String, dynamic> toJson() => {
    'name': name,
    if (address != null) 'address': address,
    'active': active,
    if (createdAt != null) 'createdAt': createdAt!.toUtc().toIso8601String(),
  };

  factory UnitModel.fromJson(Map<String, dynamic> json, String id) {
    final createdAt = json['createdAt'];
    return UnitModel(
      id: id,
      name: (json['name'] as String?) ?? '',
      address: json['address'] as String?,
      active: json['active'] as bool? ?? true,
      createdAt: createdAt is String ? DateTime.tryParse(createdAt) : null,
    );
  }
}
