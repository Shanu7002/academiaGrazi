import 'package:academiagrazi/models/memberships/membership_model.dart';
import 'package:academiagrazi/models/memberships/membership_plan_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Catálogo de planos (`membershipPlans`) e planos dos alunos com as
/// mensalidades pagas (`memberships`). Só o admin grava; o aluno lê só o
/// próprio plano (ver `firestore.rules`). Não há gateway: o admin registra
/// cada pagamento.
class MembershipService {
  final FirebaseFirestore _db;
  final DateTime Function() _clock;

  // coverage:ignore-start
  MembershipService({FirebaseFirestore? db, DateTime Function()? clock})
    : _db = db ?? FirebaseFirestore.instance,
      _clock = clock ?? DateTime.now;
  // coverage:ignore-end

  /// Maior vigência aceita, igual à de `firestore.rules`.
  static const int maxDurationMonths = 36;

  CollectionReference<Map<String, dynamic>> get _plans =>
      _db.collection('membershipPlans');

  CollectionReference<Map<String, dynamic>> get _memberships =>
      _db.collection('memberships');

  // ---------------------------------------------------------------- catálogo

  /// Planos em ordem alfabética. Os retirados do catálogo só aparecem com
  /// [includeInactive] (tela de gestão).
  Stream<List<MembershipPlanModel>> streamPlans({
    bool includeInactive = false,
  }) {
    return _plans
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => MembershipPlanModel.fromJson(doc.data(), doc.id),
                  )
                  .where((plan) => includeInactive || plan.active)
                  .toList(),
        );
  }

  Future<String> createPlan({
    required String name,
    required int monthlyPriceCents,
    required int durationMonths,
    String? modalities,
  }) async {
    final plan = MembershipPlanModel(
      id: '',
      name: _requireName(name),
      monthlyPriceCents: _requirePrice(monthlyPriceCents),
      durationMonths: _requireDuration(durationMonths),
      modalities: _clean(modalities),
      createdAt: _clock(),
    );
    final reference = await _plans.add(plan.toJson());
    return reference.id;
  }

  /// Altera o plano do catálogo. Planos já atribuídos a alunos guardam a
  /// própria cópia e não mudam.
  Future<void> updatePlan(
    String planId, {
    required String name,
    required int monthlyPriceCents,
    required int durationMonths,
    String? modalities,
  }) {
    return _plans.doc(planId).update({
      'name': _requireName(name),
      'monthlyPriceCents': _requirePrice(monthlyPriceCents),
      'durationMonths': _requireDuration(durationMonths),
      'modalities': _clean(modalities) ?? FieldValue.delete(),
    });
  }

  /// Exclusão lógica: o plano some das escolhas, mas os alunos que já o
  /// têm continuam com ele.
  Future<void> setPlanActive(String planId, {required bool active}) {
    return _plans.doc(planId).update({'active': active});
  }

  // ----------------------------------------------------------- planos do aluno

  /// Plano ativo do aluno, ou `null` quando ele não tem plano.
  Stream<MembershipModel?> streamActiveMembership(String studentId) {
    return _activeQuery(studentId).snapshots().map((snapshot) {
      final memberships = _parse(snapshot.docs);
      if (memberships.isEmpty) return null;
      // Só deve existir um; se houver mais, vale o mais recente.
      memberships.sort(
        (a, b) => (b.createdAt ?? DateTime(1970)).compareTo(
          a.createdAt ?? DateTime(1970),
        ),
      );
      return memberships.first;
    });
  }

  /// Todos os planos ativos (controle de mensalidades do admin).
  Stream<List<MembershipModel>> streamActiveMemberships() {
    return _memberships
        .where('status', isEqualTo: MembershipStatus.active.name)
        .snapshots()
        .map((snapshot) => _parse(snapshot.docs));
  }

  /// Atribui [plan] ao aluno a partir de [startDate] e encerra o plano
  /// ativo anterior, se houver. Devolve o id do novo plano do aluno.
  Future<String> assignPlan({
    required String studentId,
    required MembershipPlanModel plan,
    required DateTime startDate,
    required String adminId,
  }) async {
    if (!plan.active) {
      throw StateError('Plan ${plan.id} is not active');
    }
    final now = _clock();
    final previous = await _activeQuery(studentId).get();
    final reference = _memberships.doc();
    final membership = MembershipModel(
      id: reference.id,
      studentId: studentId,
      planId: plan.id,
      planName: plan.name,
      modalities: plan.modalities,
      monthlyPriceCents: plan.monthlyPriceCents,
      durationMonths: plan.durationMonths,
      startDate: DateTime(startDate.year, startDate.month, startDate.day),
      createdAt: now,
      createdBy: adminId,
    );

    final batch = _db.batch();
    for (final doc in previous.docs) {
      batch.update(doc.reference, _closeFields(now));
    }
    batch.set(reference, membership.toJson());
    await batch.commit();
    return reference.id;
  }

  /// Encerra o plano do aluno sem atribuir outro.
  Future<void> closeMembership(String membershipId) {
    return _memberships.doc(membershipId).update(_closeFields(_clock()));
  }

  /// Registra o pagamento da mensalidade [installment] (1 = primeira).
  Future<void> recordPayment(
    String membershipId, {
    required int installment,
    required DateTime paidOn,
    required PaymentMethod method,
    required int amountCents,
    required String adminId,
  }) {
    final reference = _memberships.doc(membershipId);
    return _db.runTransaction((transaction) async {
      final membership = await _readActive(transaction, reference);
      if (installment < 1 || installment > membership.durationMonths) {
        throw RangeError.range(installment, 1, membership.durationMonths);
      }
      if (membership.paymentFor(installment) != null) {
        throw StateError('Installment $installment is already paid');
      }
      final payment = MembershipPayment(
        installment: installment,
        paidOn: DateTime(paidOn.year, paidOn.month, paidOn.day),
        method: method,
        amountCents: _requirePrice(amountCents),
        recordedBy: adminId,
        recordedAt: _clock(),
      );
      final payments = [...membership.payments, payment]
        ..sort((a, b) => a.installment.compareTo(b.installment));
      transaction.update(reference, {
        'payments': payments.map((p) => p.toJson()).toList(),
      });
    });
  }

  /// Desfaz um pagamento registrado por engano.
  Future<void> undoPayment(String membershipId, {required int installment}) {
    final reference = _memberships.doc(membershipId);
    return _db.runTransaction((transaction) async {
      final membership = await _readActive(transaction, reference);
      final payments =
          membership.payments
              .where((payment) => payment.installment != installment)
              .toList();
      transaction.update(reference, {
        'payments': payments.map((p) => p.toJson()).toList(),
      });
    });
  }

  Query<Map<String, dynamic>> _activeQuery(String studentId) {
    return _memberships
        .where('studentId', isEqualTo: studentId)
        .where('status', isEqualTo: MembershipStatus.active.name);
  }

  Future<MembershipModel> _readActive(
    Transaction transaction,
    DocumentReference<Map<String, dynamic>> reference,
  ) async {
    final snapshot = await transaction.get(reference);
    final data = snapshot.data();
    if (!snapshot.exists || data == null) {
      throw StateError('Membership ${reference.id} not found');
    }
    final membership = MembershipModel.fromJson(data, snapshot.id);
    if (membership.status != MembershipStatus.active) {
      throw StateError('Membership ${reference.id} is closed');
    }
    return membership;
  }

  static List<MembershipModel> _parse(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    return docs
        .map((doc) => MembershipModel.fromJson(doc.data(), doc.id))
        .toList();
  }

  static Map<String, dynamic> _closeFields(DateTime now) => {
    'status': MembershipStatus.closed.name,
    'closedAt': now.toUtc().toIso8601String(),
  };

  static String _requireName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(name, 'name', 'Plan name is required');
    }
    return trimmed;
  }

  static int _requirePrice(int cents) {
    if (cents <= 0) {
      throw ArgumentError.value(cents, 'cents', 'Price must be positive');
    }
    return cents;
  }

  static int _requireDuration(int months) {
    if (months < 1 || months > maxDurationMonths) {
      throw RangeError.range(months, 1, maxDurationMonths, 'durationMonths');
    }
    return months;
  }

  static String? _clean(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
