enum PrimaryGoal {
  weightLoss,
  muscleGain,
  conditioning,
  strengthening,
  mobility,
}

class BodyMeasurements {
  final int age;
  final int heightCm;
  final double weightKg;

  const BodyMeasurements({
    required this.age,
    required this.heightCm,
    required this.weightKg,
  });

  Map<String, dynamic> toJson() => {
    'age': age,
    'heightCm': heightCm,
    'weightKg': weightKg,
  };

  factory BodyMeasurements.fromJson(Map<String, dynamic> json) {
    return BodyMeasurements(
      age: (json['age'] as num?)?.toInt() ?? 0,
      heightCm: (json['heightCm'] as num?)?.toInt() ?? 0,
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0,
    );
  }
}

class HealthProfile {
  final List<String> conditions;
  final String notes;
  final List<String> restrictions;

  const HealthProfile({
    required this.conditions,
    required this.notes,
    required this.restrictions,
  });

  Map<String, dynamic> toJson() => {
    'conditions': conditions,
    'notes': notes,
    'restrictions': restrictions,
  };

  factory HealthProfile.fromJson(Map<String, dynamic> json) {
    return HealthProfile(
      conditions: List<String>.from(json['conditions'] as List? ?? const []),
      notes: json['notes'] as String? ?? '',
      restrictions: List<String>.from(
        json['restrictions'] as List? ?? const [],
      ),
    );
  }
}

class EmergencyContact {
  final String name;
  final String relationship;
  final String phone;

  const EmergencyContact({
    required this.name,
    required this.relationship,
    required this.phone,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'relationship': relationship,
    'phone': phone,
  };

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      name: json['name'] as String? ?? '',
      relationship: json['relationship'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
    );
  }
}

class RegistrationProfile {
  final BodyMeasurements measurements;
  final PrimaryGoal primaryGoal;
  final HealthProfile health;
  final EmergencyContact emergencyContact;

  const RegistrationProfile({
    required this.measurements,
    required this.primaryGoal,
    required this.health,
    required this.emergencyContact,
  });

  Map<String, dynamic> toJson() => {
    'measurements': measurements.toJson(),
    'primaryGoal': primaryGoal.name,
    'health': health.toJson(),
    'emergencyContact': emergencyContact.toJson(),
  };

  factory RegistrationProfile.fromJson(Map<String, dynamic> json) {
    final goalName = json['primaryGoal'] as String?;
    return RegistrationProfile(
      measurements: BodyMeasurements.fromJson(
        Map<String, dynamic>.from(json['measurements'] as Map? ?? const {}),
      ),
      primaryGoal: PrimaryGoal.values.firstWhere(
        (goal) => goal.name == goalName,
        orElse: () => PrimaryGoal.conditioning,
      ),
      health: HealthProfile.fromJson(
        Map<String, dynamic>.from(json['health'] as Map? ?? const {}),
      ),
      emergencyContact: EmergencyContact.fromJson(
        Map<String, dynamic>.from(json['emergencyContact'] as Map? ?? const {}),
      ),
    );
  }
}

class RegistrationDraft {
  String name = '';
  String email = '';
  String password = '';
  String passwordConfirmation = '';
  DateTime? termsAcceptedAt;
  String instructorCode = '';
  String? instructorId;
  String? instructorName;
  int age = 28;
  int heightCm = 165;
  double weightKg = 68.5;
  PrimaryGoal? primaryGoal;
  final Set<String> conditions = {'none'};
  String healthNotes = '';
  final Set<String> restrictions = {'none'};
  String emergencyName = '';
  String emergencyRelationship = '';
  String emergencyPhone = '';

  RegistrationProfile toProfile() {
    final selectedGoal = primaryGoal;
    if (selectedGoal == null) {
      throw StateError('Primary goal is required');
    }

    return RegistrationProfile(
      measurements: BodyMeasurements(
        age: age,
        heightCm: heightCm,
        weightKg: weightKg,
      ),
      primaryGoal: selectedGoal,
      health: HealthProfile(
        conditions: conditions.toList(growable: false),
        notes: healthNotes,
        restrictions: restrictions.toList(growable: false),
      ),
      emergencyContact: EmergencyContact(
        name: emergencyName,
        relationship: emergencyRelationship,
        phone: emergencyPhone.replaceAll(RegExp(r'\D'), ''),
      ),
    );
  }
}
