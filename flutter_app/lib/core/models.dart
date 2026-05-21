class UserProfile {
  UserProfile({
    this.id = '',
    this.name = 'Umut',
    this.email = 'umut@example.com',
    this.gender = Gender.preferNotToSay,
    this.age = 30,
    this.heightCm = 175,
    this.weightKg = 78,
    this.targetWeightKg = 72,
    this.selectedGoal = Goal.weightLoss,
    this.activityLevel = ActivityLevel.light,
    this.preferredLoggingMethod = LoggingMethod.mixed,
    this.onboardingCompleted = false,
  });

  final String id;
  final String name;
  final String email;
  final Gender gender;
  final int age;
  final int heightCm;
  final int weightKg;
  final int? targetWeightKg;
  final Goal selectedGoal;
  final ActivityLevel activityLevel;
  final LoggingMethod preferredLoggingMethod;
  final bool onboardingCompleted;

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    Gender? gender,
    int? age,
    int? heightCm,
    int? weightKg,
    int? targetWeightKg,
    Goal? selectedGoal,
    ActivityLevel? activityLevel,
    LoggingMethod? preferredLoggingMethod,
    bool? onboardingCompleted,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      selectedGoal: selectedGoal ?? this.selectedGoal,
      activityLevel: activityLevel ?? this.activityLevel,
      preferredLoggingMethod: preferredLoggingMethod ?? this.preferredLoggingMethod,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }

  factory UserProfile.fromSupabase(
    Map<String, dynamic> data, {
    String email = '',
  }) {
    return UserProfile(
      id: data['id']?.toString() ?? '',
      name: data['name']?.toString() ?? 'Umut',
      email: email,
      gender: genderFromDb(data['gender']),
      age: (data['age'] as num?)?.toInt() ?? 30,
      heightCm: (data['height_cm'] as num?)?.toInt() ?? 175,
      weightKg: (data['weight_kg'] as num?)?.round() ?? 78,
      targetWeightKg: (data['target_weight_kg'] as num?)?.round(),
      selectedGoal: goalFromDb(data['selected_goal']),
      activityLevel: activityLevelFromDb(data['activity_level']),
      preferredLoggingMethod: loggingMethodFromDb(data['preferred_logging_method']),
      onboardingCompleted: data['onboarding_completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toSupabaseMap() {
    return {
      'id': id,
      'name': name,
      'gender': genderDbValue(gender),
      'age': age,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'target_weight_kg': targetWeightKg,
      'selected_goal': goalDbValue(selectedGoal),
      'activity_level': activityLevelDbValue(activityLevel),
      'preferred_logging_method': loggingMethodDbValue(preferredLoggingMethod),
      'onboarding_completed': onboardingCompleted,
    };
  }
}

Goal goalFromDb(Object? value) => switch (value?.toString()) {
      'weight_loss' => Goal.weightLoss,
      'gain_muscle' => Goal.gainMuscle,
      'maintain' => Goal.maintain,
      'fasting' => Goal.fasting,
      _ => Goal.weightLoss,
    };

Gender genderFromDb(Object? value) => switch (value?.toString()) {
      'female' => Gender.female,
      'male' => Gender.male,
      'prefer_not_to_say' => Gender.preferNotToSay,
      _ => Gender.preferNotToSay,
    };

ActivityLevel activityLevelFromDb(Object? value) => switch (value?.toString()) {
      'sedentary' => ActivityLevel.sedentary,
      'light' => ActivityLevel.light,
      'moderate' => ActivityLevel.moderate,
      'active' => ActivityLevel.active,
      _ => ActivityLevel.light,
    };

LoggingMethod loggingMethodFromDb(Object? value) => switch (value?.toString()) {
      'photo' => LoggingMethod.photo,
      'text' => LoggingMethod.text,
      'mixed' => LoggingMethod.mixed,
      _ => LoggingMethod.mixed,
    };

String goalDbValue(Goal goal) => switch (goal) {
      Goal.weightLoss => 'weight_loss',
      Goal.gainMuscle => 'gain_muscle',
      Goal.maintain => 'maintain',
      Goal.fasting => 'fasting',
    };

String genderDbValue(Gender gender) => switch (gender) {
      Gender.female => 'female',
      Gender.male => 'male',
      Gender.preferNotToSay => 'prefer_not_to_say',
    };

String activityLevelDbValue(ActivityLevel value) => switch (value) {
      ActivityLevel.sedentary => 'sedentary',
      ActivityLevel.light => 'light',
      ActivityLevel.moderate => 'moderate',
      ActivityLevel.active => 'active',
    };

String loggingMethodDbValue(LoggingMethod value) => switch (value) {
      LoggingMethod.photo => 'photo',
      LoggingMethod.text => 'text',
      LoggingMethod.mixed => 'mixed',
    };

enum Goal { weightLoss, gainMuscle, maintain, fasting }

extension GoalTitle on Goal {
  String get title => switch (this) {
        Goal.weightLoss => 'Kilo vermek',
        Goal.gainMuscle => 'Kas kazanmak',
        Goal.maintain => 'Formumu korumak',
        Goal.fasting => 'Aralıklı oruç',
      };
}

enum Gender { female, male, preferNotToSay }

extension GenderTitle on Gender {
  String get title => switch (this) {
        Gender.female => 'Kadın',
        Gender.male => 'Erkek',
        Gender.preferNotToSay => 'Belirtmek istemiyorum',
      };
}

enum ActivityLevel { sedentary, light, moderate, active }

extension ActivityLevelTitle on ActivityLevel {
  String get title => switch (this) {
        ActivityLevel.sedentary => 'Çoğunlukla oturuyorum',
        ActivityLevel.light => 'Biraz hareketliyim',
        ActivityLevel.moderate => 'Orta düzey hareketliyim',
        ActivityLevel.active => 'Oldukça aktifim',
      };
}

enum LoggingMethod { photo, text, mixed }

extension LoggingMethodTitle on LoggingMethod {
  String get title => switch (this) {
        LoggingMethod.photo => 'Fotoğraf',
        LoggingMethod.text => 'Yazı',
        LoggingMethod.mixed => 'Hepsi',
      };
}

enum MealSourceType { text, photo, voice }

extension MealSourceTypeTitle on MealSourceType {
  String get title => switch (this) {
        MealSourceType.text => 'YazÄ±',
        MealSourceType.photo => 'FotoÄŸraf',
        MealSourceType.voice => 'Ses',
      };
}

enum MealType { breakfast, lunch, dinner, snack }

extension MealTypeTitle on MealType {
  String get title => switch (this) {
        MealType.breakfast => 'Kahvaltı',
        MealType.lunch => 'Öğle',
        MealType.dinner => 'Akşam',
        MealType.snack => 'Ara öğün',
      };
}

MealType mealTypeFromDb(Object? value) => switch (value?.toString()) {
      'breakfast' => MealType.breakfast,
      'lunch' => MealType.lunch,
      'dinner' => MealType.dinner,
      'snack' => MealType.snack,
      _ => MealType.snack,
    };

String mealTypeDbValue(MealType value) => switch (value) {
      MealType.breakfast => 'breakfast',
      MealType.lunch => 'lunch',
      MealType.dinner => 'dinner',
      MealType.snack => 'snack',
    };

enum ShellState { splash, welcome, auth, onboarding, resetPassword, main }

class MacroTargets {
  MacroTargets({required this.proteinGr, required this.carbsGr, required this.fatGr});
  final int proteinGr;
  final int carbsGr;
  final int fatGr;
}

class MealItem {
  MealItem({
    this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.calories,
    required this.proteinGr,
    required this.carbsGr,
    required this.fatGr,
    this.foodId,
    this.confidence,
  });

  final String? id;
  final String? foodId;
  final String name;
  final double quantity;
  final String unit;
  final int calories;
  final int proteinGr;
  final int carbsGr;
  final int fatGr;
  final Confidence? confidence;

  MealItem copyWith({
    String? id,
    String? name,
    double? quantity,
    String? unit,
    int? calories,
    int? proteinGr,
    int? carbsGr,
    int? fatGr,
    String? foodId,
    Confidence? confidence,
  }) {
    return MealItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      calories: calories ?? this.calories,
      proteinGr: proteinGr ?? this.proteinGr,
      carbsGr: carbsGr ?? this.carbsGr,
      fatGr: fatGr ?? this.fatGr,
      foodId: foodId ?? this.foodId,
      confidence: confidence ?? this.confidence,
    );
  }
}

