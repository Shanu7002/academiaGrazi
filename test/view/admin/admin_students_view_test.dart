import 'package:academiagrazi/locator.dart';
import 'package:academiagrazi/models/users/user_model.dart';
import 'package:academiagrazi/service/admin/admin_dashboard.dart';
import 'package:academiagrazi/service/admin/admin_student_service.dart';
import 'package:academiagrazi/service/units/unit_service.dart';
import 'package:academiagrazi/view/admin/admin_student_details_view.dart';
import 'package:academiagrazi/view/admin/admin_students_view.dart';
import 'package:academiagrazi/view/components/user_avatar.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Falha na primeira assinatura de alunos e funciona nas seguintes.
class _ServiceInstavel extends AdminStudentService {
  var assinaturas = 0;

  _ServiceInstavel(FakeFirebaseFirestore db) : super(db: db);

  @override
  Stream<List<UserModel>> streamStudents() {
    assinaturas++;
    if (assinaturas == 1) return Stream.error(Exception('offline'));
    return super.streamStudents();
  }
}

void main() {
  late FakeFirebaseFirestore db;

  setUp(() async {
    await locator.reset();
    db = FakeFirebaseFirestore();
    locator.registerSingleton<AdminStudentService>(AdminStudentService(db: db));
    locator.registerSingleton<AdminDashboardService>(
      AdminDashboardService(db: db),
    );
    locator.registerSingleton<UnitService>(UnitService(db: db));
    await db.collection('users').doc('p1').set({
      'name': 'Prof. Lucas',
      'type': 'instructor',
    });
  });

  tearDown(() async => locator.reset());

  Future<void> addStudent(
    String id,
    String name, {
    String? modality,
    String? responsable,
    String? photoUrl,
  }) {
    return db.collection('users').doc(id).set({
      'name': name,
      'email': '$id@test.com',
      'type': 'user',
      if (modality != null) 'modality': modality,
      if (responsable != null) 'responsable': responsable,
      if (photoUrl != null) 'photoUrl': photoUrl,
    });
  }

  Future<void> abrir(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: AdminStudentsView()));
    await tester.pumpAndSettle();
  }

  testWidgets('lista todos os alunos com foto, professor e modalidade', (
    tester,
  ) async {
    const foto = 'https://res.cloudinary.com/demo/image/upload/ana.jpg';
    await addStudent(
      'a1',
      'Ana Lima',
      modality: 'remote',
      responsable: 'p1',
      photoUrl: foto,
    );
    await addStudent('a2', 'Bruno Alves');
    await abrir(tester);

    expect(find.text('Ana Lima'), findsOneWidget);
    expect(find.text('Prof. Lucas · Remoto'), findsOneWidget);
    expect(find.text('Bruno Alves'), findsOneWidget);
    expect(find.text('Sem professor · Sem modalidade'), findsOneWidget);
    final avatar = tester.widget<UserAvatar>(
      find.descendant(
        of: find.byKey(const Key('aluno_admin_a1')),
        matching: find.byType(UserAvatar),
      ),
    );
    expect(avatar.photoUrl, foto);
  });

  testWidgets('filtra os remotos e busca pelo nome', (tester) async {
    await addStudent('a1', 'Ana Lima', modality: 'remote');
    await addStudent('a2', 'Bruno Alves', modality: 'onSite');
    await addStudent('a3', 'Carla Souza', modality: 'remote');
    await abrir(tester);

    expect(find.text('Remotos (2)'), findsOneWidget);
    await tester.tap(find.byKey(const Key('filtro_alunos_remote')));
    await tester.pumpAndSettle();

    expect(find.text('Ana Lima'), findsOneWidget);
    expect(find.text('Carla Souza'), findsOneWidget);
    expect(find.text('Bruno Alves'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('campo_busca_aluno_admin')),
      'carla',
    );
    await tester.pumpAndSettle();

    expect(find.text('Ana Lima'), findsNothing);
    expect(find.text('Carla Souza'), findsOneWidget);
  });

  testWidgets('filtro sem resultado mostra aviso', (tester) async {
    await addStudent('a1', 'Ana Lima', modality: 'onSite');
    await abrir(tester);

    await tester.tap(find.byKey(const Key('filtro_alunos_remote')));
    await tester.pumpAndSettle();

    expect(
      find.text('Nenhum aluno encontrado com esse filtro.'),
      findsOneWidget,
    );
  });

  testWidgets('sem alunos mostra o estado vazio', (tester) async {
    await abrir(tester);

    expect(
      find.textContaining('Nenhum aluno cadastrado ainda.'),
      findsOneWidget,
    );
  });

  testWidgets('tocar no aluno abre os detalhes', (tester) async {
    await addStudent('a1', 'Ana Lima');
    await abrir(tester);

    await tester.tap(find.byKey(const Key('aluno_admin_a1')));
    await tester.pumpAndSettle();

    expect(find.byType(AdminStudentDetailsView), findsOneWidget);
  });

  testWidgets('na falha mostra erro e tenta de novo', (tester) async {
    await locator.unregister<AdminStudentService>();
    locator.registerSingleton<AdminStudentService>(_ServiceInstavel(db));
    await addStudent('a1', 'Ana Lima');
    await abrir(tester);

    expect(find.text('Não conseguimos carregar os alunos agora.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('botao_tentar_alunos')));
    await tester.pumpAndSettle();

    expect(find.text('Ana Lima'), findsOneWidget);
  });
}
