// user domain models — split from core/models.dart.
// Do not import directly; use the 'package:nutri_easy_flutter/core/models.dart' barrel.

class UserProfile {
  UserProfile({
    this.id = '',
    this.name = 'Umut',
    this.email = 'umut@example.com',
    this.gender = Gender.preferNotToSay,
    this.age = 30,
    this.heightCm = 175,
    this.weightKg = 78,
    this.targetWeightKg,
    this.selectedGoal = Goal.weightLoss,
    this.activityLevel = ActivityLevel.light,
    this.preferredLoggingMethod = LoggingMethod.text,
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


class NotificationPreferences {
  NotificationPreferences({
    this.permissionGranted = false,
    this.waterReminders = true,
    this.mealReminders = true,
    this.fastingNotifications = true,
    this.dailySummary = true,
  });

  final bool permissionGranted;
  final bool waterReminders;
  final bool mealReminders;
  final bool fastingNotifications;
  final bool dailySummary;

  NotificationPreferences copyWith({
    bool? permissionGranted,
    bool? waterReminders,
    bool? mealReminders,
    bool? fastingNotifications,
    bool? dailySummary,
  }) {
    return NotificationPreferences(
      permissionGranted: permissionGranted ?? this.permissionGranted,
      waterReminders: waterReminders ?? this.waterReminders,
      mealReminders: mealReminders ?? this.mealReminders,
      fastingNotifications: fastingNotifications ?? this.fastingNotifications,
      dailySummary: dailySummary ?? this.dailySummary,
    );
  }

  factory NotificationPreferences.fromMap(Map<String, dynamic> data) {
    return NotificationPreferences(
      permissionGranted: data['permissionGranted'] as bool? ?? false,
      waterReminders: data['waterReminders'] as bool? ?? true,
      mealReminders: data['mealReminders'] as bool? ?? true,
      fastingNotifications: data['fastingNotifications'] as bool? ?? true,
      dailySummary: data['dailySummary'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
        'permissionGranted': permissionGranted,
        'waterReminders': waterReminders,
        'mealReminders': mealReminders,
        'fastingNotifications': fastingNotifications,
        'dailySummary': dailySummary,
      };
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
      'voice' => LoggingMethod.voice,
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
      LoggingMethod.voice => 'voice',
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


enum LoggingMethod { photo, text, voice, mixed }

extension LoggingMethodTitle on LoggingMethod {
  String get title => switch (this) {
        LoggingMethod.photo => 'Fotoğraf',
        LoggingMethod.text => 'Yazı',
        LoggingMethod.voice => 'Ses',
        LoggingMethod.mixed => 'Hepsi',
      };
}


enum ShellState { splash, welcome, auth, onboarding, resetPassword, main }


