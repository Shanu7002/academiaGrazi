import 'package:academiagrazi/models/memberships/membership_model.dart';
import 'package:academiagrazi/models/memberships/membership_plan_model.dart';
import 'package:academiagrazi/service/memberships/membership_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore db;
  late MembershipService service;
  final now = DateTime.utc(2026, 11, 16, 12);

  setUp(() {
    db = FakeFirebaseFirestore();
    service = MembershipService(db: db, clock: () => now);
  });

  Future<MembershipPlanModel> createPlan({
    String name = 'Semestral',
    int price = 12990,
    int months = 6,
    String? modalities = 'Musculação + Pilates',
  }) async {
    final id = await service.createPlan(
      name: name,
      monthlyPriceCents: price,
      durationMonths: months,
      modalities: modalities,
    );
    final plans = await service.streamPlans(includeInactive: true).first;
    return plans.firstWhere((plan) => plan.id == id);
  }

  group('catálogo |', () {
    test('cria plano com createdAt e lista em ordem alfabética', () async {
      await createPlan(name: 'Trimestral');
      await createPlan(name: '  Anual  ', modalities: '  ');

      final plans = await service.streamPlans().first;

      expect(plans.map((plan) => plan.name), ['Anual', 'Trimestral']);
      expect(plans.first.modalities, isNull);
      expect(plans.first.createdAt, now);
    });

    test('recusa nome vazio, valor zero e duração fora do limite', () {
      expect(
        () => service.createPlan(
          name: ' ',
          monthlyPriceCents: 100,
          durationMonths: 1,
        ),
        throwsArgumentError,
      );
      expect(
        () => service.createPlan(
          name: 'X',
          monthlyPriceCents: 0,
          durationMonths: 1,
        ),
        throwsArgumentError,
      );
      expect(
        () => service.createPlan(
          name: 'X',
          monthlyPriceCents: 100,
          durationMonths: 37,
        ),
        throwsRangeError,
      );
    });

    test(
      'edita sem reescrever createdAt e remove modalidades vazias',
      () async {
        final plan = await createPlan();
        final createdAt =
            (await db.collection('membershipPlans').doc(plan.id).get())
                .data()!['createdAt'];

        await service.updatePlan(
          plan.id,
          name: 'Semestral Plus',
          monthlyPriceCents: 14990,
          durationMonths: 6,
          modalities: '',
        );

        final data =
            (await db.collection('membershipPlans').doc(plan.id).get()).data()!;
        expect(data['name'], 'Semestral Plus');
        expect(data['monthlyPriceCents'], 14990);
        expect(data.containsKey('modalities'), isFalse);
        expect(data['createdAt'], createdAt);
      },
    );

    test('plano desativado só aparece na gestão', () async {
      final plan = await createPlan();

      await service.setPlanActive(plan.id, active: false);

      expect(await service.streamPlans().first, isEmpty);
      expect(
        await service.streamPlans(includeInactive: true).first,
        hasLength(1),
      );
    });
  });

  group('plano do aluno |', () {
    test('atribui copiando os dados do plano', () async {
      final plan = await createPlan();

      await service.assignPlan(
        studentId: 'aluno1',
        plan: plan,
        startDate: DateTime(2026, 11, 20, 18),
        adminId: 'admin1',
      );

      final membership = await service.streamActiveMembership('aluno1').first;
      expect(membership, isNotNull);
      expect(membership!.planName, 'Semestral');
      expect(membership.modalities, 'Musculação + Pilates');
      expect(membership.monthlyPriceCents, 12990);
      expect(membership.durationMonths, 6);
      expect(membership.startDate, DateTime(2026, 11, 20));
      expect(membership.createdBy, 'admin1');
      final raw = (await db.collection('memberships').get()).docs.single.data();
      expect(raw['startDate'], '2026-11-20');
      expect(raw['status'], 'active');
    });

    test('atribuir outro plano encerra o anterior', () async {
      final plan = await createPlan();
      final firstId = await service.assignPlan(
        studentId: 'aluno1',
        plan: plan,
        startDate: DateTime(2026, 1, 1),
        adminId: 'admin1',
      );
      final anual = await createPlan(name: 'Anual', months: 12);

      final secondId = await service.assignPlan(
        studentId: 'aluno1',
        plan: anual,
        startDate: DateTime(2026, 7, 1),
        adminId: 'admin1',
      );

      final first =
          (await db.collection('memberships').doc(firstId).get()).data()!;
      expect(first['status'], 'closed');
      expect(first['closedAt'], now.toIso8601String());
      final active = await service.streamActiveMembership('aluno1').first;
      expect(active?.id, secondId);
      expect(await service.streamActiveMemberships().first, hasLength(1));
    });

    test('não atribui plano retirado do catálogo', () async {
      final plan = await createPlan();
      await service.setPlanActive(plan.id, active: false);
      final inactive =
          (await service.streamPlans(includeInactive: true).first).single;

      expect(
        () => service.assignPlan(
          studentId: 'aluno1',
          plan: inactive,
          startDate: DateTime(2026, 1, 1),
          adminId: 'admin1',
        ),
        throwsStateError,
      );
    });

    test('aluno sem plano recebe null', () async {
      expect(await service.streamActiveMembership('aluno1').first, isNull);
    });

    test('encerrar tira o plano ativo do aluno', () async {
      final plan = await createPlan();
      final id = await service.assignPlan(
        studentId: 'aluno1',
        plan: plan,
        startDate: DateTime(2026, 1, 1),
        adminId: 'admin1',
      );

      await service.closeMembership(id);

      expect(await service.streamActiveMembership('aluno1').first, isNull);
    });
  });

  group('mensalidades |', () {
    late String membershipId;

    setUp(() async {
      final plan = await createPlan(months: 3);
      membershipId = await service.assignPlan(
        studentId: 'aluno1',
        plan: plan,
        startDate: DateTime(2026, 1, 10),
        adminId: 'admin1',
      );
    });

    Future<MembershipModel> current() async =>
        (await service.streamActiveMembership('aluno1').first)!;

    test('registra pagamento em ordem de mensalidade', () async {
      await service.recordPayment(
        membershipId,
        installment: 2,
        paidOn: DateTime(2026, 2, 9),
        method: PaymentMethod.cash,
        amountCents: 12990,
        adminId: 'admin1',
      );
      await service.recordPayment(
        membershipId,
        installment: 1,
        paidOn: DateTime(2026, 1, 10),
        method: PaymentMethod.pix,
        amountCents: 10000,
        adminId: 'admin1',
      );

      final membership = await current();
      expect(membership.payments.map((p) => p.installment), [1, 2]);
      final first = membership.paymentFor(1)!;
      expect(first.method, PaymentMethod.pix);
      expect(first.amountCents, 10000);
      expect(first.paidOn, DateTime(2026, 1, 10));
      expect(first.recordedBy, 'admin1');
      expect(first.recordedAt, now);
    });

    test('não registra a mesma mensalidade duas vezes', () async {
      Future<void> pay() => service.recordPayment(
        membershipId,
        installment: 1,
        paidOn: DateTime(2026, 1, 10),
        method: PaymentMethod.pix,
        amountCents: 12990,
        adminId: 'admin1',
      );
      await pay();

      await expectLater(pay(), throwsStateError);
      expect((await current()).payments, hasLength(1));
    });

    test('recusa mensalidade fora da vigência', () async {
      await expectLater(
        service.recordPayment(
          membershipId,
          installment: 4,
          paidOn: DateTime(2026, 4, 10),
          method: PaymentMethod.pix,
          amountCents: 12990,
          adminId: 'admin1',
        ),
        throwsRangeError,
      );
    });

    test('desfaz o pagamento registrado por engano', () async {
      await service.recordPayment(
        membershipId,
        installment: 1,
        paidOn: DateTime(2026, 1, 10),
        method: PaymentMethod.card,
        amountCents: 12990,
        adminId: 'admin1',
      );

      await service.undoPayment(membershipId, installment: 1);

      expect((await current()).payments, isEmpty);
    });

    test('plano encerrado não aceita pagamento', () async {
      await service.closeMembership(membershipId);

      await expectLater(
        service.recordPayment(
          membershipId,
          installment: 1,
          paidOn: DateTime(2026, 1, 10),
          method: PaymentMethod.pix,
          amountCents: 12990,
          adminId: 'admin1',
        ),
        throwsStateError,
      );
    });
  });
}
