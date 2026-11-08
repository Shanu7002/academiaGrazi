import 'package:cloud_firestore/cloud_firestore.dart';

/// Biblioteca compartilhada de movimentos. A prescricao guarda um snapshot
/// proprio no TrainingExercise e nao depende de consultas futuras ao catalogo.
class ExerciseCatalogEntry {
  final String id;
  final String name;
  final String muscleGroup;
  final String instructions;
  /// Rascunho automatico em PT-BR para exibicao identificada no DEV.
  final String instructionsPtBrDraft;
  final String? imageUrl;
  final String? imageUrlPeak;
  final String source;
  final String language;
  final String nameReviewStatus;
  final String translationStatus;

  /// Os nomes editoriais da v6 sao PT-BR, mesmo sem traducao das orientacoes.
  bool get hasPortugueseName => language == 'pt-BR' ||
      const {'editorial_pending_review', 'editorial_approved', 'reviewed'}
          .contains(nameReviewStatus);

  const ExerciseCatalogEntry({
    required this.id,
    required this.name,
    required this.muscleGroup,
    this.instructions = '',
    this.instructionsPtBrDraft = '',
    this.imageUrl,
    this.imageUrlPeak,
    this.source = 'manual',
    this.language = '',
    this.nameReviewStatus = '',
    this.translationStatus = '',
  });

  factory ExerciseCatalogEntry.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return ExerciseCatalogEntry(
      id: doc.id,
      name: (data['name'] as String?) ?? 'Exercicio sem nome',
      muscleGroup: (data['muscleGroup'] as String?) ?? 'Geral',
      instructions: (data['instructions'] as String?) ?? '',
      instructionsPtBrDraft: (data['instructionsPtBrDraft'] as String?) ?? '',
      imageUrl: data['imageUrl'] as String?,
      imageUrlPeak: data['imageUrlPeak'] as String?,
      source: (data['source'] as String?) ?? 'manual',
      language: (data['language'] as String?) ?? '',
      nameReviewStatus: (data['nameReviewStatus'] as String?) ?? '',
      translationStatus: (data['translationStatus'] as String?) ?? '',
    );
  }
}

class ExerciseCatalogService {
  final FirebaseFirestore _db;

  ExerciseCatalogService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  static String normalizeSearch(String input) {
    var value = input.trim().toLowerCase();
    const accents = {
      'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a',
      'é': 'e', 'ê': 'e', 'í': 'i',
      'ó': 'o', 'ô': 'o', 'õ': 'o', 'ú': 'u', 'ü': 'u',
      'ç': 'c',
    };
    accents.forEach((from, to) => value = value.replaceAll(from, to));
    return value.replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Busca paginada por prefixo. Nao baixa as 701 imagens nem todos os docs
  /// ao abrir a tela: uma consulta devolve no maximo [limit] itens.
  Future<List<ExerciseCatalogEntry>> search({
    String query = '',
    int limit = 60,
  }) async {
    final normalized = normalizeSearch(query);
    Query<Map<String, dynamic>> request =
        _db.collection('exerciseCatalog').orderBy('nameNormalized');
    if (normalized.isNotEmpty) {
      request = request
          .startAt([normalized])
          .endAt(['$normalized\uf8ff']);
    }
    final docs = await request.limit(limit < 1 ? 1 : (limit > 100 ? 100 : limit)).get();
    return docs.docs.map(ExerciseCatalogEntry.fromDoc).toList(growable: false);
  }

  /// Consulta varios exercicios da biblioteca por lotes, evitando N+1
  /// ao atualizar para portugues uma ficha antiga que veio de outro catalogo.
  Future<Map<String, ExerciseCatalogEntry>> findByIds(
    Iterable<String> ids,
  ) async {
    final unique = ids.where((id) => id.trim().isNotEmpty).toSet().toList();
    final found = <String, ExerciseCatalogEntry>{};
    for (var offset = 0; offset < unique.length; offset += 20) {
      final end = offset + 20 > unique.length ? unique.length : offset + 20;
      final current = unique.sublist(offset, end);
      final snapshot = await _db.collection('exerciseCatalog')
          .where(FieldPath.documentId, whereIn: current)
          .get();
      for (final doc in snapshot.docs) {
        found[doc.id] = ExerciseCatalogEntry.fromDoc(doc);
      }
    }
    return found;
  }

  /// Novo exercicio fica salvo e pesquisavel nas proximas fichas.
  /// As regras permitem criacao somente por um professor autenticado.
  Future<ExerciseCatalogEntry> createCustom({
    required String teacherId,
    required String name,
    required String muscleGroup,
    String instructions = '',
    String? imageUrl,
  }) async {
    final title = name.trim();
    final group = muscleGroup.trim();
    if (teacherId.isEmpty || title.isEmpty || group.isEmpty) {
      throw ArgumentError('Informe professor, nome e grupo muscular.');
    }
    if (imageUrl != null && imageUrl.isNotEmpty &&
        Uri.tryParse(imageUrl)?.scheme != 'https') {
      throw ArgumentError('A imagem deve usar uma URL HTTPS.');
    }
    final ref = _db.collection('exerciseCatalog').doc();
    await ref.set({
      'name': title,
      'nameNormalized': normalizeSearch(title),
      'muscleGroup': group,
      'instructions': instructions.trim(),
      'imageUrl': imageUrl ?? '',
      'source': 'manual',
      'createdBy': teacherId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ExerciseCatalogEntry(
      id: ref.id,
      name: title,
      muscleGroup: group,
      instructions: instructions.trim(),
      imageUrl: imageUrl,
    );
  }
}
