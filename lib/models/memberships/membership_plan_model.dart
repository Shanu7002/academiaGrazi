/// Plano do catálogo da academia (ex.: "Plano Conexão Semestral").
///
/// Só o admin lê e grava. Não é apagado: a exclusão é lógica, com
/// [active] = false, porque os planos dos alunos guardam uma cópia dos
/// dados dele ([MembershipModel]).
class MembershipPlanModel {
  final String id;
  final String name;

  /// Valor da mensalidade em centavos (evita erro de arredondamento).
  final int monthlyPriceCents;

  /// Vigência do plano em meses; gera uma mensalidade por mês.
  final int durationMonths;

  /// Texto livre, ex.: "Musculação + Pilates".
  final String? modalities;
  final bool active;

  /// Gravado uma única vez, na criação do documento.
  final DateTime? createdAt;

  const MembershipPlanModel({
    required this.id,
    required this.name,
    required this.monthlyPriceCents,
    required this.durationMonths,
    this.modalities,
    this.active = true,
    this.createdAt,
  });

  /// Documento completo, usado somente na criação.
  Map<String, dynamic> toJson() => {
    'name': name,
    'monthlyPriceCents': monthlyPriceCents,
    'durationMonths': durationMonths,
    if (modalities != null) 'modalities': modalities,
    'active': active,
    if (createdAt != null) 'createdAt': createdAt!.toUtc().toIso8601String(),
  };

  factory MembershipPlanModel.fromJson(Map<String, dynamic> json, String id) {
    final createdAt = json['createdAt'];
    return MembershipPlanModel(
      id: id,
      name: (json['name'] as String?) ?? '',
      monthlyPriceCents: (json['monthlyPriceCents'] as num?)?.toInt() ?? 0,
      durationMonths: (json['durationMonths'] as num?)?.toInt() ?? 1,
      modalities: json['modalities'] as String?,
      active: json['active'] as bool? ?? true,
      createdAt: createdAt is String ? DateTime.tryParse(createdAt) : null,
    );
  }
}
