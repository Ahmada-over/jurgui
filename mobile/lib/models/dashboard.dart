class SectorStat {
  final int sectorId;
  final String sectorName;
  final int occupancy;
  final int capacity;
  final bool isOvercrowded;

  SectorStat({
    required this.sectorId,
    required this.sectorName,
    required this.occupancy,
    required this.capacity,
    required this.isOvercrowded,
  });

  factory SectorStat.fromJson(Map<String, dynamic> json) {
    return SectorStat(
      sectorId: json['sector_id'] as int,
      sectorName: json['sector_name'] as String,
      occupancy: json['occupancy'] as int,
      capacity: json['capacity'] as int,
      isOvercrowded: json['is_overcrowded'] as bool? ?? false,
    );
  }
}

class UpcomingBirth {
  final int pregnancyId;
  final String femaleId;
  final String expectedDate;
  final int daysLeft;

  UpcomingBirth({
    required this.pregnancyId,
    required this.femaleId,
    required this.expectedDate,
    required this.daysLeft,
  });

  factory UpcomingBirth.fromJson(Map<String, dynamic> json) {
    return UpcomingBirth(
      pregnancyId: json['pregnancy_id'] as int,
      femaleId: json['female_id'] as String,
      expectedDate: json['expected_date'] as String,
      daysLeft: json['days_left'] as int,
    );
  }
}

class DashboardData {
  final int totalActiveAnimals;
  final Map<String, int> byBreed;
  final Map<String, int> bySex;
  final List<SectorStat> sectors;
  final int activePregnancies;
  final List<UpcomingBirth> upcomingBirths;
  final int pendingTasks;
  final List<Map<String, dynamic>> lowStockAlerts;

  DashboardData({
    required this.totalActiveAnimals,
    required this.byBreed,
    required this.bySex,
    required this.sectors,
    required this.activePregnancies,
    required this.upcomingBirths,
    required this.pendingTasks,
    required this.lowStockAlerts,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final cheptel = json['cheptel'] as Map<String, dynamic>? ?? {};
    final repro = json['reproduction'] as Map<String, dynamic>? ?? {};
    final ops = json['operations'] as Map<String, dynamic>? ?? {};

    return DashboardData(
      totalActiveAnimals: cheptel['total_active'] as int? ?? 0,
      byBreed: (cheptel['by_breed'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toInt()),
          ) ??
          {},
      bySex: (cheptel['by_sex'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toInt()),
          ) ??
          {},
      sectors: (cheptel['sectors'] as List<dynamic>?)
              ?.map((s) => SectorStat.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      activePregnancies: repro['active_pregnancies'] as int? ?? 0,
      upcomingBirths: (repro['upcoming_births_next_30_days'] as List<dynamic>?)
              ?.map((b) => UpcomingBirth.fromJson(b as Map<String, dynamic>))
              .toList() ??
          [],
      pendingTasks: ops['pending_tasks'] as int? ?? 0,
      lowStockAlerts: (ops['low_stock_alerts'] as List<dynamic>?)
              ?.map((a) => a as Map<String, dynamic>)
              .toList() ??
          [],
    );
  }
}
