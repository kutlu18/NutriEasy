// chat domain models — split from core/models.dart.
// Do not import directly; use the 'package:nutri_easy_flutter/core/models.dart' barrel.
import 'meal.dart';
import 'plan.dart';

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


