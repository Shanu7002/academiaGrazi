import 'package:academiagrazi/controller/teachers/teacher_user_searcher.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lista os alunos vinculados com a foto de perfil', () async {
    final db = FakeFirebaseFirestore();
    await db.collection('users').doc('aluno-1').set({
      'name': 'Ana Lima',
      'type': 'user',
      'responsable': 'prof-1',
      'photoUrl': 'https://res.cloudinary.com/demo/image/upload/ana.jpg',
    });
    await db.collection('users').doc('aluno-2').set({
      'name': 'Bruno Alves',
      'type': 'user',
      'responsable': 'prof-1',
    });
    await db.collection('users').doc('aluno-3').set({
      'name': 'Outro professor',
      'type': 'user',
      'responsable': 'prof-2',
    });

    final alunos =
        await TeacherUserSearcher(db: db).streamLinkedUsers('prof-1').first;
    final porId = {for (final aluno in alunos) aluno.id: aluno};

    expect(porId.keys, unorderedEquals(['aluno-1', 'aluno-2']));
    expect(
      porId['aluno-1']!.photoUrl,
      'https://res.cloudinary.com/demo/image/upload/ana.jpg',
    );
    expect(porId['aluno-2']!.photoUrl, isNull);
  });
}
