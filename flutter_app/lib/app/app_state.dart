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
        fastingHistory = const [],
        chatSuggestionChips = const [],
        chatRecipeCards = const [],
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
  ProgressSummary? progressSummary;
  FastingSummary? fastingSummary;
  List<FastingSession> fastingHistory;
  List<String> foodSearchHistory = const [];
  ChatThread? chatThread;
  List<ChatSuggestionChip> chatSuggestionChips;
  List<ChatRecipeCard> chatRecipeCards;
  MealAnalysis? selectedAnalysis;
  List<ChatMessage> chatMessages;
  bool isLoadingProgress = false;
  bool isLoadingFasting = false;
  bool isLoadingChat = false;
  bool isSendingChat = false;

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

  ProgressSummary get progressSnapshot => progressSummary ?? _buildProgressSummary();

  FastingSummary get fastingSnapshot => fastingSummary ?? _buildLocalFastingSummary();

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
    } else {
      fastingSummary = _buildLocalFastingSummary();
      fastingHistory = fastingSummary?.history ?? const [];
      _resetChatLocalState();
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
      progressSummary = null;
      fastingSummary = null;
      fastingHistory = const [];
      chatThread = null;
      _resetChatLocalState();
      isLoadingProgress = false;
      isLoadingFasting = false;
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
      await _refreshFastingState();
      await _refreshProgressSummary();
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
        await _refreshProgressSummary();
        await _refreshFastingState();
      } else {
        meals = [
          analysis.toMeal(),
          ...meals,
        ];
        progressSummary = _buildProgressSummary();
        fastingSummary = _buildLocalFastingSummary();
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
        await _refreshProgressSummary();
        await _refreshFastingState();
      } else {
        meals = [...meals]..remove(meal);
        progressSummary = _buildProgressSummary();
        fastingSummary = _buildLocalFastingSummary();
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
        await _refreshProgressSummary();
        await _refreshFastingState();
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
        progressSummary = _buildProgressSummary();
        fastingSummary = _buildLocalFastingSummary();
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
        await _refreshProgressSummary();
        await _refreshFastingState();
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
        progressSummary = _buildProgressSummary();
        fastingSummary = _buildLocalFastingSummary();
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
    progressSummary = _buildProgressSummary();
    fastingSummary = _buildLocalFastingSummary();
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
        await _refreshProgressSummary();
        await _refreshFastingState();
      } else {
        meals = [mealModel, ...meals];
        progressSummary = _buildProgressSummary();
        fastingSummary = _buildLocalFastingSummary();
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

  Future<void> sendChat(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    isSendingChat = true;
    errorMessage = null;
    notifyListeners();

    final draft = ChatMessage(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      role: ChatRole.user,
      text: trimmed,
    );

    try {
      if (isAuthenticated && accessToken != null) {
        final thread = await _service.sendChatMessage(
          message: trimmed,
          threadId: chatThread?.id,
          context: _buildChatContextPayload(),
        );
        chatThread = thread;
        chatMessages = thread.messages.isNotEmpty ? thread.messages : [...chatMessages, draft];
        chatSuggestionChips = thread.suggestionChips;
        chatRecipeCards = thread.recipeCards;
      } else {
        final assistant = _localChatReply(trimmed);
        chatMessages = [
          ...chatMessages,
          draft,
          assistant,
        ];
        chatSuggestionChips = assistant.suggestionChips;
        chatRecipeCards = assistant.recipeCards;
      }

      AppAnalytics.instance.logEvent('chat_message_sent');
      notifyListeners();
    } catch (error) {
      errorMessage = AppErrorParser.message(error);
      AppLogger.error('Chat send failed', error: error);
      chatMessages = [
        ...chatMessages,
        draft,
        ChatMessage(
          role: ChatRole.assistant,
          text: 'Suan kısa bir bağlantı sorunu var. İstersen bugün ne yemeliyim, proteinim yeterli mi ya da hafif akşam öner diye sorabilirsin.',
        ),
      ];
      notifyListeners();
    } finally {
      isSendingChat = false;
      notifyListeners();
    }
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

  Future<void> refreshProgressSummary() => _refreshProgressSummary();

  Future<void> refreshFastingState() => _refreshFastingState();

  Future<void> _refreshProgressSummary() async {
    isLoadingProgress = true;
    notifyListeners();

    try {
      if (isAuthenticated && accessToken != null) {
        progressSummary = await _service.getProgressSummary();
      } else {
        progressSummary = _buildProgressSummary();
      }
    } catch (error) {
      AppLogger.error('Progress refresh failed', error: error);
      progressSummary = _buildProgressSummary();
    } finally {
      isLoadingProgress = false;
      notifyListeners();
    }
  }

  Future<void> _refreshFastingState() async {
    isLoadingFasting = true;
    notifyListeners();

    try {
      if (isAuthenticated && accessToken != null) {
        final summary = await _service.getFastingCurrent();
        fastingSummary = summary;
        fastingHistory = summary.history;
      } else {
        fastingSummary = _buildLocalFastingSummary();
        fastingHistory = fastingSummary?.history ?? const [];
      }
    } catch (error) {
      AppLogger.error('Fasting refresh failed', error: error);
      fastingSummary = _buildLocalFastingSummary();
      fastingHistory = fastingSummary?.history ?? const [];
    } finally {
      isLoadingFasting = false;
      notifyListeners();
    }
  }

  Future<void> _refreshChatThread() async {
    isLoadingChat = true;
    notifyListeners();

    try {
      if (isAuthenticated && accessToken != null) {
        final thread = await _service.loadChatThread(context: _buildChatContextPayload());
        chatThread = thread;
        chatMessages = thread.messages.isNotEmpty ? thread.messages : _defaultChatMessages();
        chatSuggestionChips = thread.suggestionChips.isNotEmpty ? thread.suggestionChips : _defaultChatSuggestions();
        chatRecipeCards = thread.recipeCards.isNotEmpty ? thread.recipeCards : _defaultChatRecipes();
      } else {
        _resetChatLocalState();
      }
    } catch (error) {
      AppLogger.error('Chat refresh failed', error: error);
      _resetChatLocalState();
    } finally {
      isLoadingChat = false;
      notifyListeners();
    }
  }

  Future<void> refreshChatThread() => _refreshChatThread();

  void _resetChatLocalState() {
    chatThread = null;
    chatMessages = _defaultChatMessages();
    chatSuggestionChips = _defaultChatSuggestions();
    chatRecipeCards = _defaultChatRecipes();
  }

  List<ChatMessage> _defaultChatMessages() {
    return [
      ChatMessage(
        id: 'assistant-welcome',
        role: ChatRole.assistant,
        text: 'Merhaba, ben Nuri. Bugün ne yemeliyim, proteinim yeterli mi ya da hafif akşam öner gibi sorularla yardımcı olabilirim.',
        suggestionChips: _defaultChatSuggestions(),
        recipeCards: _defaultChatRecipes(),
        quickActions: const ['camera', 'voice', 'food-search'],
        contextSummary: _chatContextHeadline(),
      ),
    ];
  }

  List<ChatSuggestionChip> _defaultChatSuggestions() {
    return [
      ChatSuggestionChip(label: 'Bugün ne yemeliyim?', prompt: 'Bugün ne yemeliyim?'),
      ChatSuggestionChip(label: 'Bu öğün dengeli mi?', prompt: 'Bu öğün dengeli mi?'),
      ChatSuggestionChip(label: 'Proteinim yeterli mi?', prompt: 'Proteinim yeterli mi?'),
      ChatSuggestionChip(label: 'Hafif akşam öner', prompt: 'Hafif akşam öner'),
      ChatSuggestionChip(label: 'Bu yemek kaç kalori?', prompt: 'Bu yemek kaç kalori?'),
    ];
  }

  List<ChatRecipeCard> _defaultChatRecipes() {
    final meals = dailyPlan.take(3).toList();
    return meals.map(_chatRecipeCardFromPlan).toList();
  }

  ChatRecipeCard _chatRecipeCardFromPlan(PlannedMeal meal) {
    return ChatRecipeCard(
      recipeId: meal.recipeId ?? meal.id ?? meal.title.toLowerCase().replaceAll(' ', '-'),
      title: meal.title,
      subtitle: meal.description,
      mealType: meal.mealType,
      description: meal.description,
      calories: meal.calories,
      proteinGr: meal.proteinGr,
      carbsGr: meal.carbsGr,
      fatGr: meal.fatGr,
      prepMinutes: meal.prepMinutes,
      cookMinutes: meal.cookMinutes,
      servings: meal.servings,
      ingredients: meal.ingredients,
      steps: meal.steps,
    );
  }

  ChatMessage _localChatReply(String text) {
    final lower = text.toLowerCase();
    final progress = progressSnapshot;
    final fasting = fastingSnapshot;
    final remaining = progress.calorieTarget - progress.consumedCalories;
    final proteinLeft = progress.macroTargets.proteinGr - progress.consumedMacros.proteinGr;

    if (lower.contains('protein')) {
      return ChatMessage(
        role: ChatRole.assistant,
        text: proteinLeft <= 0
            ? 'Protein hedefini bugün doldurmuşsun. İstersen akşamı daha hafif ve dengeli tutacak bir seçenek çıkarayım.'
            : 'Şu an protein hedefinde yaklaşık ${proteinLeft.clamp(0, 9999)} g boşluk var. Tavuk, yoğurt, yumurta veya baklagil iyi bir tamamlayıcı olur.',
        suggestionChips: _defaultChatSuggestions(),
        recipeCards: _defaultChatRecipes().take(2).toList(),
        quickActions: const ['camera', 'voice', 'food-search'],
        contextSummary: _chatContextHeadline(),
      );
    }

    if (lower.contains('kaç kalori') || lower.contains('kalori')) {
      return ChatMessage(
        role: ChatRole.assistant,
        text: 'Bugün hedefin ${progress.calorieTarget} kcal, şu ana kadar ${progress.consumedCalories} kcal aldın. Kalan yaklaşık ${remaining.clamp(0, 9999)} kcal. İstersen son öğününü de birlikte yorumlayayım.',
        suggestionChips: _defaultChatSuggestions(),
        recipeCards: _defaultChatRecipes().take(1).toList(),
        quickActions: const ['camera', 'food-search'],
        contextSummary: fasting.statusLabel,
      );
    }

    if (lower.contains('hafif akşam') || lower.contains('akşam')) {
      return ChatMessage(
        role: ChatRole.assistant,
        text: fasting.currentState == FastingStateLabel.active
            ? 'Fasting planın aktif olduğu için akşamı çok ağır tutmadan kapatmak iyi olur. Hafif akşam önerilerini aşağıya bıraktım.'
            : 'Bugün için hafif, dengeli ve yorucu olmayan birkaç akşam önerisi hazırladım.',
        suggestionChips: _defaultChatSuggestions(),
        recipeCards: _defaultChatRecipes()
            .where((recipe) => recipe.mealType == MealType.dinner)
            .toList(),
        quickActions: const ['camera', 'voice', 'food-search'],
        contextSummary: fasting.statusDetail,
      );
    }

    return ChatMessage(
      role: ChatRole.assistant,
      text: 'Bugün hedefe yakın kalmak için yemekleri protein ağırlıklı ve sade tutmak iyi görünüyor. İstersen mevcut öğününü değerlendirip tek tek bakayım.',
      suggestionChips: _defaultChatSuggestions(),
      recipeCards: _defaultChatRecipes(),
      quickActions: const ['camera', 'voice', 'food-search'],
      contextSummary: _chatContextHeadline(),
    );
  }

  String _chatContextHeadline() {
    final summary = progressSnapshot;
    final fasting = fastingSnapshot;
    return '${summary.calorieTarget} kcal hedef • ${summary.consumedCalories} kcal tüketildi • ${fasting.statusLabel}';
  }

  Map<String, dynamic> _buildChatContextPayload() {
    final summary = progressSnapshot;
    final fasting = fastingSnapshot;
    final recentMeals = meals.take(5).map(
          (meal) => {
            'id': meal.id,
            'title': meal.title,
            'mealType': meal.mealType.name,
            'calories': meal.totalCalories,
            'proteinGr': meal.macros.proteinGr,
            'carbsGr': meal.macros.carbsGr,
            'fatGr': meal.macros.fatGr,
            'loggedAt': meal.createdAt.toIso8601String(),
          },
        )
        .toList();

    final planItems = dailyPlan.take(4).map(_chatRecipeCardFromPlan).map((card) => card.toMap()).toList();

    return {
      'dailyCaloriesTarget': dashboard.calorieTarget,
      'todayConsumedCalories': dashboard.consumedCalories,
      'todayRemainingCalories': dashboard.remainingCalories,
      'macroTargets': {
        'proteinGr': dashboard.macroTargets.proteinGr,
        'carbsGr': dashboard.macroTargets.carbsGr,
        'fatGr': dashboard.macroTargets.fatGr,
      },
      'consumedMacros': {
        'proteinGr': dashboard.consumedMacros.proteinGr,
        'carbsGr': dashboard.consumedMacros.carbsGr,
        'fatGr': dashboard.consumedMacros.fatGr,
      },
      'progress': summary.toMap(),
      'fasting': fasting.toMap(),
      'activePlan': planItems,
      'recentMeals': recentMeals,
      'goal': user.selectedGoal.name,
      'activityLevel': user.activityLevel.name,
      'loggingPreference': user.preferredLoggingMethod.name,
    };
  }

  Future<bool> startFastingSession() async {
    isLoadingFasting = true;
    errorMessage = null;
    notifyListeners();

    try {
      if (isAuthenticated && accessToken != null) {
        fastingSummary = await _service.startFasting();
        fastingHistory = fastingSummary?.history ?? const [];
      } else {
        final plan = _defaultFastingPlanForProfile();
        final now = DateTime.now();
        final session = FastingSession(
          id: now.millisecondsSinceEpoch.toString(),
          status: FastingSessionStatus.active,
          targetHours: plan.targetHours,
          plannedStartAt: now.toIso8601String(),
          plannedEndAt: now.add(Duration(hours: plan.targetHours)).toIso8601String(),
          startedAt: now.toIso8601String(),
          metabolicPhase: FastingPhase.earlyFast,
          fastingWindowStart: plan.windowStart,
          fastingWindowEnd: plan.windowEnd,
          createdAt: now.toIso8601String(),
          updatedAt: now.toIso8601String(),
        );
        fastingHistory = [session, ...fastingHistory];
        fastingSummary = _buildLocalFastingSummary().copyWith(
          currentSession: session,
          history: fastingHistory,
          currentState: FastingStateLabel.active,
          statusLabel: 'Aktif oruç',
          statusDetail: 'Yerel modda oturum başlatıldı.',
          timerLabel: '00s 00dk',
          progress: 0,
          fastedMinutes: 0,
          remainingMinutes: plan.targetHours * 60,
        );
      }
      await _refreshProgressSummary();
      notifyListeners();
      return true;
    } catch (error) {
      errorMessage = AppErrorParser.message(error);
      AppLogger.error('Fasting start failed', error: error);
      notifyListeners();
      return false;
    } finally {
      isLoadingFasting = false;
      notifyListeners();
    }
  }

  Future<bool> endFastingSession({
    String? breakReason,
  }) async {
    isLoadingFasting = true;
    errorMessage = null;
    notifyListeners();

    try {
      if (isAuthenticated && accessToken != null) {
        fastingSummary = await _service.endFasting(breakReason: breakReason);
        fastingHistory = fastingSummary?.history ?? const [];
      } else {
        final summary = fastingSummary ?? _buildLocalFastingSummary();
        final session = summary.currentSession;
        if (session != null) {
          final ended = session.copyWith(
            status: breakReason == null ? FastingSessionStatus.completed : FastingSessionStatus.cancelled,
            endedAt: DateTime.now().toIso8601String(),
            actualDurationMinutes: session.durationMinutes,
            breakReason: breakReason,
            updatedAt: DateTime.now().toIso8601String(),
            metabolicPhase: breakReason == null ? FastingPhase.recovery : FastingPhase.recovery,
          );
          fastingHistory = [
            ended,
            ...fastingHistory.where((item) => item.id != ended.id),
          ];
          fastingSummary = summary.copyWith(
            currentSession: ended,
            history: fastingHistory,
            currentState: FastingStateLabel.completed,
            statusLabel: breakReason == null ? 'Tamamlandı' : 'Oruç kapatıldı',
            statusDetail: breakReason ?? 'Yerel modda oturum kapatıldı.',
            metabolicPhase: FastingPhase.recovery,
            metabolicPhaseLabel: FastingPhase.recovery.title,
            metabolicPhaseDetail: 'Yeniden beslenme penceresi.',
            timerLabel: ended.durationLabel,
            progress: 1,
            fastedMinutes: ended.durationMinutes,
            remainingMinutes: 0,
          );
        }
      }
      await _refreshProgressSummary();
      notifyListeners();
      return true;
    } catch (error) {
      errorMessage = AppErrorParser.message(error);
      AppLogger.error('Fasting end failed', error: error);
      notifyListeners();
      return false;
    } finally {
      isLoadingFasting = false;
      notifyListeners();
    }
  }

  Future<bool> updateFastingPlan({
    required FastingPlan plan,
  }) async {
    isLoadingFasting = true;
    errorMessage = null;
    notifyListeners();

    try {
      if (isAuthenticated && accessToken != null) {
        fastingSummary = await _service.updateFastingPlan(plan: plan.toMap());
        fastingHistory = fastingSummary?.history ?? fastingHistory;
      } else {
        fastingSummary = (fastingSummary ?? _buildLocalFastingSummary()).copyWith(
          plan: plan,
          statusLabel: plan.enabled ? 'Başlamaya hazır' : 'Plan kapalı',
          statusDetail: plan.enabled
              ? 'Plan ${plan.label} olarak güncellendi.'
              : 'Plan kapatıldı.',
        );
      }
      await _refreshProgressSummary();
      notifyListeners();
      return true;
    } catch (error) {
      errorMessage = AppErrorParser.message(error);
      AppLogger.error('Fasting plan update failed', error: error);
      notifyListeners();
      return false;
    } finally {
      isLoadingFasting = false;
      notifyListeners();
    }
  }

  ProgressSummary _buildProgressSummary() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(const Duration(days: 6));
    final weeklyMeals = meals.where((meal) {
      final logged = meal.createdAt;
      final day = DateTime(logged.year, logged.month, logged.day);
      return !day.isBefore(weekStart) && !day.isAfter(today);
    }).toList();

    final caloriesByDay = <DateTime, int>{};
    final macrosByDay = <DateTime, MacroTargets>{};

    for (final meal in weeklyMeals) {
      final logged = meal.createdAt;
      final day = DateTime(logged.year, logged.month, logged.day);
      caloriesByDay[day] = (caloriesByDay[day] ?? 0) + meal.totalCalories;
      final currentMacros = macrosByDay[day] ?? MacroTargets(proteinGr: 0, carbsGr: 0, fatGr: 0);
      macrosByDay[day] = MacroTargets(
        proteinGr: currentMacros.proteinGr + meal.macros.proteinGr,
        carbsGr: currentMacros.carbsGr + meal.macros.carbsGr,
        fatGr: currentMacros.fatGr + meal.macros.fatGr,
      );
    }

    final dailyTarget = calorieTargetForProfile;
    final weeklyTarget = dailyTarget * 7;
    final weeklyConsumed = caloriesByDay.values.fold<int>(0, (sum, value) => sum + value);
    final weeklyBalance = weeklyTarget - weeklyConsumed;
    final macros = weeklyMeals.fold<MacroTargets>(
      MacroTargets(proteinGr: 0, carbsGr: 0, fatGr: 0),
      (partial, meal) => MacroTargets(
        proteinGr: partial.proteinGr + meal.macros.proteinGr,
        carbsGr: partial.carbsGr + meal.macros.carbsGr,
        fatGr: partial.fatGr + meal.macros.fatGr,
      ),
    );
    final weightKg = user.weightKg.toDouble();
    final targetWeightKg = (user.targetWeightKg ?? user.weightKg).toDouble();
    final estimatedDeltaKg = weeklyBalance / 7700.0;
    final startingWeight = weightKg - estimatedDeltaKg;

    final trend = List<ProgressTrendPoint>.generate(7, (index) {
      final day = weekStart.add(Duration(days: index));
      final balanceToDay = caloriesByDay.entries
          .where((entry) => !entry.key.isAfter(day))
          .fold<int>(0, (sum, entry) => sum + (dailyTarget - entry.value));
      final projectedWeight = startingWeight + (balanceToDay / 7700.0);
      return ProgressTrendPoint(
        date: day,
        weightKg: projectedWeight,
        caloriesConsumed: caloriesByDay[day] ?? 0,
        calorieTarget: dailyTarget,
      );
    });

    final streakDays = _calculateStreakDays(weeklyMeals);
    final hydrationTarget = 8;
    final hydrationCurrent = _estimateHydration(currentMeals: weeklyMeals.length, streakDays: streakDays);
    final stepsTarget = _stepsTargetForProfile;
    final stepsCurrent = _estimateSteps(
      meals: weeklyMeals.length,
      calorieAverage: weeklyConsumed / 7.0,
      streakDays: streakDays,
    );
    final achievements = _buildAchievements(
      streakDays: streakDays,
      consumedMacros: macros,
      macroTargets: macroTargetsForProfile,
      calorieBalance: weeklyBalance,
    );

    return ProgressSummary(
      weekStart: weekStart,
      weekEnd: today,
      calorieTarget: weeklyTarget,
      consumedCalories: weeklyConsumed,
      calorieBalance: weeklyBalance,
      macroTargets: MacroTargets(
        proteinGr: macroTargetsForProfile.proteinGr * 7,
        carbsGr: macroTargetsForProfile.carbsGr * 7,
        fatGr: macroTargetsForProfile.fatGr * 7,
      ),
      consumedMacros: macros,
      currentWeightKg: weightKg,
      targetWeightKg: targetWeightKg,
      estimatedWeightDeltaKg: estimatedDeltaKg,
      streakDays: streakDays,
      hydrationCurrent: hydrationCurrent,
      hydrationTarget: hydrationTarget,
      stepsCurrent: stepsCurrent,
      stepsTarget: stepsTarget,
      mealCount: weeklyMeals.length,
      weightTrend: trend,
      achievements: achievements,
      weeklyInsight: _buildWeeklyInsight(
        weeklyConsumed: weeklyConsumed,
        weeklyTarget: weeklyTarget,
        consumedMacros: macros,
        macroTargets: macroTargetsForProfile,
        streakDays: streakDays,
        estimatedDeltaKg: estimatedDeltaKg,
      ),
      isEmpty: weeklyMeals.isEmpty,
      source: isAuthenticated ? 'backend-calculated' : 'local-calculated',
    );
  }

  FastingSummary _buildLocalFastingSummary() {
    final plan = _defaultFastingPlanForProfile();
    final session = fastingSummary?.currentSession;
    final history = fastingHistory;
    final startedAtIso = session?.startedAt;
    final mealsSinceStart = startedAtIso == null
        ? 0
        : meals.where((meal) => meal.createdAt.isAfter(DateTime.tryParse(startedAtIso) ?? meal.createdAt)).length;
    final fastedMinutes = session?.durationMinutes ?? 0;
    final remainingMinutes = session?.durationRemainingMinutes ?? 0;
    final activeState = session == null
        ? (plan.enabled ? FastingStateLabel.ready : FastingStateLabel.idle)
        : switch (session.status) {
            FastingSessionStatus.active => mealsSinceStart > 0 ? FastingStateLabel.broken : FastingStateLabel.active,
            FastingSessionStatus.completed => FastingStateLabel.completed,
            FastingSessionStatus.cancelled => FastingStateLabel.completed,
            FastingSessionStatus.planned => FastingStateLabel.ready,
          };

    final metabolicPhase = session?.metabolicPhase ?? FastingPhase.fed;
    final statusLabel = switch (activeState) {
      FastingStateLabel.idle => 'Plan kapalı',
      FastingStateLabel.ready => 'Başlamaya hazır',
      FastingStateLabel.active => 'Aktif oruç',
      FastingStateLabel.broken => 'Oruç bozuldu',
      FastingStateLabel.completed => 'Son oturum tamamlandı',
    };
    final statusDetail = switch (activeState) {
      FastingStateLabel.idle => 'Fasting planı kapalı; istersen buradan açabiliriz.',
      FastingStateLabel.ready => 'Plan ${plan.label} olarak ayarlı. ${plan.windowStart} - ${plan.windowEnd} penceresi hazır.',
      FastingStateLabel.active => 'Yerel moda göre oturum sürüyor.',
      FastingStateLabel.broken => 'Başlangıçtan sonra öğün kaydı var.',
      FastingStateLabel.completed => 'Son oturum tamamlandı.',
    };

    return FastingSummary(
      plan: plan,
      currentSession: session,
      history: history,
      currentState: activeState,
      statusLabel: statusLabel,
      statusDetail: statusDetail,
      metabolicPhase: metabolicPhase,
      metabolicPhaseLabel: metabolicPhase.title,
      metabolicPhaseDetail: switch (metabolicPhase) {
        FastingPhase.earlyFast => 'Son öğünden sonra vücut önce glikozu kullanıyor.',
        FastingPhase.fatBurning => 'Yağ kullanımına geçiş başlıyor.',
        FastingPhase.deepFast => 'Su ve elektrolit takibi önemli.',
        FastingPhase.recovery => 'Yeniden beslenme penceresi.',
        FastingPhase.fed => 'Beslenme penceresi açık.',
      },
      timerLabel: session?.durationLabel ?? '00s 00dk',
      progress: session?.progress() ?? 0,
      fastedMinutes: fastedMinutes,
      remainingMinutes: remainingMinutes,
      mealSinceStartCount: mealsSinceStart,
      weeklyInsight: plan.enabled
          ? 'Fasting plani hazir; baslatildiginda state otomatik guncellenecek.'
          : 'Plan kapali görünüyor.',
      achievements: history.isNotEmpty ? ['Son fasting kaydı hazır'] : ['İlk fasting oturumu için hazır'],
      isEmpty: !plan.enabled && history.isEmpty && session == null,
    );
  }

  FastingPlan _defaultFastingPlanForProfile() {
    return switch (user.selectedGoal) {
      Goal.gainMuscle => FastingPlan(enabled: true, targetHours: 14, windowStart: '21:00', windowEnd: '11:00', label: '14:10'),
      Goal.maintain => FastingPlan(enabled: true, targetHours: 16, windowStart: '20:30', windowEnd: '12:30', label: '16:8'),
      Goal.fasting => FastingPlan(enabled: true, targetHours: 18, windowStart: '20:00', windowEnd: '12:00', label: '18:6'),
      Goal.weightLoss => FastingPlan(enabled: true, targetHours: 18, windowStart: '20:00', windowEnd: '12:00', label: '18:6'),
    };
  }

  int _calculateStreakDays(List<Meal> mealsForWeek) {
    final byDay = <DateTime>{};
    for (final meal in mealsForWeek) {
      final created = meal.createdAt;
      byDay.add(DateTime(created.year, created.month, created.day));
    }

    int streak = 0;
    final today = DateTime.now();
    for (int offset = 0; offset < 30; offset++) {
      final day = DateTime(today.year, today.month, today.day).subtract(Duration(days: offset));
      if (!byDay.contains(day)) break;
      streak += 1;
    }

    return streak;
  }

  int _estimateHydration({
    required int currentMeals,
    required int streakDays,
  }) {
    final estimated = 3 + currentMeals + (streakDays ~/ 2);
    return estimated.clamp(3, 8);
  }

  int get _stepsTargetForProfile => switch (user.activityLevel) {
        ActivityLevel.sedentary => 6000,
        ActivityLevel.light => 7500,
        ActivityLevel.moderate => 9000,
        ActivityLevel.active => 10500,
      };

  int _estimateSteps({
    required int meals,
    required double calorieAverage,
    required int streakDays,
  }) {
    final baseline = switch (user.activityLevel) {
      ActivityLevel.sedentary => 4200,
      ActivityLevel.light => 5600,
      ActivityLevel.moderate => 6800,
      ActivityLevel.active => 8200,
    };
    final mealBoost = meals * 350;
    final streakBoost = streakDays * 120;
    final calorieBoost = (calorieAverage / 2).round();
    final value = baseline + mealBoost + streakBoost + calorieBoost;
    return value.clamp(3000, _stepsTargetForProfile + 1800);
  }

  List<String> _buildAchievements({
    required int streakDays,
    required MacroTargets consumedMacros,
    required MacroTargets macroTargets,
    required int calorieBalance,
  }) {
    final achievements = <String>[];

    if (streakDays >= 3) {
      achievements.add('$streakDays gunluk kayit serisi');
    }

    final proteinRatio = macroTargets.proteinGr == 0 ? 0.0 : consumedMacros.proteinGr / macroTargets.proteinGr;
    if (proteinRatio >= 0.8) {
      achievements.add('Protein hedefinin %80+ seviyesine ulastin');
    }

    if (calorieBalance.abs() <= 250) {
      achievements.add('Kalori dengesi hedefe yakin');
    }

    if (achievements.isEmpty) {
      achievements.add('Bu hafta yeni bir hedef yakalamak icin iyi bir baslangic var');
    }

    return achievements;
  }

  String _buildWeeklyInsight({
    required int weeklyConsumed,
    required int weeklyTarget,
    required MacroTargets consumedMacros,
    required MacroTargets macroTargets,
    required int streakDays,
    required double estimatedDeltaKg,
  }) {
    final caloriesGap = weeklyTarget - weeklyConsumed;
    final proteinRatio = macroTargets.proteinGr == 0 ? 0.0 : consumedMacros.proteinGr / macroTargets.proteinGr;
    final calorieLine = caloriesGap >= 0
        ? 'Bu hafta kalori dengesi hedefe yakin; yaklasik ${caloriesGap ~/ 7} kcal gunluk acik var.'
        : 'Bu hafta hedefin uzerine cikilmis; gunluk ortalama ${(-caloriesGap) ~/ 7} kcal fazla gorunuyor.';
    final proteinLine = proteinRatio >= 0.8
        ? 'Protein tarafi guclu ilerliyor.'
        : 'Protein miktarini biraz artirmak hedefe daha hizli yaklastirir.';
    final streakLine = streakDays >= 3
        ? 'Serin tutarlı gidiyor.'
        : 'Bir kac gunluk düzenli kayıt, trendi daha net hale getirir.';
    final weightLine = estimatedDeltaKg >= 0
        ? 'Mevcut gidişat tahmini olarak ${estimatedDeltaKg.toStringAsFixed(1)} kg kayip potansiyeli gosteriyor.'
        : 'Mevcut gidişat tahmini olarak ${estimatedDeltaKg.abs().toStringAsFixed(1)} kg artis tarafinda.';

    return '$calorieLine $proteinLine $streakLine $weightLine';
  }

  Future<void> _hydrateAuthenticatedSession(Session session) async {
    await _syncProfileFromSession(session);
    await _refreshMealsFromBackend();
    await _refreshDailyPlanFromBackend();
    await _refreshProgressSummary();
    await _refreshFastingState();
    await _refreshChatThread();
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
