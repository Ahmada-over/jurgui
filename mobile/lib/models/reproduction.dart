class MatingEvent {
  final int id;
  final String femaleId;
  final String? ramId;
  final DateTime matingDate;
  final String matingType;
  final String status;
  final String? notes;

  MatingEvent({
    required this.id,
    required this.femaleId,
    this.ramId,
    required this.matingDate,
    required this.matingType,
    required this.status,
    this.notes,
  });

  factory MatingEvent.fromJson(Map<String, dynamic> json) {
    return MatingEvent(
      id: json['id'] as int,
      femaleId: json['female_id'] as String,
      ramId: json['ram_id'] as String?,
      matingDate: DateTime.parse(json['mating_date'] as String),
      matingType: json['mating_type'] as String? ?? 'natural',
      status: json['status'] as String? ?? 'observed',
      notes: json['notes'] as String?,
    );
  }
}

class GestationTimelineItem {
  final int dayOffset;
  final String title;
  final DateTime targetDate;
  final String actionDescription;
  final bool isPassed;

  GestationTimelineItem({
    required this.dayOffset,
    required this.title,
    required this.targetDate,
    required this.actionDescription,
    required this.isPassed,
  });

  factory GestationTimelineItem.fromJson(Map<String, dynamic> json) {
    return GestationTimelineItem(
      dayOffset: json['day_offset'] as int,
      title: json['title'] as String,
      targetDate: DateTime.parse(json['target_date'] as String),
      actionDescription: json['action_description'] as String,
      isPassed: json['is_passed'] as bool? ?? false,
    );
  }
}

class Pregnancy {
  final int id;
  final String femaleId;
  final String? ramId;
  final int? matingEventId;
  final DateTime startDate;
  final int gestationDurationDays;
  final DateTime expectedBirthDate;
  final String confirmationStatus;
  final String status;
  final String? notes;
  final List<GestationTimelineItem> timeline;

  Pregnancy({
    required this.id,
    required this.femaleId,
    this.ramId,
    this.matingEventId,
    required this.startDate,
    this.gestationDurationDays = 150,
    required this.expectedBirthDate,
    required this.confirmationStatus,
    required this.status,
    this.notes,
    this.timeline = const [],
  });

  int get daysRemaining => expectedBirthDate.difference(DateTime.now()).inDays;
  int get currentDay => DateTime.now().difference(startDate).inDays;

  factory Pregnancy.fromJson(Map<String, dynamic> json) {
    return Pregnancy(
      id: json['id'] as int,
      femaleId: json['female_id'] as String,
      ramId: json['ram_id'] as String?,
      matingEventId: json['mating_event_id'] as int?,
      startDate: DateTime.parse(json['start_date'] as String),
      gestationDurationDays: json['gestation_duration_days'] as int? ?? 150,
      expectedBirthDate: DateTime.parse(json['expected_birth_date'] as String),
      confirmationStatus: json['confirmation_status'] as String? ?? 'unverified',
      status: json['status'] as String? ?? 'in_progress',
      notes: json['notes'] as String?,
      timeline: (json['timeline'] as List<dynamic>?)
              ?.map((t) => GestationTimelineItem.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class Birth {
  final int id;
  final int? pregnancyId;
  final String femaleId;
  final String? ramId;
  final DateTime birthDate;
  final int totalLambs;
  final int aliveCount;
  final int stillbornCount;
  final int maleCount;
  final int femaleCount;
  final String? difficulties;

  Birth({
    required this.id,
    this.pregnancyId,
    required this.femaleId,
    this.ramId,
    required this.birthDate,
    required this.totalLambs,
    required this.aliveCount,
    required this.stillbornCount,
    required this.maleCount,
    required this.femaleCount,
    this.difficulties,
  });

  factory Birth.fromJson(Map<String, dynamic> json) {
    return Birth(
      id: json['id'] as int,
      pregnancyId: json['pregnancy_id'] as int?,
      femaleId: json['female_id'] as String,
      ramId: json['ram_id'] as String?,
      birthDate: DateTime.parse(json['birth_date'] as String),
      totalLambs: json['total_lambs'] as int? ?? 1,
      aliveCount: json['alive_count'] as int? ?? 1,
      stillbornCount: json['stillborn_count'] as int? ?? 0,
      maleCount: json['male_count'] as int? ?? 0,
      femaleCount: json['female_count'] as int? ?? 0,
      difficulties: json['difficulties'] as String?,
    );
  }
}
