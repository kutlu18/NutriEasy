// progress domain models — split from core/models.dart.
// Do not import directly; use the 'package:nutri_easy_flutter/core/models.dart' barrel.
import 'meal.dart';

class ProgressSummary {
  ProgressSummary({
    required this.weekStart,
    required this.weekEnd,
    required this.calorieTarget,
    required this.consumedCalories,
    required this.calorieBalance,
    required this.macroTargets,
    required this.consumedMacros,
    required this.currentWeightKg,
    required this.targetWeightKg,
    required this.estimatedWeightDeltaKg,
    required this.streakDays,
    required this.hydrationCurrent,
    required this.hydrationTarget,
    required this.stepsCurrent,
    required this.stepsTarget,
    required this.mealCount,
    required this.weightTrend,
    required this.achievements,
    required this.weeklyInsight,
    this.isEmpty = false,
    this.source = 'calculated',
  });

  final DateTime weekStart;
  final DateTime weekEnd;
  final int calorieTarget;
  final int consumedCalories;
  final int calorieBalance;
  final MacroTargets macroTargets;
  final MacroTargets consumedMacros;
  final double currentWeightKg;
  final double targetWeightKg;
  final double estimatedWeightDeltaKg;
  final int streakDays;
  final int hydrationCurrent;
  final int hydrationTarget;
  final int stepsCurrent;
  final int stepsTarget;
  final int mealCount;
  final List<ProgressTrendPoint> weightTrend;
  final List<String> achievements;
  final String weeklyInsight;
  final bool isEmpty;
  final String source;

  ProgressSummary copyWith({
    DateTime? weekStart,
    DateTime? weekEnd,
    int? calorieTarget,
    int? consumedCalories,
    int? calorieBalance,
    MacroTargets? macroTargets,
    MacroTargets? consumedMacros,
    double? currentWeightKg,
    double? targetWeightKg,
    double? estimatedWeightDeltaKg,
    int? streakDays,
    int? hydrationCurrent,
    int? hydrationTarget,
    int? stepsCurrent,
    int? stepsTarget,
    int? mealCount,
    List<ProgressTrendPoint>? weightTrend,
    List<String>? achievements,
    String? weeklyInsight,
    bool? isEmpty,
    String? source,
  }) {
    return ProgressSummary(
      weekStart: weekStart ?? this.weekStart,
      weekEnd: weekEnd ?? this.weekEnd,
      calorieTarget: calorieTarget ?? this.calorieTarget,
      consumedCalories: consumedCalories ?? this.consumedCalories,
      calorieBalance: calorieBalance ?? this.calorieBalance,
      macroTargets: macroTargets ?? this.macroTargets,
      consumedMacros: consumedMacros ?? this.consumedMacros,
      currentWeightKg: currentWeightKg ?? this.currentWeightKg,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      estimatedWeightDeltaKg: estimatedWeightDeltaKg ?? this.estimatedWeightDeltaKg,
      streakDays: streakDays ?? this.streakDays,
      hydrationCurrent: hydrationCurrent ?? this.hydrationCurrent,
      hydrationTarget: hydrationTarget ?? this.hydrationTarget,
      stepsCurrent: stepsCurrent ?? this.stepsCurrent,
      stepsTarget: stepsTarget ?? this.stepsTarget,
      mealCount: mealCount ?? this.mealCount,
      weightTrend: weightTrend ?? this.weightTrend,
      achievements: achievements ?? this.achievements,
      weeklyInsight: weeklyInsight ?? this.weeklyInsight,
      isEmpty: isEmpty ?? this.isEmpty,
      source: source ?? this.source,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'weekStart': weekStart.toIso8601String(),
      'weekEnd': weekEnd.toIso8601String(),
      'calorieTarget': calorieTarget,
      'consumedCalories': consumedCalories,
      'calorieBalance': calorieBalance,
      'macroTargets': {
        'proteinGr': macroTargets.proteinGr,
        'carbsGr': macroTargets.carbsGr,
        'fatGr': macroTargets.fatGr,
      },
      'consumedMacros': {
        'proteinGr': consumedMacros.proteinGr,
        'carbsGr': consumedMacros.carbsGr,
        'fatGr': consumedMacros.fatGr,
      },
      'currentWeightKg': currentWeightKg,
      'targetWeightKg': targetWeightKg,
      'estimatedWeightDeltaKg': estimatedWeightDeltaKg,
      'streakDays': streakDays,
      'hydrationCurrent': hydrationCurrent,
      'hydrationTarget': hydrationTarget,
      'stepsCurrent': stepsCurrent,
      'stepsTarget': stepsTarget,
      'mealCount': mealCount,
      'weightTrend': weightTrend.map((point) => point.toMap()).toList(),
      'achievements': achievements,
      'weeklyInsight': weeklyInsight,
      'isEmpty': isEmpty,
      'source': source,
    };
  }

