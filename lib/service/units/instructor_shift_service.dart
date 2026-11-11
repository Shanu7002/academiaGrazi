import 'package:academiagrazi/models/units/instructor_shift_model.dart';
import 'package:academiagrazi/service/units/shift_schedule.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// O turno novo cruza com [conflict], que já está na escala do professor.
class ShiftOverlapException implements Exception {
  final InstructorShiftModel conflict;

  const ShiftOverlapException(this.conflict);

  @override
  String toString() => 'ShiftOverlapException(${conflict.id})';
}

/// Escala dos professores (`instructorShifts`). Só o admin grava; qualquer
/// usuário autenticado lê (ver `firestore.rules`).
class InstructorShiftService {
  final FirebaseFirestore _db;
  final DateTime Function() _clock;

  // coverage:ignore-start
  InstructorShiftService({FirebaseFirestore? db, DateTime Function()? clock})
    : _db = db ?? FirebaseFirestore.instance,
      _clock = clock ?? DateTime.now;
  // coverage:ignore-end

  CollectionReference<Map<String, dynamic>> get _shifts =>
      _db.collection('instructorShifts');

  /// Turnos do professor, em ordem de dia da semana e horário.
  Stream<List<InstructorShiftModel>> streamShiftsForInstructor(
    String instructorId,
  ) {
    return _shifts
        .where('instructorId', isEqualTo: instructorId)
        .snapshots()
        .map((snapshot) {
          final shifts =
              snapshot.docs
                  .map(
                    (doc) => InstructorShiftModel.fromJson(doc.data(), doc.id),
                  )
                  .where((shift) => shift.isValid)
                  .toList();
          // Ordenado no app para não exigir índice composto.
          shifts.sort(
            (a, b) =>
                a.weekday != b.weekday
                    ? a.weekday.compareTo(b.weekday)
                    : a.startMinutes.compareTo(b.startMinutes),
          );
          return shifts;
        });
  }

  /// Cria o turno e devolve o id do documento. Lança
  /// [ShiftOverlapException] se cruzar com outro turno do professor.
  Future<String> addShift({
    required String instructorId,
    required String unitId,
    required int weekday,
    required String startTime,
    required String endTime,
  }) async {
    final shift = InstructorShiftModel(
      id: '',
      instructorId: instructorId,
      unitId: unitId,
      weekday: weekday,
      startTime: startTime,
      endTime: endTime,
      createdAt: _clock(),
    );
    if (!shift.isValid) {
      throw ArgumentError('Invalid shift: weekday 1-7 and start before end');
    }
    final current =
        await _shifts.where('instructorId', isEqualTo: instructorId).get();
    final conflict = findOverlappingShift(
      current.docs.map(
        (doc) => InstructorShiftModel.fromJson(doc.data(), doc.id),
      ),
      shift,
    );
    if (conflict != null) throw ShiftOverlapException(conflict);
    final reference = await _shifts.add(shift.toJson());
    return reference.id;
  }

  /// Remove o turno. Nenhum outro documento aponta para turnos.
  Future<void> deleteShift(String shiftId) {
    return _shifts.doc(shiftId).delete();
  }
}
