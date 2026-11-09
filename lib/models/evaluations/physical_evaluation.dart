import 'package:cloud_firestore/cloud_firestore.dart';

enum BiologicalSex { male, female }

/// Dobras cutâneas (em mm) do protocolo Jackson & Pollock de 7 dobras.
class Skinfolds {
  final double chest;
  final double midaxillary;
  final double triceps;
  final double subscapular;
  final double abdominal;
  final double suprailiac;
  final double thigh;

  const Skinfolds({
    required this.chest,
    required this.midaxillary,
    required this.triceps,
    required this.subscapular,
    required this.abdominal,
    required this.suprailiac,
    required this.thigh,
  });

  double get sum =>
      chest +
      midaxillary +
      triceps +
      subscapular +
      abdominal +
      suprailiac +
      thigh;

  Map<String, dynamic> toJson() => {
    'chest': chest,
    'midaxillary': midaxillary,
    'triceps': triceps,
    'subscapular': subscapular,
    'abdominal': abdominal,
    'suprailiac': suprailiac,
    'thigh': thigh,
  };

  factory Skinfolds.fromJson(Map<String, dynamic> json) {
    double read(String key) => (json[key] as num?)?.toDouble() ?? 0;
    return Skinfolds(
      chest: read('chest'),
      midaxillary: read('midaxillary'),
      triceps: read('triceps'),
      subscapular: read('subscapular'),
      abdominal: read('abdominal'),
      suprailiac: read('suprailiac'),
      thigh: read('thigh'),
    );
  }
}

/// Avaliação física por dobras cutâneas.
///
/// Somente as medidas coletadas são persistidas; os resultados são
/// derivados delas (Jackson & Pollock 7 dobras + equação de Siri).
class PhysicalEvaluation {
  final String id;
  final DateTime date;
  final String instructorId;
  final BiologicalSex sex;
  final int age;
  final double weightKg;
  final int heightCm;
  final Skinfolds skinfolds;

  const PhysicalEvaluation({
    this.id = '',
    required this.date,
    required this.instructorId,
    required this.sex,
    required this.age,
    required this.weightKg,
    required this.heightCm,
    required this.skinfolds,
  });

  /// Densidade corporal (g/cm³) — Jackson & Pollock, 7 dobras.
  double get bodyDensity {
    final s = skinfolds.sum;
    return switch (sex) {
      BiologicalSex.male =>
        1.112 - 0.00043499 * s + 0.00000055 * s * s - 0.00028826 * age,
      BiologicalSex.female =>
        1.097 - 0.00046971 * s + 0.00000056 * s * s - 0.00012828 * age,
    };
  }

  /// Percentual de gordura — equação de Siri.
  double get bodyFatPercent => 495 / bodyDensity - 450;

  double get fatMassKg => weightKg * bodyFatPercent / 100;

  double get leanMassKg => weightKg - fatMassKg;

  double get bmi {
    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }

  Map<String, dynamic> toJson() => {
    'date': Timestamp.fromDate(date),
    'instructorId': instructorId,
    'sex': sex.name,
    'age': age,
    'weightKg': weightKg,
    'heightCm': heightCm,
    'skinfolds': skinfolds.toJson(),
  };

  factory PhysicalEvaluation.fromJson(Map<String, dynamic> json, String id) {
    return PhysicalEvaluation(
      id: id,
      date: (json['date'] as Timestamp).toDate(),
      instructorId: json['instructorId'] as String? ?? '',
      sex: BiologicalSex.values.byName(json['sex'] as String),
      age: (json['age'] as num).toInt(),
      weightKg: (json['weightKg'] as num).toDouble(),
      heightCm: (json['heightCm'] as num).toInt(),
      skinfolds: Skinfolds.fromJson(
        Map<String, dynamic>.from(json['skinfolds'] as Map),
      ),
    );
  }
}
