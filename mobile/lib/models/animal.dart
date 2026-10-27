class Breed {
  final int id;
  final String name;
  final String? description;
  final String? origin;

  Breed({
    required this.id,
    required this.name,
    this.description,
    this.origin,
  });

  factory Breed.fromJson(Map<String, dynamic> json) {
    return Breed(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      origin: json['origin'] as String?,
    );
  }
}

class Sector {
  final int id;
  final String name;
  final String? description;
  final int estimatedCapacity;
  final int currentOccupancy;
  final String status;

  Sector({
    required this.id,
    required this.name,
    this.description,
    required this.estimatedCapacity,
    this.currentOccupancy = 0,
    required this.status,
  });

  factory Sector.fromJson(Map<String, dynamic> json) {
    return Sector(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      estimatedCapacity: json['estimated_capacity'] as int? ?? 0,
      currentOccupancy: json['current_occupancy'] as int? ?? 0,
      status: json['status'] as String? ?? 'active',
    );
  }
}

class WeightRecord {
  final int id;
  final String animalId;
  final double weightKg;
  final DateTime recordedAt;
  final String? notes;

  WeightRecord({
    required this.id,
    required this.animalId,
    required this.weightKg,
    required this.recordedAt,
    this.notes,
  });

  factory WeightRecord.fromJson(Map<String, dynamic> json) {
    return WeightRecord(
      id: json['id'] as int,
      animalId: json['animal_id'] as String,
      weightKg: (json['weight_kg'] as num).toDouble(),
      recordedAt: DateTime.parse(json['recorded_at'] as String),
      notes: json['notes'] as String?,
    );
  }
}

class AnimalMovement {
  final int id;
  final String animalId;
  final int? fromSectorId;
  final int toSectorId;
  final DateTime movementDate;
  final String? reason;

  AnimalMovement({
    required this.id,
    required this.animalId,
    this.fromSectorId,
    required this.toSectorId,
    required this.movementDate,
    this.reason,
  });

  factory AnimalMovement.fromJson(Map<String, dynamic> json) {
    return AnimalMovement(
      id: json['id'] as int,
      animalId: json['animal_id'] as String,
      fromSectorId: json['from_sector_id'] as int?,
      toSectorId: json['to_sector_id'] as int,
      movementDate: DateTime.parse(json['movement_date'] as String),
      reason: json['reason'] as String?,
    );
  }
}

class Animal {
  final String id;
  final String name;
  final String? physicalTag;
  final String? photoUrl;
  final int breedId;
  final String sex;
  final DateTime? birthDate;
  final int? estimatedAgeMonths;
  final String origin;
  final DateTime? entryDate;
  final double? purchasePriceCfa;
  final String status;
  final int? currentSectorId;
  final double? currentWeightKg;
  final String bodyCondition;
  final String reproductionStatus;
  final String? motherId;
  final String? fatherId;
  final String? lineage;
  final String? notes;
  final Breed? breed;
  final Sector? currentSector;
  final List<WeightRecord> weightRecords;
  final List<AnimalMovement> movements;

  Animal({
    required this.id,
    required this.name,
    this.physicalTag,
    this.photoUrl,
    required this.breedId,
    required this.sex,
    this.birthDate,
    this.estimatedAgeMonths,
    required this.origin,
    this.entryDate,
    this.purchasePriceCfa,
    required this.status,
    this.currentSectorId,
    this.currentWeightKg,
    required this.bodyCondition,
    required this.reproductionStatus,
    this.motherId,
    this.fatherId,
    this.lineage,
    this.notes,
    this.breed,
    this.currentSector,
    this.weightRecords = const [],
    this.movements = const [],
  });

  bool get isFemale => sex.toLowerCase() == 'female';
  bool get isMale => sex.toLowerCase() == 'male';

  Animal copyWith({
    String? id,
    String? name,
    String? physicalTag,
    bool clearPhysicalTag = false,
    String? photoUrl,
    bool clearPhotoUrl = false,
    int? breedId,
    String? sex,
    DateTime? birthDate,
    bool clearBirthDate = false,
    int? estimatedAgeMonths,
    String? origin,
    DateTime? entryDate,
    double? purchasePriceCfa,
    bool clearPurchasePrice = false,
    String? status,
    int? currentSectorId,
    double? currentWeightKg,
    String? bodyCondition,
    String? reproductionStatus,
    String? motherId,
    bool clearMotherId = false,
    String? fatherId,
    bool clearFatherId = false,
    String? lineage,
    bool clearLineage = false,
    String? notes,
    bool clearNotes = false,
    Breed? breed,
    Sector? currentSector,
    List<WeightRecord>? weightRecords,
    List<AnimalMovement>? movements,
  }) {
    return Animal(
      id: id ?? this.id,
      name: name ?? this.name,
      physicalTag: clearPhysicalTag ? null : (physicalTag ?? this.physicalTag),
      photoUrl: clearPhotoUrl ? null : (photoUrl ?? this.photoUrl),
      breedId: breedId ?? this.breedId,
      sex: sex ?? this.sex,
      birthDate: clearBirthDate ? null : (birthDate ?? this.birthDate),
      estimatedAgeMonths: estimatedAgeMonths ?? this.estimatedAgeMonths,
      origin: origin ?? this.origin,
      entryDate: entryDate ?? this.entryDate,
      purchasePriceCfa:
          clearPurchasePrice ? null : (purchasePriceCfa ?? this.purchasePriceCfa),
      status: status ?? this.status,
      currentSectorId: currentSectorId ?? this.currentSectorId,
      currentWeightKg: currentWeightKg ?? this.currentWeightKg,
      bodyCondition: bodyCondition ?? this.bodyCondition,
      reproductionStatus: reproductionStatus ?? this.reproductionStatus,
      motherId: clearMotherId ? null : (motherId ?? this.motherId),
      fatherId: clearFatherId ? null : (fatherId ?? this.fatherId),
      lineage: clearLineage ? null : (lineage ?? this.lineage),
      notes: clearNotes ? null : (notes ?? this.notes),
      breed: breed ?? this.breed,
      currentSector: currentSector ?? this.currentSector,
      weightRecords: weightRecords ?? this.weightRecords,
      movements: movements ?? this.movements,
    );
  }