  factory ProgressSummary.fromMap(Map<String, dynamic> data) {
    final macroTargetsMap = data['macroTargets'] as Map<String, dynamic>? ?? const {};
    final consumedMacrosMap = data['consumedMacros'] as Map<String, dynamic>? ?? const {};
    final trend = (data['weightTrend'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(ProgressTrendPoint.fromMap)
        .toList();

    return ProgressSummary(
      weekStart: DateTime.tryParse(data['weekStart']?.toString() ?? '') ?? DateTime.now(),
      weekEnd: DateTime.tryParse(data['weekEnd']?.toString() ?? '') ?? DateTime.now(),
      calorieTarget: (data['calorieTarget'] as num?)?.toInt() ?? 0,
      consumedCalories: (data['consumedCalories'] as num?)?.toInt() ?? 0,
      calorieBalance: (data['calorieBalance'] as num?)?.toInt() ?? 0,
      macroTargets: MacroTargets(
        proteinGr: (macroTargetsMap['proteinGr'] as num?)?.toInt() ?? 0,
        carbsGr: (macroTargetsMap['carbsGr'] as num?)?.toInt() ?? 0,
        fatGr: (macroTargetsMap['fatGr'] as num?)?.toInt() ?? 0,
      ),
      consumedMacros: MacroTargets(
        proteinGr: (consumedMacrosMap['proteinGr'] as num?)?.toInt() ?? 0,
        carbsGr: (consumedMacrosMap['carbsGr'] as num?)?.toInt() ?? 0,
        fatGr: (consumedMacrosMap['fatGr'] as num?)?.toInt() ?? 0,
      ),
      currentWeightKg: (data['currentWeightKg'] as num?)?.toDouble() ?? 0,
      targetWeightKg: (data['targetWeightKg'] as num?)?.toDouble() ?? 0,
      estimatedWeightDeltaKg: (data['estimatedWeightDeltaKg'] as num?)?.toDouble() ?? 0,
      streakDays: (data['streakDays'] as num?)?.toInt() ?? 0,
      hydrationCurrent: (data['hydrationCurrent'] as num?)?.toInt() ?? 0,
      hydrationTarget: (data['hydrationTarget'] as num?)?.toInt() ?? 0,
      stepsCurrent: (data['stepsCurrent'] as num?)?.toInt() ?? 0,
      stepsTarget: (data['stepsTarget'] as num?)?.toInt() ?? 0,
      mealCount: (data['mealCount'] as num?)?.toInt() ?? 0,
      weightTrend: trend,
      achievements: (data['achievements'] as List<dynamic>? ?? const []).map((e) => e.toString()).toList(),
      weeklyInsight: data['weeklyInsight']?.toString() ?? '',
      isEmpty: data['isEmpty'] as bool? ?? false,
      source: data['source']?.toString() ?? 'calculated',
    );
  }

  String get calorieBalanceLabel => '${calorieBalance >= 0 ? '+' : ''}$calorieBalance kcal';

  String get weightDeltaLabel {
    final sign = estimatedWeightDeltaKg >= 0 ? '+' : '';
    return '$sign${estimatedWeightDeltaKg.toStringAsFixed(1)} kg';
  }

  String get dateRangeLabel {
    final start = _progressDateLabel(weekStart);
    final end = _progressDateLabel(weekEnd);
    return '$start - $end';
  }

  bool get hasActivity => mealCount > 0 || consumedCalories > 0 || streakDays > 0;
}


class ProgressTrendPoint {
  ProgressTrendPoint({
    required this.date,
    required this.weightKg,
    required this.caloriesConsumed,
    required this.calorieTarget,
  });

  final DateTime date;
  final double weightKg;
  final int caloriesConsumed;
  final int calorieTarget;

  Map<String, dynamic> toMap() => {
        'date': date.toIso8601String(),
        'weightKg': weightKg,
        'caloriesConsumed': caloriesConsumed,
        'calorieTarget': calorieTarget,
      };

  factory ProgressTrendPoint.fromMap(Map<String, dynamic> data) {
    return ProgressTrendPoint(
      date: DateTime.tryParse(data['date']?.toString() ?? '') ?? DateTime.now(),
      weightKg: (data['weightKg'] as num?)?.toDouble() ?? 0,
      caloriesConsumed: (data['caloriesConsumed'] as num?)?.toInt() ?? 0,
      calorieTarget: (data['calorieTarget'] as num?)?.toInt() ?? 0,
    );
  }
}


String _progressDateLabel(DateTime date) {
  const months = <String>[
    'Oca',
    'Sub',
    'Mar',
    'Nis',
    'May',
    'Haz',
    'Tem',
    'Agu',
    'Eyl',
    'Eki',
    'Kas',
    'Ara',
  ];
  return '${date.day} ${months[date.month - 1]}';
}


