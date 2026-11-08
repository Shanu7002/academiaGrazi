import 'package:academiagrazi/models/training/training_plan.dart';
import 'package:academiagrazi/service/training/exercise_catalog_service.dart';
import 'package:academiagrazi/models/users/user_model.dart';
import 'package:academiagrazi/service/training/training_plan_service.dart';
import 'package:academiagrazi/service/users/register_user.dart';
import 'package:academiagrazi/view/user/adapters/training_plan_ui_mapper.dart';
import 'package:academiagrazi/view/user/ui_data/aluno_treinos_ui_data.dart';

/// Converte a ficha ativa do Firestore para a estrutura das telas de aluno.
/// Nao altera fichas, nao cria historico e nao substitui ausencia de dados
/// reais pelos mocks de demonstracao.
class StudentTrainingViewDataService {
  final TrainingPlanService _plans;
  final RegisterUserService _users;
  final DateTime Function() _clock;
  final ExerciseCatalogService? _catalog;

  StudentTrainingViewDataService({
    TrainingPlanService? planService,
    RegisterUserService? userService,
    DateTime Function()? clock,
    ExerciseCatalogService? catalogService,
  }) : _catalog = catalogService, _plans = planService ?? TrainingPlanService(),
       _users = userService ?? RegisterUserService(),
       _clock = clock ?? DateTime.now;

  Future<AlunoTreinosUiData?> getActiveUiData(String studentId) async {
    _validateStudentId(studentId);
    final plan = await _plans.getActivePlan(studentId);
    if (plan == null) return null;
    return _mapForStudent(studentId, plan);
  }

  /// Uma nova publicacao atualiza a aba do aluno sem precisar reiniciar o app.
  Stream<AlunoTreinosUiData?> watchActiveUiData(String studentId) {
    _validateStudentId(studentId);
    return _plans.watchActivePlan(studentId).asyncMap((plan) async {
      if (plan == null) return null;
      return _mapForStudent(studentId, plan);
    });
  }

  void _validateStudentId(String studentId) {
    if (studentId.trim().isEmpty) {
      throw ArgumentError.value(studentId, 'studentId', 'Aluno obrigatorio');
    }
  }

  Future<AlunoTreinosUiData> _mapForStudent(
    String studentId,
    TrainingPlan plan,
  ) async {
    if (plan.studentId != studentId ||
        plan.status != TrainingPlanStatus.published) {
      throw StateError('A ficha solicitada nao pertence ao aluno.');
    }

    final student = await _users.getUserById(studentId);
    if (student == null || student.type != UserType.user) {
      throw StateError('Aluno nao encontrado.');
    }
    // Se o vinculo mudou, nao apresenta a antiga ficha como vigente.
    if (student.responsable != plan.instructorId) {
      throw StateError('Esta ficha nao pertence ao professor atual do aluno.');
    }

    // Uma busca por lotes, sem N+1. Se a biblioteca estiver temporariamente
    // indisponivel, a ficha publicada continua legivel pelo snapshot.
    var catalog = <String, ExerciseCatalogEntry>{};
    final service = _catalog;
    if (service != null) {
      final ids = plan.routines.expand((routine) => routine.exercises)
          .map((exercise) => exercise.catalogExerciseId);
      try {
        catalog = await service.findByIds(ids);
      } catch (_) {
        // Nao bloqueia a ficha do aluno por falha secundaria da biblioteca.
      }
    }
    final instructor = await _users.getUserById(plan.instructorId);
    return TrainingPlanUiMapper.fromPlan(
      plan,
      studentName: student.name,
      instructorName: instructor?.name ?? 'Professor',
      now: _clock(),
      catalog: catalog,
    );
  }
}