class Meal {
  Meal({
    this.id,
    required this.mealType,
    required this.title,
    required this.totalCalories,
    required this.macros,
    required this.items,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String? id;
  final MealType mealType;
  final String title;
  final int totalCalories;
  final MacroTargets macros;
  final List<MealItem> items;
  final DateTime createdAt;

  Meal copyWith({
    String? id,
    MealType? mealType,
    String? title,
    int? totalCalories,
    MacroTargets? macros,
    List<MealItem>? items,
    DateTime? createdAt,
  }) {
    return Meal(
      id: id ?? this.id,
      mealType: mealType ?? this.mealType,
      title: title ?? this.title,
      totalCalories: totalCalories ?? this.totalCalories,
      macros: macros ?? this.macros,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Meal.fromSupabase(Map<String, dynamic> data) {
    final rawItems = (data['meal_items'] as List<dynamic>? ?? const []);
    return Meal(
      id: data['id']?.toString(),
      mealType: mealTypeFromDb(data['meal_type']),
      title: data['title']?.toString() ?? 'Meal',
      totalCalories: (data['total_calories'] as num?)?.round() ?? 0,
      macros: MacroTargets(
        proteinGr: (data['protein_gr'] as num?)?.round() ?? 0,
        carbsGr: (data['carbs_gr'] as num?)?.round() ?? 0,
        fatGr: (data['fat_gr'] as num?)?.round() ?? 0,
      ),
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(
            (item) => MealItem(
              id: item['id']?.toString(),
              foodId: item['food_id']?.toString(),
              name: item['name']?.toString() ?? 'Food',
              quantity: (item['quantity'] as num?)?.toDouble() ?? 1,
              unit: item['unit']?.toString() ?? 'serving',
              calories: (item['calories'] as num?)?.round() ?? 0,
              proteinGr: (item['protein_gr'] as num?)?.round() ?? 0,
              carbsGr: (item['carbs_gr'] as num?)?.round() ?? 0,
              fatGr: (item['fat_gr'] as num?)?.round() ?? 0,
              confidence: confidenceFromDb(item['confidence']),
            ),
          )
          .toList(),
      createdAt: DateTime.tryParse(data['logged_at']?.toString() ?? '') ??
          DateTime.tryParse(data['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class MealAnalysis {
  MealAnalysis({
    this.analysisId,
    required this.mealType,
    required this.confidence,
    required this.totalCalories,
    required this.macros,
    required this.detectedItems,
    this.sourceType = MealSourceType.text,
    this.sourceLabel,
    this.portionMultiplier = 1,
    this.correctionNote,
    this.warnings = const [],
  });

  final String? analysisId;
  final MealType mealType;
  final Confidence confidence;
  final int totalCalories;
  final MacroTargets macros;
  final List<MealItem> detectedItems;
  final MealSourceType sourceType;
  final String? sourceLabel;
  final double portionMultiplier;
  final String? correctionNote;
  final List<String> warnings;

  MealAnalysis copyWith({
    String? analysisId,
    MealType? mealType,
    Confidence? confidence,
    int? totalCalories,
    MacroTargets? macros,
    List<MealItem>? detectedItems,
    MealSourceType? sourceType,
    String? sourceLabel,
    double? portionMultiplier,
    String? correctionNote,
    List<String>? warnings,
  }) {
    return MealAnalysis(
      analysisId: analysisId ?? this.analysisId,
      mealType: mealType ?? this.mealType,
      confidence: confidence ?? this.confidence,
      totalCalories: totalCalories ?? this.totalCalories,
      macros: macros ?? this.macros,
      detectedItems: detectedItems ?? this.detectedItems,
      sourceType: sourceType ?? this.sourceType,
      sourceLabel: sourceLabel ?? this.sourceLabel,
      portionMultiplier: portionMultiplier ?? this.portionMultiplier,
      correctionNote: correctionNote ?? this.correctionNote,
      warnings: warnings ?? this.warnings,
    );
  }

  MealAnalysis scalePortions(double multiplier) {
    final scaledItems = detectedItems
        .map(
          (item) => item.copyWith(
            quantity: (item.quantity * multiplier * 10).roundToDouble() / 10,
            calories: (item.calories * multiplier).round(),
            proteinGr: (item.proteinGr * multiplier).round(),
            carbsGr: (item.carbsGr * multiplier).round(),
            fatGr: (item.fatGr * multiplier).round(),
          ),
        )
        .toList();

    return copyWith(
      totalCalories: (totalCalories * multiplier).round(),
      macros: MacroTargets(
        proteinGr: (macros.proteinGr * multiplier).round(),
        carbsGr: (macros.carbsGr * multiplier).round(),
        fatGr: (macros.fatGr * multiplier).round(),
      ),
      detectedItems: scaledItems,
      portionMultiplier: multiplier,
    );
  }

  Meal toMeal() {
    return Meal(
      mealType: mealType,
      title: detectedItems.map((item) => item.name).join(', '),
      totalCalories: totalCalories,
      macros: macros,
      items: detectedItems,
    );
  }
}

enum Confidence { low, medium, high }

extension ConfidenceTitle on Confidence {
  String get title => switch (this) {
        Confidence.low => 'Düşük',
        Confidence.medium => 'Orta',
        Confidence.high => 'Yüksek',
      };
}

Confidence? confidenceFromDb(Object? value) => switch (value?.toString()) {
      'low' => Confidence.low,
      'medium' => Confidence.medium,
      'high' => Confidence.high,
      _ => null,
    };

class TodayDashboard {
  TodayDashboard({
    required this.calorieTarget,
    required this.consumedCalories,
    required this.macroTargets,
    required this.consumedMacros,
    required this.meals,
    required this.hydrationCurrent,
    required this.hydrationTarget,
  });

  final int calorieTarget;
  final int consumedCalories;
  final MacroTargets macroTargets;
  final MacroTargets consumedMacros;
  final List<Meal> meals;
  final int hydrationCurrent;
  final int hydrationTarget;

  int get remainingCalories => (calorieTarget - consumedCalories).clamp(0, calorieTarget);
}

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

class RecipeIngredient {
  RecipeIngredient({
    required this.name,
    required this.amount,
    required this.unit,
    this.note,
  });

  final String name;
  final String amount;
  final String unit;
  final String? note;

  Map<String, dynamic> toMap() => {
        'name': name,
        'amount': amount,
        'unit': unit,
        if (note != null) 'note': note,
      };

  factory RecipeIngredient.fromMap(Map<String, dynamic> data) {
    return RecipeIngredient(
      name: data['name']?.toString() ?? 'Ingredient',
      amount: data['amount']?.toString() ?? '1',
      unit: data['unit']?.toString() ?? 'serving',
      note: data['note']?.toString(),
    );
  }
}

class PlannedMeal {
  PlannedMeal({
    this.id,
    this.recipeId,
    required this.mealType,
    required this.title,
    required this.description,
    required this.calories,
    this.proteinGr = 0,
    this.carbsGr = 0,
    this.fatGr = 0,
    this.prepMinutes = 0,
    this.cookMinutes = 0,
    this.servings = 1,
    this.ingredients = const [],
    this.steps = const [],
    this.alternatives = const [],
    this.isApplied = false,
    this.note,
  });

  final String? id;
  final String? recipeId;
  final MealType mealType;
  final String title;
  final String description;
  final int calories;
  final int proteinGr;
  final int carbsGr;
  final int fatGr;
  final int prepMinutes;
  final int cookMinutes;
  final int servings;
  final List<RecipeIngredient> ingredients;
  final List<String> steps;
  final List<PlannedMeal> alternatives;
  final bool isApplied;
  final String? note;

  PlannedMeal copyWith({
    String? id,
    String? recipeId,
    MealType? mealType,
    String? title,
    String? description,
    int? calories,
    int? proteinGr,
    int? carbsGr,
    int? fatGr,
    int? prepMinutes,
    int? cookMinutes,
    int? servings,
    List<RecipeIngredient>? ingredients,
    List<String>? steps,
    List<PlannedMeal>? alternatives,
    bool? isApplied,
    String? note,
  }) {
    return PlannedMeal(
      id: id ?? this.id,
      recipeId: recipeId ?? this.recipeId,
      mealType: mealType ?? this.mealType,
      title: title ?? this.title,
      description: description ?? this.description,
      calories: calories ?? this.calories,
      proteinGr: proteinGr ?? this.proteinGr,
      carbsGr: carbsGr ?? this.carbsGr,
      fatGr: fatGr ?? this.fatGr,
      prepMinutes: prepMinutes ?? this.prepMinutes,
      cookMinutes: cookMinutes ?? this.cookMinutes,
      servings: servings ?? this.servings,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
      alternatives: alternatives ?? this.alternatives,
      isApplied: isApplied ?? this.isApplied,
      note: note ?? this.note,
    );
  }

  int get totalMinutes => prepMinutes + cookMinutes;
}

class ChatMessage {
  ChatMessage({
    this.id,
    required this.role,
    required this.text,
    DateTime? createdAt,
    this.suggestionChips = const [],
    this.recipeCards = const [],
    this.quickActions = const [],
    this.contextSummary,
  }) : createdAt = createdAt ?? DateTime.now();

  final String? id;
  final ChatRole role;
  final String text;
  final DateTime createdAt;
  final List<ChatSuggestionChip> suggestionChips;
  final List<ChatRecipeCard> recipeCards;
  final List<String> quickActions;
  final String? contextSummary;

  ChatMessage copyWith({
    String? id,
    ChatRole? role,
    String? text,
    DateTime? createdAt,
    List<ChatSuggestionChip>? suggestionChips,
    List<ChatRecipeCard>? recipeCards,
    List<String>? quickActions,
    String? contextSummary,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      suggestionChips: suggestionChips ?? this.suggestionChips,
      recipeCards: recipeCards ?? this.recipeCards,
      quickActions: quickActions ?? this.quickActions,
      contextSummary: contextSummary ?? this.contextSummary,
    );
  }

  factory ChatMessage.fromMap(Map<String, dynamic> data) {
    return ChatMessage(
      id: data['id']?.toString(),
      role: (data['role']?.toString() == 'assistant') ? ChatRole.assistant : ChatRole.user,
      text: data['text']?.toString() ?? '',
      createdAt: DateTime.tryParse(data['createdAt']?.toString() ?? '') ?? DateTime.now(),
      suggestionChips: (data['suggestionChips'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ChatSuggestionChip.fromMap)
          .toList(),
      recipeCards: (data['recipeCards'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ChatRecipeCard.fromMap)
          .toList(),
      quickActions: (data['quickActions'] as List<dynamic>? ?? const []).map((e) => e.toString()).toList(),
      contextSummary: data['contextSummary']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'role': role.name,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
        if (suggestionChips.isNotEmpty) 'suggestionChips': suggestionChips.map((chip) => chip.toMap()).toList(),
        if (recipeCards.isNotEmpty) 'recipeCards': recipeCards.map((card) => card.toMap()).toList(),
        if (quickActions.isNotEmpty) 'quickActions': quickActions,
        if (contextSummary != null) 'contextSummary': contextSummary,
      };
}

enum ChatRole { user, assistant }

class ChatSuggestionChip {
  ChatSuggestionChip({
    required this.label,
    required this.prompt,
    this.kind,
  });

  final String label;
  final String prompt;
  final String? kind;

  factory ChatSuggestionChip.fromMap(Map<String, dynamic> data) {
    return ChatSuggestionChip(
      label: data['label']?.toString() ?? '',
      prompt: data['prompt']?.toString() ?? data['label']?.toString() ?? '',
      kind: data['kind']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
        'label': label,
        'prompt': prompt,
        if (kind != null) 'kind': kind,
      };
}

class ChatRecipeCard {
  ChatRecipeCard({
    required this.recipeId,
    required this.title,
    required this.subtitle,
    required this.mealType,
    required this.description,
    required this.calories,
    required this.proteinGr,
    required this.carbsGr,
    required this.fatGr,
    this.prepMinutes = 0,
    this.cookMinutes = 0,
    this.servings = 1,
    this.ingredients = const [],
    this.steps = const [],
    this.tags = const [],
  });

  final String recipeId;
  final String title;
  final String subtitle;
  final MealType mealType;
  final String description;
  final int calories;
  final int proteinGr;
  final int carbsGr;
  final int fatGr;
  final int prepMinutes;
  final int cookMinutes;
  final int servings;
  final List<RecipeIngredient> ingredients;
  final List<String> steps;
  final List<String> tags;

  PlannedMeal toPlannedMeal() {
    return PlannedMeal(
      id: recipeId,
      recipeId: recipeId,
      mealType: mealType,
      title: title,
      description: description,
      calories: calories,
      proteinGr: proteinGr,
      carbsGr: carbsGr,
      fatGr: fatGr,
      prepMinutes: prepMinutes,
      cookMinutes: cookMinutes,
      servings: servings,
      ingredients: ingredients,
      steps: steps,
    );
  }

  factory ChatRecipeCard.fromMap(Map<String, dynamic> data) {
    return ChatRecipeCard(
      recipeId: data['recipeId']?.toString() ?? data['id']?.toString() ?? '',
      title: data['title']?.toString() ?? '',
      subtitle: data['subtitle']?.toString() ?? '',
      mealType: mealTypeFromDb(data['mealType'] ?? data['meal_type']),
      description: data['description']?.toString() ?? '',
      calories: (data['calories'] as num?)?.toInt() ?? 0,
      proteinGr: (data['proteinGr'] as num?)?.toInt() ?? (data['protein_gr'] as num?)?.toInt() ?? 0,
      carbsGr: (data['carbsGr'] as num?)?.toInt() ?? (data['carbs_gr'] as num?)?.toInt() ?? 0,
      fatGr: (data['fatGr'] as num?)?.toInt() ?? (data['fat_gr'] as num?)?.toInt() ?? 0,
      prepMinutes: (data['prepMinutes'] as num?)?.toInt() ?? (data['prep_minutes'] as num?)?.toInt() ?? 0,
      cookMinutes: (data['cookMinutes'] as num?)?.toInt() ?? (data['cook_minutes'] as num?)?.toInt() ?? 0,
      servings: (data['servings'] as num?)?.toInt() ?? 1,
      ingredients: (data['ingredients'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(RecipeIngredient.fromMap)
          .toList(),
      steps: (data['steps'] as List<dynamic>? ?? const []).map((e) => e.toString()).toList(),
      tags: (data['tags'] as List<dynamic>? ?? const []).map((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toMap() => {
        'recipeId': recipeId,
        'title': title,
        'subtitle': subtitle,
        'mealType': mealTypeDbValue(mealType),
        'description': description,
        'calories': calories,
        'proteinGr': proteinGr,
        'carbsGr': carbsGr,
        'fatGr': fatGr,
        'prepMinutes': prepMinutes,
        'cookMinutes': cookMinutes,
        'servings': servings,
        'ingredients': ingredients.map((item) => item.toMap()).toList(),
        'steps': steps,
        'tags': tags,
      };
}

class ChatThread {
  ChatThread({
    required this.id,
    required this.title,
    required this.messages,
    this.suggestionChips = const [],
    this.recipeCards = const [],
    this.quickActions = const [],
    this.contextSummary,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String title;
  final List<ChatMessage> messages;
  final List<ChatSuggestionChip> suggestionChips;
  final List<ChatRecipeCard> recipeCards;
  final List<String> quickActions;
  final String? contextSummary;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatThread copyWith({
    String? id,
    String? title,
    List<ChatMessage>? messages,
    List<ChatSuggestionChip>? suggestionChips,
    List<ChatRecipeCard>? recipeCards,
    List<String>? quickActions,
    String? contextSummary,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatThread(
      id: id ?? this.id,
      title: title ?? this.title,
      messages: messages ?? this.messages,
      suggestionChips: suggestionChips ?? this.suggestionChips,
      recipeCards: recipeCards ?? this.recipeCards,
      quickActions: quickActions ?? this.quickActions,
      contextSummary: contextSummary ?? this.contextSummary,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ChatThread.fromMap(Map<String, dynamic> data) {
    return ChatThread(
      id: data['id']?.toString() ?? cryptoRandomId(),
      title: data['title']?.toString() ?? 'Nuri',
      messages: (data['messages'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ChatMessage.fromMap)
          .toList(),
      suggestionChips: (data['suggestionChips'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ChatSuggestionChip.fromMap)
          .toList(),
      recipeCards: (data['recipeCards'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ChatRecipeCard.fromMap)
          .toList(),
      quickActions: (data['quickActions'] as List<dynamic>? ?? const []).map((e) => e.toString()).toList(),
      contextSummary: data['contextSummary']?.toString(),
      createdAt: DateTime.tryParse(data['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(data['updatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'messages': messages.map((message) => message.toMap()).toList(),
        if (suggestionChips.isNotEmpty) 'suggestionChips': suggestionChips.map((chip) => chip.toMap()).toList(),
        if (recipeCards.isNotEmpty) 'recipeCards': recipeCards.map((card) => card.toMap()).toList(),
        if (quickActions.isNotEmpty) 'quickActions': quickActions,
        if (contextSummary != null) 'contextSummary': contextSummary,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}

String cryptoRandomId() => DateTime.now().microsecondsSinceEpoch.toString();

class FoodSearchResult {
  FoodSearchResult({
    this.id,
    this.brand,
    this.sourceUrl,
    this.source,
    this.servings = const [],
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final String? id;
  final String? brand;
  final String? sourceUrl;
  final String? source;
  final String name;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final List<FoodServingOption> servings;

  FoodServingOption? get primaryServing {
    if (servings.isEmpty) return null;
    return servings.firstWhere(
      (serving) => serving.isDefault,
      orElse: () => servings.first,
    );
  }

  FoodSearchResult copyWith({
    String? id,
    String? name,
    String? brand,
    String? sourceUrl,
    String? source,
    int? calories,
    int? protein,
    int? carbs,
    int? fat,
    List<FoodServingOption>? servings,
  }) {
    return FoodSearchResult(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      source: source ?? this.source,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      servings: servings ?? this.servings,
    );
  }

  factory FoodSearchResult.fromSupabase(Map<String, dynamic> data) {
    final servings = (data['food_servings'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(FoodServingOption.fromSupabase)
        .toList();
    final primaryServing = servings.isNotEmpty
        ? servings.firstWhere(
            (serving) => serving.isDefault,
            orElse: () => servings.first,
          )
        : null;

    return FoodSearchResult(
      id: data['id']?.toString(),
      name: data['name']?.toString() ?? 'Food',
      brand: data['brand']?.toString(),
      sourceUrl: data['source_url']?.toString(),
      source: data['source']?.toString(),
      calories: primaryServing?.calories ?? 0,
      protein: primaryServing?.proteinGr ?? 0,
      carbs: primaryServing?.carbsGr ?? 0,
      fat: primaryServing?.fatGr ?? 0,
      servings: servings,
    );
  }

  factory FoodSearchResult.fromMealItem(MealItem item) {
    return FoodSearchResult(
      id: item.foodId,
      name: item.name,
      calories: item.calories,
      protein: item.proteinGr,
      carbs: item.carbsGr,
      fat: item.fatGr,
      servings: [
        FoodServingOption(
          id: item.id,
          description: item.unit,
          metricAmount: item.quantity,
          metricUnit: item.unit,
          calories: item.calories,
          proteinGr: item.proteinGr,
          carbsGr: item.carbsGr,
          fatGr: item.fatGr,
          isDefault: true,
        ),
      ],
    );
  }

  Map<String, dynamic> toMealItemPayload({
    required double quantity,
    FoodServingOption? serving,
  }) {
    final selectedServing = serving ?? primaryServing;
    final baseCalories = selectedServing?.calories ?? calories;
    final baseProtein = selectedServing?.proteinGr ?? protein;
    final baseCarbs = selectedServing?.carbsGr ?? carbs;
    final baseFat = selectedServing?.fatGr ?? fat;

    return {
      'foodId': id,
      'name': name,
      'quantity': quantity,
      'unit': selectedServing?.metricUnit ?? selectedServing?.description ?? 'serving',
      'calories': (baseCalories * quantity).round(),
      'proteinGr': (baseProtein * quantity).round(),
      'carbsGr': (baseCarbs * quantity).round(),
      'fatGr': (baseFat * quantity).round(),
    };
  }
}

class FoodServingOption {
  FoodServingOption({
    this.id,
    required this.description,
    required this.metricAmount,
    required this.metricUnit,
    required this.calories,
    required this.proteinGr,
    required this.carbsGr,
    required this.fatGr,
    required this.isDefault,
  });

  final String? id;
  final String description;
  final double metricAmount;
  final String metricUnit;
  final int calories;
  final int proteinGr;
  final int carbsGr;
  final int fatGr;
  final bool isDefault;

  String get label {
    final amount = metricAmount == metricAmount.roundToDouble()
        ? metricAmount.round().toString()
        : metricAmount.toStringAsFixed(1);
    if (metricUnit.isEmpty) {
      return description;
    }
    return '$amount $metricUnit · $description';
  }

  FoodServingOption copyWith({
    String? id,
    String? description,
    double? metricAmount,
    String? metricUnit,
    int? calories,
    int? proteinGr,
    int? carbsGr,
    int? fatGr,
    bool? isDefault,
  }) {
    return FoodServingOption(
      id: id ?? this.id,
      description: description ?? this.description,
      metricAmount: metricAmount ?? this.metricAmount,
      metricUnit: metricUnit ?? this.metricUnit,
      calories: calories ?? this.calories,
      proteinGr: proteinGr ?? this.proteinGr,
      carbsGr: carbsGr ?? this.carbsGr,
      fatGr: fatGr ?? this.fatGr,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  factory FoodServingOption.fromSupabase(Map<String, dynamic> data) {
    return FoodServingOption(
      id: data['id']?.toString(),
      description: data['serving_description']?.toString() ?? 'serving',
      metricAmount: (data['metric_amount'] as num?)?.toDouble() ?? 1,
      metricUnit: data['metric_unit']?.toString() ?? 'serving',
      calories: (data['calories'] as num?)?.round() ?? 0,
      proteinGr: (data['protein_gr'] as num?)?.round() ?? 0,
      carbsGr: (data['carbs_gr'] as num?)?.round() ?? 0,
      fatGr: (data['fat_gr'] as num?)?.round() ?? 0,
      isDefault: data['is_default'] as bool? ?? false,
    );
  }
}
