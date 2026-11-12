import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/models/users/registration_profile.dart';
import 'package:academiagrazi/models/users/user_model.dart';
import 'package:academiagrazi/service/admin/admin_dashboard.dart';
import 'package:academiagrazi/service/units/instructor_shift_service.dart';
import 'package:academiagrazi/service/units/unit_service.dart';
import 'package:academiagrazi/service/users/register_instructor.dart';
import 'package:academiagrazi/service/admin/admin_student_service.dart';
import 'package:academiagrazi/view/admin/admin_student_details_view.dart';
import 'package:academiagrazi/view/admin/instructor_details_view.dart';
import 'package:academiagrazi/view/admin/manual_redistribution_view.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDashboardService extends AdminDashboardService {
  final Future<InstructorDetails?> Function() onGetDetails;

  _FakeDashboardService(this.onGetDetails) : super(db: FakeFirebaseFirestore());

  @override
  Future<InstructorDetails?> getInstructorDetails(String instructorId) =>
      onGetDetails();
}

UserModel _student(
  String id,
  String name, {
  List<String> conditions = const ['Nenhuma dor'],
}) {
  return UserModel(
    id: id,
    name: name,
    email: '$id@grazi.com',
    registrationProfile: RegistrationProfile(
      measurements: const BodyMeasurements(
        age: 30,
        heightCm: 170,
        weightKg: 70,
      ),
      primaryGoal: PrimaryGoal.muscleGain,
      health: HealthProfile(
        conditions: conditions,
        notes: '',
        restrictions: const ['Não possuo'],
      ),
      emergencyContact: EmergencyContact(
        name: 'Maria',
        relationship: 'Pai / Mãe',
        phone: '11999998888',
      ),
    ),
  );
}

class _FakeInstructorService extends RegisterInstructorService {
  _FakeInstructorService() : super(db: FakeFirebaseFirestore());

  @override
  Future<InstructorInviteCode> getCurrentInviteCode(
    String instructorId, {
    String Function()? codeGenerator,
  }) async {
    return InstructorInviteCode(
      code: '4821',
      expiresAt: DateTime.now().add(const Duration(minutes: 15)),
    );
  }
}

void main() {
  final instructor = UserModel(
    id: 'p1',
    name: 'Marcos Silva',
    email: 'marcos@grazi.com',
    type: UserType.instructor,
  );

  setUp(() {
    locator.reset();
    locator.allowReassignment = true;
  });

  tearDown(() => locator.reset());

  Future<void> pumpView(
    WidgetTester tester,
    Future<InstructorDetails?> Function() onGetDetails,
  ) async {
    tester.view.physicalSize = const Size(430, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    locator.registerSingleton<AdminDashboardService>(
      _FakeDashboardService(onGetDetails),
    );
    locator.registerSingleton<RegisterInstructorService>(
      _FakeInstructorService(),
    );
    final db = FakeFirebaseFirestore();
    locator.registerSingleton<InstructorShiftService>(
      InstructorShiftService(db: db),
    );
    locator.registerSingleton<UnitService>(UnitService(db: db));
    await tester.pumpWidget(
      const MaterialApp(home: InstructorDetailsView(instructorId: 'p1')),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('mostra dados do professor, código e alunos', (tester) async {
    await pumpView(
      tester,
      () async => InstructorDetails(
        instructor: instructor,
        students: [
          InstructorStudent(
            user: _student('a1', 'Ana Souza', conditions: ['Joelho']),
            joinedAt: DateTime(2026, 3, 5),
          ),
          InstructorStudent(user: _student('a2', 'Bruno Lima')),
        ],
      ),
    );

    expect(find.text('Marcos Silva'), findsOneWidget);
    expect(find.text('marcos@grazi.com'), findsOneWidget);
    expect(find.text('4821'), findsOneWidget);
    expect(find.text('ALUNOS (2)'), findsOneWidget);
    expect(find.text('2/30'), findsOneWidget);
    expect(find.text('Ana Souza'), findsOneWidget);
    expect(
      find.text('Ganho de Massa Muscular • Desde 05/03/2026'),
      findsOneWidget,
    );
    expect(find.text('Atenção à saúde'), findsOneWidget);
    expect(find.byKey(const Key('secao_escala')), findsOneWidget);
  });

  testWidgets('filtra alunos pela busca', (tester) async {
    await pumpView(
      tester,
      () async => InstructorDetails(
        instructor: instructor,
        students: [
          InstructorStudent(user: _student('a1', 'Ana Souza')),
          InstructorStudent(user: _student('a2', 'Bruno Lima')),
        ],
      ),
    );

    await tester.enterText(find.byKey(const Key('campo_busca_aluno')), 'bru');
    await tester.pump();

    expect(find.text('Ana Souza'), findsNothing);
    expect(find.text('Bruno Lima'), findsOneWidget);
  });

  testWidgets('abre a ficha do aluno ao tocar', (tester) async {
    await pumpView(
      tester,
      () async => InstructorDetails(
        instructor: instructor,
        students: [
          InstructorStudent(
            user: _student('a1', 'Ana Souza', conditions: ['Joelho']),
          ),
        ],
      ),
    );

    await tester.ensureVisible(find.byKey(const Key('aluno_a1')));
    await tester.tap(find.byKey(const Key('aluno_a1')));
    await tester.pumpAndSettle();

    expect(find.text('30 anos • 170 cm • 70.0 kg'), findsOneWidget);
    expect(find.text('Joelho'), findsOneWidget);
    expect(find.text('Maria • Pai / Mãe • (11) 99999-8888'), findsOneWidget);
  });

  testWidgets('mostra estado vazio sem alunos', (tester) async {
    await pumpView(
      tester,
      () async => InstructorDetails(instructor: instructor, students: const []),
    );

    expect(find.text('ALUNOS (0)'), findsOneWidget);
    expect(find.textContaining('Nenhum aluno vinculado'), findsOneWidget);
    expect(find.byKey(const Key('campo_busca_aluno')), findsNothing);
  });

  testWidgets('avisa quando o professor não existe', (tester) async {
    await pumpView(tester, () async => null);

    expect(find.text('Professor não encontrado.'), findsOneWidget);
  });

  testWidgets('redistribuir abre a manual com o professor como origem', (
    tester,
  ) async {
    locator.registerSingleton<AdminStudentService>(
      AdminStudentService(db: FakeFirebaseFirestore()),
    );
    await pumpView(
      tester,
      () async => InstructorDetails(instructor: instructor, students: const []),
    );

    await tester.tap(find.byKey(const Key('botao_redistribuir_professor')));
    await tester.pumpAndSettle();

    final tela = tester.widget<ManualRedistributionView>(
      find.byType(ManualRedistributionView),
    );
    expect(tela.initialFromInstructorId, 'p1');
  });

  testWidgets('a ficha do aluno leva ao cadastro para editar o bloco', (
    tester,
  ) async {
    locator.registerSingleton<AdminStudentService>(
      AdminStudentService(db: FakeFirebaseFirestore()),
    );
    await pumpView(
      tester,
      () async => InstructorDetails(
        instructor: instructor,
        students: [InstructorStudent(user: _student('a1', 'Ana Souza'))],
      ),
    );

    await tester.tap(find.text('Ana Souza'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('botao_abrir_cadastro_aluno')),
    );
    await tester.tap(find.byKey(const Key('botao_abrir_cadastro_aluno')));
    await tester.pumpAndSettle();

    final tela = tester.widget<AdminStudentDetailsView>(
      find.byType(AdminStudentDetailsView),
    );
    expect(tela.studentId, 'a1');
  });
}
