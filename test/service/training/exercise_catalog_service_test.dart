import 'package:academiagrazi/service/training/exercise_catalog_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('novo exercicio fica salvo e pesquisavel', () async {
    final db = FakeFirebaseFirestore();
    final service = ExerciseCatalogService(db: db);
    final entry = await service.createCustom(
      teacherId: 'prof-1', name: 'Supino Inclinado',
      muscleGroup: 'Peito', imageUrl: 'https://example.org/supino.jpg',
    );
    final results = await service.search(query: 'supino');
    expect(results.any((e) => e.id == entry.id), isTrue);
    expect(results.single.imageUrl, 'https://example.org/supino.jpg');
  });
  test('nome editorial em PT-BR nao implica instrucao traduzida', () async {
    final db = FakeFirebaseFirestore();
    final service = ExerciseCatalogService(db: db);
    await db.collection('exerciseCatalog').doc('repdb-levantamento').set({
      'name': 'Levantamento Terra',
      'nameNormalized': 'levantamento terra',
      'muscleGroup': 'Pernas',
      'instructions': 'Keep your back neutral.',
      'source': 'repdb-free',
      'nameReviewStatus': 'editorial_pending_review',
      // language nao foi alterado pela migracao de nomes v6.
    });
    final result = await service.findByIds(['repdb-levantamento']);
    final entry = result['repdb-levantamento']!;
    expect(entry.hasPortugueseName, isTrue);
    expect(entry.language, isEmpty);
    expect(entry.instructions, 'Keep your back neutral.');
  });

  test('consulta varios exercicios ja traduzidos sem um get por exercicio', () async {
    final db = FakeFirebaseFirestore();
    final service = ExerciseCatalogService(db: db);
    await db.collection('exerciseCatalog').doc('repdb-supino').set({
      'name': 'Supino Reto',
      'nameNormalized': 'supino reto',
      'muscleGroup': 'Peito',
      'instructions': 'Mantenha os pes apoiados no chao.',
      'imageUrl': 'https://example.org/supino.webp',
      'source': 'repdb-free',
      'language': 'pt-BR',
    });
    final found = await service.findByIds(['repdb-supino', 'repdb-inexistente']);
    expect(found.length, 1);
    expect(found['repdb-supino']?.language, 'pt-BR');
    expect(found['repdb-supino']?.hasPortugueseName, isTrue);
    expect(found['repdb-supino']?.instructions,
        'Mantenha os pes apoiados no chao.');
  });
}
