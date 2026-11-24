/// Situação do plano do aluno. Só um plano fica [active] por aluno: ao
/// atribuir outro, o anterior vira [closed].
enum MembershipStatus { active, closed }

/// Forma de pagamento registrada pelo admin (não há gateway no app).
enum PaymentMethod { pix, cash, card, transfer }

/// Plano atribuído a um aluno, com as mensalidades já pagas.
///
/// Guarda uma cópia do plano do catálogo (nome, valor, vigência) para que
/// uma mudança no catálogo não altere planos já contratados. As
/// mensalidades não são documentos: são calculadas a partir de
/// [startDate] e [durationMonths] (ver `membership_schedule.dart`), e
/// [payments] registra as que foram pagas.
class MembershipModel {
  final String id;
  final String studentId;
  final String planId;
  final String planName;
  final String? modalities;
  final int monthlyPriceCents;
  final int durationMonths;

  /// Data (sem hora) da primeira mensalidade e do início da vigência.
  final DateTime startDate;
  final MembershipStatus status;
  final List<MembershipPayment> payments;

  /// Gravado uma única vez, na criação do documento.
  final DateTime? createdAt;

  /// Admin que atribuiu o plano.
  final String createdBy;
  final DateTime? closedAt;

  const MembershipModel({
    required this.id,
    required this.studentId,
    required this.planId,
    required this.planName,
    this.modalities,
    required this.monthlyPriceCents,
    required this.durationMonths,
    required this.startDate,
    this.status = MembershipStatus.active,
    this.payments = const [],
    this.createdAt,
    required this.createdBy,
    this.closedAt,
  });

  /// Pagamento da mensalidade [installment] (1 = primeira), se houver.
  MembershipPayment? paymentFor(int installment) {
    for (final payment in payments) {
      if (payment.installment == installment) return payment;
    }
    return null;
  }

  /// Documento completo, usado somente na criação.
  Map<String, dynamic> toJson() => {
    'studentId': studentId,
    'planId': planId,
    'planName': planName,
    if (modalities != null) 'modalities': modalities,
    'monthlyPriceCents': monthlyPriceCents,
    'durationMonths': durationMonths,
    'startDate': formatDateOnly(startDate),
    'status': status.name,
    'payments': payments.map((payment) => payment.toJson()).toList(),
    if (createdAt != null) 'createdAt': createdAt!.toUtc().toIso8601String(),
    'createdBy': createdBy,
    if (closedAt != null) 'closedAt': closedAt!.toUtc().toIso8601String(),
  };

  factory MembershipModel.fromJson(Map<String, dynamic> json, String id) {
    final rawPayments = json['payments'];
    return MembershipModel(
      id: id,
      studentId: (json['studentId'] as String?) ?? '',
      planId: (json['planId'] as String?) ?? '',
      planName: (json['planName'] as String?) ?? '',
      modalities: json['modalities'] as String?,
      monthlyPriceCents: (json['monthlyPriceCents'] as num?)?.toInt() ?? 0,
      durationMonths: (json['durationMonths'] as num?)?.toInt() ?? 1,
      startDate: parseDateOnly(json['startDate'] as String?) ?? DateTime(1970),
      status: MembershipStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => MembershipStatus.closed,
      ),
      payments:
          rawPayments is List
              ? rawPayments
                  .whereType<Map>()
                  .map(
                    (raw) => MembershipPayment.fromJson(
                      Map<String, dynamic>.from(raw),
                    ),
                  )
                  .toList()
              : const [],
      createdAt: _parseInstant(json['createdAt']),
      createdBy: (json['createdBy'] as String?) ?? '',
      closedAt: _parseInstant(json['closedAt']),
    );
  }
}

/// Mensalidade paga, registrada manualmente pelo admin.
class MembershipPayment {
  /// Número da mensalidade (1 = primeira).
  final int installment;

  /// Data (sem hora) em que o aluno pagou.
  final DateTime paidOn;
  final PaymentMethod method;
  final int amountCents;

  /// Admin que registrou o pagamento.
  final String recordedBy;
  final DateTime recordedAt;

  const MembershipPayment({
    required this.installment,
    required this.paidOn,
    required this.method,
    required this.amountCents,
    required this.recordedBy,
    required this.recordedAt,
  });

  Map<String, dynamic> toJson() => {
    'installment': installment,
    'paidOn': formatDateOnly(paidOn),
    'method': method.name,
    'amountCents': amountCents,
    'recordedBy': recordedBy,
    'recordedAt': recordedAt.toUtc().toIso8601String(),
  };

  factory MembershipPayment.fromJson(Map<String, dynamic> json) {
    return MembershipPayment(
      installment: (json['installment'] as num?)?.toInt() ?? 0,
      paidOn: parseDateOnly(json['paidOn'] as String?) ?? DateTime(1970),
      method: PaymentMethod.values.firstWhere(
        (method) => method.name == json['method'],
        orElse: () => PaymentMethod.cash,
      ),
      amountCents: (json['amountCents'] as num?)?.toInt() ?? 0,
      recordedBy: (json['recordedBy'] as String?) ?? '',
      recordedAt: _parseInstant(json['recordedAt']) ?? DateTime(1970),
    );
  }
}

/// Data sem hora no formato do banco, `YYYY-MM-DD` (AGENTS.md §5.1).
String formatDateOnly(DateTime date) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${date.year.toString().padLeft(4, '0')}-${two(date.month)}-'
      '${two(date.day)}';
}

/// Lê `YYYY-MM-DD` como data local à meia-noite; `null` se inválida.
DateTime? parseDateOnly(String? value) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value ?? '');
  if (match == null) return null;
  return DateTime(
    int.parse(match[1]!),
    int.parse(match[2]!),
    int.parse(match[3]!),
  );
}

DateTime? _parseInstant(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
