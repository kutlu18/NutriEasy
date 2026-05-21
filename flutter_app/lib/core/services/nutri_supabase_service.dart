import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import '../models.dart';

class NutriSupabaseService {
  SupabaseClient get client => Supabase.instance.client;

  String? get accessToken => client.auth.currentSession?.accessToken;

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) {
    return client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) {
    return client.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<void> requestPasswordReset({
    required String email,
  }) {
    return client.auth.resetPasswordForEmail(
      email,
      redirectTo: AppConfig.supabaseAuthRedirectUrl,
    );
  }

  Future<void> updatePassword({
    required String password,
  }) async {
    await client.auth.updateUser(
      UserAttributes(password: password),
    );
  }

  Future<Map<String, dynamic>> analyzeText({
    required String text,
    required String mealType,
    Map<String, dynamic>? profile,
  }) async {
    final response = await client.functions.invoke(
      'analyze-text',
      body: {
        'text': text,
        'mealType': mealType,
        if (profile != null) 'profile': profile,
      },
      headers: _authHeaders,
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> correctAnalysis({
    required Map<String, dynamic> analysis,
    required String note,
    Map<String, dynamic>? profile,
  }) async {
    final response = await client.functions.invoke(
      'meal-analysis-correct',
      body: {
        'analysis': analysis,
        'note': note,
        if (profile != null) 'profile': profile,
      },
      headers: _authHeaders,
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> analyzeImage({
    required String imageLabel,
    required String mealType,
    Map<String, dynamic>? profile,
  }) async {
    final response = await client.functions.invoke(
      'analyze-image',
      body: {
        'imageLabel': imageLabel,
        'mealType': mealType,
        if (profile != null) 'profile': profile,
      },
      headers: _authHeaders,
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> submitMealLog({
    required Map<String, dynamic> payload,
  }) async {
    final response = await client.functions.invoke(
      'submit-meal-log',
      body: payload,
      headers: _authHeaders,
    );
    return _asMap(response.data);
  }

  Future<List<Map<String, dynamic>>> listMeals() async {
    final response = await client.functions.invoke(
      'meals',
      method: HttpMethod.get,
      headers: _authHeaders,
    );

    final data = response.data;
    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item.cast<String, dynamic>()))
          .toList();
    }

    if (data is Map<String, dynamic>) {
      final meals = data['meals'];
      if (meals is List) {
        return meals
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item.cast<String, dynamic>()))
            .toList();
      }
    }

    return const [];
  }

  Future<void> deleteMeal(String mealId) async {
    await client.functions.invoke(
      'meals',
      method: HttpMethod.delete,
      headers: _authHeaders,
      queryParameters: {'id': mealId},
    );
  }

  Future<Map<String, dynamic>> updateMealItem({
    required String itemId,
    required Map<String, dynamic> payload,
  }) async {
    final response = await client.functions.invoke(
      'meal-items',
      method: HttpMethod.patch,
      body: {
        'id': itemId,
        ...payload,
      },
      headers: _authHeaders,
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> refreshProfile({
    required Map<String, dynamic> profile,
  }) async {
    final response = await client.functions.invoke(
      'profile-refresh',
      body: {
        'profile': profile,
      },
      headers: _authHeaders,
    );
    return _asMap(response.data);
  }

  Future<List<PlannedMeal>> getDailyPlan({
    DateTime? date,
  }) async {
    final response = await client.functions.invoke(
      'plans-daily',
      method: HttpMethod.get,
      queryParameters: {
        if (date != null) 'date': date.toIso8601String().split('T').first,
      },
      headers: _authHeaders,
    );

    final data = response.data;
    final planMap = _asMap(data);
    final items = planMap['items'];
    if (items is List) {
      return items
          .whereType<Map>()
          .map((item) => _plannedMealFromMap(Map<String, dynamic>.from(item.cast<String, dynamic>())))
          .toList();
    }
    return const [];
  }

  Future<Map<String, dynamic>> getRecipe({
    required String id,
  }) async {
    final response = await client.functions.invoke(
      'recipes',
      method: HttpMethod.get,
      queryParameters: {'id': id},
      headers: _authHeaders,
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> applyDailyPlan({
    required String planItemId,
  }) async {
    final response = await client.functions.invoke(
      'plans-daily-apply',
      method: HttpMethod.post,
      body: {'planItemId': planItemId},
      headers: _authHeaders,
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> replaceDailyPlanAlternative({
    required String planItemId,
    required String alternativeRecipeId,
  }) async {
    final response = await client.functions.invoke(
      'plans-daily-alternative',
      method: HttpMethod.post,
      body: {
        'planItemId': planItemId,
        'alternativeRecipeId': alternativeRecipeId,
      },
      headers: _authHeaders,
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> createMealFromRecipe({
    required String recipeId,
  }) async {
    final response = await client.functions.invoke(
      'meals-from-recipe',
      method: HttpMethod.post,
      body: {'recipeId': recipeId},
      headers: _authHeaders,
    );
    return _asMap(response.data);
  }

  Future<ProgressSummary> getProgressSummary() async {
    final response = await client.functions.invoke(
      'progress-summary',
      method: HttpMethod.get,
      headers: _authHeaders,
    );

    final data = _asMap(response.data);
    final summary = data['summary'];
    if (summary is Map<String, dynamic>) {
      return ProgressSummary.fromMap(summary);
    }
    return ProgressSummary.fromMap(data);
  }

  Future<Map<String, dynamic>> getProgressMetric({
    required String metric,
  }) async {
    final response = await client.functions.invoke(
      'progress-metric',
      method: HttpMethod.get,
      queryParameters: {'metric': metric},
      headers: _authHeaders,
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> getHydrationStatus() async {
    final response = await client.functions.invoke(
      'progress-hydration',
      method: HttpMethod.get,
      headers: _authHeaders,
    );
    return _asMap(response.data);
  }

  Future<Map<String, dynamic>> getStepsStatus() async {
    final response = await client.functions.invoke(
      'progress-steps',
      method: HttpMethod.get,
      headers: _authHeaders,
    );
    return _asMap(response.data);
  }

  Future<FastingSummary> getFastingCurrent() async {
    final response = await client.functions.invoke(
      'fasting-current',
      method: HttpMethod.get,
      headers: _authHeaders,
    );
    final data = _asMap(response.data);
    final summary = data['summary'];
    if (summary is Map<String, dynamic>) {
      return FastingSummary.fromMap(summary);
    }
    return FastingSummary.fromMap(data);
  }

  Future<FastingSummary> startFasting() async {
    final response = await client.functions.invoke(
      'fasting-start',
      method: HttpMethod.post,
      headers: _authHeaders,
    );
    final data = _asMap(response.data);
    final summary = data['summary'];
    if (summary is Map<String, dynamic>) {
      return FastingSummary.fromMap(summary);
    }
    return FastingSummary.fromMap(data);
  }

  Future<FastingSummary> endFasting({
    String? breakReason,
  }) async {
    final response = await client.functions.invoke(
      'fasting-end',
      method: HttpMethod.post,
      body: {
        if (breakReason != null) 'breakReason': breakReason,
      },
      headers: _authHeaders,
    );
    final data = _asMap(response.data);
    final summary = data['summary'];
    if (summary is Map<String, dynamic>) {
      return FastingSummary.fromMap(summary);
    }
    return FastingSummary.fromMap(data);
  }

  Future<FastingSummary> updateFastingPlan({
    required Map<String, dynamic> plan,
  }) async {
    final response = await client.functions.invoke(
      'fasting-plan',
      method: HttpMethod.patch,
      body: plan,
      headers: _authHeaders,
    );
    final data = _asMap(response.data);
    final summary = data['summary'];
    if (summary is Map<String, dynamic>) {
      return FastingSummary.fromMap(summary);
    }
    return FastingSummary.fromMap(data);
  }

  Future<List<FastingSession>> loadFastingHistory() async {
    final response = await client.functions.invoke(
      'fasting-history',
      method: HttpMethod.get,
      headers: _authHeaders,
    );
    final data = _asMap(response.data);
    final history = data['history'];
    if (history is List) {
      return history
          .whereType<Map>()
          .map((item) => FastingSession.fromMap(Map<String, dynamic>.from(item.cast<String, dynamic>())))
          .toList();
    }
    final sessions = data['sessions'];
    if (sessions is List) {
      return sessions
          .whereType<Map>()
          .map((item) => FastingSession.fromMap(Map<String, dynamic>.from(item.cast<String, dynamic>())))
          .toList();
    }
    return const [];
  }

  Future<List<FoodSearchResult>> searchFoods({
    required String query,
    String region = 'TR',
    String language = 'tr',
  }) async {
    final response = await client.functions.invoke(
      'food-search',
      method: HttpMethod.get,
      queryParameters: {
        'q': query,
        'region': region,
        'language': language,
      },
      headers: _authHeaders,
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      final results = data['results'];
      if (results is List) {
        return results
            .whereType<Map>()
            .map((item) => FoodSearchResult.fromSupabase(Map<String, dynamic>.from(item.cast<String, dynamic>())))
            .toList();
      }
    }

    if (data is String && data.isNotEmpty) {
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic>) {
        final results = decoded['results'];
        if (results is List) {
          return results
              .whereType<Map>()
              .map((item) => FoodSearchResult.fromSupabase(Map<String, dynamic>.from(item.cast<String, dynamic>())))
              .toList();
        }
      }
    }

    return const [];
  }

  Map<String, String> get _authHeaders {
    final token = accessToken;
    if (token == null || token.isEmpty) {
      return const {};
    }
    return {'Authorization': 'Bearer $token'};
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is String && data.isNotEmpty) {
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    }
    return <String, dynamic>{};
  }

  PlannedMeal _plannedMealFromMap(Map<String, dynamic> data) {
    final ingredients = (data['ingredients'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(RecipeIngredient.fromMap)
        .toList();
    final alternatives = (data['alternatives'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(_plannedMealFromMap)
        .toList();
    final mealType = mealTypeFromDb(data['meal_type']);

    return PlannedMeal(
      id: data['id']?.toString(),
      recipeId: data['recipe_id']?.toString(),
      mealType: mealType,
      title: data['title']?.toString() ?? mealType.title,
      description: data['description']?.toString() ?? '',
      calories: (data['calories'] as num?)?.round() ?? 0,
      proteinGr: (data['protein_gr'] as num?)?.round() ?? 0,
      carbsGr: (data['carbs_gr'] as num?)?.round() ?? 0,
      fatGr: (data['fat_gr'] as num?)?.round() ?? 0,
      prepMinutes: (data['prep_minutes'] as num?)?.toInt() ?? 0,
      cookMinutes: (data['cook_minutes'] as num?)?.toInt() ?? 0,
      servings: (data['servings'] as num?)?.toInt() ?? 1,
      ingredients: ingredients,
      steps: (data['steps'] as List<dynamic>? ?? const []).map((e) => e.toString()).toList(),
      alternatives: alternatives,
      isApplied: data['is_applied'] as bool? ?? false,
      note: data['note']?.toString(),
    );
  }
}
