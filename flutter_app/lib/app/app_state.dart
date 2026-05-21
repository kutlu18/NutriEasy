import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/analytics/app_analytics.dart';
import '../core/errors/app_error_parser.dart';
import '../core/logging/app_logger.dart';
import '../core/mock_data.dart';
import '../core/models.dart';
import '../core/services/nutri_supabase_service.dart';
import '../core/storage/app_local_storage.dart';

class AppState extends ChangeNotifier {
  AppState()
      : user = UserProfile(),
        meals = List<Meal>.from(MockData.meals),
        dailyPlan = List<PlannedMeal>.from(MockData.plannedMeals),
        chatMessages = [
          ChatMessage(
            role: ChatRole.assistant,
            text: 'Merhaba, ben Nuri. Bugunku hedeflerine gore ogun kararlarinda yardimci olabilirim.',
          ),
        ];

  final NutriSupabaseService _service = NutriSupabaseService();
  StreamSubscription<AuthState>? _authSubscription;
  AppLocalStorage? _storage;
  bool _initialized = false;

  ShellState shellState = ShellState.splash;
  bool hasSeenWelcome = false;
  int mainTabIndex = 0;
  bool isAuthenticated = false;
  bool isBootstrapping = false;
  bool isAuthenticating = false;
  bool isAnalyzingMeal = false;
  bool isCorrectingAnalysis = false;
  bool isSavingMeal = false;
  bool isUpdatingMealItem = false;
  String? errorMessage;
  String? accessToken;

  UserProfile user;
  List<Meal> meals;
  List<PlannedMeal> dailyPlan;
  List<String> foodSearchHistory = const [];
  MealAnalysis? selectedAnalysis;
  List<ChatMessage> chatMessages;

  TodayDashboard get dashboard {
    final calories = meals.fold<int>(0, (sum, meal) => sum + meal.totalCalories);
    final macros = meals.fold<MacroTargets>(
      MacroTargets(proteinGr: 0, carbsGr: 0, fatGr: 0),
      (partial, meal) => MacroTargets(
        proteinGr: partial.proteinGr + meal.macros.proteinGr,
        carbsGr: partial.carbsGr + meal.macros.carbsGr,
        fatGr: partial.fatGr + meal.macros.fatGr,
      ),
    );

    return TodayDashboard(
      calorieTarget: calorieTargetForProfile,
      consumedCalories: calories,
      macroTargets: macroTargetsForProfile,
      consumedMacros: macros,
      meals: meals,
      hydrationCurrent: 4,
      hydrationTarget: 8,
    );
  }

  int get calorieTargetForProfile => switch (user.selectedGoal) {
        Goal.weightLoss => user.activityLevel == ActivityLevel.active ? 1900 : 1750,
        Goal.gainMuscle => user.activityLevel == ActivityLevel.active ? 2450 : 2250,
        Goal.maintain => user.activityLevel == ActivityLevel.active ? 2200 : 2000,
        Goal.fasting => 1700,
      };

  MacroTargets get macroTargetsForProfile => switch (user.selectedGoal) {
        Goal.weightLoss => MacroTargets(proteinGr: 130, carbsGr: 150, fatGr: 55),
        Goal.gainMuscle => MacroTargets(proteinGr: 160, carbsGr: 220, fatGr: 70),
        Goal.maintain => MacroTargets(proteinGr: 125, carbsGr: 190, fatGr: 65),
        Goal.fasting => MacroTargets(proteinGr: 120, carbsGr: 140, fatGr: 60),
      };