  factory Animal.fromJson(Map<String, dynamic> json) {
    return Animal(
      id: json['id'] as String,
      name: json['name'] as String,
      physicalTag: json['physical_tag'] as String?,
      photoUrl: json['photo_url'] as String?,
      breedId: json['breed_id'] as int,
      sex: json['sex'] as String,
      birthDate: json['birth_date'] != null ? DateTime.parse(json['birth_date'] as String) : null,
      estimatedAgeMonths: json['estimated_age_months'] as int?,
      origin: json['origin'] as String? ?? 'birth',
      entryDate: json['entry_date'] != null ? DateTime.parse(json['entry_date'] as String) : null,
      purchasePriceCfa: json['purchase_price_cfa'] != null ? (json['purchase_price_cfa'] as num).toDouble() : null,
      status: json['status'] as String? ?? 'active',
      currentSectorId: json['current_sector_id'] as int?,
      currentWeightKg: json['current_weight_kg'] != null ? (json['current_weight_kg'] as num).toDouble() : null,
      bodyCondition: json['body_condition'] as String? ?? 'normal',
      reproductionStatus: json['reproduction_status'] as String? ?? 'not_pregnant',
      motherId: json['mother_id'] as String?,
      fatherId: json['father_id'] as String?,
      lineage: json['lineage'] as String?,
      notes: json['notes'] as String?,
      breed: json['breed'] != null ? Breed.fromJson(json['breed'] as Map<String, dynamic>) : null,
      currentSector: json['current_sector'] != null ? Sector.fromJson(json['current_sector'] as Map<String, dynamic>) : null,
      weightRecords: (json['weight_records'] as List<dynamic>?)
              ?.map((w) => WeightRecord.fromJson(w as Map<String, dynamic>))
              .toList() ??
          [],
      movements: (json['movements'] as List<dynamic>?)
              ?.map((m) => AnimalMovement.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class AnimalParentSummary {
  final String id;
  final String name;
  final String sex;
  final String? lineage;
  final Breed? breed;

  AnimalParentSummary({
    required this.id,
    required this.name,
    required this.sex,
    this.lineage,
    this.breed,
  });

  factory AnimalParentSummary.fromJson(Map<String, dynamic> json) {
    return AnimalParentSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      sex: json['sex'] as String,
      lineage: json['lineage'] as String?,
      breed: json['breed'] != null
          ? Breed.fromJson(json['breed'] as Map<String, dynamic>)
          : null,
    );
  }
}

class AnimalGenealogy {
  final Animal animal;
  final AnimalParentSummary? mother;
  final AnimalParentSummary? father;
  final AnimalParentSummary? paternalGrandfather;
  final AnimalParentSummary? paternalGrandmother;
  final AnimalParentSummary? maternalGrandfather;
  final AnimalParentSummary? maternalGrandmother;
  final List<AnimalParentSummary> offspring;

  AnimalGenealogy({
    required this.animal,
    this.mother,
    this.father,
    this.paternalGrandfather,
    this.paternalGrandmother,
    this.maternalGrandfather,
    this.maternalGrandmother,
    this.offspring = const [],
  });

  factory AnimalGenealogy.fromJson(Map<String, dynamic> json) {
    final patGp = json['paternal_grandparents'] as Map<String, dynamic>?;
    final matGp = json['maternal_grandparents'] as Map<String, dynamic>?;

    return AnimalGenealogy(
      animal: Animal.fromJson(json['animal'] as Map<String, dynamic>),
      mother: json['mother'] != null
          ? AnimalParentSummary.fromJson(json['mother'] as Map<String, dynamic>)
          : null,
      father: json['father'] != null
          ? AnimalParentSummary.fromJson(json['father'] as Map<String, dynamic>)
          : null,
      paternalGrandfather: patGp?['father'] != null
          ? AnimalParentSummary.fromJson(
              patGp!['father'] as Map<String, dynamic>,
            )
          : null,
      paternalGrandmother: patGp?['mother'] != null
          ? AnimalParentSummary.fromJson(
              patGp!['mother'] as Map<String, dynamic>,
            )
          : null,
      maternalGrandfather: matGp?['father'] != null
          ? AnimalParentSummary.fromJson(
              matGp!['father'] as Map<String, dynamic>,
            )
          : null,
      maternalGrandmother: matGp?['mother'] != null
          ? AnimalParentSummary.fromJson(
              matGp!['mother'] as Map<String, dynamic>,
            )
          : null,
      offspring: (json['offspring'] as List<dynamic>?)
              ?.map(
                (o) =>
                    AnimalParentSummary.fromJson(o as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }
}
