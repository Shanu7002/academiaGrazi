import 'package:academiagrazi/service/training/exercise_catalog_service.dart';

/// Dados de apresentacao; nao modifica a prescricao nem o historico.
/// Os nomes editoriais em PT-BR podem ser usados mesmo antes de as instrucoes
/// serem traduzidas. Nao inventa traducoes tecnicas de exercicios.
abstract final class StudentExercisePresentation {
  static String name(String original, ExerciseCatalogEntry? catalog) {
    final translated = catalog?.name.trim() ?? '';
    return catalog != null && catalog.hasPortugueseName && translated.isNotEmpty
        ? translated
        : original;
  }

  static String muscleGroup(String original) {
    const translated = <String, String>{
      'abs': 'Abdômen', 'abdominals': 'Abdômen', 'core': 'Abdômen',
      'quads': 'Quadríceps', 'quadriceps': 'Quadríceps',
      'hamstrings': 'Posterior de coxa', 'glutes': 'Glúteos',
      'calves': 'Panturrilhas', 'chest': 'Peito', 'back': 'Costas',
      'lats': 'Costas', 'shoulders': 'Ombros', 'biceps': 'Bíceps',
      'triceps': 'Tríceps', 'forearms': 'Antebraços',
      'lower back': 'Lombar', 'legs': 'Pernas', 'hips': 'Quadril',
      'full body': 'Corpo inteiro', 'cardio': 'Cardiorrespiratório',
    };
    return translated[original.trim().toLowerCase()] ?? original;
  }

  static String? image(String? original, ExerciseCatalogEntry? catalog) {
    for (final candidate in [original, catalog?.imageUrl, catalog?.imageUrlPeak]) {
      if (candidate == null || candidate.trim().isEmpty) continue;
      final uri = Uri.tryParse(candidate.trim());
      if (uri != null && uri.scheme == 'https' && uri.host.isNotEmpty) {
        return candidate.trim();
      }
    }
    return null;
  }

  /// Orientacao do professor em portugues sempre tem prioridade. Se ainda
  /// nao existir, usa a traducao do catalogo; traducoes automaticas sao
  /// identificadas ao aluno, pois aguardam revisao por Educacao Fisica.
  static StudentExerciseGuidance guidance(
    String snapshotInstructions,
    ExerciseCatalogEntry? catalog,
  ) {
    final snapshot = snapshotInstructions.trim();
    final official = catalog?.instructions.trim() ?? '';
    final autoDraft = catalog?.instructionsPtBrDraft.trim() ?? '';

    // Ficha pode ter instrucao personalizada pelo professor. Nao ocultar
    // textos validos em portugues so porque o item nasceu na RepDB.
    if (snapshot.isNotEmpty && !looksEnglish(snapshot) &&
        (snapshot.length >= 8 || catalog == null || catalog.source == 'manual')) {
      return StudentExerciseGuidance(snapshot);
    }
    if (catalog?.language == 'pt-BR' && official.isNotEmpty &&
        !looksEnglish(official)) {
      return StudentExerciseGuidance(official,
          automaticTranslation: catalog?.translationStatus == 'automatic_pending_review');
    }
    if (autoDraft.isNotEmpty && !looksEnglish(autoDraft)) {
      return StudentExerciseGuidance(autoDraft, automaticTranslation: true);
    }
    return const StudentExerciseGuidance(null);
  }

  static String? portugueseInstructions(
    String original,
    ExerciseCatalogEntry? catalog,
  ) => guidance(original, catalog).text;

  static bool looksEnglish(String text) {
    final hits = RegExp(
      r'\b(the|your|you|with|while|through|until|then|should|start|stand|hold|keep|lower|raise|extend|bend|pull|push|feet|hands|arms|legs|elbows|shoulders|backwards|repeat|return)\b',
      caseSensitive: false,
    ).allMatches(text).length;
    return hits >= 2 ||
        RegExp(r'^(stand|hold|keep|lower|raise|extend|bend|pull|push|sit|lie|place)\b',
            caseSensitive: false).hasMatch(text.trim());
  }
}

/// Texto para exibicao. Rascunhos automaticos precisam de aviso explicito.
class StudentExerciseGuidance {
  final String? text;
  final bool automaticTranslation;
  const StudentExerciseGuidance(this.text, {this.automaticTranslation = false});
}
