// fasting domain models — split from core/models.dart.
// Do not import directly; use the 'package:nutri_easy_flutter/core/models.dart' barrel.

enum FastingStateLabel { idle, ready, active, broken, completed }

extension FastingStateLabelTitle on FastingStateLabel {
  String get title => switch (this) {
        FastingStateLabel.idle => 'Başlamadı',
        FastingStateLabel.ready => 'Hazır',
        FastingStateLabel.active => 'Aktif',
        FastingStateLabel.broken => 'Bozuldu',
        FastingStateLabel.completed => 'Tamamlandı',
      };
}


enum FastingPhase { fed, earlyFast, fatBurning, deepFast, recovery }

extension FastingPhaseTitle on FastingPhase {
  String get title => switch (this) {
        FastingPhase.fed => 'Beslenme penceresi',
        FastingPhase.earlyFast => 'Erken açlık',
        FastingPhase.fatBurning => 'Yağ kullanımına geçiş',
        FastingPhase.deepFast => 'Derin oruç',
        FastingPhase.recovery => 'Yeniden beslenme',
      };
}


enum FastingSessionStatus { planned, active, completed, cancelled }

extension FastingSessionStatusTitle on FastingSessionStatus {
  String get title => switch (this) {
        FastingSessionStatus.planned => 'Planlandı',
        FastingSessionStatus.active => 'Aktif',
        FastingSessionStatus.completed => 'Tamamlandı',
        FastingSessionStatus.cancelled => 'İptal edildi',
      };
}


FastingSessionStatus fastingSessionStatusFromDb(Object? value) => switch (value?.toString()) {
      'planned' => FastingSessionStatus.planned,
      'active' => FastingSessionStatus.active,
      'completed' => FastingSessionStatus.completed,
      'cancelled' => FastingSessionStatus.cancelled,
      _ => FastingSessionStatus.planned,
    };


FastingPhase fastingPhaseFromDb(Object? value) => switch (value?.toString()) {
      'early_fast' => FastingPhase.earlyFast,
      'fat_burning' => FastingPhase.fatBurning,
      'deep_fast' => FastingPhase.deepFast,
      'recovery' => FastingPhase.recovery,
      'fed' => FastingPhase.fed,
      _ => FastingPhase.fed,
    };


String fastingPhaseDbValue(FastingPhase phase) => switch (phase) {
      FastingPhase.fed => 'fed',
      FastingPhase.earlyFast => 'early_fast',
      FastingPhase.fatBurning => 'fat_burning',
      FastingPhase.deepFast => 'deep_fast',
      FastingPhase.recovery => 'recovery',
    };


String fastingStatusDbValue(FastingSessionStatus status) => switch (status) {
      FastingSessionStatus.planned => 'planned',
      FastingSessionStatus.active => 'active',
      FastingSessionStatus.completed => 'completed',
      FastingSessionStatus.cancelled => 'cancelled',
    };


class FastingPlan {
  FastingPlan({
    this.enabled = false,
    this.targetHours = 16,
    this.windowStart = '20:00',
    this.windowEnd = '12:00',
    this.label = '16:8',
    this.notes,
  });

  final bool enabled;
  final int targetHours;
  final String windowStart;
  final String windowEnd;
  final String label;
  final String? notes;

  FastingPlan copyWith({
    bool? enabled,
    int? targetHours,
    String? windowStart,
    String? windowEnd,
    String? label,
    String? notes,
  }) {
    return FastingPlan(
      enabled: enabled ?? this.enabled,
      targetHours: targetHours ?? this.targetHours,
      windowStart: windowStart ?? this.windowStart,
      windowEnd: windowEnd ?? this.windowEnd,
      label: label ?? this.label,
      notes: notes ?? this.notes,
    );
  }