  void initialize() {
    if (_initialized) return;
    _initialized = true;

    final session = Supabase.instance.client.auth.currentSession;
    accessToken = session?.accessToken;
    isAuthenticated = session != null;
    AppAnalytics.instance.logEvent('app_initialize', parameters: {'hasSession': session != null});

    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      (data) {
        accessToken = data.session?.accessToken;
        isAuthenticated = data.session != null;

        if (data.event == AuthChangeEvent.signedOut) {
          user = UserProfile();
          selectedAnalysis = null;
          errorMessage = null;
          _applySessionToShell();
        } else if (data.event == AuthChangeEvent.passwordRecovery) {
          errorMessage = null;
          _setShellState(ShellState.resetPassword);
        } else if (data.session != null && data.event == AuthChangeEvent.signedIn) {
          unawaited(_hydrateAuthenticatedSession(data.session!));
        } else if (data.session != null && data.event == AuthChangeEvent.tokenRefreshed) {
          unawaited(_hydrateAuthenticatedSession(data.session!));
        }

        notifyListeners();
      },
      onError: (error, stackTrace) {
        errorMessage = 'Oturum durumu guncellenemedi: ${AppErrorParser.message(error)}';
        AppLogger.error('Auth state listener failed', error: error, stackTrace: stackTrace);
        notifyListeners();
      },
    );
  }

  Future<void> bootstrapApp() async {
    isBootstrapping = true;
    notifyListeners();

    _storage ??= await AppLocalStorage.create();
    hasSeenWelcome = _storage!.hasSeenWelcome;
    mainTabIndex = _storage!.lastMainTabIndex;
    foodSearchHistory = List<String>.from(_storage!.foodSearchHistory);

    await Future<void>.delayed(const Duration(milliseconds: 650));

    final session = Supabase.instance.client.auth.currentSession;
    accessToken = session?.accessToken;
    isAuthenticated = session != null;

    if (session != null) {
      await _hydrateAuthenticatedSession(session);
    }

    _applySessionToShell();

    isBootstrapping = false;
    notifyListeners();
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    isAuthenticating = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await _service.signInWithPassword(email: email, password: password);
      accessToken = response.session?.accessToken;
      isAuthenticated = response.session != null;
      if (response.session != null) {
        await _hydrateAuthenticatedSession(response.session!);
      }
      _applySessionToShell();
    } catch (error) {
      errorMessage = AppErrorParser.message(error);
      AppLogger.error('Sign in failed', error: error);
    } finally {
      isAuthenticating = false;
      notifyListeners();
    }
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    isAuthenticating = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await _service.signUp(email: email, password: password);
      accessToken = response.session?.accessToken;
      isAuthenticated = response.session != null;
      if (response.session != null) {
        await _hydrateAuthenticatedSession(response.session!);
      }

      if (response.session == null) {
        errorMessage = 'Kayit tamamlandi, e-posta dogrulamasi bekleniyor.';
      }

      _applySessionToShell();
    } catch (error) {
      errorMessage = AppErrorParser.message(error);
      AppLogger.error('Sign up failed', error: error);
    } finally {
      isAuthenticating = false;
      notifyListeners();
    }
  }

  Future<void> requestPasswordReset({
    required String email,
  }) async {
    isAuthenticating = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _service.requestPasswordReset(email: email);
    } catch (error) {
      errorMessage = AppErrorParser.message(error);
      AppLogger.error('Password reset request failed', error: error);
    } finally {
      isAuthenticating = false;
      notifyListeners();
    }
  }

  Future<void> updatePassword({
    required String password,
  }) async {
    isAuthenticating = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _service.updatePassword(password: password);
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        await _hydrateAuthenticatedSession(session);
      }
      _applySessionToShell();
    } catch (error) {
      errorMessage = AppErrorParser.message(error);
      AppLogger.error('Password update failed', error: error);
    } finally {
      isAuthenticating = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      user = UserProfile();
      isAuthenticated = false;
      accessToken = null;
      selectedAnalysis = null;
      mainTabIndex = 0;
      meals = List<Meal>.from(MockData.meals);
      dailyPlan = List<PlannedMeal>.from(MockData.plannedMeals);
      foodSearchHistory = const [];
      _applySessionToShell();
      notifyListeners();
    } catch (error) {
      errorMessage = AppErrorParser.message(error);
      AppLogger.error('Sign out failed', error: error);
      notifyListeners();
    }
  }

  Future<void> completeWelcome() async {
    hasSeenWelcome = true;
    await _storage?.setHasSeenWelcome(true);
    _applySessionToShell();
    notifyListeners();
  }

  List<FoodSearchResult> get popularFoods {
    final counts = <String, _FoodPopularityBucket>{};

    for (final meal in meals) {
      for (final item in meal.items) {
        final key = item.foodId ?? item.name.toLowerCase();
        final bucket = counts.putIfAbsent(
          key,
          () => _FoodPopularityBucket(
            food: FoodSearchResult.fromMealItem(item),
            count: 0,
          ),
        );
        bucket.count += 1;
        bucket.food = bucket.food.copyWith(
          calories: item.calories,
          protein: item.proteinGr,
          carbs: item.carbsGr,
          fat: item.fatGr,
        );
      }
    }

    final popular = counts.values.toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    if (popular.isEmpty) {
      return MockData.quickAdd;
    }

    return popular.take(8).map((bucket) => bucket.food).toList();
  }

  Future<void> recordFoodSearch(String query) async {
    final cleaned = query.trim();
    if (cleaned.length < 2) return;

    final nextHistory = <String>[
      cleaned,
      ...foodSearchHistory.where((item) => item.toLowerCase() != cleaned.toLowerCase()),
    ].take(8).toList();

    foodSearchHistory = nextHistory;
    await _storage?.setFoodSearchHistory(nextHistory);
    notifyListeners();
  }

  void showAuthFlow() {
    errorMessage = null;
    _setShellState(hasSeenWelcome ? ShellState.auth : ShellState.welcome);
    notifyListeners();
  }

  void clearErrorMessage() {
    if (errorMessage == null) return;
    errorMessage = null;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    user = user.copyWith(onboardingCompleted: true);
    if (isAuthenticated) {
      final response = await _service.refreshProfile(profile: user.toSupabaseMap());
      final profileData = response['profile'];
      if (profileData is Map<String, dynamic>) {
        user = UserProfile.fromSupabase(profileData, email: user.email);
      }
    }

    _applySessionToShell();
    notifyListeners();
  }

  Future<void> hydrateProfileFromAuth() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return;
    await _hydrateAuthenticatedSession(session);
    _applySessionToShell();
    notifyListeners();
  }

  Future<void> setMainTabIndex(int value) async {
    if (mainTabIndex == value) return;
    mainTabIndex = value;
    await _storage?.setLastMainTabIndex(value);
    AppAnalytics.instance.logScreen(_screenNameForTab(value));
    notifyListeners();
  }

  Future<void> analyzeMeal({
    required String source,
    required MealType mealType,
    MealSourceType sourceType = MealSourceType.text,
    String? sourceLabel,
  }) async {
    final text = source.trim();
    if (text.isEmpty) {
      errorMessage = 'Analiz icin kisa bir ogun aciklamasi yazmalisin.';
      notifyListeners();
      return;
    }

    isAnalyzingMeal = true;
    errorMessage = null;
    notifyListeners();

    try {
      if (isAuthenticated && accessToken != null) {
        final response = await _service.analyzeText(
          text: text,
          mealType: mealType.name,
          profile: {
            'selectedGoal': goalDbValue(user.selectedGoal),
            'activityLevel': activityLevelDbValue(user.activityLevel),
            'targetCalories': calorieTargetForProfile,
            'proteinTarget': macroTargetsForProfile.proteinGr,
          },
        );
        selectedAnalysis = _analysisFromResponse(
          response,
          mealType,
          sourceType: sourceType,
          sourceLabel: sourceLabel ?? text,
        );
      } else {
        final fallback = MockData.analysis;
        selectedAnalysis = MealAnalysis(
          mealType: mealType,
          confidence: fallback.confidence,
          totalCalories: fallback.totalCalories,
          macros: fallback.macros,
          detectedItems: fallback.detectedItems,
          sourceType: sourceType,
          sourceLabel: sourceLabel ?? text,
          warnings: const ['Demo modunda ornek analiz gosteriliyor.'],
        );
      }
    } catch (error) {
      final fallback = MockData.analysis;
      selectedAnalysis = MealAnalysis(
        mealType: mealType,
        confidence: fallback.confidence,
        totalCalories: fallback.totalCalories,
        macros: fallback.macros,
        detectedItems: fallback.detectedItems,
        sourceType: sourceType,
        sourceLabel: sourceLabel ?? text,
        warnings: const ['Canli analiz calismadi. Simdilik ornek analiz gosteriliyor.'],
      );
      errorMessage = AppErrorParser.message(error);
      AppLogger.error('Meal analysis failed', error: error);
    } finally {
      isAnalyzingMeal = false;
      notifyListeners();
    }
  }

  Future<void> analyzePhoto({
    required String sourceLabel,
    required MealType mealType,
  }) async {
    final label = sourceLabel.trim();
    if (label.isEmpty) {
      errorMessage = 'Foto analiz icin kisa bir aciklama gerekli.';
      notifyListeners();
      return;
    }

    isAnalyzingMeal = true;
    errorMessage = null;
    notifyListeners();

    try {
      if (isAuthenticated && accessToken != null) {
        final response = await _service.analyzeImage(
          imageLabel: label,
          mealType: mealType.name,
          profile: {
            'selectedGoal': goalDbValue(user.selectedGoal),
            'activityLevel': activityLevelDbValue(user.activityLevel),
            'targetCalories': calorieTargetForProfile,
            'proteinTarget': macroTargetsForProfile.proteinGr,
          },
        );
        selectedAnalysis = _analysisFromResponse(
          response,
          mealType,
          sourceType: MealSourceType.photo,
          sourceLabel: sourceLabel,
        );
      } else {
        final fallback = MockData.analysis;
        selectedAnalysis = MealAnalysis(
          mealType: mealType,
          confidence: fallback.confidence,
          totalCalories: fallback.totalCalories,
          macros: fallback.macros,
          detectedItems: fallback.detectedItems,
          sourceType: MealSourceType.photo,
          sourceLabel: sourceLabel,
          warnings: const ['Demo modunda foto analiz ornek sonucu gosteriliyor.'],
        );
      }
    } catch (error) {
      final fallback = MockData.analysis;
      selectedAnalysis = MealAnalysis(
        mealType: mealType,
        confidence: fallback.confidence,
        totalCalories: fallback.totalCalories,
        macros: fallback.macros,
        detectedItems: fallback.detectedItems,
        sourceType: MealSourceType.photo,
        sourceLabel: sourceLabel,
        warnings: const ['Canli foto analiz calismadi. Simdilik ornek analiz gosteriliyor.'],
      );
      errorMessage = AppErrorParser.message(error);
      AppLogger.error('Photo meal analysis failed', error: error);
    } finally {
      isAnalyzingMeal = false;
      notifyListeners();
    }
  }

  Future<void> analyzeVoice({
    required String transcript,
    required MealType mealType,
  }) async {
    await analyzeMeal(
      source: transcript,
      mealType: mealType,
      sourceType: MealSourceType.voice,
      sourceLabel: transcript,
    );
  }

  void updateSelectedAnalysisPortion(double multiplier) {
    final analysis = selectedAnalysis;
    if (analysis == null) return;
    selectedAnalysis = analysis.scalePortions(multiplier);
    notifyListeners();
  }

  Future<void> applySelectedAnalysisCorrection(String note) async {
    final analysis = selectedAnalysis;
    if (analysis == null) return;

    final cleaned = note.trim();
    if (cleaned.isEmpty) return;

    isCorrectingAnalysis = true;
    errorMessage = null;
    notifyListeners();

    try {
      if (isAuthenticated && accessToken != null) {
        final response = await _service.correctAnalysis(
          analysis: {
            'analysisId': analysis.analysisId,
            'mealType': analysis.mealType.name,
            'totalCalories': analysis.totalCalories,
            'macros': {
              'proteinGr': analysis.macros.proteinGr,
              'carbsGr': analysis.macros.carbsGr,
              'fatGr': analysis.macros.fatGr,
            },
            'detectedItems': analysis.detectedItems
                .map(
                  (item) => {
                    'foodId': item.foodId,
                    'name': item.name,
                    'quantity': item.quantity,
                    'unit': item.unit,
                    'calories': item.calories,
                    'proteinGr': item.proteinGr,
                    'carbsGr': item.carbsGr,
                    'fatGr': item.fatGr,
                    'confidence': item.confidence?.name,
                  },
                )
                .toList(),
            'sourceType': analysis.sourceType.name,
            'sourceLabel': analysis.sourceLabel,
            'portionMultiplier': analysis.portionMultiplier,
            'warnings': analysis.warnings,
            'correctionNote': analysis.correctionNote,
          },
          note: cleaned,
          profile: {
            'selectedGoal': goalDbValue(user.selectedGoal),
            'activityLevel': activityLevelDbValue(user.activityLevel),
            'targetCalories': calorieTargetForProfile,
            'proteinTarget': macroTargetsForProfile.proteinGr,
          },
        );
        selectedAnalysis = _analysisFromResponse(
          response,
          analysis.mealType,
          sourceType: analysis.sourceType,
          sourceLabel: analysis.sourceLabel,
        ).copyWith(
          correctionNote: cleaned,
        );
      } else {
        selectedAnalysis = analysis.copyWith(
          correctionNote: cleaned,
          warnings: [
            ...analysis.warnings,
            'Duzeltme notu kaydedildi: $cleaned',
          ],
          confidence: Confidence.low,
        );
      }
      notifyListeners();
    } catch (error) {
      errorMessage = AppErrorParser.message(error);
      AppLogger.error('Analysis correction failed', error: error);
      selectedAnalysis = analysis.copyWith(
        correctionNote: cleaned,
        warnings: [
          ...analysis.warnings,
          'Duzeltme notu kaydedildi: $cleaned',
        ],
        confidence: Confidence.low,
      );
      notifyListeners();
    } finally {
      isCorrectingAnalysis = false;
      notifyListeners();
    }
  }

  Future<void> saveAnalysis() async {
    final analysis = selectedAnalysis;
    if (analysis == null) return;

    isSavingMeal = true;
    errorMessage = null;
    notifyListeners();

    try {
      if (isAuthenticated && accessToken != null) {
        await _service.submitMealLog(
          payload: {
            'title': analysis.detectedItems.map((item) => item.name).join(', '),
            'mealType': analysis.mealType.name,
            'items': analysis.detectedItems
                .map(
                  (item) => {
                    'foodId': item.foodId,
                    'name': item.name,
                    'quantity': item.quantity,
                    'unit': item.unit,
                    'calories': item.calories,
                    'proteinGr': item.proteinGr,
                    'carbsGr': item.carbsGr,
                    'fatGr': item.fatGr,
                  },
                )
                .toList(),
          },
        );
        await _refreshMealsFromBackend();
      } else {
        meals = [
          analysis.toMeal(),
          ...meals,
        ];
      }
      selectedAnalysis = null;
      AppAnalytics.instance.logEvent('meal_saved', parameters: {'mealType': analysis.mealType.name});
    } catch (error) {
      errorMessage = AppErrorParser.message(error);
      AppLogger.error('Save meal failed', error: error);
    } finally {
      isSavingMeal = false;
      notifyListeners();
    }
  }

  Future<bool> deleteMeal(Meal meal) async {
    try {
      if (isAuthenticated && accessToken != null && meal.id != null && meal.id!.isNotEmpty) {
        await _service.deleteMeal(meal.id!);
        await _refreshMealsFromBackend();
      } else {
        meals = [...meals]..remove(meal);
      }
      AppAnalytics.instance.logEvent('meal_deleted');
      notifyListeners();
      return true;
    } catch (error) {
      errorMessage = AppErrorParser.message(error);
      AppLogger.error('Delete meal failed', error: error);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateMealItem({
    required Meal meal,
    required MealItem item,
    required double quantity,
  }) async {
    final itemId = item.id;
    if (itemId == null || itemId.isEmpty) return false;

    isUpdatingMealItem = true;
    errorMessage = null;
    notifyListeners();

    try {
      if (isAuthenticated && accessToken != null) {
        final payload = <String, dynamic>{
          'quantity': quantity,
        };
        await _service.updateMealItem(itemId: itemId, payload: payload);
        await _refreshMealsFromBackend();
      } else {
        final ratio = item.quantity == 0 ? 1.0 : quantity / item.quantity;
        meals = meals.map((mealEntry) {
          if (mealEntry.id != meal.id) return mealEntry;
          final updatedItems = mealEntry.items.map((entryItem) {
            if (entryItem.id != item.id) return entryItem;
            return entryItem.copyWith(
              quantity: quantity,
              calories: (entryItem.calories * ratio).round(),
              proteinGr: (entryItem.proteinGr * ratio).round(),
              carbsGr: (entryItem.carbsGr * ratio).round(),
              fatGr: (entryItem.fatGr * ratio).round(),
            );
          }).toList();
          final totalCalories = updatedItems.fold<int>(0, (sum, entryItem) => sum + entryItem.calories);
          final macros = updatedItems.fold<MacroTargets>(
            MacroTargets(proteinGr: 0, carbsGr: 0, fatGr: 0),
            (partial, entryItem) => MacroTargets(
              proteinGr: partial.proteinGr + entryItem.proteinGr,
              carbsGr: partial.carbsGr + entryItem.carbsGr,
              fatGr: partial.fatGr + entryItem.fatGr,
            ),
          );
          return mealEntry.copyWith(
            totalCalories: totalCalories,
            macros: macros,
            items: updatedItems,
          );
        }).toList();
      }
      AppAnalytics.instance.logEvent('meal_item_updated');
      notifyListeners();
      return true;
    } catch (error) {
      errorMessage = AppErrorParser.message(error);
      AppLogger.error('Update meal item failed', error: error);
      notifyListeners();
      return false;
    } finally {
      isUpdatingMealItem = false;
      notifyListeners();
    }
  }

  Future<bool> addFoodToMeal({
    required FoodSearchResult food,
    required MealType mealType,
    required double quantity,
    FoodServingOption? serving,
  }) async {
    final selectedServing = serving ?? food.primaryServing;
    final payloadItem = food.toMealItemPayload(quantity: quantity, serving: selectedServing);

    isSavingMeal = true;
    errorMessage = null;
    notifyListeners();

    try {
      final payload = {
        'title': food.name,
        'mealType': mealType.name,
        'items': [
          {
            ...payloadItem,
            'confidence': selectedServing != null ? 'high' : 'medium',
          },
        ],
      };

      if (isAuthenticated && accessToken != null) {
        await _service.submitMealLog(payload: payload);
        await _refreshMealsFromBackend();
      } else {
        final calories = payloadItem['calories'] as int? ?? 0;
        final proteinGr = payloadItem['proteinGr'] as int? ?? 0;
        final carbsGr = payloadItem['carbsGr'] as int? ?? 0;
        final fatGr = payloadItem['fatGr'] as int? ?? 0;
        meals = [
          Meal(
            mealType: mealType,
            title: food.name,
            totalCalories: calories,
            macros: MacroTargets(proteinGr: proteinGr, carbsGr: carbsGr, fatGr: fatGr),
            items: [
              MealItem(
                name: food.name,
                quantity: quantity,
                unit: selectedServing?.metricUnit ?? selectedServing?.description ?? 'serving',
                calories: calories,
                proteinGr: proteinGr,
                carbsGr: carbsGr,
                fatGr: fatGr,
                foodId: food.id,
              ),
            ],
          ),
          ...meals,
        ];
      }

      AppAnalytics.instance.logEvent('food_quick_add');
      notifyListeners();
      return true;
    } catch (error) {
      errorMessage = AppErrorParser.message(error);
      AppLogger.error('Food add failed', error: error);
      notifyListeners();
      return false;
    } finally {
      isSavingMeal = false;
      notifyListeners();
    }
  }

  void addQuickMeal(PlannedMeal meal) {
    meals = [
      Meal(
        mealType: meal.mealType,
        title: meal.title,
        totalCalories: meal.calories,
        macros: MacroTargets(proteinGr: 20, carbsGr: 30, fatGr: 12),
        items: [
          MealItem(
            name: meal.title,
            quantity: 1,
            unit: 'serving',
            calories: meal.calories,
            proteinGr: 20,
            carbsGr: 30,
            fatGr: 12,
          ),
        ],
      ),
      ...meals,
    ];
    AppAnalytics.instance.logEvent('quick_add');
    notifyListeners();
  }

  void editPlannedMeal(PlannedMeal original, PlannedMeal updated) {
    dailyPlan = dailyPlan.map((item) => item.id == original.id ? updated : item).toList();
    AppAnalytics.instance.logEvent('daily_plan_edited');
    notifyListeners();
  }

  void replacePlannedMeal(PlannedMeal original, PlannedMeal replacement) {
    final normalized = replacement.copyWith(
      id: original.id,
      recipeId: replacement.recipeId ?? replacement.id,
    );
    dailyPlan = dailyPlan.map((item) => item.id == original.id ? normalized : item).toList();
    AppAnalytics.instance.logEvent('daily_plan_alternative_selected');
    notifyListeners();
  }

  Future<void> applyPlannedMeal(PlannedMeal meal) async {
    isSavingMeal = true;
    errorMessage = null;
    notifyListeners();

    try {
      final mealModel = Meal(
        mealType: meal.mealType,
        title: meal.title,
        totalCalories: meal.calories,
        macros: MacroTargets(
          proteinGr: meal.proteinGr,
          carbsGr: meal.carbsGr,
          fatGr: meal.fatGr,
        ),
        items: meal.ingredients.isEmpty
            ? [
                MealItem(
                  name: meal.title,
                  quantity: 1,
                  unit: 'serving',
                  calories: meal.calories,
                  proteinGr: meal.proteinGr,
                  carbsGr: meal.carbsGr,
                  fatGr: meal.fatGr,
                ),
              ]
            : meal.ingredients
                .map(
                  (ingredient) => MealItem(
                    name: ingredient.name,
                    quantity: 1,
                    unit: ingredient.unit,
                    calories: (meal.calories / meal.ingredients.length).round(),
                    proteinGr: (meal.proteinGr / meal.ingredients.length).round(),
                    carbsGr: (meal.carbsGr / meal.ingredients.length).round(),
                    fatGr: (meal.fatGr / meal.ingredients.length).round(),
                  ),
                )
                .toList(),
      );

      if (isAuthenticated && accessToken != null) {
        await _service.submitMealLog(
          payload: {
            'title': meal.title,
            'mealType': meal.mealType.name,
            'items': mealModel.items
                .map(
                  (item) => {
                    'name': item.name,
                    'quantity': item.quantity,
                    'unit': item.unit,
                    'calories': item.calories,
                    'proteinGr': item.proteinGr,
                    'carbsGr': item.carbsGr,
                    'fatGr': item.fatGr,
                  },
                )
                .toList(),
          },
        );
        await _refreshMealsFromBackend();
      } else {
        meals = [mealModel, ...meals];
      }

      dailyPlan = dailyPlan
          .map((item) => item.id == meal.id ? item.copyWith(isApplied: true) : item)
          .toList();
      AppAnalytics.instance.logEvent('daily_plan_applied');
      notifyListeners();
    } catch (error) {
      errorMessage = AppErrorParser.message(error);
      AppLogger.error('Apply planned meal failed', error: error);
      notifyListeners();
    } finally {
      isSavingMeal = false;
      notifyListeners();
    }
  }

  void sendChat(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    chatMessages = [
      ...chatMessages,
      ChatMessage(role: ChatRole.user, text: trimmed),
      ChatMessage(
        role: ChatRole.assistant,
        text: 'Bugunku protein hedefin icin aksam ogununde yogurt veya izgara tavuk iyi gider. Istersen plana ekleyebilirim.',
      ),
    ];
    AppAnalytics.instance.logEvent('chat_message_sent');
    notifyListeners();
  }

  Future<void> _syncProfileFromSession(Session session) async {
    final authUser = session.user;
    final email = authUser.email ?? user.email;
    final emailPrefix = email.split('@').first;
    final displayName = user.name.isNotEmpty && user.name != 'Umut'
        ? user.name
        : (emailPrefix.isNotEmpty ? emailPrefix : 'Umut');

    final seededProfile = UserProfile(
      id: authUser.id,
      name: displayName,
      email: email,
      gender: user.gender,
      age: user.age,
      heightCm: user.heightCm,
      weightKg: user.weightKg,
      targetWeightKg: user.targetWeightKg,
      selectedGoal: user.selectedGoal,
      activityLevel: user.activityLevel,
      preferredLoggingMethod: user.preferredLoggingMethod,
      onboardingCompleted: user.onboardingCompleted,
    );

    final response = await _service.refreshProfile(profile: seededProfile.toSupabaseMap());
    final profileData = response['profile'];
    if (profileData is Map<String, dynamic>) {
      user = UserProfile.fromSupabase(profileData, email: email);
    } else {
      user = seededProfile;
    }
  }

  Future<void> _refreshMealsFromBackend() async {
    if (!isAuthenticated || accessToken == null) return;
    try {
      final mealMaps = await _service.listMeals();
      meals = mealMaps.map(Meal.fromSupabase).toList();
    } catch (error) {
      AppLogger.error('Meal refresh failed', error: error);
    }
  }

  Future<void> _refreshDailyPlanFromBackend() async {
    if (!isAuthenticated || accessToken == null) return;
    try {
      final planItems = await _service.getDailyPlan();
      if (planItems.isNotEmpty) {
        dailyPlan = planItems;
      }
    } catch (error) {
      AppLogger.error('Daily plan refresh failed', error: error);
    }
  }

  Future<void> _hydrateAuthenticatedSession(Session session) async {
    await _syncProfileFromSession(session);
    await _refreshMealsFromBackend();
    await _refreshDailyPlanFromBackend();
  }

  void _applySessionToShell() {
    final nextState = isAuthenticated
        ? (user.onboardingCompleted ? ShellState.main : ShellState.onboarding)
        : (hasSeenWelcome ? ShellState.auth : ShellState.welcome);
    _setShellState(nextState);
  }

  void _setShellState(ShellState nextState) {
    if (shellState == nextState) return;
    shellState = nextState;
    AppAnalytics.instance.logScreen(nextState.name);
  }

  String _screenNameForTab(int index) {
    return switch (index) {
      0 => 'home',
      1 => 'food',
      2 => 'plan',
      3 => 'progress',
      4 => 'profile',
      _ => 'main',
    };
  }

  MealAnalysis _analysisFromResponse(
    Map<String, dynamic> response,
    MealType fallbackMealType, {
    MealSourceType sourceType = MealSourceType.text,
    String? sourceLabel,
  }) {
    final macros = response['macros'] as Map<String, dynamic>? ?? const {};
    final items = (response['detectedItems'] as List<dynamic>? ?? const [])
        .map(
          (dynamic item) => MealItem(
            foodId: item is Map<String, dynamic> ? item['foodId'] as String? : null,
            name: item is Map<String, dynamic> ? (item['name'] as String? ?? 'Food') : 'Food',
            quantity: item is Map<String, dynamic> ? (item['quantity'] as num?)?.toDouble() ?? 1 : 1,
            unit: item is Map<String, dynamic> ? (item['unit'] as String? ?? 'serving') : 'serving',
            calories: item is Map<String, dynamic> ? (item['calories'] as num?)?.toInt() ?? 0 : 0,
            proteinGr: item is Map<String, dynamic> ? (item['proteinGr'] as num?)?.toInt() ?? 0 : 0,
            carbsGr: item is Map<String, dynamic> ? (item['carbsGr'] as num?)?.toInt() ?? 0 : 0,
            fatGr: item is Map<String, dynamic> ? (item['fatGr'] as num?)?.toInt() ?? 0 : 0,
          ),
        )
        .toList();

    return MealAnalysis(
      analysisId: response['analysisId']?.toString(),
      mealType: fallbackMealType,
      confidence: Confidence.medium,
      totalCalories: (response['totalCalories'] as num?)?.toInt() ?? 0,
      macros: MacroTargets(
        proteinGr: (macros['proteinGr'] as num?)?.toInt() ?? 0,
        carbsGr: (macros['carbsGr'] as num?)?.toInt() ?? 0,
        fatGr: (macros['fatGr'] as num?)?.toInt() ?? 0,
      ),
      detectedItems: items.isEmpty ? MockData.analysis.detectedItems : items,
      sourceType: sourceType,
      sourceLabel: sourceLabel,
      warnings: (response['warnings'] as List<dynamic>? ?? const []).map((e) => e.toString()).toList(),
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

class _FoodPopularityBucket {
  _FoodPopularityBucket({
    required this.food,
    required this.count,
  });

  FoodSearchResult food;
  int count;
}