  factory FastingPlan.fromMap(Map<String, dynamic> data) {
    return FastingPlan(
      enabled: data['enabled'] as bool? ?? false,
      targetHours: (data['targetHours'] as num?)?.toInt() ?? 16,
      windowStart: data['windowStart']?.toString() ?? '20:00',
      windowEnd: data['windowEnd']?.toString() ?? '12:00',
      label: data['label']?.toString() ?? '16:8',
      notes: data['notes']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
        'enabled': enabled,
        'targetHours': targetHours,
        'windowStart': windowStart,
        'windowEnd': windowEnd,
        'label': label,
        if (notes != null) 'notes': notes,
      };
}


class FastingSession {
  FastingSession({
    required this.id,
    required this.status,
    required this.targetHours,
    required this.plannedStartAt,
    required this.plannedEndAt,
    this.startedAt,
    this.endedAt,
    this.actualDurationMinutes,
    required this.metabolicPhase,
    required this.fastingWindowStart,
    required this.fastingWindowEnd,
    this.lastMealAt,
    this.lastMealTitle,
    this.lastMealCalories,
    this.breakReason,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final FastingSessionStatus status;
  final int targetHours;
  final String plannedStartAt;
  final String plannedEndAt;
  final String? startedAt;
  final String? endedAt;
  final int? actualDurationMinutes;
  final FastingPhase metabolicPhase;
  final String fastingWindowStart;
  final String fastingWindowEnd;
  final String? lastMealAt;
  final String? lastMealTitle;
  final int? lastMealCalories;
  final String? breakReason;
  final String? notes;
  final String createdAt;
  final String updatedAt;

  int get durationMinutes => actualDurationMinutes ?? _minutesBetween(startedAt, endedAt ?? DateTime.now().toIso8601String());
  int get durationHours => (durationMinutes / 60).floor();
  int get durationRemainingMinutes => startedAt == null || status != FastingSessionStatus.active
      ? 0
      : _minutesBetween(DateTime.now().toIso8601String(), plannedEndAt).clamp(0, 99999);
  double progress([DateTime? now]) {
    final start = startedAt == null ? null : DateTime.tryParse(startedAt!);
    final end = plannedEndAt.isEmpty ? null : DateTime.tryParse(plannedEndAt);
    final current = now ?? DateTime.now();
    if (start == null || end == null) return 0;
    final elapsed = current.difference(start).inMinutes;
    final total = mathMax(1, end.difference(start).inMinutes);
    return (elapsed / total).clamp(0.0, 1.0);
  }

  String get durationLabel => '${durationHours}s ${durationMinutes.remainder(60)}dk';

  String get lastMealLabel {
    if (lastMealTitle == null || lastMealTitle!.isEmpty) return 'Son öğün yok';
    final calories = lastMealCalories == null ? '' : ' • ${lastMealCalories!.round()} kcal';
    return '$lastMealTitle$calories';
  }

  FastingSession copyWith({
    String? id,
    FastingSessionStatus? status,
    int? targetHours,
    String? plannedStartAt,
    String? plannedEndAt,
    String? startedAt,
    String? endedAt,
    int? actualDurationMinutes,
    FastingPhase? metabolicPhase,
    String? fastingWindowStart,
    String? fastingWindowEnd,
    String? lastMealAt,
    String? lastMealTitle,
    int? lastMealCalories,
    String? breakReason,
    String? notes,
    String? createdAt,
    String? updatedAt,
  }) {
    return FastingSession(
      id: id ?? this.id,
      status: status ?? this.status,
      targetHours: targetHours ?? this.targetHours,
      plannedStartAt: plannedStartAt ?? this.plannedStartAt,
      plannedEndAt: plannedEndAt ?? this.plannedEndAt,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      actualDurationMinutes: actualDurationMinutes ?? this.actualDurationMinutes,
      metabolicPhase: metabolicPhase ?? this.metabolicPhase,
      fastingWindowStart: fastingWindowStart ?? this.fastingWindowStart,
      fastingWindowEnd: fastingWindowEnd ?? this.fastingWindowEnd,
      lastMealAt: lastMealAt ?? this.lastMealAt,
      lastMealTitle: lastMealTitle ?? this.lastMealTitle,
      lastMealCalories: lastMealCalories ?? this.lastMealCalories,
      breakReason: breakReason ?? this.breakReason,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory FastingSession.fromMap(Map<String, dynamic> data) {
    return FastingSession(
      id: data['id']?.toString() ?? '',
      status: fastingSessionStatusFromDb(data['status']),
      targetHours: (data['targetHours'] as num?)?.toInt() ?? 16,
      plannedStartAt: data['plannedStartAt']?.toString() ?? '',
      plannedEndAt: data['plannedEndAt']?.toString() ?? '',
      startedAt: data['startedAt']?.toString(),
      endedAt: data['endedAt']?.toString(),
      actualDurationMinutes: (data['actualDurationMinutes'] as num?)?.toInt(),
      metabolicPhase: fastingPhaseFromDb(data['metabolicPhase']),
      fastingWindowStart: data['fastingWindowStart']?.toString() ?? '20:00',
      fastingWindowEnd: data['fastingWindowEnd']?.toString() ?? '12:00',
      lastMealAt: data['lastMealAt']?.toString(),
      lastMealTitle: data['lastMealTitle']?.toString(),
      lastMealCalories: (data['lastMealCalories'] as num?)?.toInt(),
      breakReason: data['breakReason']?.toString(),
      notes: data['notes']?.toString(),
      createdAt: data['createdAt']?.toString() ?? '',
      updatedAt: data['updatedAt']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'status': fastingStatusDbValue(status),
        'targetHours': targetHours,
        'plannedStartAt': plannedStartAt,
        'plannedEndAt': plannedEndAt,
        if (startedAt != null) 'startedAt': startedAt,
        if (endedAt != null) 'endedAt': endedAt,
        if (actualDurationMinutes != null) 'actualDurationMinutes': actualDurationMinutes,
        'metabolicPhase': fastingPhaseDbValue(metabolicPhase),
        'fastingWindowStart': fastingWindowStart,
        'fastingWindowEnd': fastingWindowEnd,
        if (lastMealAt != null) 'lastMealAt': lastMealAt,
        if (lastMealTitle != null) 'lastMealTitle': lastMealTitle,
        if (lastMealCalories != null) 'lastMealCalories': lastMealCalories,
        if (breakReason != null) 'breakReason': breakReason,
        if (notes != null) 'notes': notes,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };
}


class FastingSummary {
  FastingSummary({
    required this.plan,
    this.currentSession,
    this.history = const [],
    required this.currentState,
    required this.statusLabel,
    required this.statusDetail,
    required this.metabolicPhase,
    required this.metabolicPhaseLabel,
    required this.metabolicPhaseDetail,
    required this.timerLabel,
    required this.progress,
    required this.fastedMinutes,
    required this.remainingMinutes,
    required this.mealSinceStartCount,
    required this.weeklyInsight,
    required this.achievements,
    required this.isEmpty,
  });

  final FastingPlan plan;
  final FastingSession? currentSession;
  final List<FastingSession> history;
  final FastingStateLabel currentState;
  final String statusLabel;
  final String statusDetail;
  final FastingPhase metabolicPhase;
  final String metabolicPhaseLabel;
  final String metabolicPhaseDetail;
  final String timerLabel;
  final double progress;
  final int fastedMinutes;
  final int remainingMinutes;
  final int mealSinceStartCount;
  final String weeklyInsight;
  final List<String> achievements;
  final bool isEmpty;

  bool get hasActiveSession => currentSession?.status == FastingSessionStatus.active;

  FastingSummary copyWith({
    FastingPlan? plan,
    FastingSession? currentSession,
    List<FastingSession>? history,
    FastingStateLabel? currentState,
    String? statusLabel,
    String? statusDetail,
    FastingPhase? metabolicPhase,
    String? metabolicPhaseLabel,
    String? metabolicPhaseDetail,
    String? timerLabel,
    double? progress,
    int? fastedMinutes,
    int? remainingMinutes,
    int? mealSinceStartCount,
    String? weeklyInsight,
    List<String>? achievements,
    bool? isEmpty,
  }) {
    return FastingSummary(
      plan: plan ?? this.plan,
      currentSession: currentSession ?? this.currentSession,
      history: history ?? this.history,
      currentState: currentState ?? this.currentState,
      statusLabel: statusLabel ?? this.statusLabel,
      statusDetail: statusDetail ?? this.statusDetail,
      metabolicPhase: metabolicPhase ?? this.metabolicPhase,
      metabolicPhaseLabel: metabolicPhaseLabel ?? this.metabolicPhaseLabel,
      metabolicPhaseDetail: metabolicPhaseDetail ?? this.metabolicPhaseDetail,
      timerLabel: timerLabel ?? this.timerLabel,
      progress: progress ?? this.progress,
      fastedMinutes: fastedMinutes ?? this.fastedMinutes,
      remainingMinutes: remainingMinutes ?? this.remainingMinutes,
      mealSinceStartCount: mealSinceStartCount ?? this.mealSinceStartCount,
      weeklyInsight: weeklyInsight ?? this.weeklyInsight,
      achievements: achievements ?? this.achievements,
      isEmpty: isEmpty ?? this.isEmpty,
    );
  }

  factory FastingSummary.fromMap(Map<String, dynamic> data) {
    final planData = data['plan'] as Map<String, dynamic>? ?? const {};
    final currentSessionData = data['currentSession'] as Map<String, dynamic>?;
    final historyData = (data['history'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(FastingSession.fromMap)
        .toList();

    return FastingSummary(
      plan: FastingPlan.fromMap(planData),
      currentSession: currentSessionData == null ? null : FastingSession.fromMap(currentSessionData),
      history: historyData,
      currentState: fastingStateLabelFromDb(data['currentState']),
      statusLabel: data['statusLabel']?.toString() ?? '',
      statusDetail: data['statusDetail']?.toString() ?? '',
      metabolicPhase: fastingPhaseFromDb(data['metabolicPhase']),
      metabolicPhaseLabel: data['metabolicPhaseLabel']?.toString() ?? '',
      metabolicPhaseDetail: data['metabolicPhaseDetail']?.toString() ?? '',
      timerLabel: data['timerLabel']?.toString() ?? '00s 00dk',
      progress: (data['progress'] as num?)?.toDouble() ?? 0,
      fastedMinutes: (data['fastedMinutes'] as num?)?.toInt() ?? 0,
      remainingMinutes: (data['remainingMinutes'] as num?)?.toInt() ?? 0,
      mealSinceStartCount: (data['mealSinceStartCount'] as num?)?.toInt() ?? 0,
      weeklyInsight: data['weeklyInsight']?.toString() ?? '',
      achievements: (data['achievements'] as List<dynamic>? ?? const []).map((e) => e.toString()).toList(),
      isEmpty: data['isEmpty'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'plan': plan.toMap(),
        if (currentSession != null) 'currentSession': currentSession!.toMap(),
        'history': history.map((session) => session.toMap()).toList(),
        'currentState': currentState.name,
        'statusLabel': statusLabel,
        'statusDetail': statusDetail,
        'metabolicPhase': metabolicPhase.name,
        'metabolicPhaseLabel': metabolicPhaseLabel,
        'metabolicPhaseDetail': metabolicPhaseDetail,
        'timerLabel': timerLabel,
        'progress': progress,
        'fastedMinutes': fastedMinutes,
        'remainingMinutes': remainingMinutes,
        'mealSinceStartCount': mealSinceStartCount,
        'weeklyInsight': weeklyInsight,
        'achievements': achievements,
        'isEmpty': isEmpty,
      };
}


FastingStateLabel fastingStateLabelFromDb(Object? value) => switch (value?.toString()) {
      'ready' => FastingStateLabel.ready,
      'active' => FastingStateLabel.active,
      'broken' => FastingStateLabel.broken,
      'completed' => FastingStateLabel.completed,
      'idle' => FastingStateLabel.idle,
      _ => FastingStateLabel.idle,
    };

int _minutesBetween(String? startIso, String endIso) {
  if (startIso == null || startIso.isEmpty) return 0;
  final start = DateTime.tryParse(startIso);
  final end = DateTime.tryParse(endIso);
  if (start == null || end == null) return 0;
  return end.difference(start).inMinutes;
}

int mathMax(int a, int b) => a > b ? a : b;


